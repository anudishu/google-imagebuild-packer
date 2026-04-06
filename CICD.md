# CI notes

Repository is proprietary; see root `NOTICE`. GitHub Actions live under `.github/workflows/`. Each workflow is scoped to path changes (e.g. `terraform/rhel8/**`).

- Packer workflows: mostly `packer init` + `packer validate` + ansible syntax-check. Add a build step if you want images built in CI.
- Terraform workflows: fmt check, init, validate, plan on PR; apply on push to `main` or manual dispatch (see yaml for destroy).

Secret: `GCP_SA_KEY` (JSON for a SA that can run terraform / compute in your project).

Local equivalent before push: `./scripts/validate-all.sh` or `make validate`.
