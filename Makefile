# =============================================================================
# Makefile for Paul Lee's Bash Scripts Repository
# =============================================================================
# This Makefile provides common operations for managing bash scripts
# in this repository.
# =============================================================================

# =============================================================================
# Configuration
# =============================================================================

# Shell to use for commands
SHELL := /bin/bash

# Default target
.DEFAULT_GOAL := help

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
BOLD := \033[1m
RESET := \033[0m

# Directories
SCRIPTS := $(wildcard *.sh)

# =============================================================================
# Help Target
# =============================================================================

.PHONY: help
help: ## Show this help message
	@echo "$(BOLD)Paul Lee's Bash Scripts Repository$(RESET)"
	@echo "========================================================"
	@echo ""
	@echo "$(BOLD)Available targets:$(RESET)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(BOLD)Examples:$(RESET)"
	@echo "  make install     # Install dependencies"
	@echo "  make lint        # Lint all bash scripts"
	@echo "  make test        # Test all bash scripts"
	@echo "  make clean       # Clean up temporary files"

# =============================================================================
# Installation and Dependencies
# =============================================================================

.PHONY: install
install: ## Install required dependencies
	@echo "$(BLUE)[INFO]$(RESET) Installing dependencies..."
	@if command -v brew >/dev/null 2>&1; then \
		echo "$(BLUE)[INFO]$(RESET) Installing via Homebrew..."; \
		brew install lftp jq shellcheck; \
	else \
		echo "$(YELLOW)[WARNING]$(RESET) Homebrew not found. Please install dependencies manually:"; \
		echo "  - lftp: FTP client"; \
		echo "  - jq: JSON processor"; \
		echo "  - shellcheck: Shell script linter"; \
	fi
	@echo "$(GREEN)[SUCCESS]$(RESET) Dependencies installation completed"

.PHONY: check-deps
check-deps: ## Check if required dependencies are installed
	@echo "$(BLUE)[INFO]$(RESET) Checking dependencies..."
	@missing=0; \
	for dep in lftp jq shellcheck; do \
		if command -v $$dep >/dev/null 2>&1; then \
			echo "$(GREEN)[✓]$(RESET) $$dep is installed"; \
		else \
			echo "$(RED)[✗]$(RESET) $$dep is missing"; \
			missing=1; \
		fi; \
	done; \
	if [ $$missing -eq 1 ]; then \
		echo "$(YELLOW)[WARNING]$(RESET) Some dependencies are missing. Run 'make install' to install them."; \
		exit 1; \
	else \
		echo "$(GREEN)[SUCCESS]$(RESET) All dependencies are installed"; \
	fi

# =============================================================================
# Linting and Code Quality
# =============================================================================

.PHONY: lint
lint: check-deps ## Lint all bash scripts
	@echo "$(BLUE)[INFO]$(RESET) Linting bash scripts..."
	@if [ -z "$(SCRIPTS)" ]; then \
		echo "$(YELLOW)[WARNING]$(RESET) No bash scripts found in current directory"; \
		exit 0; \
	fi
	@for script in $(SCRIPTS); do \
		echo "$(BLUE)[INFO]$(RESET) Linting $$script..."; \
		shellcheck $$script || exit 1; \
	done
	@echo "$(GREEN)[SUCCESS]$(RESET) All scripts passed linting"

.PHONY: lint-fix
lint-fix: ## Attempt to fix common linting issues
	@echo "$(BLUE)[INFO]$(RESET) Attempting to fix common linting issues..."
	@for script in $(SCRIPTS); do \
		echo "$(BLUE)[INFO]$(RESET) Processing $$script..."; \
		# Remove trailing whitespace
		sed -i '' 's/[[:space:]]*$$//' $$script; \
		# Ensure file ends with newline
		if [ -n "$$(tail -c1 $$script)" ]; then echo >> $$script; fi; \
	done
	@echo "$(GREEN)[SUCCESS]$(RESET) Linting fixes applied"

# =============================================================================
# Testing
# =============================================================================

.PHONY: test
test: check-deps ## Test all bash scripts
	@echo "$(BLUE)[INFO]$(RESET) Testing bash scripts..."
	@if [ -z "$(SCRIPTS)" ]; then \
		echo "$(YELLOW)[WARNING]$(RESET) No bash scripts found in current directory"; \
		exit 0; \
	fi
	@for script in $(SCRIPTS); do \
		echo "$(BLUE)[INFO]$(RESET) Testing $$script..."; \
		# Test script syntax
		bash -n $$script || exit 1; \
		# Test help/version options
		if grep -q "help\|version" $$script; then \
			bash $$script --help >/dev/null 2>&1 || bash $$script -h >/dev/null 2>&1 || true; \
			bash $$script --version >/dev/null 2>&1 || bash $$script -V >/dev/null 2>&1 || true; \
		fi; \
	done
	@echo "$(GREEN)[SUCCESS]$(RESET) All scripts passed testing"

.PHONY: test-dry-run
test-dry-run: ## Test scripts in dry-run mode
	@echo "$(BLUE)[INFO]$(RESET) Testing scripts in dry-run mode..."
	@if [ -z "$(SCRIPTS)" ]; then \
		echo "$(YELLOW)[WARNING]$(RESET) No bash scripts found in current directory"; \
		exit 0; \
	fi
	@for script in $(SCRIPTS); do \
		echo "$(BLUE)[INFO]$(RESET) Testing $$script in dry-run mode..."; \
		if grep -q "dry-run\|dry_run" $$script; then \
			bash $$script --dry-run >/dev/null 2>&1 || bash $$script -n >/dev/null 2>&1 || true; \
		fi; \
	done
	@echo "$(GREEN)[SUCCESS]$(RESET) Dry-run testing completed"

# =============================================================================
# Documentation
# =============================================================================

.PHONY: docs
docs: ## Generate documentation for bash scripts
	@echo "$(BLUE)[INFO]$(RESET) Generating documentation..."
	@mkdir -p docs
	@for script in $(SCRIPTS); do \
		script_name=$$(basename $$script .sh); \
		echo "$(BLUE)[INFO]$(RESET) Documenting $$script..."; \
		echo "# $$script_name" > docs/$$script_name.md; \
		echo "" >> docs/$$script_name.md; \
		echo "## Description" >> docs/$$script_name.md; \
		echo "" >> docs/$$script_name.md; \
		# Extract description from script comments
		grep -E "^#.*[Dd]escription|^#.*[Uu]sage" $$script | sed 's/^# *//' >> docs/$$script_name.md || true; \
		echo "" >> docs/$$script_name.md; \
		echo "## Usage" >> docs/$$script_name.md; \
		echo "" >> docs/$$script_name.md; \
		echo "\`\`\`bash" >> docs/$$script_name.md; \
		bash $$script --help 2>&1 >> docs/$$script_name.md || bash $$script -h 2>&1 >> docs/$$script_name.md || true; \
		echo "\`\`\`" >> docs/$$script_name.md; \
	done
	@echo "$(GREEN)[SUCCESS]$(RESET) Documentation generated in docs/"

# =============================================================================
# Maintenance
# =============================================================================

.PHONY: clean
clean: ## Clean up temporary files
	@echo "$(BLUE)[INFO]$(RESET) Cleaning up temporary files..."
	@find . -name "*.tmp" -delete 2>/dev/null || true
	@find . -name "*.log" -delete 2>/dev/null || true
	@find . -name "*.swp" -delete 2>/dev/null || true
	@find . -name "*.swo" -delete 2>/dev/null || true
	@find . -name "*~" -delete 2>/dev/null || true
	@find . -name ".DS_Store" -delete 2>/dev/null || true
	@echo "$(GREEN)[SUCCESS]$(RESET) Cleanup completed"

.PHONY: format
format: lint-fix ## Format all bash scripts
	@echo "$(BLUE)[INFO]$(RESET) Formatting bash scripts..."
	@for script in $(SCRIPTS); do \
		echo "$(BLUE)[INFO]$(RESET) Formatting $$script..."; \
		# Make scripts executable
		chmod +x $$script; \
	done
	@echo "$(GREEN)[SUCCESS]$(RESET) Formatting completed"

# =============================================================================
# Development
# =============================================================================

.PHONY: dev-setup
dev-setup: install ## Set up development environment
	@echo "$(BLUE)[INFO]$(RESET) Setting up development environment..."
	@# Create necessary directories
	@mkdir -p docs logs
	@# Make scripts executable
	@for script in $(SCRIPTS); do \
		chmod +x $$script; \
	done
	@echo "$(GREEN)[SUCCESS]$(RESET) Development environment setup completed"

.PHONY: status
status: ## Show repository status
	@echo "$(BLUE)[INFO]$(RESET) Repository Status"
	@echo "========================================================"
	@echo "$(BOLD)Scripts:$(RESET)"
	@if [ -z "$(SCRIPTS)" ]; then \
		echo "  No bash scripts found in current directory"; \
	else \
		for script in $(SCRIPTS); do \
			echo "  $$script"; \
		done; \
	fi
	@echo ""
	@echo "$(BOLD)Dependencies:$(RESET)"
	@make check-deps >/dev/null 2>&1 || echo "  Some dependencies are missing"
	@echo ""
	@echo "$(BOLD)Git Status:$(RESET)"
	@git status --porcelain 2>/dev/null || echo "  Not a git repository"

# =============================================================================
# End of Makefile
# =============================================================================