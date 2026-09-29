# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

A Python project that also contains Salesforce DX source under `force-app/` (see `sfdx-project.json`).

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

## Salesforce

- `ContactTrigger` + `ContactTriggerHandler` keep `Account.Number_of_Contacts__c` in sync on Contact insert, update (Account change), delete and undelete.
- Keep trigger logic in handler classes; triggers only dispatch.
- Deploy with `sf project deploy start` and run tests with `sf apex run test --tests ContactTriggerHandlerTest`.
