public with sharing class Utils_Ticket {
    /** 
     * As part of the step to get the Tickets' related conference, this method
     * loops all Conference fields in the list of tickets, then returns them as a collection.
     */
    public static Set<Id> getConferenceIdsFromTickets(List<Ticket__c> tickets) {
        Set<Id> conferenceIds = new Set<Id>();
        for (Ticket__c ticket : tickets) {
            if (ticket.Conference__c != null) {
                conferenceIds.add(ticket.Conference__c);
            }
        }
        return conferenceIds;
    }

    /**
     * As part of the step to query all existing tickets of the conference (and to get their amount),
     * this method queries the Ticket schema to compute the price sum of all tickets grouped by the conference ID.
     * After querying, a map of Conference ID to Ticket Sum is created for value tracking.
     */
    public static Map<Id, Decimal> getConferenceTicketsAmount(List<Id> conferenceIds, List<Ticket__c> excludedTickets) {
        Map<Id, Decimal> conferenceTickets = new Map<Id, Decimal>();
        List<AggregateResult> results = [
            SELECT Conference__c, SUM(Price__c) total
            FROM Ticket__c
            WHERE Conference__c IN :conferenceIds
            AND Id NOT IN :excludedTickets
            GROUP BY Conference__c
        ];

        for (AggregateResult ar : results) {
            conferenceTickets.put((Id) ar.get('Conference__c'), (Decimal) ar.get('total'));
        }

        return conferenceTickets;
    }

    /**
     * Main trigger handler method for updating the conference's revenue after ticket insert/update/delete.
     * 
     * 1. Gets all the conference IDs based from the relevent tickets inserted/updated/deleted
     * 2. Computes the total conference revenues of the conferences excluding the relevant tickets
     * 3. For each ticket inserted, update the conference revenue mapping.
     * 
     * Note: The parameter flags can be an enum instead.
     */
    public static void updateConferenceRevenue(
        Boolean isInsert,
        Boolean isUpdate,
        Boolean isDelete,
        List<Ticket__c> newTickets,
        List<Ticket__c> oldTickets,
        Map<Id, Ticket__c> oldMap
    ) {
        List<Ticket__c> relevantTickets = isDelete ? oldTickets : newTickets;
        Set<Id> conferenceIds = getConferenceIdsFromTickets(relevantTickets);

        Map<Id, Decimal> conferenceRevenues = getConferenceTicketsAmount(new List<Id>(conferenceIds), relevantTickets);

        for (Ticket__c ticket : relevantTickets) {
            Decimal ticketPrice = ticket.Price__c != null ? ticket.Price__c : 0;
            if (isInsert) {
                conferenceRevenues.put(ticket.Conference__c, conferenceRevenues.containsKey(ticket.Conference__c) ? conferenceRevenues.get(ticket.Conference__c) + ticketPrice : ticketPrice);
            } else if (isUpdate) {
                conferenceRevenues.put(ticket.Conference__c, conferenceRevenues.containsKey(ticket.Conference__c) ? conferenceRevenues.get(ticket.Conference__c) + ticketPrice : ticketPrice);
            } else if (isDelete) {
                // Since we already excluded the relevant deleted ticket, we can just get the actual sum of the tickets directly
                conferenceRevenues.put(ticket.Conference__c, conferenceRevenues.containsKey(ticket.Conference__c) ? conferenceRevenues.get(ticket.Conference__c) : 0);
            }
        }

        List<Conference__c> conferences = [SELECT Id, Current_Revenue__c FROM Conference__c WHERE Id IN :conferenceIds];
        for (Conference__c conf : conferences) {
            Decimal totalRevenue = conferenceRevenues.containsKey(conf.Id) ? conferenceRevenues.get(conf.Id) : 0;
            conf.Current_Revenue__c = totalRevenue;
        }

        update conferences;
    }
}