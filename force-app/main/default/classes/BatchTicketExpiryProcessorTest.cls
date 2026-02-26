@isTest
public with sharing class BatchTicketExpiryProcessorTest {
    @TestSetup
    static void makeData(){
        String generalTypeValue;
        for (Schema.PicklistEntry entry: Ticket__c.Type__c.getDescribe().getPicklistValues()){
            if (entry.getLabel() == 'General') {
                generalTypeValue = entry.getValue();
                break;
            }
        }

        List<Ticket__c> tickets = new List<Ticket__c>();

        // Create 5 pending tickets that are overdue
        for (Integer i = 0; i < 5; i++) {
            tickets.add(new Ticket__c(
                Name = 'Pending Ticket ' + i,
                Payment_Status__c = 'Pending',
                Type__c = generalTypeValue,
                CreatedDate = Date.today().addDays(-32),
                Price__c=(i+1)*100,
                LastModifiedDate = Date.today().addDays(-31) // Set to 31 days ago to ensure they are overdue
            ));
        }

        // Create 5 pending tickets that are not overdue
        for (Integer j = 0; j < 5; j++) {
            tickets.add(new Ticket__c(
                Name = 'Recent Pending Ticket ' + j,
                Payment_Status__c = 'Pending',
                Type__c = generalTypeValue,
                CreatedDate = Date.today().addDays(-2),
                Price__c=(j+1)*1000,
                LastModifiedDate = Date.today() // Set to today to ensure they are not overdue
            ));
        }

        insert tickets;    
    }

    @isTest
    static void testBatchTicketExpiryProcessor() {
        Test.startTest();

        BatchTicketExpiryProcessor expirer = new BatchTicketExpiryProcessor();
        Id batchId = Database.executeBatch(expirer, 10);
        
        Test.stopTest();

        System.assertEquals(5, [SELECT COUNT() FROM Ticket__c WHERE Payment_Status__c = 'Refunded']);
    }
}