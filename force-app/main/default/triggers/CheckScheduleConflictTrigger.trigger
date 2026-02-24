trigger CheckScheduleConflictTrigger on Speaker_Engagement__c (before insert, before update) {
    Utils_CheckScheduleConflictTrigger.checkForScheduleConflict(Trigger.new);
}