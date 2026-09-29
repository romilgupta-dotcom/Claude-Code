# Contact Expected Revenue field renamed and replaced

- **Date:** 2026-09-29
- **Related:** commit [64e5e89](https://github.com/romilgupta-dotcom/Claude-Code/commit/64e5e89), merged to `main` in [83a757c](https://github.com/romilgupta-dotcom/Claude-Code/commit/83a757c)

## Symptom

The Contact rollup code failed in a higher environment. Because of a new business requirement, the Contact field `Expected_Revenue__c` had been replaced by a new field, `Expected_Revenues__c`. The Apex still referenced the old field, which no longer exists there.

The Account rollup field `Account.Expected_Revenue__c` was **not** renamed. Only the Contact field changed.

## Root cause

The code was written against the old Contact field, and nothing flagged those references when the field was replaced. A partial manual edit made it worse: line 22 of `ContactTriggerHandler` ended up comparing the new field on one side with the old field on the other:

```apex
newContact.Expected_Revenues__c != oldContact.Expected_Revenue__c
```

That line either fails to compile (old field gone) or compares two different fields, so the rollup recalculates on every update.

Salesforce's own dependency checks (**Where is this used?**, deploy-time validation) only see references the platform can parse. They miss any field name held in a plain string, so a field can be "unused" according to Setup and still break code at runtime.

## Fix

Every **Contact** reference now uses `Expected_Revenues__c`. Every **Account** reference stays `Expected_Revenue__c`.

- `ContactTriggerHandler.cls`: the update change check (both sides), the `SUM(Expected_Revenues__c)` aggregate query, and the class comment.
- `ContactTriggerHandlerTest.cls` and `AccountContactCountBatchTest.cls`: test Contacts are built with the new field. Test lines that set out-of-date Account values still use the Account field.
- `CLAUDE.md`: the field descriptions now use the new name.

The rollup logic did not change. The handler still recalculates from an aggregate query, and the backfill batch reuses the same method.

Still to do in each environment:

1. Deploy, then run `ContactTriggerHandlerTest` and `AccountContactCountBatchTest`.
2. Copy the old Contact values into `Expected_Revenues__c`, since it is a new field and not a rename. Then run `Database.executeBatch(new AccountContactCountBatch());`. Otherwise each Account's `Expected_Revenue__c` resets to 0 the next time one of its Contacts changes.

## How to avoid

When a field is renamed or replaced, don't rely on the platform to find every reference. Search for the old API name everywhere:

```bash
grep -rn "Expected_Revenue__c" force-app
```

Then check each match for the object it belongs to, because the same API name can exist on two objects, as it does here.

Places the platform's dependency checks usually miss:

- **LWC / Aura JavaScript:** field names written as strings, for example `fields: ['Contact.Expected_Revenue__c']` in `getRecord`, or `record.fields.Expected_Revenue__c.value`. Only `@salesforce/schema/...` imports are tracked.
- **Dynamic Apex:** `Database.query('SELECT ... ')` strings, `sObject.get('Field__c')` / `put(...)`, and field sets or maps keyed by field name.
- **Visualforce and Aura markup** that builds field names at runtime.
- **Configuration that stores field names as text:** custom metadata, custom settings and custom labels.
- **Reports, list views, dashboards, email templates and some Flow formulas**, which may not block the change but will show blank or broken values.
- **Outside Salesforce:** integrations, middleware/ETL jobs, data loader mappings and API clients that query the field by name.

Before replacing the field in a higher environment, deploy with `--dry-run` or run all tests there, and check the list above in that org, not just in this repo.
