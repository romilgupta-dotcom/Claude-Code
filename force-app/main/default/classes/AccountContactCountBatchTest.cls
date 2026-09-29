@IsTest
private class AccountContactCountBatchTest {

    @IsTest
    static void backfillsCountsForExistingAccounts() {
        Account withContacts = new Account(Name = 'With Contacts');
        Account withoutContacts = new Account(Name = 'Without Contacts');
        insert new List<Account>{ withContacts, withoutContacts };

        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 3; i++) {
            contacts.add(new Contact(LastName = 'Test ' + i, AccountId = withContacts.Id));
        }
        insert contacts;

        // Simulate data that existed before the trigger: stale counts on both Accounts.
        withContacts.Number_of_Contacts__c = 0;
        withoutContacts.Number_of_Contacts__c = 5;
        update new List<Account>{ withContacts, withoutContacts };

        Test.startTest();
        Database.executeBatch(new AccountContactCountBatch());
        Test.stopTest();

        Map<Id, Account> accountsById = new Map<Id, Account>(
            [SELECT Id, Number_of_Contacts__c FROM Account]
        );
        Assert.areEqual(3, accountsById.get(withContacts.Id).Number_of_Contacts__c);
        Assert.areEqual(0, accountsById.get(withoutContacts.Id).Number_of_Contacts__c);
    }
}
