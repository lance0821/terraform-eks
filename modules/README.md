## modules

This folder is for reusable Terraform modules owned by this repository.

Recommended usage:

- Keep root stack orchestration in `infra/`.
- Add thin wrapper modules here around upstream/community modules when you need org defaults.
- Expose only the variables and outputs your teams should consume.

Suggested structure:

- `modules/<name>/main.tf`
- `modules/<name>/variables.tf`
- `modules/<name>/outputs.tf`
- `modules/<name>/versions.tf`

Examples:

- `modules/vpc/`
- `modules/networking/`
- `modules/eks/`
