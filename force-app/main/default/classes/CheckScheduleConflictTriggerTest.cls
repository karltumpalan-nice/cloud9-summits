@istest
public with sharing class CheckScheduleConflictTriggerTest {
    @TestSetup
    static void makeData(){
        // Create test data
        Contact testContact = new Contact(LastName = 'Test Contact');
        insert testContact;

        String inProgressStatusValue;
        for (Schema.PicklistEntry entry : Conference__c.Status__c.getDescribe().getPicklistValues()) {
            if (entry.getLabel() == 'In Progress' || entry.getValue() == 'In Progress') {
                inProgressStatusValue = entry.getValue();
                break;
            }
        }

        if (inProgressStatusValue == null) {
            inProgressStatusValue = Conference__c.Status__c.getDescribe().getPicklistValues()[0].getValue();
        }

        Conference__c testConference = new Conference__c(
            Name = 'Test Conference',
            Location__c = 'Philippines',
            Start_Date__c = Date.newInstance(2027, 1, 1),
            End_Date__c = Date.newInstance(2027, 1, 2),
            Status__c = inProgressStatusValue
        );
        insert testConference;

        Session__c testSession1 = new Session__c(
            Name = 'Test Session 1', 
            Conference__c = testConference.Id,
            Start_Date_and_Time__c = DateTime.newInstance(2027, 1,
                1, 10, 0, 0),
            End_Date_and_Time__c = DateTime.newInstance(2027, 1,
                1, 11, 0, 0),
            Title__c = 'Test Session 1 Title',
            Room_Name__c = 'Test Room 1'
        );
        Session__c testSession2 = new Session__c(
            Name = 'Test Session 2', 
            Conference__c = testConference.Id,
            Start_Date_and_Time__c = DateTime.newInstance(2027, 1,
                1, 10, 30, 0),
            End_Date_and_Time__c = DateTime.newInstance(2027, 1,
                1, 11, 30, 0),
            Title__c = 'Test Session 2 Title',
            Room_Name__c = 'Test Room 2'
        );
        Session__c testSession3 = new Session__c(
            Name = 'Test Session 3', 
            Conference__c = testConference.Id,
            Start_Date_and_Time__c = DateTime.newInstance(2027, 1,
                1, 11, 30, 0),
            End_Date_and_Time__c = DateTime.newInstance(2027, 1,
                1, 12, 30, 0),
            Title__c = 'Test Session 3 Title',
            Room_Name__c = 'Test Room 3'
        );

        List<Session__c> testSessions = new List<Session__c>{testSession1, testSession2, testSession3};
        insert testSessions;
    }

    @isTest
    static void testScheduleConflictTrigger() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Session__c testSession1 = [SELECT Id FROM Session__c WHERE Name = 'Test Session 1' LIMIT 1];
        Session__c testSession2 = [SELECT Id FROM Session__c WHERE Name = 'Test Session 2' LIMIT 1];
        Speaker_Engagement__c se1 = new Speaker_Engagement__c(
            Contact__c = testContact.Id,
            Session__c = testSession1.Id
        );

        // Create a second engagement that overlaps with the first one
        Speaker_Engagement__c se2 = new Speaker_Engagement__c(
            Contact__c = testContact.Id,
            Session__c = testSession2.Id
        );

        // Attempt to insert the second engagement (should fail with an error)
        Test.startTest();
        try {
            insert se1;
            insert se2;
            System.assert(false, 'Expected an exception due to schedule conflict, but insert succeeded.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Schedule conflict detected'), 'Expected schedule conflict error, but got: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testNonOverlappingEngagement() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Session__c testSession1 = [SELECT Id FROM Session__c WHERE Name = 'Test Session 1' LIMIT 1];
        Session__c testSession3 = [SELECT Id FROM Session__c WHERE Name = 'Test Session 3' LIMIT 1];
        Speaker_Engagement__c se1 = new Speaker_Engagement__c(
            Contact__c = testContact.Id,
            Session__c = testSession1.Id
        );

        Speaker_Engagement__c se3 = new Speaker_Engagement__c(
            Contact__c = testContact.Id,
            Session__c = testSession3.Id
        );
        Test.startTest();
        try {
            insert se1;
            insert se3;
            System.assert(true, 'Non-overlapping insert succeeded as expected');
        } catch (DmlException e) {
            System.assert(false, 'Did not expect an exception for non-overlapping engagement, but got: ' + e.getMessage());
        }
        Test.stopTest();
    }
}