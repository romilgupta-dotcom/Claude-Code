# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

A Python project, currently in its initial setup stage (no source code yet).

## Environment

- Use a virtual environment in `.venv/` (already gitignored).
- Development happens on Windows; prefer cross-platform paths and commands.

## Conventions

- Follow PEP 8 and use type hints for new code.
- Keep dependencies declared in `requirements.txt` or `pyproject.toml`.
- Put tests under `tests/` and run them with `pytest`.

## Git

- Default branch: `main`.
- Never commit secrets, `.env` files, or virtual environments.
