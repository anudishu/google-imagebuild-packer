#!/bin/bash
# Golden Image Build Selector

echo "🚀 Golden Image Builder"
echo "======================"
echo "1. Debian 11 + Apache + CIS Level 2 Hardening"
echo "2. Windows Server 2016 + IIS + CIS Level 2 Hardening"
echo ""
echo "Choose your build:"
echo "- For Debian: cd packer/debian && packer init && packer build simple-apache.pkr.hcl"
echo "- For Windows: cd packer/windows && packer init && packer build windows-server-2016.pkr.hcl"
echo ""
echo "Deploy with Terraform:"
echo "- For Debian: cd terraform/debian && terraform init && terraform apply"
echo "- For Windows: cd terraform/windows && terraform init && terraform apply"
