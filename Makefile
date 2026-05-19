SHELL := /usr/bin/env bash

.DEFAULT_GOAL := help
define BROWSER_PYSCRIPT
import webbrowser
webbrowser.open("docs/_build/html/index.html")
endef
export BROWSER_PYSCRIPT

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-40s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT
BROWSER := python -c "$$BROWSER_PYSCRIPT"

TEST_REGION="us-west-1"
TEST_ROLE="arn:aws:iam::303467602807:role/state-bucket-tester"

help: ## Print this help
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)


.PHONY: install-hooks
install-hooks:  ## Install repo hooks
	@echo "Checking and installing hooks"
	@test -d .git/hooks || (echo "Looks like you are not in a Git repo" ; exit 1)
	@test -L .git/hooks/pre-commit || ln -fs ../../hooks/pre-commit .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@test -L .git/hooks/commit-msg || ln -fs ../../hooks/commit-msg .git/hooks/commit-msg
	@chmod +x .git/hooks/commit-msg


.PHONY: bootstrap
bootstrap: install-hooks  ## Build development environment
	pip install -r requirements.txt

.PHONY: bootstrap-ci
bootstrap-ci:  ## Build environment for CI
	pip install -r requirements-ci.txt

.PHONY: lint
lint:  ## Check code style
	yamllint \
		.github/workflows \
		.readthedocs.yaml
	terraform fmt -check -recursive

.PHONY: test
test:  ## Run tests on the module
	pytest -xvvs tests

.PHONY: test-keep
test-keep:  ## Run a test and keep resources
	pytest -xvvs \
		--aws-region=${TEST_REGION} \
		--test-role-arn=${TEST_ROLE} \
		--keep-after \
		tests/test_module.py

.PHONY: test-clean
test-clean:  ## Run a test and destroy resources
	pytest -xvvs \
		--aws-region=${TEST_REGION} \
		--test-role-arn=${TEST_ROLE} \
		tests/test_module.py

.PHONY: format
format:  ## Format terraform files
	terraform fmt -recursive
	black tests/

.PHONY: init
init:
	terraform init

.PHONY: plan
plan: init ## Run terraform plan
	set -o pipefail ; terraform plan -no-color --out=tf.plan 2> plan.stderr | tee plan.stdout || (cat plan.stderr; exit 1)


.PHONY: apply
apply: ## Run terraform apply
	terraform apply -auto-approve -no-color -input=false tf.plan

.PHONY: docs
docs: ## generate Sphinx HTML documentation
	$(MAKE) -C docs clean
	$(MAKE) -C docs html
	$(BROWSER) docs/_build/html/index.html

# Internal function to handle version release
# Args: $(1) = major|minor|patch
define do_release
	@echo "Checking if git-cliff is installed..."
	@command -v git-cliff >/dev/null 2>&1 || { \
		echo ""; \
		echo "Error: git-cliff is not installed."; \
		echo ""; \
		echo "Please install it using one of the following methods:"; \
		echo ""; \
		echo "  Cargo (Rust):"; \
		echo "    cargo install git-cliff"; \
		echo ""; \
		echo "  Arch Linux:"; \
		echo "    pacman -S git-cliff"; \
		echo ""; \
		echo "  Homebrew (macOS/Linux):"; \
		echo "    brew install git-cliff"; \
		echo ""; \
		echo "  From binary (Linux/macOS/Windows):"; \
		echo "    https://github.com/orhun/git-cliff/releases"; \
		echo ""; \
		echo "For more installation options, see: https://git-cliff.org/docs/installation"; \
		echo ""; \
		exit 1; \
	}
	@echo "Checking if bumpversion is installed..."
	@command -v bumpversion >/dev/null 2>&1 || { \
		echo ""; \
		echo "Error: bumpversion is not installed."; \
		echo ""; \
		echo "Please install it using:"; \
		echo "  make bootstrap"; \
		echo ""; \
		exit 1; \
	}
	@BRANCH=$$(git rev-parse --abbrev-ref HEAD); \
	if [ "$$BRANCH" != "main" ]; then \
		echo "Error: You must be on the 'main' branch to release."; \
		echo "Current branch: $$BRANCH"; \
		exit 1; \
	fi; \
	CURRENT=$$(grep ^current_version .bumpversion.cfg | head -1 | cut -d= -f2 | tr -d ' '); \
	echo "Current version: $$CURRENT"; \
	MAJOR=$$(echo $$CURRENT | cut -d. -f1); \
	MINOR=$$(echo $$CURRENT | cut -d. -f2); \
	PATCH=$$(echo $$CURRENT | cut -d. -f3); \
	if [ "$(1)" = "major" ]; then \
		NEW_VERSION=$$((MAJOR + 1)).0.0; \
	elif [ "$(1)" = "minor" ]; then \
		NEW_VERSION=$$MAJOR.$$((MINOR + 1)).0; \
	elif [ "$(1)" = "patch" ]; then \
		NEW_VERSION=$$MAJOR.$$MINOR.$$((PATCH + 1)); \
	fi; \
	echo "New version will be: $$NEW_VERSION"; \
	printf "Continue? (y/n) "; \
	read -r REPLY; \
	case "$$REPLY" in \
		[Yy]|[Yy][Ee][Ss]) \
			echo "Updating CHANGELOG.md with git-cliff..."; \
			git cliff --unreleased --tag $$NEW_VERSION --prepend CHANGELOG.md; \
			git add CHANGELOG.md; \
			git commit -m "chore: update CHANGELOG for $$NEW_VERSION"; \
			echo "Bumping version with bumpversion..."; \
			bumpversion --new-version $$NEW_VERSION --message "chore: bump version to {new_version}" patch; \
			echo ""; \
			echo "✓ Released version $$NEW_VERSION"; \
			echo ""; \
			echo "Next steps:"; \
			echo "  git push && git push --tags"; \
			;; \
		*) \
			echo "Release cancelled"; \
			;; \
	esac
endef

.PHONY: release-patch
release-patch: ## Release a patch version (x.x.PATCH)
	$(call do_release,patch)

.PHONY: release-minor
release-minor: ## Release a minor version (x.MINOR.0)
	$(call do_release,minor)

.PHONY: release-major
release-major: ## Release a major version (MAJOR.0.0)
	$(call do_release,major)
