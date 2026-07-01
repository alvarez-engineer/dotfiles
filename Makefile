SHELL := /usr/bin/env bash

.PHONY: install install-copy dry-run uninstall doctor backup validate check tree \
        bootstrap bootstrap-dev all \
        install-shell install-git install-tmux install-nvim install-ghostty install-cli

# --- Bootstrap (install tool binaries; needs sudo on Linux) ----------------
bootstrap:
	./scripts/bootstrap.sh

bootstrap-dev:
	./scripts/bootstrap.sh --dev

# --- Install ---------------------------------------------------------------
install:
	./install.sh

# Tools + configs in one shot
all:
	./install.sh --bootstrap

install-copy:
	./install.sh --copy

dry-run:
	./install.sh --dry-run

# Per-module installs
install-shell:   ; ./install.sh shell
install-git:     ; ./install.sh git
install-tmux:    ; ./install.sh tmux
install-nvim:    ; ./install.sh nvim
install-ghostty: ; ./install.sh ghostty
install-cli:     ; ./install.sh cli

uninstall:
	./scripts/uninstall.sh

# --- Diagnostics -----------------------------------------------------------
doctor:
	./scripts/doctor.sh

backup:
	./scripts/backup.sh

validate:
	./ghostty/validate.sh

# --- Quality gate ----------------------------------------------------------
check:
	bash -n install.sh lib/common.sh */install.sh scripts/*.sh ghostty/*.sh \
	        shell/exports.sh shell/aliases.sh shell/functions.sh shell/bashrc \
	        shell/prompt/bash_prompt.sh
	@if command -v zsh >/dev/null 2>&1; then \
		echo "zsh -n shell/zshrc shell/prompt/zsh_prompt.zsh"; \
		zsh -n shell/zshrc; zsh -n shell/prompt/zsh_prompt.zsh; \
	else echo "zsh not found; skipping zsh syntax check"; fi
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo "shellcheck"; \
		shellcheck -e SC1090,SC1091 install.sh lib/common.sh */install.sh scripts/*.sh ghostty/*.sh \
		           shell/exports.sh shell/aliases.sh shell/functions.sh; \
	else echo "shellcheck not found; skipping lint"; fi
	@if command -v luacheck >/dev/null 2>&1; then \
		echo "luacheck nvim/"; luacheck --no-max-line-length -q nvim/ || true; \
	else echo "luacheck not found; skipping lua lint"; fi

tree:
	find . -path ./.git -prune -o -type f -print | sort
