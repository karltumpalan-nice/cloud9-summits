public with sharing class BatchTicketExpiryProcessorScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        BatchTicketExpiryProcessor expirer = new BatchTicketExpiryProcessor();
        Database.executeBatch(expirer);
    }
}