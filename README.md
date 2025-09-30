# Simple Golden Image on Google Cloud (Packer + Ansible + Terraform)

A minimal workflow to build a Debian-based golden image with Apache and Google Cloud Ops Agent, then deploy a VM on GCP.

## What this project does
- Builds a golden image (Debian 11) with Apache installed.
- Installs and enables Google Cloud Ops Agent during image build.
- Deploys a Compute Engine VM from the golden image and opens HTTP (80).

## Structure
- `packer/simple-apache.pkr.hcl`: Packer template to build the golden image. Uses Debian 11 as base, installs Ansible, runs the playbook.
- `ansible/simple-playbook.yml`: Installs Apache, a simple index page, basic tools, and calls the Ops Agent role.
- `ansible/roles/ops_agent/`: Reusable role to install and configure Google Cloud Ops Agent.
  - `tasks/main.yml`: Installs Ops Agent using Google’s script, writes config, ensures service running.
  - `templates/ops-agent-config.yaml.j2`: Minimal default config (Apache logs + metrics, host metrics). Customize here.
  - `handlers/main.yml`: Restarts the Ops Agent on config change.
- `terraform/simple.tf`: Deploys a single VM from the latest image in the `apache-simple` family and creates an HTTP firewall rule.
- `terraform/terraform.tfvars`: Your project/zone values.

## Prerequisites
- Tools: Packer, Ansible, Terraform, Google Cloud SDK
- GCP Project with Compute API enabled
- Logged in and project set:
  - `gcloud auth login --account=admin@cloudedgetechy.com`
  - `gcloud config set project root-cortex-465610-p8`
  - `gcloud auth application-default login`

## Steps
1) Build the golden image
- `cd packer`
- `packer init simple-apache.pkr.hcl`
- `packer validate simple-apache.pkr.hcl`
- `packer build simple-apache.pkr.hcl`

2) Deploy a VM from the image
- `cd ../terraform`
- Ensure `terraform.tfvars` has: `project_id = "root-cortex-465610-p8"`, `zone = "us-central1-a"`
- `terraform init`
- `terraform apply -auto-approve`
- Output shows `instance_ip` and `instance_url`

3) Test
- `curl http://$(terraform output -raw instance_ip)`

4) Cleanup (optional)
- `terraform destroy -auto-approve`

## Ansible: Ops Agent (overview)
- This image includes Google Cloud Ops Agent installed at build time using a dedicated role.
- Role location: `ansible/roles/ops_agent/`
- What it does:
  - Downloads and runs Google’s install script (`--also-install`).
  - Writes `/etc/google-cloud-ops-agent/config.yaml` from the Jinja2 template.
  - Enables and starts the service; restarts on config changes.
- Customize logging/metrics in `templates/ops-agent-config.yaml.j2`.
- Reference: Google’s official guide “Install the Ops Agent” [link](https://cloud.google.com/monitoring/agent/ops-agent/installation).

## Ansible File Structure and Purpose
- `ansible/simple-playbook.yml`
  - Top-level play that:
    - Updates apt cache
    - Installs and starts Apache
    - Drops a simple `index.html` for validation
    - Installs basic tools (`htop`, `curl`, `wget`)
    - Calls the reusable `ops_agent` role to install/configure the Ops Agent

- `ansible/roles/ops_agent/tasks/main.yml`
  - Downloads the official Ops Agent repo script
  - Registers the repo and installs the agent (`--also-install`)
  - Renders `/etc/google-cloud-ops-agent/config.yaml` from template
  - Notifies handler to restart the agent if config changes

- `ansible/roles/ops_agent/templates/ops-agent-config.yaml.j2`
  - Central place to define logging and metrics receivers/pipelines
  - Ships with:
    - Logging for Apache access/error logs
    - Metrics for host (cpu, memory, disk, network) + Apache endpoint
  - Edit this file to add/remove integrations; rebuild the image to bake changes

- `ansible/roles/ops_agent/handlers/main.yml`
  - Contains the `Restart Ops Agent` handler
  - Ensures service is restarted after config changes so new settings take effect

## Notes
- Terraform uses the latest image from the image family `apache-simple` created by Packer.
- External IP + HTTP firewall are enabled for a simple POC. Adjust for your org’s policies as needed.
- If you change Ops Agent config, rebuild the image to bake it in.

## CIS Level 2 Hardening
This project now includes CIS (Center for Internet Security) Level 2 hardening based on the CIS Debian Linux 11 Benchmark v1.0.0.

### Security Features Applied
- **Filesystem Security**: Disabled unnecessary filesystem types (cramfs, freevxfs, jffs2, hfs, hfsplus, udf)
- **File Integrity**: AIDE installed with daily integrity checks
- **Network Security**: Disabled IPv6, configured secure network parameters, enabled SYN cookies
- **Service Hardening**: Removed unnecessary services (X11, Avahi, CUPS, DHCP, LDAP, NFS, DNS, FTP, Samba, SNMP)
- **SSH Hardening**: Secure SSH configuration with strong ciphers, disabled root login, connection limits
- **Password Policy**: Strong password requirements (14+ chars, complexity rules)
- **Audit Logging**: auditd configured for comprehensive system auditing
- **Access Control**: Proper file permissions on critical system files
- **Intrusion Prevention**: Fail2Ban configured for SSH and Apache protection
- **System Accounts**: Secured system accounts with nologin shells

### Ansible Role: CIS Hardening
- **Location**: `ansible/roles/cis_hardening/`
- **Tasks**: `tasks/main.yml` - Implements 50+ CIS Level 2 controls
- **Templates**: 
  - `sshd_config.j2` - Hardened SSH configuration
  - `pwquality.conf.j2` - Password complexity requirements
  - `securetty.j2` - Root login restrictions
  - `jail.local.j2` - Fail2Ban configuration
- **Handlers**: Service restart handlers for SSH, Fail2Ban, GRUB updates

### Build Order
The playbook now applies hardening in this order:
1. **CIS Hardening** - Security baseline first
2. **Ops Agent** - Monitoring after security is applied
3. **Apache** - Application services last

### Compliance
This implementation addresses key CIS Level 2 controls including:
- CIS 1.x: Filesystem Configuration
- CIS 2.x: Services Configuration  
- CIS 3.x: Network Configuration
- CIS 4.x: Logging and Auditing
- CIS 5.x: Access, Authentication and Authorization
- CIS 6.x: System Maintenance

### Testing Hardening
After deployment, you can verify hardening with:
```bash
# Check SSH configuration
ssh -o PreferredAuthentications=password user@instance_ip  # Should fail

# Check fail2ban status
sudo fail2ban-client status

# Check audit daemon
sudo systemctl status auditd

# Check disabled services
systemctl list-unit-files | grep disabled
```
