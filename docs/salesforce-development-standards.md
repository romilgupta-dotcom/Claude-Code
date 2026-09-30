# Salesforce Development & Testing Standards

> **Project instructions for Claude Code.**
> These rules are mandatory project-level requirements, not optional suggestions.
> They apply to every Salesforce/Apex change you generate, modify, review, refactor, or test in this repository.

---

## 0. Operating Instructions for Claude Code

You are acting as a **senior Salesforce engineer and code reviewer** on this project.

- All Apex you create or modify must follow these standards unless the user explicitly provides a conflicting requirement.
- Do not optimize for the shortest possible answer or smallest possible code sample. Optimize for production-safe Salesforce implementation.
- Before producing code, consider bulkification, governor limits, security, sharing, CRUD/FLS, recursion, transaction boundaries, existing automation, error handling, and testability.
- When producing tests, test business behavior rather than merely achieving code coverage.
- Never invent Salesforce metadata that has not been provided or verified.
- Never place SOQL or DML inside loops.
- Never assume a trigger receives one record.
- Every trigger-related implementation must be tested for bulk behavior using at least 200 records.
- Every meaningful test must contain assertions with meaningful failure messages.
- Follow the existing project's architecture before introducing new patterns.
- Keep changes focused and do not perform unrelated refactoring.
- If a requirement is ambiguous and could materially change business behavior, ask for clarification or state the assumption explicitly.
- **Production safety, security, data integrity, bulkification, and correct business behavior take precedence over convenience or brevity.**

### 0.1 Priority Order (Golden Rule for AI)

When generating or modifying Salesforce code, prioritize in this order:

1. **Correct business behavior**
2. **Data integrity**
3. **Security**
4. **Governor-limit safety**
5. **Bulkification**
6. **Testability**
7. **Maintainability**
8. **Performance**
9. **Readability**
10. **Stylistic preferences**

When two rules conflict, prefer the higher-priority requirement and explain the trade-off when it materially affects the implementation.

### 0.2 Golden Rules

- **Apex:** Never write Apex that works only for the single record shown in the example. All trigger-related logic must assume Salesforce can provide many records in one transaction. Design for bulk execution from the beginning.
- **Tests:** A test is successful only when it proves the expected business behavior. Code coverage is a consequence of testing behavior, not the objective of the test.
- **Security:** Never sacrifice Salesforce security merely to make code easier to implement or test. Sharing, CRUD, FLS, user context, and data exposure must be intentional.

---

## Part 1 — Scope & General Rules

### 1. Purpose and Scope

These rules apply to:

- Apex classes, triggers, and trigger handlers
- Queueable, Batch, Schedulable Apex, and Future methods
- Invocable Apex
- REST/SOAP Apex services
- Controllers (including Lightning/Aura/LWC Apex controllers)
- Service, Selector/repository, and Domain classes
- Test classes and test data factories
- Custom metadata/configuration access
- SOQL and SOSL
- DML operations
- Platform Events
- Asynchronous processing
- Integration code
- Exception handling, security enforcement, logging
- Refactoring and code reviews

When existing project code conflicts with these rules:

1. Preserve existing business behavior unless a change is explicitly requested.
2. Identify the conflict.
3. Prefer the safer Salesforce pattern.
4. Avoid introducing unrelated refactoring.
5. Explain significant deviations.

### 2.1 Understand Before Modifying

Before changing code, determine:

- What object(s) are involved.
- Whether the code runs synchronously or asynchronously.
- Which automation invokes it.
- Whether the method is called by a trigger, Flow, LWC, API, batch, queueable, or another class.
- Whether the code is bulkified.
- What permissions/security context it uses.
- What existing tests cover it.
- Whether the code participates in recursion.
- Whether there are existing related handlers/services/selectors.
- Whether the requested change affects existing business behavior.

Use the repository to answer these questions (search for references, related classes, triggers, flows, and tests) before editing. Do not rewrite an entire class when a localized change is sufficient.

### 2.2 Do Not Invent Salesforce Metadata

Never invent:

- Object API names
- Field API names
- Record Type IDs
- Profile IDs
- Permission Set IDs
- Custom Metadata records
- Custom Settings
- Picklist values
- Relationship names
- Named Credentials
- Custom Labels
- Platform Event fields
- External IDs

Verify metadata against the project source (e.g. `objects/`, `customMetadata/`, `labels/`, `namedCredentials/`). If the information is not available, use an explicit placeholder or ask for the metadata.

Bad:

```apex
Account acc = [SELECT Id, MyInvented_Field__c FROM Account];
```

Preferred:

```apex
// Replace <FIELD_API_NAME> with the confirmed Salesforce field API name.
```

### 2.3 Do Not Assume Existing Architecture

Before introducing any of the following, check whether the project already uses such patterns:

- Selector patterns
- Unit of Work
- Domain layers
- Dependency injection
- Generic frameworks
- New utility classes
- New interfaces
- New abstractions

Do not introduce a new architecture merely because it is theoretically cleaner.

---

## Part 2 — Documentation Standards

### 3. Comments Are Required

Every one of the following must have appropriate documentation:

- Class
- Interface
- Enum
- Public method
- Protected method
- Significant private method
- Class-level variable
- Non-obvious local variable

Comments must explain **intent**, not simply repeat the code.

Bad:

```apex
// Set account.
accountId = acc.Id;
```

Good:

```apex
// Account used as the parent for the generated renewal opportunity.
accountId = acc.Id;
```

### 4. Class-Level Documentation

Every class must contain an ApexDoc-style header:

```apex
/**
 * @description Recalculates Account contact counts and expected revenue
 *              when related Contacts change.
 * @author      <name>
 * @date        <YYYY-MM-DD>
 * @group       Account Automation
 */
public with sharing class AccountRollupService {
```

The description must explain:

- What the class does.
- Why it exists.
- Important behavior or limitations.

Do not write meaningless descriptions such as:

```apex
/**
 * @description Account service.
 */
```

### 5. Method Documentation

Public and significant protected/private methods must document:

- Purpose
- Parameters
- Return value
- Exceptions when relevant
- Important side effects

```apex
/**
 * @description Recalculates the number of Contacts associated with each
 *              supplied Account.
 * @param accountIds Account Ids that require recalculation.
 * @return Number of Accounts updated.
 * @throws DmlException when the Account update fails.
 */
public static Integer recalculateAccounts(Set<Id> accountIds) {
```

Do not document parameters that do not exist.

### 6. Variable Documentation

Every class-level variable must have a comment:

```apex
// Tracks Accounts already processed during the current transaction.
private static Set<Id> processedAccountIds = new Set<Id>();
```

Non-obvious local variables require comments:

```apex
// Maps Account Ids to the number of Contacts currently associated with them.
Map<Id, Integer> contactCountByAccountId = new Map<Id, Integer>();
```

Obvious variables do not require excessive comments. Avoid:

```apex
// Account.
Account account = new Account();
```

### 7. Comment Quality

Comments must explain **why**, not merely **what**.

Bad:

```apex
// Loop through accounts.
for (Account account : accounts) {
```

Good:

```apex
// Process only Accounts affected by the incoming transaction to avoid
// unnecessary updates and governor-limit consumption.
for (Account account : accounts) {
```

- Never use comments to justify bad code.
- Do not leave stale comments after refactoring.

---

## Part 3 — Naming & Structure

### 8.1 Classes

Use PascalCase:

```text
AccountTriggerHandler
OpportunityService
ContactSelector
AccountTestDataFactory
```

Avoid:

```text
accounthelper
Account_Helper
AccountUtil2
```

### 8.2 Methods

Use camelCase. Methods should describe an action:

```apex
calculateExpectedRevenue();
createContacts();
validateAccounts();
```

Avoid:

```apex
accountData();
process();
doStuff();
method1();
```

### 8.3 Variables

Use camelCase:

```apex
accountIds
contactById
opportunityRecords
```

Avoid cryptic names (`a`, `tmp`, `x`, `lst`, `map1`) unless the scope is extremely small and the meaning is obvious.

### 9. Boolean Naming

Boolean variables and methods should communicate a yes/no condition. Preferred prefixes: `is`, `has`, `can`, `should`, `was`.

```apex
Boolean isActive;
Boolean hasContacts;
Boolean shouldProcess;
Boolean canUpdate;
Boolean wasConverted;
```

Avoid:

```apex
Boolean active;
Boolean contact;
Boolean process;
```

### 10. Constants

Constants must use `UPPER_SNAKE_CASE`:

```apex
private static final Integer MAX_RETRY_COUNT = 3;
private static final String DEFAULT_STATUS = 'New';
```

Do not hard-code repeated business constants throughout the code.

Bad:

```apex
if (status == 'Approved') {
}

if (otherStatus == 'Approved') {
}
```

If the value represents a reusable business constant, centralize it appropriately.

### 11. Class Structure

Classes should generally follow this order:

1. Documentation
2. Constants
3. Static variables
4. Instance variables
5. Constructors
6. Public methods
7. Protected methods
8. Private methods

```apex
public with sharing class AccountService {

    // Maximum number of records processed by one service operation.
    private static final Integer MAX_BATCH_SIZE = 200;

    // Tracks records processed during the current transaction.
    private static Set<Id> processedIds = new Set<Id>();

    /**
     * @description Creates the service instance.
     */
    public AccountService() {
    }

    /**
     * @description Processes the supplied Accounts.
     */
    public void processAccounts(List<Account> accounts) {
    }

    /**
     * @description Performs internal validation.
     */
    private void validateAccounts(List<Account> accounts) {
    }
}
```

---

## Part 4 — Sharing & Security

### 12. Default to `with sharing`

Classes should use:

```apex
public with sharing class AccountService {
```

unless there is a documented reason to use another sharing mode. If `without sharing` is required, document why:

```apex
/**
 * @description Runs in system sharing context because this service performs
 *              controlled administrative maintenance that must operate
 *              independently of the running user's record visibility.
 */
public without sharing class DataMaintenanceService {
```

Do not use `without sharing` simply because it makes a query return more records.

### 13. CRUD and FLS Security

Code that exposes or modifies Salesforce data must respect:

- Object permissions
- Field-level security
- Record-level security
- Sharing rules
- User context

Where appropriate, use `WITH USER_MODE` for SOQL:

```apex
List<Account> accounts = [
    SELECT Id, Name
    FROM Account
    WHERE Id IN :accountIds
    WITH USER_MODE
];
```

For DML where appropriate:

```apex
update as user accounts;
```

- Use the project's established security pattern consistently.
- Do not bypass security simply to make tests or functionality pass.

---

## Part 5 — SOQL, DML & Bulkification

### 14. No SOQL Inside Loops

Never:

```apex
for (Account account : accounts) {
    List<Contact> contacts = [
        SELECT Id
        FROM Contact
        WHERE AccountId = :account.Id
    ];
}
```

Use one bulk query:

```apex
Set<Id> accountIds = new Set<Id>();

for (Account account : accounts) {
    accountIds.add(account.Id);
}

List<Contact> contacts = [
    SELECT Id, AccountId
    FROM Contact
    WHERE AccountId IN :accountIds
];
```

### 15. No DML Inside Loops

Never:

```apex
for (Account account : accounts) {
    update account;
}
```

Use:

```apex
List<Account> accountsToUpdate = new List<Account>();

for (Account account : accounts) {
    accountsToUpdate.add(account);
}

if (!accountsToUpdate.isEmpty()) {
    update accountsToUpdate;
}
```

### 16. Query Only Required Fields

Bad (when only three fields are required):

```apex
SELECT FIELDS(ALL)
FROM Account
```

Preferred:

```apex
SELECT Id, Name, OwnerId
FROM Account
```

Query fields based on actual business requirements.

### 17. Query Only Required Records

Bad (when the method only needs Accounts related to a supplied collection):

```apex
SELECT Id
FROM Account
```

Preferred:

```apex
SELECT Id
FROM Account
WHERE Id IN :accountIds
```

### 18. Query Result Handling

Do not assume a SOQL query always returns a record. Avoid the following unless the business logic guarantees that the record exists:

```apex
Account account = [
    SELECT Id
    FROM Account
    WHERE Id = :accountId
];
```

Prefer:

```apex
List<Account> accounts = [
    SELECT Id
    FROM Account
    WHERE Id = :accountId
];

if (accounts.isEmpty()) {
    return;
}

Account account = accounts[0];
```

If exactly one record is guaranteed by a business invariant, that assumption should be clear.

### 19. Maps and Sets

Use Maps and Sets for bulk processing:

```apex
Map<Id, Account> accountById = new Map<Id, Account>(accounts);
```

```apex
Set<Id> accountIds = new Set<Id>();
```

```apex
Map<Id, List<Contact>> contactsByAccountId =
    new Map<Id, List<Contact>>();
```

Do not repeatedly iterate over large lists to find related records when a Map can provide O(1)-style lookup.

### 20. Bulkification

Every Apex method must be designed with bulk execution in mind unless it is explicitly guaranteed to process one record. The code must safely handle:

- 1 record
- 10 records
- 100 records
- 200 records
- Multiple trigger invocations in one transaction where applicable

Do not write logic assuming `Trigger.new` contains one record.

### 21. The 200-Record Rule

Every trigger-related change must include a test that processes at least 200 records:

```apex
List<Account> accounts = new List<Account>();

for (Integer index = 0; index < 200; index++) {
    accounts.add(new Account(
        Name = 'Bulk Test Account ' + index
    ));
}

insert accounts;
```

The test must verify meaningful behavior, not merely that the insert succeeds.

---

## Part 6 — Triggers

### 22. Trigger Standards

Use one trigger per object. The trigger must contain no business logic.

```apex
trigger AccountTrigger on Account (
    before insert,
    before update,
    after insert,
    after update,
    before delete,
    after delete,
    after undelete
) {
    AccountTriggerHandler.run();
}
```

Before creating a trigger, check that no other trigger already exists for the object.

### 23. Trigger Handler Standards

Triggers delegate to handlers:

```apex
public with sharing class AccountTriggerHandler {

    /**
     * @description Executes Account trigger behavior for the current context.
     */
    public static void run() {
        if (Trigger.isBefore) {
            handleBefore();
        }

        if (Trigger.isAfter) {
            handleAfter();
        }
    }

    /**
     * @description Handles before-trigger behavior.
     */
    private static void handleBefore() {
    }

    /**
     * @description Handles after-trigger behavior.
     */
    private static void handleAfter() {
    }
}
```

Do not place complex logic directly inside triggers.

### 24. Trigger Context

Code must explicitly consider:

- `Trigger.isInsert`
- `Trigger.isUpdate`
- `Trigger.isDelete`
- `Trigger.isUndelete`
- `Trigger.isBefore`
- `Trigger.isAfter`

Do not access `Trigger.new` or `Trigger.old` in an incompatible context.

### 25. Old vs New Values

For updates, compare old and new values when processing is conditional.

Bad (if the operation is only necessary when a specific field changed):

```apex
for (Account account : Trigger.new) {
    updateSomething(account);
}
```

Preferred:

```apex
for (Account account : Trigger.new) {
    Account oldAccount = Trigger.oldMap.get(account.Id);

    if (account.Status__c != oldAccount.Status__c) {
        accountsToProcess.add(account);
    }
}
```

This reduces unnecessary processing.

### 26. Recursion Prevention

Trigger-driven logic must avoid accidental recursion. Use an appropriate recursion-control mechanism when necessary:

```apex
// Tracks Accounts already processed during this transaction.
private static Set<Id> processedAccountIds = new Set<Id>();
```

Do not use a global static Boolean as the default recursion solution when multiple trigger batches may occur in the same transaction.

Bad:

```apex
if (hasRun) {
    return;
}

hasRun = true;
```

This can incorrectly prevent legitimate processing of subsequent batches. Prefer record-based tracking where appropriate.

### 27. Avoid Unnecessary DML

Do not update records if no meaningful field changed.

Bad (when every Account is unchanged):

```apex
update accounts;
```

Preferred:

```apex
if (!accountsToUpdate.isEmpty()) {
    update accountsToUpdate;
}
```

Where possible, only add records that actually require changes.

### 28. Partial Success DML

Use partial-success DML only when the business requirement supports it:

```apex
Database.SaveResult[] results =
    Database.update(accountsToUpdate, false);
```

When using partial success:

- Inspect every `SaveResult`.
- Capture failures.
- Do not silently ignore errors.
- Log or return meaningful error information.
- Test both success and failure paths.

---

## Part 7 — Exceptions

### 29. Exception Handling

Do not catch exceptions without handling them. Never silently swallow exceptions.

Bad:

```apex
try {
    update accounts;
} catch (Exception e) {
}
```

### 30. Exception Logging

If an exception is intentionally caught, the code must either:

- Re-throw it.
- Convert it into a meaningful application exception.
- Return an explicit error.
- Log it through the project's logging mechanism.
- Handle it according to the established architecture.

```apex
try {
    update accountsToUpdate;
} catch (DmlException dmlException) {
    // Preserve the original failure while adding business context.
    throw new AccountServiceException(
        'Unable to update Accounts: ' + dmlException.getMessage()
    );
}
```

> Note: `exception` is a reserved word in Apex and cannot be used as a variable name. Use a descriptive name such as `dmlException` or `serviceException`.

### 31. Custom Exceptions

Use custom exceptions when they provide meaningful business context:

```apex
public class AccountServiceException extends Exception {
}
```

Do not create custom exception classes for trivial cases without a clear benefit.

---

## Part 8 — Governor Limits & Efficiency

### 32. Governor Limits

All code must be designed around Salesforce governor limits. Consider:

- SOQL query limits
- DML statement limits
- DML row limits
- CPU time
- Heap size
- Callouts
- Queueable limits
- Future limits
- Email limits
- SOSL limits
- Query rows

Do not write code that merely works for one record but fails at scale.

### 33. Avoid Repeated Queries

Do not execute the same query repeatedly. Query once and reuse the result.

Bad:

```apex
List<Account> accounts1 = [SELECT Id FROM Account WHERE Id IN :ids];
List<Account> accounts2 = [SELECT Id FROM Account WHERE Id IN :ids];
```

### 34. SOQL Relationship Queries

Use relationship queries when they reduce unnecessary queries:

```apex
List<Account> accounts = [
    SELECT Id,
           Name,
           (SELECT Id, Email FROM Contacts)
    FROM Account
    WHERE Id IN :accountIds
];
```

Do not use child relationship queries blindly if the number of child records could become very large. Choose the query shape based on expected data volume.

### 35. Avoid Nested Loops Where Maps Work

Bad:

```apex
for (Account account : accounts) {
    for (Contact contact : contacts) {
        if (contact.AccountId == account.Id) {
            // ...
        }
    }
}
```

Prefer building a `Map<Id, List<Contact>> contactsByAccountId` once and looking up by key.

### 36. Collections

Use the correct collection for the job:

- **List** — order matters; duplicate values are allowed; processing records sequentially.
- **Set** — values must be unique; membership checks are needed; building SOQL `IN` filters.
- **Map** — records need to be looked up by key; parent-child relationships need to be represented; existing records need to be matched efficiently.

### 37. Null Handling

Explicitly consider null values:

- Null Ids
- Null lookup fields
- Null strings
- Null dates
- Empty collections
- Missing query results

Avoid unnecessary null checks where the Apex type or platform guarantees a value.

### 38. Empty Collections

Methods accepting collections should safely handle `null` and empty collections (e.g. `new Set<Id>()`) when appropriate:

```apex
if (accountIds == null || accountIds.isEmpty()) {
    return;
}
```

Do not execute unnecessary SOQL/DML for empty input.

---

## Part 9 — Design & Architecture

### 39. Method Size

Methods should have one clear responsibility. Avoid very large methods containing querying, validation, business logic, DML, error handling, notifications, and integration all in one method.

- Extract cohesive operations into appropriately named methods.
- Do not split code into dozens of meaningless one-line methods.

### 40. Single Responsibility

A class should have a clear primary responsibility:

```text
AccountTriggerHandler
AccountSelector
AccountService
AccountValidator
AccountTestDataFactory
```

Avoid a class such as `AccountUtils` containing unrelated queries, email logic, validation, integration, formatting, and trigger processing — unless the existing project architecture explicitly uses such a utility pattern.

### 41. Selector / Query Classes

If the project uses selectors, centralize reusable SOQL:

```apex
public with sharing class AccountSelector {

    /**
     * @description Returns Accounts required by the Account service.
     * @param accountIds Account Ids to retrieve.
     * @return Matching Accounts.
     */
    public static List<Account> selectByIds(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return new List<Account>();
        }

        return [
            SELECT Id, Name, OwnerId
            FROM Account
            WHERE Id IN :accountIds
        ];
    }
}
```

Do not duplicate the same query in many classes without reason.

### 42. Service Classes

Service classes should contain business operations (e.g. `AccountService`, `OpportunityService`, `ContactService`, `ContractRenewalService`). A service should not become a dumping ground for unrelated functionality.

### 43. Validation

Validation should happen before DML where possible:

```apex
validateAccounts(accountsToProcess);

if (!accountsToProcess.isEmpty()) {
    update accountsToProcess;
}
```

Validation messages should be meaningful.

Bad:

```apex
throw new Exception('Invalid');
```

Preferred:

```apex
throw new AccountServiceException(
    'An Account must have an active owner before renewal processing.'
);
```

---

## Part 10 — Asynchronous Apex

### 44. Asynchronous Apex

Use asynchronous processing when appropriate for:

- Long-running operations
- Large data volumes
- Callouts
- Work that does not need to complete within the current transaction

Choose the appropriate mechanism: Queueable, Batch, Scheduled Apex, or Future (only where appropriate and supported by project architecture).

Prefer Queueable over Future for most new asynchronous work when Queueable meets the requirement.

### 45. Queueable Apex

Queueable classes should:

- Have a clear responsibility.
- Use serializable state.
- Avoid passing unnecessary data.
- Prefer Ids over entire large object graphs.
- Avoid chaining indefinitely.
- Handle errors appropriately.
- Have dedicated tests.

```apex
public with sharing class AccountRecalculationQueueable
    implements Queueable {

    // Accounts that require asynchronous recalculation.
    private Set<Id> accountIds;

    /**
     * @description Creates the queueable job.
     * @param accountIds Accounts requiring recalculation.
     */
    public AccountRecalculationQueueable(Set<Id> accountIds) {
        this.accountIds = accountIds;
    }

    /**
     * @description Executes asynchronous Account recalculation.
     */
    public void execute(QueueableContext context) {
        AccountService.recalculate(accountIds);
    }
}
```

### 46. Batch Apex

Batch Apex must be used when the data volume requires it. Batch classes should:

- Keep `start`, `execute`, and `finish` focused.
- Use a reasonable batch size.
- Avoid unnecessary state.
- Handle partial failures intentionally.
- Be tested with representative data.
- Document whether `Database.Stateful` is required.

Do not use Batch Apex simply because it is available.

### 47. Scheduled Apex

Scheduled jobs should:

- Delegate business logic to a service.
- Avoid putting substantial business logic in `execute`.
- Be testable.
- Avoid creating duplicate scheduled jobs accidentally.
- Document the expected schedule.

---

## Part 11 — Integrations, Callouts & Logging

### 48. Callouts

Never perform a synchronous callout from a context where Salesforce prohibits it. Use appropriate asynchronous processing.

Callout code must:

- Use Named Credentials where appropriate.
- Avoid hard-coded credentials.
- Handle non-success HTTP statuses.
- Set appropriate timeouts.
- Avoid logging secrets.
- Have mocked tests.

### 49. Integration Security

Never hard-code passwords, tokens, API keys, client secrets, authorization headers containing secrets, or private credentials.

Use Named Credentials, External Credentials, and appropriate Salesforce security configuration.

### 50. Logging

Logging must not expose sensitive information. Never log:

- Passwords
- Tokens
- Secrets
- Session IDs
- Authorization headers
- Sensitive personal information unless explicitly required and approved

Use the project's existing logging framework if one exists.

---

## Part 12 — IDs, Record Types, Picklists & Configuration

### 51. Hard-Coded IDs

Do not hard-code Salesforce record IDs in production code or tests. Tests must not depend on production IDs.

Bad:

```apex
Id recordTypeId = '012XXXXXXXXXXXX';
```

Prefer querying or using metadata/configuration appropriately.

### 52. Record Types

Do not assume a Record Type ID. Prefer:

```apex
RecordType recordType = [
    SELECT Id
    FROM RecordType
    WHERE SObjectType = 'Account'
    AND DeveloperName = 'Business_Account'
    LIMIT 1
];
```

(`Business_Account` is illustrative — confirm the actual DeveloperName per rule 2.2.) When appropriate, centralize Record Type lookup.

### 53. Picklists

Do not blindly hard-code picklist values throughout the application. Where configuration-driven behavior is required, use Custom Metadata, Custom Settings, or appropriate metadata APIs/configuration. If a business value must be hard-coded, centralize it where practical.

### 54. Custom Metadata

Use Custom Metadata for configuration that should be deployable and environment-independent. Do not use Custom Metadata as a replacement for normal business records. Document why configuration is stored there.

---

## Part 13 — Test Class Standards

### 55. Test Classes Required

Every production Apex class must have an appropriate test class unless the platform behavior or project architecture explicitly makes separate coverage unnecessary. Test classes must verify **behavior**, not merely coverage.

### 56. Test Class Naming

Use `<ClassName>Test`:

```text
AccountServiceTest
AccountTriggerHandlerTest
ContactSelectorTest
RenewalQueueableTest
```

### 57. Test Data Factory

Use a shared `TestDataFactory` when the project has one:

```apex
Account account = TestDataFactory.createAccount(false);
insert account;
```

The factory should support an `insertRecord` flag (or equivalent behavior) rather than forcing every test to perform DML unnecessarily. The boolean should have a clear meaning and be documented.

### 58. Never Depend on Existing Org Data

Tests must not use `@IsTest(SeeAllData=true)` unless there is a documented, unavoidable reason. Tests should create their own data.

### 59. Test Isolation

Every test must be independent. A test must not depend on:

- Execution order
- Data created by another test
- Existing org records
- Another test method
- Static state from another test

### 60. Test Setup

Use `@TestSetup` for shared immutable test data where appropriate:

```apex
@TestSetup
static void setupData() {
    insert TestDataFactory.createAccount(false);
}
```

Do not put all possible test data into `@TestSetup` if individual tests require substantially different scenarios.

### 61. Test Method Naming

Test method names should describe the scenario:

```apex
@IsTest
static void shouldCreateRenewalOpportunityWhenContractExpires() {
}

@IsTest
static void shouldNotCreateOpportunityWhenContractIsInactive() {
}

@IsTest
static void shouldProcess200AccountsInBulk() {
}
```

Avoid: `test1()`, `testMethod()`, `testAccount()`.

### 62. Given / When / Then

Tests should generally follow the Given / When / Then structure:

```apex
@IsTest
static void shouldUpdateAccountWhenContactIsCreated() {
    // Given
    Account account = TestDataFactory.createAccount(true);

    Test.startTest();

    // When
    insert TestDataFactory.createContact(account.Id, false);

    Test.stopTest();

    // Then
    Account actualAccount = [
        SELECT Contact_Count__c
        FROM Account
        WHERE Id = :account.Id
    ];

    System.assertEquals(
        1,
        actualAccount.Contact_Count__c,
        'The Account contact count should be recalculated.'
    );
}
```

### 63. Assertions Are Mandatory

Every meaningful test must contain assertions. This is **not** a sufficient test:

```apex
@IsTest
static void testAccountInsert() {
    insert new Account(Name = 'Test');
}
```

Preferred:

```apex
System.assertEquals(
    'Expected Status',
    actual.Status__c,
    'Status should be updated after processing.'
);
```

### 64. Assertion Messages

Every assertion should have a meaningful failure message:

```apex
System.assertEquals(
    expectedValue,
    actualValue,
    'The service should calculate the expected revenue.'
);
```

Avoid: `System.assertEquals(expectedValue, actualValue);`

### 65. Do Not Over-Assert

Do not assert every field simply to increase the number of assertions. Assert behavior relevant to the test scenario.

Bad (unless those values are part of the requirement):

```apex
System.assertNotEquals(null, record.Id);
System.assertEquals('Test', record.Name);
System.assertEquals(null, record.Description);
System.assertEquals(null, record.Phone);
```

### 66. Positive Tests

Every business feature should have tests for valid behavior:

```text
Given an active Account
When the renewal process runs
Then a renewal Opportunity is created.
```

### 67. Negative Tests

Test invalid and blocked scenarios:

- Missing required information
- Inactive records
- Invalid status
- Unauthorized action
- Missing relationship
- Duplicate input
- Empty input

### 68. Boundary Tests

Test boundary conditions:

- 0 records
- 1 record
- 199 records
- 200 records
- 201 records where relevant
- Empty collections
- Maximum supported values
- Minimum supported values

Not every feature requires every boundary, but bulk processing must be tested appropriately.

### 69. Bulk Tests

Every trigger must have a bulk test with a minimum of **200 records**. The test must verify that:

- No governor limit exception occurs.
- All relevant records are processed.
- Results are correct.

Simply inserting 200 records without assertions is insufficient.

### 70. Bulk Update Tests

If behavior occurs on update, test 200 updates, then verify the expected result:

```apex
List<Account> accounts = [
    SELECT Id, Status__c
    FROM Account
    LIMIT 200
];

for (Account account : accounts) {
    account.Status__c = 'Active';
}

Test.startTest();
update accounts;
Test.stopTest();
```

### 71. Bulk Delete Tests

If delete logic exists, test multiple records. Verify:

- Correct records are processed.
- Related records are handled correctly.
- No limits are exceeded.

### 72. Bulk Undelete Tests

If undelete behavior exists, explicitly test it, then verify the expected behavior:

```apex
delete accounts;
undelete accounts;
```

### 73. Trigger Context Tests

If a trigger supports multiple contexts, test the relevant contexts separately: insert, update, delete, undelete, before, after. Do not assume testing insert automatically validates update/delete behavior.

### 74. `Test.startTest()` and `Test.stopTest()`

Use these to isolate the operation being tested. They are especially important for Queueable, Batch, Scheduled Apex, Future methods, and governor-limit-sensitive operations.

```apex
Test.startTest();

System.enqueueJob(new AccountQueueable(accountIds));

Test.stopTest();
```

Assertions should generally occur after `Test.stopTest()` when testing asynchronous work.

### 75. Testing Asynchronous Apex

For Queueable, Batch, Scheduled, and Future Apex:

```apex
Test.startTest();

// Execute asynchronous operation.

Test.stopTest();

// Assert final result.
```

Do not assert asynchronous results before `Test.stopTest()` unless testing only enqueue behavior.

### 76. Queueable Tests

Test:

- Job can be enqueued.
- Job executes.
- Expected records are changed.
- Error scenarios where relevant.
- Bulk input where applicable.

Do not test only `System.enqueueJob(job);` without validating its effect.

### 77. Batch Tests

Batch tests should verify:

- Start scope.
- Execute behavior.
- Finish behavior when applicable.
- Records processed.
- Results after `Test.stopTest()`.

Use manageable test data volumes.

### 78. Scheduled Tests

```apex
Test.startTest();

System.schedule(
    'Test Schedule',
    cronExpression,
    scheduledJob
);

Test.stopTest();
```

Then assert the resulting behavior.

### 79. Callout Tests

Use `HttpCalloutMock` or the project's established mock framework. Never perform a real external callout in a unit test. Test:

- Successful response.
- HTTP error response.
- Timeout/error behavior where practical.
- Invalid response handling.

### 80. Callout Mock Example

```apex
Test.setMock(
    HttpCalloutMock.class,
    new ExternalServiceMock()
);

Test.startTest();

ExternalService.sendAccount(account.Id);

Test.stopTest();
```

Then assert the resulting behavior.

### 81. Test Exceptions

If a method is expected to throw an exception, explicitly test it:

```apex
try {
    AccountService.process(null);

    System.assert(
        false,
        'The service should reject null input.'
    );
} catch (AccountService.AccountServiceException serviceException) {
    System.assert(
        serviceException.getMessage().contains('Account'),
        'The exception should explain the invalid Account input.'
    );
}
```

### 82. `System.assert(false)` Usage

Use `System.assert(false, '...')` only when deliberately verifying that an exception should occur. Do not use it as a replacement for proper assertions.

### 83. Test Factory Rules

Test factories must:

- Create valid baseline records.
- Avoid hard-coded IDs.
- Allow tests to override relevant fields.
- Avoid hidden business behavior.
- Avoid excessive DML.
- Be reusable.
- Clearly document parameters.

Bad: `createAccount(Boolean insertRecord)` without explaining what the Boolean means.

Better:

```apex
/**
 * @description Creates a valid Account test record.
 * @param insertRecord Whether the record should be inserted.
 * @return A valid Account test record.
 */
public static Account createAccount(Boolean insertRecord) {
```

### 84. Avoid Hidden DML in Factories

Factories should make DML behavior obvious. If a method inserts records, its name should communicate that. Preferred patterns: `createAccount(false)`, `createAndInsertAccount()` — rather than hiding substantial DML behind an ambiguous method.

### 85. Test Data Independence

Tests should modify their own test data. Do not rely on mutable shared objects between test methods.

### 86. Testing Security

Where security behavior is part of the requirement, tests should verify user context, sharing behavior, CRUD/FLS behavior, and permission-dependent behavior. Use `System.runAs()` where appropriate. Do not use `runAs()` merely because it looks like a best practice.

### 87. Testing Record Ownership

When ownership affects business behavior, create the required users/owners explicitly. Do not assume the running user's role or permissions unless the requirement depends on them.

### 88. Testing Platform Events

Tests involving Platform Events should verify:

- Event publication.
- Relevant fields.
- Subscriber behavior where testable.
- Error handling.
- Bulk publication where relevant.

Use the appropriate Salesforce test mechanisms for event delivery.

### 89. Testing Flows and Automation Interactions

When Apex interacts with Flow or other automation:

- Be aware that DML can invoke additional automation.
- Do not assume Apex is the only code executing.
- Test the final observable behavior.
- Avoid creating recursive automation.
- Document important dependencies.

---

## Part 14 — Automation, DML Order & Transactions

### 90. Mixed Automation

Avoid duplicating the same business logic across Apex Triggers, Flow, legacy Process Builder, Workflow Rules, and Validation Rules. Before adding Apex logic, determine whether the behavior already exists elsewhere (search `flows/`, `workflows/`, `objects/*/validationRules/`).

### 91. Validation Rules

Do not duplicate validation-rule logic in Apex unless necessary. Tests should account for validation rules that affect the operation.

### 92. DML Order

Respect Salesforce relationship dependencies (e.g. Account → Contact → Opportunity). Create parent records before child records when required. Delete dependent records appropriately.

### 93. Mixed DML

Be aware of Mixed DML restrictions involving setup and non-setup objects. When necessary, isolate operations appropriately using asynchronous execution or supported testing patterns.

### 94. Database Methods

When using `Database.insert(...)`, `Database.update(...)`, or `Database.delete(...)`, choose the appropriate `allOrNone` behavior deliberately. Do not use `false` automatically.

### 95. Error Collection

If partial DML is used, inspect every result. Never silently discard errors.

```apex
Database.SaveResult[] results =
    Database.update(records, false);

for (Database.SaveResult result : results) {
    if (!result.isSuccess()) {
        for (Database.Error error : result.getErrors()) {
            // Record or handle the failure.
        }
    }
}
```

### 96. Transaction Boundaries

Apex code within one synchronous transaction generally shares governor limits, the database transaction, and static state. Do not assume another class invocation resets static variables.

### 97. Static Variables

Static state must be used carefully. Avoid static variables for persistent business state. Static variables should generally support recursion control, transaction-level caching, constants, and temporary state. Document non-obvious static state.

### 98. Caching

If a record is repeatedly queried during one transaction, consider transaction-level caching where appropriate. Do not introduce caching where stale values could cause incorrect behavior.

---

## Part 15 — Dynamic SOQL, SOSL & Exposed Services

### 99. SOQL Injection

Never concatenate untrusted user input directly into dynamic SOQL.

Bad:

```apex
String query = 'SELECT Id FROM Account WHERE Name = \'' + name + '\'';
```

Prefer bind variables:

```apex
String query = 'SELECT Id FROM Account WHERE Name = :name';
```

Dynamic field/object names must be validated against an allowlist.

### 100. Dynamic SOQL

Use dynamic SOQL only when required; prefer static SOQL when the query structure is known. Dynamic queries must:

- Validate dynamic object names.
- Validate dynamic field names.
- Bind user-provided values.
- Avoid injection.
- Document why dynamic SOQL is required.

### 101. SOSL

Use SOSL only when searching across multiple objects is actually required. Do not use SOSL where a targeted SOQL query is simpler and more efficient.

### 102. Sharing Context

Every service exposed to UI/API/integration code must deliberately consider the intended sharing context. Do not assume `with sharing` automatically enforces CRUD/FLS. Sharing, CRUD, and FLS are separate concerns.

### 103. User Mode

Where project architecture permits, prefer user-mode database operations when the operation is intended to respect the current user's permissions. Document intentional system-mode operations.

### 104. Invocable Apex

Invocable methods must:

- Be bulkified.
- Accept collections.
- Avoid one-record assumptions.
- Avoid SOQL/DML in loops.
- Return appropriate results when required.
- Have Flow-oriented documentation.

Bad for an invocable action: `public static void process(Id accountId)`. Prefer collection-based processing.

### 105. REST Apex

REST endpoints must:

- Validate input.
- Validate authorization.
- Return meaningful status codes.
- Avoid exposing internal exceptions.
- Avoid exposing sensitive data.
- Be bulk-safe where appropriate.
- Have tests for success and failure responses.

### 106. API Error Messages

External consumers should receive meaningful but safe error messages. Do not expose stack traces, internal class names unnecessarily, database implementation details, credentials, secrets, or sensitive information.

### 107. LWC Apex Controllers

Apex methods exposed to LWC must:

- Be explicitly annotated.
- Validate inputs.
- Respect security.
- Return appropriate DTO/wrapper data when necessary.
- Avoid returning unnecessarily large objects.
- Be bulk-aware where applicable.

### 108. `@AuraEnabled(cacheable=true)`

Only use `cacheable=true` for methods that are genuinely read-only. Do not perform DML in a cacheable method. Do not mark a method cacheable simply to improve performance.

### 109. DTO / Wrapper Classes

Use DTO/wrapper classes when returning multiple unrelated values, aggregated results, UI-specific structures, or API-specific response models. Document each public property.

### 110. Avoid Returning Excessive Data

Do not return entire Salesforce records when the consumer only needs a few fields. Return the minimum necessary data.

---

## Part 16 — Performance, Data Volume & Locale

### 111. Performance

Performance considerations must include SOQL count, query row count, DML count, CPU time, heap usage, collection sizes, string manipulation, nested loops, serialization, and callouts. Do not optimize prematurely, but avoid obviously inefficient patterns.

### 112. Large Data Volume

For large data volumes:

- Avoid loading unnecessary records.
- Use selective filters.
- Consider Batch Apex.
- Avoid large nested collections.
- Avoid non-selective queries.
- Consider indexing and query selectivity.
- Avoid processing entire tables when only a subset is required.

### 113. Query Selectivity

Queries processing large objects should use selective filters where appropriate. Avoid broad queries such as the following when the business operation can identify a smaller dataset:

```apex
SELECT Id
FROM Account
WHERE Name != null
```

### 114. Date and Time

Use Salesforce date/time types appropriately. Do not manually calculate time zones when Salesforce APIs already provide appropriate behavior. Be explicit about `Date`, `Datetime`, user timezone, UTC, and business timezone when time-sensitive behavior is involved.

### 115. Currency

Do not assume all Salesforce orgs use a single currency. When multi-currency is enabled, consider `CurrencyIsoCode`, conversion behavior, corporate currency, and user currency when relevant.

### 116. Locale

Do not parse formatted currency/date strings manually unless required. Avoid assumptions about decimal separators, date formats, currency symbols, and user locale.

---

## Part 17 — Test Quality Rules

### 117. Governor-Limit Testing

Tests should expose inefficient code where practical. For expensive operations, consider assertions around limits when appropriate:

```apex
Integer queriesBefore = Limits.getQueries();

// Operation.

Integer queriesUsed =
    Limits.getQueries() - queriesBefore;
```

Do not make tests unnecessarily brittle by asserting exact internal query counts unless query count is itself a contractual requirement.

### 118. Test Exact Business Outcomes

Prefer:

```apex
System.assertEquals(
    3,
    account.Contact_Count__c,
    'The Contact count should equal the number of related Contacts.'
);
```

over `System.assertNotEquals(null, account);` — the first verifies business behavior.

### 119. Do Not Test Implementation Instead of Behavior

Avoid tests that fail simply because internal implementation changes (e.g. "assert that private method X was called"). Prefer asserting that the expected Salesforce state exists after the operation.

### 120. Test Existing Data Changes

If the feature updates existing records, create realistic existing records first. Do not only test new-record creation.

### 121. Test Duplicate Operations

Where idempotency matters, execute the operation twice:

```text
Given an Account eligible for processing
When processing occurs twice
Then duplicate records are not created.
```

### 122. Idempotency

Operations triggered repeatedly should be idempotent where the business process requires it. Do not create duplicate records simply because a trigger fires more than once. Use stable identifiers and existing-record checks where appropriate.

### 123. Duplicate Prevention

Before creating a record that should be logically unique, determine whether an existing record already represents the same business operation. Do not rely solely on querying without considering race conditions where uniqueness is critical. Use Salesforce uniqueness mechanisms where appropriate.

### 124. Transaction Safety

Do not leave Salesforce data in a partially updated state unless partial success is explicitly intended. Where multiple DML operations represent one business transaction, consider whether they should succeed or fail together.

### 125. Savepoints

Use savepoints only when rollback behavior is actually required.

### 126. Recursion Across Automation

Be aware of recursion such as:

```text
Trigger → Service → update Account → Trigger → Service
Apex → Flow → Update → Apex
```

The design must prevent unintended repeated processing.

### 127. Trigger Ordering

Do not rely on undocumented execution ordering between independent automation components. If ordering matters, consolidate the logic or establish an explicit orchestration mechanism.

### 128. Error Handling in Triggers

Trigger errors must provide useful messages.

Avoid: `addError('Error');`

Prefer:

```apex
account.addError(
    'An active Account owner is required before the Account can be submitted.'
);
```

### 129. `addError`

Use `addError` when the desired behavior is to prevent the transaction. Do not use exceptions where an appropriate record-level validation error is clearer.

### 130. Trigger Logic Should Be Deterministic

Given the same input and Salesforce state, trigger behavior should be predictable. Avoid (unless required): random values, current time without requirement, external dependencies without mocking, hidden static state, undocumented configuration.

---

## Part 18 — Magic Values & Configuration

### 131. Avoid Magic Numbers

Bad: `if (daysOpen > 30) {`

Prefer (if `30` is a meaningful business constant):

```apex
private static final Integer STALE_DAYS = 30;
```

### 132. Avoid Magic Strings

Bad: `if (account.Status__c == 'Approved') {`

Repeated business statuses should be centralized when appropriate. Do not centralize every trivial string.

### 133. Business Logic vs Configuration

If business users may need to change a value without deploying code, consider configuration — e.g. approval thresholds, days before renewal, status mappings, integration endpoints, feature flags. Use the project's established configuration mechanism.

### 134. Feature Flags

If a feature flag exists, tests must cover both enabled and disabled states. The code should fail safely when the feature is disabled.

### 135. Deployment Safety

Code must be deployable independently where possible. Avoid creating dependencies on undeployed metadata. If a change requires multiple metadata components, identify the dependency clearly.

---

## Part 19 — Coverage & Determinism

### 136. Test Coverage

Code coverage percentage alone is not sufficient. A test suite must cover:

- Happy paths
- Negative paths
- Bulk behavior
- Exceptions
- Boundary conditions
- Relevant trigger contexts
- Asynchronous execution
- Security behavior where applicable

### 137. Code Coverage Anti-Patterns

Never write meaningless code solely to increase coverage. Do not add tests that only execute lines without verifying outcomes.

Bad (no assertion):

```apex
Test.startTest();
AccountService.process(accounts);
Test.stopTest();
```

### 138. Tests Must Be Deterministic

Tests must not depend on the current date (unless explicitly testing date behavior), random values, external systems, existing org data, execution order, or deployment-specific IDs. Use controlled test data.
