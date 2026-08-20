#!/usr/bin/env python3
import os
import sys
import subprocess
import time
import json
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

def get_existing_roles_for_sa(project_id, sa_email):
    """Fetches assigned roles for a specific Service Account on a given project"""
    cmd = f"gcloud projects get-iam-policy {project_id} --format=json"
    success, stdout, _ = run_command(cmd)
    if not success:
        return set()
    
    assigned_roles = set()
    try:
        policy = json.loads(stdout)
        member_target = f"serviceAccount:{sa_email}"
        for binding in policy.get("bindings", []):
            if member_target in binding.get("members", []):
                assigned_roles.add(binding.get("role"))
    except Exception:
        pass
    return assigned_roles

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

    # --- Step 3: Enter Suffix ---
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

    if project_exists:
        console.print(f"[info]✓ Project '{project_id}' already exists in GCP. Skipping creation.[/info]\n")
    else:
        success, _, stderr = run_command(f"gcloud projects create {project_id} --name='{project_id}'")
        if success:
            console.print(f"[success]✓ Created GCP Project '{project_id}'[/success]")
        else:
            console.print(f"[warning]! Project creation returned warning/error: {stderr.strip()}[/warning]")

    if billing_id:
        success, _, stderr = run_command(f"gcloud billing projects link {project_id} --billing-account={billing_id}")
        if success:
            console.print(f"[success]✓ Linked Billing Account ({billing_id}) to '{project_id}'[/success]")

    # Enable Core APIs required for bootstrap
    console.print("\n[bold cyan]Enabling Core APIs...[/bold cyan]")
    api_cmd = f"gcloud services enable cloudresourcemanager.googleapis.com serviceusage.googleapis.com iam.googleapis.com compute.googleapis.com secretmanager.googleapis.com artifactregistry.googleapis.com run.googleapis.com --project={project_id}"
    success, _, stderr = run_command(api_cmd)
    if success:
        console.print("[success]✓ Enabled Resource Manager, Service Usage, IAM, Compute, Secret Manager, Artifact Registry, and Cloud Run APIs[/success]")
    else:
        console.print(f"[warning]! API Enablement warning: {stderr.strip()}[/warning]")

    # --- Check & Assign Admin Roles to Central Runner SA ---
    console.print(f"\n[bold cyan]Evaluating Central Runner Roles for '{CENTRAL_SA}'...[/bold cyan]")
    existing_roles = get_existing_roles_for_sa(project_id, CENTRAL_SA)

    roles_to_grant = [
        ("roles/editor", "Editor Access"),
        ("roles/resourcemanager.projectIamAdmin", "Project IAM Admin Access"),
        ("roles/serviceusage.serviceUsageAdmin", "Service Usage Admin Access"),
        ("roles/secretmanager.admin", "Secret Manager Admin Access"),
        ("roles/artifactregistry.admin", "Artifact Registry Admin Access"),
        ("roles/run.admin", "Cloud Run Admin Access")
    ]

    for role_id, role_name in roles_to_grant:
        if role_id in existing_roles:
            console.print(f"[info]  ├── [SKIP] Role '{role_id}' ({role_name}) is already assigned to {project_id}[/info]")
        else:
            cmd = f"gcloud projects add-iam-policy-binding {project_id} --member='serviceAccount:{CENTRAL_SA}' --role='{role_id}' --condition=None"
            success, _, stderr = run_command(cmd)
            if success:
                console.print(f"[success]  ├── [ADD] Granted '{role_id}' ({role_name}) on {project_id}[/success]")
            else:
                err_msg = stderr.strip().split('\n')[-1] if stderr else "Failed binding role"
                console.print(f"[warning]  ├── [WARN] Failed granting '{role_id}': {err_msg}[/warning]")

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
    if not (abs_target_dir / "provider.tf").exists():
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
    if not (abs_target_dir / "variables.tf").exists():
        with open(abs_target_dir / "variables.tf", "w") as f:
            f.write(variables_content)

    # api.tf
    api_content = f"""resource "google_project_service" "iam_api" {{
  project            = var.project_id
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}}

resource "google_project_service" "resource_manager_api" {{
  project            = var.project_id
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}}
"""
    if not (abs_target_dir / "api.tf").exists():
        with open(abs_target_dir / "api.tf", "w") as f:
            f.write(api_content)

    # main.tf
    main_content = f"""# Primary resources for {project_id}
# Workload resources, Service Accounts, and IAM bindings should be declared in dedicated .tf files.
"""
    if not (abs_target_dir / "main.tf").exists():
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