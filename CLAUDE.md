# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## First Steps

**Your first tool call in this repository MUST be reading .claude/CODING_STANDARD.md.
Do not read any other files, search, or take any actions until you have read it.**
This contains InfraHouse's comprehensive coding standards for Terraform, Python, and general
formatting rules.

## Module Overview

This is `terraform-aws-state-bucket`, an InfraHouse Terraform module that creates an S3 bucket
and DynamoDB table for Terraform remote state storage. It implements Hashicorp and Gruntwork best
practices: versioning, AES256 encryption, public access blocking, SSL-only bucket policy, and
PAY_PER_REQUEST DynamoDB locking. The DynamoDB table name is auto-generated using a `random_pet`
resource with the bucket name as prefix.

## Build and Test Commands

```bash
make bootstrap          # Install dependencies (requirements.txt) and git hooks
make lint               # yamllint on workflows + terraform fmt -check -recursive
make format             # terraform fmt -recursive + black tests/
make test               # pytest -xvvs tests (full suite, used in CI)
make test-keep          # Run tests, keep AWS resources for debugging
make test-clean         # Run tests, destroy all AWS resources (run before PRs)
```

Tests are **integration tests** that create real AWS infrastructure via `pytest-infrahouse`.
They assume an AWS role (`arn:aws:iam::303467602807:role/state-bucket-tester`) in `us-west-1`.
The test fixture lives in `test_data/state-bucket/` and is parametrized across AWS provider
versions (`~> 5.31` and `~> 6.0`).

To run a single test:
```bash
pytest -xvvs tests/test_module.py -k "test_state_bucket and aws-6"
```

## Commit Message Format

This repo enforces **Conventional Commits** via a `hooks/commit-msg` hook.
Format: `<type>: <description>` or `<type>(scope): <description>`.
Valid types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`,
`chore`, `revert`, `security`.

## Versioning and Releases

Version is tracked in `.bumpversion.cfg` and mirrored in `locals.tf` (`module_version`) and
`README.md`. Release via `make release-patch`, `make release-minor`, or `make release-major`
(requires `git-cliff` and `bumpversion`). Releases must be from the `main` branch. The Makefile
prompts for confirmation, updates CHANGELOG.md, bumps version, but does **not** auto-push.

On tag push, CI publishes the module to `registry.infrahouse.com` via `ih-registry upload`.

## CI/CD

- **terraform-CI.yml**: Runs on PRs. Self-hosted runner, Python 3.13, runs `make bootstrap`,
  `make lint`, `make test`.
- **terraform-CD.yml**: Runs on tag push. Publishes module to InfraHouse registry.
- **Pre-commit hook** (`hooks/pre-commit`): Checks terraform fmt, runs terraform-docs to update
  README.md, verifies trailing newlines. Managed by github-control repo.

## Key Conventions

- Max line length: 120 characters for all files.
- All files must end with a newline.
- Terraform naming: snake_case everywhere.
- IAM policies: use `aws_iam_policy_document` data sources, never `jsonencode`.
- Module source pinning: exact versions only (no ranges like `~>`).
- Python dependencies: pin to major version with `~=` syntax.
- Several repo files are managed by the `github-control` repository and should not be edited
  directly: `.terraform-docs.yml`, `mkdocs.yml`, `cliff.toml`, `hooks/commit-msg`,
  `hooks/pre-commit`, and `.github/workflows/`.
