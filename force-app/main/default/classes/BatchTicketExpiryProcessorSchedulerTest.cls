@isTest
public with sharing class BatchTicketExpiryProcessorSchedulerTest {
    // Seconds Minutes Hours DayOfMonth Month DayOfWeek Year
    public static String SAMPLE_CRON_EXP = '0 0 0 ? * 2 *';
    
    @TestSetup
    static void makeData(){
        // Same and copied from BatchTicketExpiryProcessorTest.makeData()
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

        insert tickets;
    }

    @isTest
    static void testScheduledExpirerJob() {
        Test.startTest();
        String jobId = System.schedule(
            'BatchTicketExpiryProcessorSchedulerTestingJob',
            SAMPLE_CRON_EXP, 
            new BatchTicketExpiryProcessorScheduler()
        );
        Test.stopTest();

        List<Ticket__c> originalTIckets = [SELECT Id, Payment_Status__c FROM Ticket__c];
        // Assert 5 since we added 5 from the test setup.
        System.assertEquals(5, originalTIckets.size(), 'All tickets regardless of status');

        CronTrigger ct = [SELECT Id, CronExpression, State, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(SAMPLE_CRON_EXP, ct.CronExpression);
        System.debug('Next fire time: ' + ct.NextFireTime);
        System.assertEquals('WAITING', ct.State);
    }
}