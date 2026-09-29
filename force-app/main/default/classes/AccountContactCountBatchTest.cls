@IsTest
private class AccountContactCountBatchTest {

    @IsTest
    static void backfillsRollupsForExistingAccounts() {
        Account withContacts = new Account(Name = 'With Contacts');
        Account withoutContacts = new Account(Name = 'Without Contacts');
        insert new List<Account>{ withContacts, withoutContacts };

        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 3; i++) {
            contacts.add(new Contact(
                LastName = 'Test ' + i,
                AccountId = withContacts.Id,
                Expected_Revenues__c = 100
            ));
        }
        insert contacts;

        // Simulate data that existed before the trigger: stale rollups on both Accounts.
        withContacts.Number_of_Contacts__c = 0;
        withContacts.Expected_Revenue__c = 0;
        withoutContacts.Number_of_Contacts__c = 5;
        withoutContacts.Expected_Revenue__c = 500;
        update new List<Account>{ withContacts, withoutContacts };

        Test.startTest();
        Database.executeBatch(new AccountContactCountBatch());
        Test.stopTest();

        Map<Id, Account> accountsById = new Map<Id, Account>(
            [SELECT Id, Number_of_Contacts__c, Expected_Revenue__c FROM Account]
        );
        Assert.areEqual(3, accountsById.get(withContacts.Id).Number_of_Contacts__c);
        Assert.areEqual(300, accountsById.get(withContacts.Id).Expected_Revenue__c);
        Assert.areEqual(0, accountsById.get(withoutContacts.Id).Number_of_Contacts__c);
        Assert.areEqual(0, accountsById.get(withoutContacts.Id).Expected_Revenue__c);
    }
}
