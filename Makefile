# make validate / fmt — needs terraform, packer, ansible on PATH

REPO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
TERRAFORM_DEBIAN := $(REPO_ROOT)/terraform/debian
TERRAFORM_WINDOWS := $(REPO_ROOT)/terraform/windows
TERRAFORM_RHEL7 := $(REPO_ROOT)/terraform/rhel7
TERRAFORM_RHEL8 := $(REPO_ROOT)/terraform/rhel8
TERRAFORM_RHEL9 := $(REPO_ROOT)/terraform/rhel9
TERRAFORM_CENTOS7 := $(REPO_ROOT)/terraform/centos7
PACKER_DEBIAN := $(REPO_ROOT)/packer/debian
PACKER_WINDOWS := $(REPO_ROOT)/packer/windows
PACKER_RHEL7 := $(REPO_ROOT)/packer/rhel7
PACKER_RHEL8 := $(REPO_ROOT)/packer/rhel8
PACKER_RHEL9 := $(REPO_ROOT)/packer/rhel9
PACKER_CENTOS7 := $(REPO_ROOT)/packer/centos7
ANSIBLE_DEBIAN_PLAY := $(REPO_ROOT)/ansible/debian/simple-playbook.yml
ANSIBLE_RHEL7_PLAY := $(REPO_ROOT)/ansible/rhel7/playbook.yml
ANSIBLE_RHEL8_PLAY := $(REPO_ROOT)/ansible/rhel8/playbook.yml
ANSIBLE_RHEL9_PLAY := $(REPO_ROOT)/ansible/rhel9/playbook.yml
ANSIBLE_CENTOS7_PLAY := $(REPO_ROOT)/ansible/centos7/playbook.yml

.PHONY: help
help:
	@echo "google-imagebuild-packer — make targets"
	@echo ""
	@echo "validate          -> scripts/validate-all.sh"
	@echo "fmt / fmt-check   -> terraform + packer fmt"
	@echo "tf-validate-debian | windows | rhel7 | rhel8 | rhel9 | centos7"
	@echo "packer-validate-* and packer-validate-all"
	@echo "ansible-syntax"
	@echo ""
	@echo "Repo root: $(REPO_ROOT)"
	@echo ""

.PHONY: validate
validate:
	@$(REPO_ROOT)/scripts/validate-all.sh

.PHONY: fmt
fmt:
	terraform -chdir=$(TERRAFORM_DEBIAN) fmt
	terraform -chdir=$(TERRAFORM_WINDOWS) fmt
	terraform -chdir=$(TERRAFORM_RHEL7) fmt
	terraform -chdir=$(TERRAFORM_RHEL8) fmt
	terraform -chdir=$(TERRAFORM_RHEL9) fmt
	terraform -chdir=$(TERRAFORM_CENTOS7) fmt
	packer fmt -recursive $(REPO_ROOT)/packer

.PHONY: fmt-check
fmt-check:
	terraform -chdir=$(TERRAFORM_DEBIAN) fmt -check -recursive
	terraform -chdir=$(TERRAFORM_WINDOWS) fmt -check -recursive
	terraform -chdir=$(TERRAFORM_RHEL7) fmt -check -recursive
	terraform -chdir=$(TERRAFORM_RHEL8) fmt -check -recursive
	terraform -chdir=$(TERRAFORM_RHEL9) fmt -check -recursive
	terraform -chdir=$(TERRAFORM_CENTOS7) fmt -check -recursive
	packer fmt -check -recursive $(REPO_ROOT)/packer

.PHONY: tf-validate-debian
tf-validate-debian:
	terraform -chdir=$(TERRAFORM_DEBIAN) init -backend=false -input=false
	terraform -chdir=$(TERRAFORM_DEBIAN) validate

.PHONY: tf-validate-windows
tf-validate-windows:
	terraform -chdir=$(TERRAFORM_WINDOWS) init -backend=false -input=false
	terraform -chdir=$(TERRAFORM_WINDOWS) validate

.PHONY: tf-validate-rhel7
tf-validate-rhel7:
	terraform -chdir=$(TERRAFORM_RHEL7) init -backend=false -input=false
	terraform -chdir=$(TERRAFORM_RHEL7) validate

.PHONY: tf-validate-rhel8
tf-validate-rhel8:
	terraform -chdir=$(TERRAFORM_RHEL8) init -backend=false -input=false
	terraform -chdir=$(TERRAFORM_RHEL8) validate

.PHONY: tf-validate-rhel9
tf-validate-rhel9:
	terraform -chdir=$(TERRAFORM_RHEL9) init -backend=false -input=false
	terraform -chdir=$(TERRAFORM_RHEL9) validate

.PHONY: tf-validate-centos7
tf-validate-centos7:
	terraform -chdir=$(TERRAFORM_CENTOS7) init -backend=false -input=false
	terraform -chdir=$(TERRAFORM_CENTOS7) validate

.PHONY: packer-validate-debian
packer-validate-debian:
	packer validate $(PACKER_DEBIAN)

.PHONY: packer-validate-windows
packer-validate-windows:
	packer validate $(PACKER_WINDOWS)

.PHONY: packer-validate-rhel7
packer-validate-rhel7:
	packer validate $(PACKER_RHEL7)

.PHONY: packer-validate-rhel8
packer-validate-rhel8:
	packer validate $(PACKER_RHEL8)

.PHONY: packer-validate-rhel9
packer-validate-rhel9:
	packer validate $(PACKER_RHEL9)

.PHONY: packer-validate-centos7
packer-validate-centos7:
	packer validate $(PACKER_CENTOS7)

.PHONY: packer-validate-all
packer-validate-all: packer-validate-debian packer-validate-windows packer-validate-rhel7 packer-validate-rhel8 packer-validate-rhel9 packer-validate-centos7

.PHONY: ansible-syntax
ansible-syntax:
	ansible-playbook --syntax-check $(ANSIBLE_DEBIAN_PLAY)
	ansible-playbook --syntax-check $(ANSIBLE_RHEL7_PLAY)
	ansible-playbook --syntax-check $(ANSIBLE_RHEL8_PLAY)
	ansible-playbook --syntax-check $(ANSIBLE_RHEL9_PLAY)
	ansible-playbook --syntax-check $(ANSIBLE_CENTOS7_PLAY)
