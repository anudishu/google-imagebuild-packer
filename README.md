# Golden images on GCP (Packer + Ansible + Terraform)

## Proprietary

This repository is **proprietary and confidential**. It is for **authorized internal use only**. Do not redistribute or publish without written approval from the owning organization. Full wording is in [`NOTICE`](NOTICE).

## End-to-end scope

This is a complete delivery path on Google Cloud, not a snippet library:

1. **Image build** — Packer launches a builder VM, runs Ansible (Linux) or PowerShell (Windows), and publishes a **golden image** in your project.
2. **Infrastructure** — Terraform creates a small footprint: firewall rule, service account, and a **VM booted from that image**.
3. **Verification** — You hit the VM on port 80 (or RDP for Windows). Locally, `make validate` runs formatter checks, `terraform validate`, `packer validate`, and Ansible syntax-check before you push.
4. **Automation** — GitHub Actions workflows mirror those checks per OS path; Terraform can plan/apply in CI when wired to your secrets.

High-level diagram: **`Architecture.png`** (in repo root).

Supported OS tracks (each has its own `packer/`, `ansible/` or `ps1`, `terraform/`, and workflow files): **Debian 11**, **RHEL 7/8/9**, **CentOS 7**, **Windows Server 2016**.

## Repository layout

```
google-imagebuild-packer/
├── packer/<os>/          Packer templates
├── ansible/<os>/        Linux playbooks / roles (Windows uses ansible/windows/*.ps1)
├── terraform/<os>/      VM + firewall + SA per golden image
├── scripts/             validate-all.sh, preflight-gcp.sh
├── Makefile
├── NOTICE               proprietary statement
└── .github/workflows/   path-scoped CI
```

RHEL images use **`rhel-cloud`** (RHEL on GCP / entitlements). CentOS 7 uses **`centos-cloud`**, SSH user **`centos`**; Packer installs EPEL so `yum` can install Ansible on the builder.

## Readability and quality bar

- **One OS per folder** so reviewers can read a full vertical slice without cross-file hunting.
- **Naming** follows `packer` / `terraform` / `google` conventions (`*_httpd`, `google_compute_instance`, etc.).
- **Before a PR:** run `make validate` (or `./scripts/validate-all.sh`).
- **Secrets:** do not commit `terraform.tfvars`, service account JSON, or state (see `.gitignore`). Use each stack’s `terraform.tfvars.example` as a template.

## Prerequisites

```bash
brew install packer ansible terraform google-cloud-sdk   # mac; Linux: use your package manager
```

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud auth application-default login
```

## Example: full loop on one Linux image

Build the image:

```bash
cd packer/rhel8
packer init httpd.pkr.hcl
packer build httpd.pkr.hcl
```

Deploy a VM from it:

```bash
cd ../../terraform/rhel8
cp terraform.tfvars.example terraform.tfvars   # set project_id, zone
terraform init
terraform apply
```

Check:

```bash
terraform output
curl -sS "http://$(terraform output -raw rhel8_instance_ip)/"
```

Other OS folders follow the same pattern; image names are documented below.

## Packer: image names

| Packer folder   | Image name produced   | SSH user (builder) |
|----------------|------------------------|--------------------|
| packer/rhel7   | rhel7-httpd-golden     | cloud-user         |
| packer/rhel8   | rhel8-httpd-golden     | cloud-user         |
| packer/rhel9   | rhel9-httpd-golden     | cloud-user         |
| packer/centos7 | centos7-httpd-golden   | centos             |

Debian and Windows: see the `image_name` / `source_image` fields in the respective `.pkr.hcl` files and the matching `data "google_compute_image"` in Terraform.

## Packer build commands (all OS)

**Debian**

```bash
cd packer/debian && packer init simple-apache.pkr.hcl && packer build simple-apache.pkr.hcl
```

**RHEL / CentOS** — swap directory (`rhel7`, `rhel8`, `rhel9`, `centos7`):

```bash
cd packer/rhel8 && packer init httpd.pkr.hcl && packer build httpd.pkr.hcl
```

**Windows**

```bash
cd packer/windows && packer init windows-server-2016.pkr.hcl && packer build windows-server-2016.pkr.hcl
```

## Terraform

For each OS, `cd terraform/<os>`, copy `terraform.tfvars.example` → `terraform.tfvars` where provided, set `project_id` and `zone`, then `terraform init` and `terraform apply`.

**Debian** smoke test (output name may vary — use `terraform output`):

```bash
curl http://$(terraform output -raw instance_ip)
```

**RHEL** stacks expose outputs such as `rhel8_instance_ip` / `rhel8_instance_url`.

## Local validation (no cloud apply)

```bash
make validate
# or
./scripts/validate-all.sh
./scripts/preflight-gcp.sh    # optional: paths + gcloud sanity
```

## CI (GitHub Actions)

Workflows under `.github/workflows/` trigger on path changes. Packer jobs validate templates and Ansible syntax; Terraform jobs run plan/apply per your branch rules. Secret: **`GCP_SA_KEY`**. Details: [`CICD.md`](CICD.md).

## Operational notes

- WinRM build hangs: usually metadata password or firewall — use builder logs / serial console.
- Renamed Packer image: update the matching Terraform image lookup.
- Optional disk snapshots: set `enable_disk_snapshot_schedule` (and Windows equivalent) where defined.
