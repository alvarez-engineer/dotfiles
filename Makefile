SHELL := /usr/bin/env bash
CONFIG := ./config/config.ghostty

.PHONY: install install-copy install-prompt uninstall validate doctor backup tree check

install:
	./scripts/install.sh

install-copy:
	./scripts/install.sh --copy

install-prompt:
	./scripts/install-prompt.sh

uninstall:
	./scripts/uninstall.sh

validate:
	./scripts/validate.sh $(CONFIG)

doctor:
	./scripts/doctor.sh

backup:
	./scripts/backup.sh

tree:
	find . -maxdepth 4 -type f | sort

check:
	bash -n scripts/*.sh
	bash -n config/shell/bash_prompt.sh
	@if command -v zsh >/dev/null 2>&1; then \
		echo "zsh -n config/shell/zsh_prompt.zsh"; \
		zsh -n config/shell/zsh_prompt.zsh; \
	else \
		echo "zsh not found; skipping zsh_prompt.zsh syntax check"; \
	fi
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo "shellcheck scripts/*.sh config/shell/bash_prompt.sh"; \
		shellcheck scripts/*.sh config/shell/bash_prompt.sh; \
	else \
		echo "shellcheck not found; skipping lint"; \
	fi
