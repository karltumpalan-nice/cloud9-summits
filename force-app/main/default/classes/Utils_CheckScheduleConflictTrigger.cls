public with sharing class Utils_CheckScheduleConflictTrigger {

    /**
     * @description Checks incoming SpeakerEngagements for schedule conflicts against prior state.
     *              Adds an error to any incoming record that overlaps an existing engagement
     *              for the same Contact__c within the provided old list.
     * @param newSpeakerEngagements New/updated SpeakerEngagements to validate (e.g., Trigger.new)
     */
    public static void checkForScheduleConflict(
        List<Speaker_Engagement__c> newSpeakerEngagements
    ) {
        if (newSpeakerEngagements == null || newSpeakerEngagements.isEmpty()) {
            return;
        }

        // Gather all contact and session IDs related to NEW engagements
        Set<Id> contactIds = new Set<Id>();
        Set<Id> sessionIds = new Set<Id>();
        for (Speaker_Engagement__c se : newSpeakerEngagements) {
            if (se.Contact__c != null) {
                contactIds.add(se.Contact__c);
            }
            if (se.Session__c != null) {
                sessionIds.add(se.Session__c);
            }
        }

        // Query all existing speaker engagements of the new speakers
        List<Speaker_Engagement__c> existingEngagements = [
            SELECT Id, Contact__c, Session__c
            FROM Speaker_Engagement__c
            WHERE Contact__c IN :contactIds
        ];

        // Gather all Session IDs of the existing engagements of the speakers
        for (Speaker_Engagement__c se : existingEngagements) {
            if (se.Session__c != null) {
                sessionIds.add(se.Session__c);
            }
        }

        // Query all relevant session records
        Map<Id, Session__c> sessionMap = new Map<Id, Session__c>([
            SELECT Id, Start_Date_and_Time__c, End_Date_and_Time__c
            FROM Session__c
            WHERE Id IN :sessionIds
        ]);

        // Build a map of Contact: existing speaker sessions
        Map<Id, List<Session__c>> contactSessionsMap = new Map<Id, List<Session__c>>();
        for (Speaker_Engagement__c se : existingEngagements) {
            if (se.Contact__c != null && se.Session__c != null) {
                if (!contactSessionsMap.containsKey(se.Contact__c)) {
                    contactSessionsMap.put(se.Contact__c, new List<Session__c>());
                }
                contactSessionsMap.get(se.Contact__c).add(sessionMap.get(se.Session__c));
            }
        }

        // For each new engagement, check for overlap with existing engagements for the same contact
        for (Speaker_Engagement__c nse : newSpeakerEngagements) {
            Session__c newSession = sessionMap.get(nse.Session__c);
            if (newSession == null || newSession.Start_Date_and_Time__c == null || newSession.End_Date_and_Time__c == null) {
                continue;
            }
            if (!contactSessionsMap.containsKey(nse.Contact__c)) {
                continue;
            }
            for (Session__c existingSession : contactSessionsMap.get(nse.Contact__c)) {
                if (existingSession == null || existingSession.Start_Date_and_Time__c == null || existingSession.End_Date_and_Time__c == null) {
                    continue;
                }
                Boolean isOverlapping =
                    (existingSession.Start_Date_and_Time__c.getTime() < newSession.End_Date_and_Time__c.getTime()) &&
                    (existingSession.End_Date_and_Time__c.getTime() > newSession.Start_Date_and_Time__c.getTime());
                if (isOverlapping) {
                    nse.addError('Schedule conflict detected with another engagement for this speaker.');
                }
            }
        }
    }
}
