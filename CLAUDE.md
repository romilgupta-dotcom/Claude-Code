# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Set up as a Python project, but it has no Python source, dependencies or tests yet. All current code is Salesforce DX source under `force-app/` (package config in `sfdx-project.json`, API version 64.0).

## Environment

- Development happens on Windows; prefer cross-platform paths and commands.
- Python: use a virtual environment in `.venv/` (gitignored), follow PEP 8 with type hints, declare dependencies in `requirements.txt` or `pyproject.toml`, and put tests under `tests/` (run with `pytest`).

## Git

- Default branch: `main`.
- Never commit `.env` files or virtual environments.

## Salesforce development standards

Every Apex change, test and review must follow the mandatory project rules in @docs/salesforce-development-standards.md.

## Salesforce commands

```bash
# Deploy (add --target-org <alias> if no default org is set)
sf project deploy start --source-dir force-app

# Run all tests
sf apex run test --tests ContactTriggerHandlerTest --tests AccountContactCountBatchTest --result-format human --synchronous

# Run a single test method
sf apex run test --tests ContactTriggerHandlerTest.insertRollsUpCountAndRevenue --result-format human --synchronous
```

Backfill existing Accounts from Anonymous Apex: `Database.executeBatch(new AccountContactCountBatch());` (pass a smaller scope, e.g. `50`, if a chunk's Accounts have more than 50,000 Contacts between them).

## Salesforce architecture

Two Account rollups are kept in sync with their Contacts:

- `Number_of_Contacts__c`: count of Contacts (field metadata is in this repo).
- `Expected_Revenue__c`: sum of `Contact.Expected_Revenues__c` (the Contact field was renamed from `Expected_Revenue__c`; the Account field was not). Both of these fields already exist in the org and are **not** in this repo, so deploying to a fresh org needs them created first.

How the pieces fit:

- `ContactTrigger` only dispatches (after insert/update/delete/undelete) to `ContactTriggerHandler`. Keep logic in handler classes.
- On update, the handler only recalculates when `AccountId` or `Contact.Expected_Revenues__c` changed, and recalculates both the old and the new Account.
- `ContactTriggerHandler.recalculateAccountRollups(Set<Id>)` is the single source of truth. It recomputes from an aggregate SOQL query rather than incrementing or decrementing, so values self-correct. It defaults each Account to 0 (so Accounts that lost their last Contact are reset) and treats a null `SUM` as 0.
- `AccountContactCountBatch` reuses `recalculateAccountRollups`, so the batch and the trigger always calculate the same way. Any change to rollup logic belongs in that method.
- Both classes are `without sharing`, so rollups count every Contact regardless of the running user's visibility.

## Known issues & fixes

Rules learned from past fixes (details in `docs/solutions/`). Add entries with `/log-fix`.

- When a field is renamed or replaced, search all of `force-app` for the old API name, including JS/LWC/Aura strings and dynamic SOQL, then check the org for Flows, reports and integrations; the platform's dependency check misses string references ([details](docs/solutions/2026-09-contact-expected-revenues-rename.md)).
