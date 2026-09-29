@IsTest
private class ContactTriggerHandlerTest {

    @TestSetup
    static void setup() {
        insert new List<Account>{ new Account(Name = 'Account A'), new Account(Name = 'Account B') };
    }

    private static Account getAccount(String name) {
        return [SELECT Id, Number_of_Contacts__c, Expected_Revenue__c FROM Account WHERE Name = :name];
    }

    private static List<Contact> buildContacts(Id accountId, Integer count, Decimal expectedRevenue) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            contacts.add(new Contact(
                LastName = 'Test ' + i,
                AccountId = accountId,
                Expected_Revenues__c = expectedRevenue
            ));
        }
        return contacts;
    }

    @IsTest
    static void insertRollsUpCountAndRevenue() {
        Account accountA = getAccount('Account A');

        Test.startTest();
        insert buildContacts(accountA.Id, 3, 100);
        Test.stopTest();

        accountA = getAccount('Account A');
        Assert.areEqual(3, accountA.Number_of_Contacts__c);
        Assert.areEqual(300, accountA.Expected_Revenue__c);
    }

    @IsTest
    static void bulkInsertIsRolledUp() {
        Account accountA = getAccount('Account A');

        Test.startTest();
        insert buildContacts(accountA.Id, 200, 10);
        Test.stopTest();

        accountA = getAccount('Account A');
        Assert.areEqual(200, accountA.Number_of_Contacts__c);
        Assert.areEqual(2000, accountA.Expected_Revenue__c);
    }

    @IsTest
    static void blankRevenueIsTreatedAsZero() {
        Account accountA = getAccount('Account A');
        List<Contact> contacts = buildContacts(accountA.Id, 2, null);
        contacts[0].Expected_Revenues__c = 50;

        Test.startTest();
        insert contacts;
        Test.stopTest();

        Assert.areEqual(50, getAccount('Account A').Expected_Revenue__c);
    }

    @IsTest
    static void allBlankRevenueRollsUpToZero() {
        Account accountA = getAccount('Account A');

        Test.startTest();
        insert buildContacts(accountA.Id, 2, null);
        Test.stopTest();

        accountA = getAccount('Account A');
        Assert.areEqual(2, accountA.Number_of_Contacts__c);
        Assert.areEqual(0, accountA.Expected_Revenue__c);
    }

    @IsTest
    static void changingRevenueRecalculatesAccount() {
        Account accountA = getAccount('Account A');
        List<Contact> contacts = buildContacts(accountA.Id, 2, 100);
        insert contacts;

        Test.startTest();
        contacts[0].Expected_Revenues__c = 250;
        update contacts[0];
        Test.stopTest();

        accountA = getAccount('Account A');
        Assert.areEqual(2, accountA.Number_of_Contacts__c);
        Assert.areEqual(350, accountA.Expected_Revenue__c);
    }

    @IsTest
    static void changingAccountRecalculatesBothAccounts() {
        Account accountA = getAccount('Account A');
        Account accountB = getAccount('Account B');
        List<Contact> contacts = buildContacts(accountA.Id, 2, 100);
        insert contacts;

        Test.startTest();
        contacts[0].AccountId = accountB.Id;
        update contacts[0];
        Test.stopTest();

        accountA = getAccount('Account A');
        accountB = getAccount('Account B');
        Assert.areEqual(1, accountA.Number_of_Contacts__c);
        Assert.areEqual(100, accountA.Expected_Revenue__c);
        Assert.areEqual(1, accountB.Number_of_Contacts__c);
        Assert.areEqual(100, accountB.Expected_Revenue__c);
    }

    @IsTest
    static void removingAccountFromContactResetsRollups() {
        Account accountA = getAccount('Account A');
        Contact contact = buildContacts(accountA.Id, 1, 100)[0];
        insert contact;

        Test.startTest();
        contact.AccountId = null;
        update contact;
        Test.stopTest();

        accountA = getAccount('Account A');
        Assert.areEqual(0, accountA.Number_of_Contacts__c);
        Assert.areEqual(0, accountA.Expected_Revenue__c);
    }

    @IsTest
    static void deleteAndUndeleteRecalculateRollups() {
        Account accountA = getAccount('Account A');
        List<Contact> contacts = buildContacts(accountA.Id, 2, 100);
        insert contacts;

        Test.startTest();
        delete contacts[0];
        accountA = getAccount('Account A');
        Assert.areEqual(1, accountA.Number_of_Contacts__c);
        Assert.areEqual(100, accountA.Expected_Revenue__c);

        undelete contacts[0];
        Test.stopTest();

        accountA = getAccount('Account A');
        Assert.areEqual(2, accountA.Number_of_Contacts__c);
        Assert.areEqual(200, accountA.Expected_Revenue__c);
    }

    @IsTest
    static void contactWithoutAccountIsIgnored() {
        Test.startTest();
        insert new Contact(LastName = 'Private', Expected_Revenues__c = 100);
        Test.stopTest();

        Assert.areEqual(0, getAccount('Account A').Number_of_Contacts__c);
    }
}
