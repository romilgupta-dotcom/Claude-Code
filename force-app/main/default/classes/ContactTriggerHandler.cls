/**
 * Keeps these Account rollups in sync with the Contacts related to each Account:
 *   - Number_of_Contacts__c: count of Contacts
 *   - Expected_Revenue__c:   sum of Contact.Expected_Revenue__c
 *
 * Runs without sharing so the rollups include every Contact on the Account,
 * not just the ones visible to the running user.
 */
public without sharing class ContactTriggerHandler {

    public static void onAfterInsert(List<Contact> newContacts) {
        recalculateAccountRollups(collectAccountIds(newContacts));
    }

    public static void onAfterUpdate(List<Contact> newContacts, Map<Id, Contact> oldContactsById) {
        // Only a change of Account or Expected Revenue affects the rollups;
        // recount both the old and the new Account.
        Set<Id> accountIds = new Set<Id>();
        for (Contact newContact : newContacts) {
            Contact oldContact = oldContactsById.get(newContact.Id);
            if (newContact.AccountId != oldContact.AccountId
                    || newContact.Expected_Revenue__c != oldContact.Expected_Revenue__c) {
                accountIds.add(newContact.AccountId);
                accountIds.add(oldContact.AccountId);
            }
        }
        recalculateAccountRollups(accountIds);
    }

    public static void onAfterDelete(List<Contact> oldContacts) {
        recalculateAccountRollups(collectAccountIds(oldContacts));
    }

    public static void onAfterUndelete(List<Contact> restoredContacts) {
        recalculateAccountRollups(collectAccountIds(restoredContacts));
    }

    /**
     * Recalculates rollups from the database rather than incrementing/decrementing,
     * so the values self-correct if they ever drift.
     */
    public static void recalculateAccountRollups(Set<Id> accountIds) {
        accountIds.remove(null);
        if (accountIds.isEmpty()) {
            return;
        }

        // Default every Account to 0 so Accounts that lost their last Contact are reset.
        Map<Id, Account> accountsById = new Map<Id, Account>();
        for (Id accountId : accountIds) {
            accountsById.put(accountId, new Account(
                Id = accountId,
                Number_of_Contacts__c = 0,
                Expected_Revenue__c = 0
            ));
        }

        for (AggregateResult result : [
            SELECT AccountId, COUNT(Id) contactCount, SUM(Expected_Revenue__c) expectedRevenue
            FROM Contact
            WHERE AccountId IN :accountIds
            GROUP BY AccountId
        ]) {
            Account account = accountsById.get((Id) result.get('AccountId'));
            account.Number_of_Contacts__c = (Integer) result.get('contactCount');
            // SUM is null when every Contact's Expected Revenue is blank.
            Decimal expectedRevenue = (Decimal) result.get('expectedRevenue');
            account.Expected_Revenue__c = expectedRevenue == null ? 0 : expectedRevenue;
        }

        update accountsById.values();
    }

    private static Set<Id> collectAccountIds(List<Contact> contacts) {
        Set<Id> accountIds = new Set<Id>();
        for (Contact contact : contacts) {
            accountIds.add(contact.AccountId);
        }
        return accountIds;
    }
}
