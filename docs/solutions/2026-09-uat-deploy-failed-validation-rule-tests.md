# UAT deployment failed because tests broke on a new validation rule

- **Date:** 2026-09-29
- **Related:** commit [COMMIT_HASH](https://github.com/romilgupta-dotcom/Claude-Code/commit/COMMIT_HASH), merged to `main` in [MERGE_HASH](https://github.com/romilgupta-dotcom/Claude-Code/commit/MERGE_HASH)

## Symptom

A deployment to UAT failed during test execution, even though every test passed in the developer sandbox and no Apex had changed in the tests being run. The deploy report showed failures in `ContactTriggerHandlerTest` and `AccountContactCountBatchTest`:

```
System.DmlException: Insert failed. First exception on row 0; first error:
FIELD_CUSTOM_VALIDATION_EXCEPTION, Industry is required for all Accounts.: [Industry]
```

Because the tests failed, overall code coverage fell below 75% and the whole deployment was rolled back, including unrelated changes in the same package.

## Root cause

An admin had added a new validation rule, `Account_Industry_Required`, directly in UAT for a reporting requirement. The rule was never added to this repo or to the developer sandbox.

Each test class built its own Accounts inline with only a `Name`:

```apex
Account acc = new Account(Name = 'Test Account');
insert acc;
```

Apex tests run against the target org's configuration, not the developer's. Validation rules, required fields, duplicate rules, Flows and restricted picklists in that org all apply to test data. So any test that creates records with the bare minimum of fields can break the moment an admin adds a rule, even with no code change.

The same inline Account setup was copied across several test classes, so one config change broke all of them at once.

## Fix

Test records are now built in one place, and the validation rule is tracked in source control.

- `TestDataFactory.cls` (new): builds Accounts and Contacts with every field required by current org rules, including `Industry`. Methods accept overrides so a test can still set the values it cares about, for example `TestDataFactory.createAccount(new Map<String, Object>{ 'Name' => 'Rollup Test' })`.
- `ContactTriggerHandlerTest.cls` and `AccountContactCountBatchTest.cls`: replaced inline `new Account(...)` and `new Contact(...)` setup with `TestDataFactory` calls. Test assertions did not change.
- `force-app/main/default/objects/Account/validationRules/Account_Industry_Required.validationRule-meta.xml`: retrieved from UAT and committed, so every environment and every developer sandbox now has the rule.
- `CLAUDE.md`: added a rule that tests must use `TestDataFactory` and never create records inline.

Still to do in each environment:

1. Deploy the validation rule first, or in the same deployment as the test changes.
2. Validate before the real deploy with `sf project deploy start --dry-run --test-level RunLocalTests --target-org <org>`.
3. Once the dry run passes, run the real deploy.

## How to avoid

Treat the target org's configuration as something that can change under your tests at any time.

- **Use one test data factory.** When a new required field or rule appears, you fix one class instead of every test.
- **Retrieve admin changes into the repo.** If admins change config in a higher environment, retrieve it with `sf project retrieve start --metadata ValidationRule:Account.<RuleName> --target-org <org>` and commit it. Config that only lives in one org is invisible to developers and to Claude.
- **Validate against the real target, not just your sandbox.** Always run a `--dry-run` deploy with tests against the org you're deploying to.
- **Don't use `@IsTest(SeeAllData=true)`** to get around missing data. It hides these problems and makes tests depend on whatever records exist in that org.

Org configuration that commonly breaks test data:

- **Validation rules** and **required fields** added at the field or page-layout level.
- **Duplicate rules** that block test records with repeated names or emails.
- **Record types** that are required, or whose default differs between orgs.
- **Restricted picklists** whose allowed values differ between orgs.
- **Record-triggered Flows and managed-package triggers** that run on insert and have their own requirements.
- **Sharing and user setup** when tests use `System.runAs` with a profile or permission set that differs between orgs.

When a deploy fails only in a higher environment, compare that org's configuration with the repo before changing any code.
