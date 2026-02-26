trigger CalculateRevenueTrigger on Ticket__c (after insert, after update, after delete) {
    Utils_Ticket.updateConferenceRevenue(
        Trigger.isInsert,
        Trigger.isUpdate,
        Trigger.isDelete,
        Trigger.new,
        Trigger.old,
        Trigger.oldMap
    );
}