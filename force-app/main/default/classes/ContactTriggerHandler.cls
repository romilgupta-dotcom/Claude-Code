/**
 * Keeps Account.Number_of_Contacts__c in sync with the Contacts related to each Account.
 *
 * Runs without sharing so the count includes every Contact on the Account,
 * not just the ones visible to the running user.
 */
public without sharing class ContactTriggerHandler {

    public static void onAfterInsert(List<Contact> newContacts) {
        recalculateContactCounts(collectAccountIds(newContacts));
    }

    public static void onAfterUpdate(List<Contact> newContacts, Map<Id, Contact> oldContactsById) {
        // Only a change of Account affects the counts; recount both the old and the new Account.
        Set<Id> accountIds = new Set<Id>();
        for (Contact newContact : newContacts) {
            Id oldAccountId = oldContactsById.get(newContact.Id).AccountId;
            if (newContact.AccountId != oldAccountId) {
                accountIds.add(newContact.AccountId);
                accountIds.add(oldAccountId);
            }
        }
        recalculateContactCounts(accountIds);
    }

    public static void onAfterDelete(List<Contact> oldContacts) {
        recalculateContactCounts(collectAccountIds(oldContacts));
    }

    public static void onAfterUndelete(List<Contact> restoredContacts) {
        recalculateContactCounts(collectAccountIds(restoredContacts));
    }

    /**
     * Recounts Contacts from the database rather than incrementing/decrementing,
     * so the value self-corrects if it ever drifts.
     */
    public static void recalculateContactCounts(Set<Id> accountIds) {
        accountIds.remove(null);
        if (accountIds.isEmpty()) {
            return;
        }

        // Default every Account to 0 so Accounts that lost their last Contact are reset.
        Map<Id, Account> accountsById = new Map<Id, Account>();
        for (Id accountId : accountIds) {
            accountsById.put(accountId, new Account(Id = accountId, Number_of_Contacts__c = 0));
        }

        for (AggregateResult result : [
            SELECT AccountId, COUNT(Id) contactCount
            FROM Contact
            WHERE AccountId IN :accountIds
            GROUP BY AccountId
        ]) {
            Id accountId = (Id) result.get('AccountId');
            accountsById.get(accountId).Number_of_Contacts__c = (Integer) result.get('contactCount');
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
