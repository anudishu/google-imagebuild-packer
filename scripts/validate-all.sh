#!/usr/bin/env bash
# fmt-check + terraform validate (all stacks), packer init/validate, ansible syntax-check.
# Does not apply anything. Fails the script on real errors.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# no ansi if not a tty
if [[ -t 1 ]]; then
  RED=$'\033[0;31m'
  GRN=$'\033[0;32m'
  YLW=$'\033[0;33m'
  DIM=$'\033[2m'
  RST=$'\033[0m'
else
  RED="" GRN="" YLW="" DIM="" RST=""
fi

STAGES_RAN=0
STAGES_OK=0

usage() {
  sed -n '1,120p' "$0" | sed -n '/^#/,$p' | head -n 22
  cat <<'EOF'

Usage: validate-all.sh [options]

  --skip-terraform     skip terraform
  --skip-packer        skip packer
  --skip-ansible       skip ansible syntax
  --skip-shellcheck    don’t run shellcheck/shfmt even if present
  -h, --help           this text

You can set TF_CLI_ARGS_init for plugin cache dirs etc.; terraform passes it through.

EOF
}

SKIP_TERRAFORM=0
SKIP_PACKER=0
SKIP_ANSIBLE=0
SKIP_SHELLCHECK=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-terraform) SKIP_TERRAFORM=1 ;;
    --skip-packer) SKIP_PACKER=1 ;;
    --skip-ansible) SKIP_ANSIBLE=1 ;;
    --skip-shellcheck) SKIP_SHELLCHECK=1 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "${RED}Unknown option:${RST} $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

log_section() {
  echo ""
  echo "${GRN}==>${RST} $*"
}

log_info() {
  echo "${DIM}    $*${RST}"
}

log_warn() {
  echo "${YLW}WARN:${RST} $*"
}

stage_ok() {
  STAGES_RAN=$((STAGES_RAN + 1))
  STAGES_OK=$((STAGES_OK + 1))
  echo "${GRN}OK${RST}  $*"
}

stage_fail() {
  STAGES_RAN=$((STAGES_RAN + 1))
  echo "${RED}FAIL${RST} $*"
  return 1
}

require_cmd() {
  local c="$1"
  if ! command -v "$c" >/dev/null 2>&1; then
    log_warn "no '$c' on PATH"
    return 1
  fi
  return 0
}

# Terraform
run_terraform_stages() {
  log_section "Terraform (fmt -check, init -backend=false, validate)"

  local roots=(
    "${REPO_ROOT}/terraform/debian"
    "${REPO_ROOT}/terraform/windows"
    "${REPO_ROOT}/terraform/rhel7"
    "${REPO_ROOT}/terraform/rhel8"
    "${REPO_ROOT}/terraform/rhel9"
    "${REPO_ROOT}/terraform/centos7"
  )

  for root in "${roots[@]}"; do
    [[ -d "$root" ]] || { stage_fail "missing dir: $root"; return 1; }
    log_info "chdir $root"

    if ! terraform -chdir="$root" fmt -check -recursive; then
      stage_fail "fmt -check failed: $root"
      return 1
    fi

    if ! terraform -chdir="$root" init -backend=false -input=false; then
      stage_fail "terraform init failed: $root"
      return 1
    fi

    if ! terraform -chdir="$root" validate; then
      stage_fail "terraform validate failed: $root"
      return 1
    fi

    stage_ok "terraform ok: $root"
  done
}

# Packer
run_packer_stages() {
  log_section "Packer (fmt -check, validate)"

  local dirs=(
    "${REPO_ROOT}/packer/debian"
    "${REPO_ROOT}/packer/windows"
    "${REPO_ROOT}/packer/rhel7"
    "${REPO_ROOT}/packer/rhel8"
    "${REPO_ROOT}/packer/rhel9"
    "${REPO_ROOT}/packer/centos7"
  )

  if ! packer fmt -check -recursive "${REPO_ROOT}/packer"; then
    stage_fail "packer fmt -check failed"
    return 1
  fi

  for d in "${dirs[@]}"; do
    [[ -d "$d" ]] || { stage_fail "missing packer dir: $d"; return 1; }
    log_info "packer validate in $d"
    if ! (cd "$d" && packer init . && packer validate .); then
      stage_fail "packer validate failed: $d"
      return 1
    fi
    stage_ok "packer ok: $d"
  done
}

# Ansible (linux playbooks only here)
run_ansible_stages() {
  log_section "Ansible syntax-check"

  local plays=(
    "${REPO_ROOT}/ansible/debian/simple-playbook.yml"
    "${REPO_ROOT}/ansible/rhel7/playbook.yml"
    "${REPO_ROOT}/ansible/rhel8/playbook.yml"
    "${REPO_ROOT}/ansible/rhel9/playbook.yml"
    "${REPO_ROOT}/ansible/centos7/playbook.yml"
  )

  for play in "${plays[@]}"; do
    [[ -f "$play" ]] || { stage_fail "missing $play"; return 1; }
    if ! ansible-playbook --syntax-check "$play"; then
      stage_fail "syntax-check failed: $play"
      return 1
    fi
    log_info "ok: $play"
  done

  stage_ok "ansible syntax ok (${#plays[@]} playbooks)"
}

# optional shellcheck / shfmt
run_optional_shell_lint() {
  log_section "Shell lint (optional)"

  local scripts=(
    "${REPO_ROOT}/build-selector.sh"
    "${REPO_ROOT}/scripts/validate-all.sh"
    "${REPO_ROOT}/scripts/preflight-gcp.sh"
  )

  if command -v shellcheck >/dev/null 2>&1; then
    for s in "${scripts[@]}"; do
      [[ -f "$s" ]] || continue
      log_info "shellcheck $s"
      if ! shellcheck -x "$s"; then
        stage_fail "shellcheck: $s"
        return 1
      fi
    done
    stage_ok "shellcheck clean"
  else
    log_warn "no shellcheck — skipped."
  fi

  if command -v shfmt >/dev/null 2>&1; then
    for s in "${scripts[@]}"; do
      [[ -f "$s" ]] || continue
      if ! shfmt -d -i 2 -ci "$s" >/dev/null; then
        stage_fail "shfmt wants changes: $s"
        return 1
      fi
    done
    stage_ok "shfmt clean"
  else
    log_warn "no shfmt — skipped."
  fi
}

# quick check expected paths exist
verify_expected_paths() {
  log_section "Sanity: files still where we expect"

  local paths=(
    "${REPO_ROOT}/NOTICE"
    "${REPO_ROOT}/terraform/debian/simple.tf"
    "${REPO_ROOT}/terraform/debian/terraform.tfvars.example"
    "${REPO_ROOT}/terraform/windows/terraform.tfvars.example"
    "${REPO_ROOT}/terraform/windows/windows.tf"
    "${REPO_ROOT}/terraform/rhel7/simple.tf"
    "${REPO_ROOT}/terraform/rhel8/simple.tf"
    "${REPO_ROOT}/terraform/rhel9/simple.tf"
    "${REPO_ROOT}/terraform/centos7/simple.tf"
    "${REPO_ROOT}/packer/debian/simple-apache.pkr.hcl"
    "${REPO_ROOT}/packer/windows/windows-server-2016.pkr.hcl"
    "${REPO_ROOT}/packer/rhel7/httpd.pkr.hcl"
    "${REPO_ROOT}/packer/rhel8/httpd.pkr.hcl"
    "${REPO_ROOT}/packer/rhel9/httpd.pkr.hcl"
    "${REPO_ROOT}/packer/centos7/httpd.pkr.hcl"
    "${REPO_ROOT}/ansible/debian/simple-playbook.yml"
    "${REPO_ROOT}/ansible/rhel7/playbook.yml"
    "${REPO_ROOT}/ansible/rhel8/playbook.yml"
    "${REPO_ROOT}/ansible/rhel9/playbook.yml"
    "${REPO_ROOT}/ansible/centos7/playbook.yml"
    "${REPO_ROOT}/ansible/windows/install-iis.ps1"
    "${REPO_ROOT}/.github/workflows/packer-debian.yml"
    "${REPO_ROOT}/.github/workflows/packer-rhel7.yml"
    "${REPO_ROOT}/.github/workflows/packer-rhel8.yml"
    "${REPO_ROOT}/.github/workflows/packer-rhel9.yml"
    "${REPO_ROOT}/.github/workflows/packer-centos7.yml"
    "${REPO_ROOT}/.github/workflows/terraform-windows.yml"
    "${REPO_ROOT}/.github/workflows/terraform-rhel7.yml"
    "${REPO_ROOT}/.github/workflows/terraform-rhel8.yml"
    "${REPO_ROOT}/.github/workflows/terraform-rhel9.yml"
    "${REPO_ROOT}/.github/workflows/terraform-centos7.yml"
    "${REPO_ROOT}/scripts/preflight-gcp.sh"
  )

  local missing=0
  for p in "${paths[@]}"; do
    if [[ ! -e "$p" ]]; then
      echo "${RED}missing:${RST} $p"
      missing=1
    fi
  done

  if [[ "$missing" -ne 0 ]]; then
    stage_fail "path check failed"
    return 1
  fi

  stage_ok "paths ok"
}

main() {
  echo "${GRN}repo:${RST} $REPO_ROOT"

  require_cmd terraform || true
  require_cmd packer || true
  require_cmd ansible-playbook || true

  verify_expected_paths

  if [[ "$SKIP_TERRAFORM" -eq 0 ]]; then
    require_cmd terraform || exit 1
    run_terraform_stages
  else
    log_warn "skipping terraform (--skip-terraform)"
  fi

  if [[ "$SKIP_PACKER" -eq 0 ]]; then
    require_cmd packer || exit 1
    run_packer_stages
  else
    log_warn "skipping packer (--skip-packer)"
  fi

  if [[ "$SKIP_ANSIBLE" -eq 0 ]]; then
    require_cmd ansible-playbook || exit 1
    run_ansible_stages
  else
    log_warn "skipping ansible (--skip-ansible)"
  fi

  if [[ "$SKIP_SHELLCHECK" -eq 0 ]]; then
    run_optional_shell_lint || true
  fi

  echo ""
  echo "${GRN}ok${RST}"
}

main "$@"
