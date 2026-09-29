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

- `ContactTrigger` + `ContactTriggerHandler` keep two Account rollups in sync on Contact insert, update (Account or Expected Revenue change), delete and undelete:
  - `Number_of_Contacts__c`: count of Contacts (field metadata is in this repo).
  - `Expected_Revenue__c`: sum of `Contact.Expected_Revenue__c` (both fields already exist in the org and are not in this repo).
- `AccountContactCountBatch` backfills both rollups for existing Accounts: `Database.executeBatch(new AccountContactCountBatch());`
- Keep trigger logic in handler classes; triggers only dispatch.
- Deploy with `sf project deploy start` and run tests with `sf apex run test --tests ContactTriggerHandlerTest --tests AccountContactCountBatchTest`.
