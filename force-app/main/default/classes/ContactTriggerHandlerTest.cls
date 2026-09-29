@IsTest
private class ContactTriggerHandlerTest {

    @TestSetup
    static void setup() {
        insert new List<Account>{ new Account(Name = 'Account A'), new Account(Name = 'Account B') };
    }

    private static Account getAccount(String name) {
        return [SELECT Id, Number_of_Contacts__c FROM Account WHERE Name = :name];
    }

    private static List<Contact> buildContacts(Id accountId, Integer count) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            contacts.add(new Contact(LastName = 'Test ' + i, AccountId = accountId));
        }
        return contacts;
    }

    @IsTest
    static void insertIncrementsCount() {
        Account accountA = getAccount('Account A');

        Test.startTest();
        insert buildContacts(accountA.Id, 3);
        Test.stopTest();

        Assert.areEqual(3, getAccount('Account A').Number_of_Contacts__c);
    }

    @IsTest
    static void bulkInsertIsCounted() {
        Account accountA = getAccount('Account A');

        Test.startTest();
        insert buildContacts(accountA.Id, 200);
        Test.stopTest();

        Assert.areEqual(200, getAccount('Account A').Number_of_Contacts__c);
    }

    @IsTest
    static void changingAccountRecountsBothAccounts() {
        Account accountA = getAccount('Account A');
        Account accountB = getAccount('Account B');
        List<Contact> contacts = buildContacts(accountA.Id, 2);
        insert contacts;

        Test.startTest();
        contacts[0].AccountId = accountB.Id;
        update contacts[0];
        Test.stopTest();

        Assert.areEqual(1, getAccount('Account A').Number_of_Contacts__c);
        Assert.areEqual(1, getAccount('Account B').Number_of_Contacts__c);
    }

    @IsTest
    static void removingAccountFromContactDecrementsCount() {
        Account accountA = getAccount('Account A');
        Contact contact = buildContacts(accountA.Id, 1)[0];
        insert contact;

        Test.startTest();
        contact.AccountId = null;
        update contact;
        Test.stopTest();

        Assert.areEqual(0, getAccount('Account A').Number_of_Contacts__c);
    }

    @IsTest
    static void deleteAndUndeleteRecalculateCount() {
        Account accountA = getAccount('Account A');
        List<Contact> contacts = buildContacts(accountA.Id, 2);
        insert contacts;

        Test.startTest();
        delete contacts[0];
        Assert.areEqual(1, getAccount('Account A').Number_of_Contacts__c);

        undelete contacts[0];
        Test.stopTest();

        Assert.areEqual(2, getAccount('Account A').Number_of_Contacts__c);
    }

    @IsTest
    static void contactWithoutAccountIsIgnored() {
        Test.startTest();
        insert new Contact(LastName = 'Private');
        Test.stopTest();

        Assert.areEqual(0, getAccount('Account A').Number_of_Contacts__c);
    }
}
