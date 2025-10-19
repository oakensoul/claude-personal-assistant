# AIDA Framework Makefile
# Provides convenient targets for development, testing, and validation

.PHONY: help
help: ## Show this help message
	@echo "AIDA Framework - Available targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

#######################################
# Testing targets
#######################################

.PHONY: test-unit
test-unit: ## Run all unit tests
	@echo "Running unit tests..."
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/unit/*.bats; \
	else \
		echo "Error: bats not installed. See docs/testing/BATS_SETUP.md"; \
		exit 1; \
	fi

.PHONY: test-integration
test-integration: ## Run all integration tests
	@echo "Running integration tests..."
	@if command -v bats >/dev/null 2>&1; then \
		if [ -f tests/integration/*.bats ]; then \
			bats tests/integration/*.bats; \
		else \
			echo "No integration tests found (tests/integration/*.bats)"; \
		fi \
	else \
		echo "Error: bats not installed. See docs/testing/BATS_SETUP.md"; \
		exit 1; \
	fi

.PHONY: test-all
test-all: test-unit test-integration ## Run all tests
	@echo ""
	@echo "✓ All tests passed!"

.PHONY: test-watch
test-watch: ## Watch for changes and re-run tests (requires entr)
	@echo "Watching for changes..."
	@if command -v entr >/dev/null 2>&1; then \
		find lib tests -name "*.sh" -o -name "*.bats" | entr -c make test-unit; \
	else \
		echo "Error: entr not installed. Install with:"; \
		echo "  macOS:  brew install entr"; \
		echo "  Linux:  apt-get install entr"; \
		exit 1; \
	fi

.PHONY: test-verbose
test-verbose: ## Run unit tests with verbose output
	@echo "Running unit tests (verbose)..."
	@if command -v bats >/dev/null 2>&1; then \
		bats --verbose tests/unit/*.bats; \
	else \
		echo "Error: bats not installed. See docs/testing/BATS_SETUP.md"; \
		exit 1; \
	fi

.PHONY: test-coverage
test-coverage: ## Show test coverage summary
	@echo "Test Coverage Summary:"
	@echo ""
	@echo "Unit Tests:"
	@echo "  prompts.sh:     $$(grep -c '^@test' tests/unit/test_prompts.bats 2>/dev/null || echo 0) tests"
	@echo "  config.sh:      $$(grep -c '^@test' tests/unit/test_config.bats 2>/dev/null || echo 0) tests"
	@echo "  directories.sh: $$(grep -c '^@test' tests/unit/test_directories.bats 2>/dev/null || echo 0) tests"
	@echo "  summary.sh:     $$(grep -c '^@test' tests/unit/test_summary.bats 2>/dev/null || echo 0) tests"
	@echo ""
	@echo "Total unit tests: $$(cat tests/unit/*.bats | grep -c '^@test' 2>/dev/null || echo 0)"
	@echo ""

#######################################
# Quality checks
#######################################

.PHONY: lint
lint: lint-shell lint-yaml lint-markdown ## Run all linters

.PHONY: lint-shell
lint-shell: ## Run shellcheck on all shell scripts
	@echo "Running shellcheck..."
	@find lib scripts -name "*.sh" -type f -exec shellcheck {} +

.PHONY: lint-yaml
lint-yaml: ## Run yamllint on all YAML files
	@echo "Running yamllint..."
	@yamllint --strict .

.PHONY: lint-markdown
lint-markdown: ## Run markdownlint on all markdown files
	@echo "Running markdownlint..."
	@markdownlint '**/*.md' --ignore node_modules

.PHONY: validate
validate: ## Validate templates and configuration
	@echo "Validating templates..."
	@./scripts/validate-templates.sh

.PHONY: validate-verbose
validate-verbose: ## Validate templates with verbose output
	@echo "Validating templates (verbose)..."
	@./scripts/validate-templates.sh --verbose

.PHONY: check
check: lint test-all validate ## Run all quality checks

#######################################
# Development targets
#######################################

.PHONY: install
install: ## Install AIDA framework (normal mode)
	@./install.sh

.PHONY: install-dev
install-dev: ## Install AIDA framework (dev mode with symlinks)
	@./install.sh --dev

.PHONY: uninstall
uninstall: ## Uninstall AIDA framework
	@./install.sh --uninstall

.PHONY: clean
clean: ## Clean temporary files and build artifacts
	@echo "Cleaning temporary files..."
	@find . -name "*.backup.*" -type f -delete
	@find . -name ".DS_Store" -type f -delete
	@echo "✓ Clean complete"

.PHONY: clean-test
clean-test: ## Clean test artifacts
	@echo "Cleaning test artifacts..."
	@rm -rf tests/tmp
	@find tests -name "*.log" -type f -delete
	@echo "✓ Test artifacts cleaned"

#######################################
# Documentation targets
#######################################

.PHONY: docs
docs: ## Generate documentation index
	@echo "Documentation available at:"
	@echo "  Setup:     docs/testing/BATS_SETUP.md"
	@echo "  Testing:   docs/testing/UNIT_TESTING.md"
	@echo "  Tests:     tests/README.md"
	@echo "  Main:      README.md"

#######################################
# Pre-commit targets
#######################################

.PHONY: pre-commit-install
pre-commit-install: ## Install pre-commit hooks
	@pre-commit install

.PHONY: pre-commit-run
pre-commit-run: ## Run pre-commit hooks on all files
	@pre-commit run --all-files

#######################################
# CI/CD targets
#######################################

.PHONY: ci
ci: lint test-all validate ## Run all CI checks
	@echo ""
	@echo "✓ All CI checks passed!"

.PHONY: ci-fast
ci-fast: lint-shell test-unit ## Run fast CI checks (skip integration tests)
	@echo ""
	@echo "✓ Fast CI checks passed!"
