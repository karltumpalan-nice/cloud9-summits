public with sharing class ConferenceController {
    @AuraEnabled(cacheable=true)
    public static Conference__c getConferenceDetails(Id conferenceId) {
        return [
            SELECT Id, Name, Start_Date__c, End_Date__c
            FROM Conference__c
            WHERE Id = :conferenceId
        ];
    }
}