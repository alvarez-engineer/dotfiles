SHELL := /usr/bin/env bash

.PHONY: install install-copy dry-run uninstall doctor backup validate check tree \
        bootstrap bootstrap-dev all \
        install-shell install-git install-tmux install-nvim install-ghostty install-cli install-opencode \
        install-vscode install-claude install-notes

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
install-opencode:; ./install.sh opencode
install-vscode:  ; ./install.sh vscode
install-claude:  ; ./install.sh claude
install-notes:   ; ./install.sh notes

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
# Files checked by both `bash -n` and shellcheck. The sourced rc files carry a
# `# shellcheck shell=bash` directive instead of a shebang, so they lint too.
# $(sort) also de-duplicates: ghostty/install.sh matches two globs below.
SH_FILES := $(sort install.sh lib/common.sh $(wildcard */install.sh) $(wildcard scripts/*.sh) \
            $(wildcard ghostty/*.sh) $(wildcard notes/bin/*) $(wildcard vscode/bin/*) \
            $(wildcard claude/*.sh) \
            shell/exports.sh shell/aliases.sh shell/functions.sh \
            shell/bashrc shell/prompt/bash_prompt.sh)

ZSH_FILES := shell/zshrc shell/prompt/zsh_prompt.zsh

# Every leg of this gate must be able to FAIL the build. Three ways it silently
# could not, all fixed here and worth not reintroducing:
#   - `bash -n a b c` parses only `a`; the rest become positional args.
#   - `cmd1; cmd2` yields cmd2's status, so a cmd1 failure vanished.
#   - `luacheck ... || true` swallowed every lua error.
check:
	@echo "bash -n"
	@for f in $(SH_FILES); do \
		bash -n "$$f" || exit 1; \
	done
	@if command -v zsh >/dev/null 2>&1; then \
		echo "zsh -n"; \
		for f in $(ZSH_FILES); do \
			zsh -n "$$f" || exit 1; \
		done; \
	else echo "zsh not found; skipping zsh syntax check"; fi
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo "shellcheck"; \
		shellcheck -e SC1090,SC1091 $(SH_FILES) || exit 1; \
	else echo "shellcheck not found; skipping lint"; fi
	@if command -v luacheck >/dev/null 2>&1; then \
		echo "luacheck nvim/"; \
		luacheck --no-max-line-length -q nvim/ || exit 1; \
	else echo "luacheck not found; skipping lua lint"; fi

tree:
	find . -path ./.git -prune -o -type f -print | sort
