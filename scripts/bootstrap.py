#!/usr/bin/env python3
import os
import sys
import subprocess
import time
from pathlib import Path
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.prompt import Prompt, Confirm
from rich.theme import Theme
import inquirer

# Custom dark-theme console
custom_theme = Theme({
    "info": "cyan",
    "warning": "yellow",
    "danger": "bold red",
    "success": "bold green"
})
console = Console(theme=custom_theme)

# Locate repository root reliably by finding .git directory
current_dir = Path(__file__).resolve().parent
REPO_ROOT = current_dir
while REPO_ROOT != REPO_ROOT.parent:
    if (REPO_ROOT / ".git").exists():
        break
    REPO_ROOT = REPO_ROOT.parent

# Central Management & Billing Details
HUB_PROJECT_ID = "p-tf-state-mgmt"
CENTRAL_SA = "gha-central-runner@p-tf-state-mgmt.iam.gserviceaccount.com"
STATE_BUCKET = "p-tf-state-mgmt-bucket"

DEFAULT_BILLING_NAME = "My Billing Account"
DEFAULT_BILLING_ID = "019268-9979CD-2C267E"
DEFAULT_BILLING_DISPLAY = f"{DEFAULT_BILLING_NAME} ({DEFAULT_BILLING_ID})"

def run_command(cmd):
    """Executes a shell command and returns success boolean, stdout, and stderr"""
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        return True, result.stdout, result.stderr
    except subprocess.CalledProcessError as e:
        return False, e.stdout, e.stderr

def extract_billing_id(billing_input):
    """Extracts the raw billing ID if the user inputs name + ID or just ID"""
    if "(" in billing_input and ")" in billing_input:
        return billing_input.split("(")[-1].replace(")", "").strip()
    return billing_input.strip()

def main():
    console.clear()
    console.print(Panel.fit(
        "[bold cyan]GCP Project & Infrastructure Bootstrapper[/bold cyan]\n"
        "[dim]Interactive onboarding CLI for core, non-prod, and prod tiers[/dim]",
        border_style="cyan"
    ))

    # --- Step 1: Select Target Domain / Environment Tier ---
    env_question = [
        inquirer.List(
            'env',
            message="Select Target Domain / Environment Tier",
            choices=['np (Non-Production)', 'pd (Production)', 'core (Platform Infrastructure)'],
        )
    ]
    env_answer = inquirer.prompt(env_question)
    if not env_answer:
        console.print("[danger]Onboarding cancelled.[/danger]")
        sys.exit(1)

    env = env_answer['env'].split()[0]  # 'np', 'pd', or 'core'

    # --- Step 2: Dynamic Sub-domain Selection ---
    if env == 'np':
        subdomain_choices = ['adt', 'spt']
    elif env == 'pd':
        subdomain_choices = ['ppe', 'prd']
    else:  # 'core'
        subdomain_choices = ['iam', 'net']

    subdomain_question = [
        inquirer.List(
            'subdomain',
            message=f"Select Sub-domain for [{env}]",
            choices=subdomain_choices,
        )
    ]
    subdomain_answer = inquirer.prompt(subdomain_question)
    if not subdomain_answer:
        console.print("[danger]Onboarding cancelled.[/danger]")
        sys.exit(1)

    subdomain = subdomain_answer['subdomain']

    # --- Step 3: Enter Suffix with Hyphen Handling ---
    raw_suffix = Prompt.ask(
        "\nEnter Project Suffix (e.g. [bold yellow]-landing[/bold yellow], [bold yellow]-de[/bold yellow], or [bold yellow]-hub[/bold yellow])"
    ).strip()

    clean_suffix = raw_suffix.lstrip('-')
    project_id = f"p-{env}-{subdomain}-{clean_suffix}".lower()

    # --- Step 4: Billing Account Selection ---
    billing_input = Prompt.ask(
        "\nEnter GCP Billing Account Name & ID",
        default=DEFAULT_BILLING_DISPLAY
    ).strip()

    billing_id = extract_billing_id(billing_input)

    # Calculate target directory inside REPO_ROOT/terraform_gcp
    rel_target_dir = Path("terraform_gcp") / env / subdomain / project_id
    abs_target_dir = (REPO_ROOT / rel_target_dir).resolve()

    # Confirm setup details
    console.print(f"\n[bold]Target Project ID:[/bold] [green]{project_id}[/green]")
    console.print(f"[bold]Target Directory (Relative):[/bold] [green]{rel_target_dir}/[/green]")
    console.print(f"[bold]Target Directory (Absolute):[/bold] [yellow]{abs_target_dir}/[/yellow]")
    console.print(f"[bold]State File Path:[/bold] [green]gs://{STATE_BUCKET}/{env}/{subdomain}/{project_id}/state/[/green]")
    console.print(f"[bold]Billing Account:[/bold] [green]{DEFAULT_BILLING_NAME} ({billing_id})[/green]\n")

    confirm = Confirm.ask("Proceed with GCP bootstrap and file generation?", default=True)
    if not confirm:
        console.print("[warning]Aborted.[/warning]")
        sys.exit(0)

    # Check project existence before building task list
    project_exists, _, _ = run_command(f"gcloud projects describe {project_id}")

    # --- Step 5: Automated Bootstrap Pipeline ---
    console.print("\n[bold cyan]Starting Bootstrap Sequence...[/bold cyan]\n")

    tasks = []
    
    if project_exists:
        console.print(f"[info]✓ Project '{project_id}' already exists in GCP. Skipping project creation.[/info]\n")
    else:
        tasks.append(("Creating GCP Project...", f"gcloud projects create {project_id} --name='{project_id}'"))

    if billing_id:
        tasks.append(("Linking Billing Account...", f"gcloud billing projects link {project_id} --billing-account={billing_id}"))

    tasks.extend([
        ("Enabling Core APIs (Resource Manager, Service Usage, Compute)...", 
         f"gcloud services enable cloudresourcemanager.googleapis.com serviceusage.googleapis.com compute.googleapis.com --project={project_id}"),
        ("Granting IAM Editor to Central Runner Service Account...", 
         f"gcloud projects add-iam-policy-binding {project_id} --member='serviceAccount:{CENTRAL_SA}' --role='roles/editor'"),
        ("Granting Service Usage Admin to Central Runner...", 
         f"gcloud projects add-iam-policy-binding {project_id} --member='serviceAccount:{CENTRAL_SA}' --role='roles/serviceusage.serviceUsageAdmin'"),
    ])

    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        console=console
    ) as progress:
        
        for desc, cmd in tasks:
            task_id = progress.add_task(description=desc, total=None)
            success, stdout, stderr = run_command(cmd)
            
            if success:
                progress.update(task_id, description=f"[success]✓ {desc}[/success]")
            else:
                err_msg = stderr.strip().split('\n')[-1] if stderr else "Command completed with warnings/non-zero exit."
                progress.update(task_id, description=f"[warning]! {desc}\n  └── Reason: {err_msg}[/warning]")
            
            time.sleep(0.5)

    # --- Step 6: Generate Local Terraform Files ---
    console.print("\n[bold cyan]Generating Local Terraform Files...[/bold cyan]")
    
    os.makedirs(abs_target_dir, exist_ok=True)

    # provider.tf
    provider_content = f"""terraform {{
  required_version = ">= 1.5.0"
  required_providers {{
    google = {{
      source  = "hashicorp/google"
      version = "~> 5.0"
    }}
  }}

  backend "gcs" {{
    bucket = "{STATE_BUCKET}"
    prefix = "{env}/{subdomain}/{project_id}/state"
  }}
}}

provider "google" {{
  project = var.project_id
  region  = var.region
  zone    = var.zone
}}
"""
    with open(abs_target_dir / "provider.tf", "w") as f:
        f.write(provider_content)

    # variables.tf
    variables_content = f"""variable "project_id" {{
  type    = string
  default = "{project_id}"
}}

variable "region" {{
  type    = string
  default = "us-west1"
}}

variable "zone" {{
  type    = string
  default = "us-west1-a"
}}
"""
    with open(abs_target_dir / "variables.tf", "w") as f:
        f.write(variables_content)

    # api.tf
    api_content = f"""resource "google_project_service" "compute_api" {{
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}}
"""
    with open(abs_target_dir / "api.tf", "w") as f:
        f.write(api_content)

    # main.tf
    main_content = f"""# Primary resources for {project_id}

resource "google_compute_instance" "vm_instance" {{
  depends_on   = [google_project_service.compute_api]
  name         = "{project_id}-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {{
    initialize_params {{
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 20
      type  = "pd-standard"
    }}
  }}

  network_interface {{
    network = "default"
    access_config {{}}
  }}
}}
"""
    with open(abs_target_dir / "main.tf", "w") as f:
        f.write(main_content)

    console.print(Panel.fit(
        f"[bold green]Project Bootstrap Complete![/bold green]\n\n"
        f"Target Path: [yellow]{abs_target_dir}/[/yellow]\n\n"
        f"[dim]Next steps:\n"
        f" 1. cd {abs_target_dir}\n"
        f" 2. terraform init\n"
        f" 3. terraform plan[/dim]",
        border_style="green"
    ))

if __name__ == "__main__":
    main()