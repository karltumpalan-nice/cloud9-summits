public with sharing class BatchTicketExpiryProcessor implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date last30Days = Date.today().addDays(-30);

        return Database.getQueryLocator([
            SELECT Id, Name, Payment_Status__c, LastModifiedDate
            FROM Ticket__c
            WHERE Payment_Status__c = 'Pending'
            AND LastModifiedDate <= :last30Days
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Ticket__c> overduePendingTickets) {
        String paymentStatusValue;
        for (Schema.PicklistEntry entry: Ticket__c.Payment_Status__c.getDescribe().getPicklistValues()){
            if (entry.getLabel() == 'Refunded') {
                paymentStatusValue = entry.getValue();
                break;
            }
        }

        for (Ticket__c ticket : overduePendingTickets) {
            ticket.Payment_Status__c = paymentStatusValue;
        }

        update overduePendingTickets;
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('All overdue pending tickets expired!');
    }
}