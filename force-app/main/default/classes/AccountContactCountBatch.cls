/**
 * One-off backfill of Account.Number_of_Contacts__c for existing Accounts.
 * Reuses ContactTriggerHandler so the batch and the trigger count the same way.
 *
 * Run from Anonymous Apex:
 *     Database.executeBatch(new AccountContactCountBatch());
 *
 * If Accounts in a chunk have more than 50,000 Contacts between them, pass a
 * smaller scope, e.g. Database.executeBatch(new AccountContactCountBatch(), 50);
 */
public without sharing class AccountContactCountBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([SELECT Id FROM Account]);
    }

    public void execute(Database.BatchableContext context, List<Account> accounts) {
        ContactTriggerHandler.recalculateContactCounts(new Map<Id, Account>(accounts).keySet().clone());
    }

    public void finish(Database.BatchableContext context) {
    }
}
