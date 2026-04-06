#!/usr/bin/env bash
# Quick checks: repo files present, gcloud on PATH, optional ADC.
# ./scripts/preflight-gcp.sh [--require-auth]
set -euo pipefail

REQUIRE_AUTH=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --require-auth) REQUIRE_AUTH=1 ;;
    -h|--help)
      head -n 12 "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
  esac
  shift
done

log() { printf '%s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
err() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

check_cmd() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    warn "no $name in PATH (might be ok depending what you’re doing)"
    return 1
  fi
  return 0
}

# --- creds file on disk -------------------------------------------------------

if [[ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
  if [[ ! -f "${GOOGLE_APPLICATION_CREDENTIALS}" ]]; then
    err "GOOGLE_APPLICATION_CREDENTIALS points at a file that doesn’t exist: ${GOOGLE_APPLICATION_CREDENTIALS}"
  fi
  log "using json key from GOOGLE_APPLICATION_CREDENTIALS"
fi

if [[ -n "${CLOUDSDK_CORE_PROJECT:-}" ]]; then
  log "CLOUDSDK_CORE_PROJECT=${CLOUDSDK_CORE_PROJECT}"
fi

# --- gcloud -------------------------------------------------------------------

if check_cmd gcloud; then
  # core version line is enough noise for logs
  log "gcloud: $(gcloud version --format='value(core)' 2>/dev/null | head -1 || echo unknown)"

  if [[ "$REQUIRE_AUTH" -eq 1 ]]; then
    gcloud auth application-default print-access-token >/dev/null 2>&1 || \
      err "no ADC token — run: gcloud auth application-default login"
    log "ADC token looks good."
  else
    if gcloud auth application-default print-access-token >/dev/null 2>&1; then
      log "ADC ok"
    else
      warn "ADC not set; maybe you rely on a service account json instead."
    fi
  fi

  active_account="$(gcloud config get-value account 2>/dev/null || true)"
  if [[ -n "$active_account" && "$active_account" != "(unset)" ]]; then
    log "gcloud account: $active_account"
  else
    warn "gcloud account unset — run: gcloud config set account <you@example.com>"
  fi
else
  warn "gcloud not installed; skipping identity bits."
fi

# --- can we hit google oauth at all (proxy / vpn issues) ------------------------

if check_cmd curl; then
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 https://oauth2.googleapis.com/ || true)"
  if [[ "$code" == "000" ]]; then
    warn "curl couldn’t reach oauth2.googleapis.com — check VPN or corp proxy."
  else
    log "oauth2.googleapis.com http code: $code (anything non-000 is fine here)"
  fi
fi

# --- repo skeleton ------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

required_paths=(
  "${ROOT}/terraform/debian/simple.tf"
  "${ROOT}/terraform/windows/windows.tf"
  "${ROOT}/terraform/rhel7/simple.tf"
  "${ROOT}/terraform/rhel8/simple.tf"
  "${ROOT}/terraform/rhel9/simple.tf"
  "${ROOT}/terraform/centos7/simple.tf"
  "${ROOT}/packer/debian/simple-apache.pkr.hcl"
  "${ROOT}/packer/windows/windows-server-2016.pkr.hcl"
  "${ROOT}/packer/rhel7/httpd.pkr.hcl"
  "${ROOT}/packer/rhel8/httpd.pkr.hcl"
  "${ROOT}/packer/rhel9/httpd.pkr.hcl"
  "${ROOT}/packer/centos7/httpd.pkr.hcl"
)

for p in "${required_paths[@]}"; do
  [[ -f "$p" ]] || err "expected file missing: $p"
done
log "core tf/packer files present (${#required_paths[@]} checked)."

# --- binary smoke -------------------------------------------------------------

if check_cmd terraform; then
  terraform -version | head -n1 | sed 's/^/terraform /'
fi
if check_cmd packer; then
  packer version | head -n1 | sed 's/^/packer /'
fi

log "preflight done."
