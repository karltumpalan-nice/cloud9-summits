@isTest
public with sharing class Utils_TicketTest {
    @TestSetup
    static void setupData() {
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

        Conference__c conf1 = new Conference__c(
            Name='Conf 1',
            Start_Date__c=Date.today().addDays(1),
            End_Date__c=Date.today().addDays(5),
            Status__c=inProgressStatusValue,
            Location__c='Location 1'
        );
        Conference__c conf2 = new Conference__c(
            Name='Conf 2',
            Start_Date__c=Date.today().addDays(1),
            End_Date__c=Date.today().addDays(5),
            Status__c='Planned',
            Location__c='Location 1'
        );
        insert new List<Conference__c>{conf1, conf2};
        
        String generalTypeValue;
        for (Schema.PicklistEntry entry: Ticket__c.Type__c.getDescribe().getPicklistValues()){
            if (entry.getLabel() == 'General') {
                generalTypeValue = entry.getValue();
                break;
            }
        }

        Ticket__c t1 = new Ticket__c(Name='T1', Conference__c=conf1.Id, Price__c=100, Type__c=generalTypeValue);
        Ticket__c t2 = new Ticket__c(Name='T2', Conference__c=conf1.Id, Price__c=200, Type__c=generalTypeValue);
        Ticket__c t3 = new Ticket__c(Name='T3', Conference__c=conf2.Id, Price__c=300, Type__c=generalTypeValue);
        insert new List<Ticket__c>{t1, t2, t3};
    }

    @isTest
    static void testGetConferenceIdsFromTickets() {
        List<Ticket__c> tickets = [SELECT Id, Conference__c FROM Ticket__c];
        Set<Id> ids = Utils_Ticket.getConferenceIdsFromTickets(tickets);
        System.assertEquals(2, ids.size());
    }

    @isTest
    static void testGetConferenceTicketsAmount() {
        List<Conference__c> confs = [SELECT Id FROM Conference__c];
        Map<Id, Decimal> amounts = Utils_Ticket.getConferenceTicketsAmount(
            new List<Id>{confs[0].Id, confs[1].Id},
            new List<Ticket__c>()
        );
        System.assertEquals(300, amounts.get(confs[0].Id));
        System.assertEquals(300, amounts.get(confs[1].Id));
    }

    @isTest
    static void testUpdateConferenceRevenue_Insert() {
        String generalTypeValue;
        for (Schema.PicklistEntry entry : Ticket__c.Type__c.getDescribe().getPicklistValues()) {
            if (entry.getLabel() == 'General' || entry.getValue() == 'General') {
                generalTypeValue = entry.getValue();
                break;
            }
        }

        // Get the conference
        Conference__c conf = [SELECT Id, Current_Revenue__c FROM Conference__c WHERE Name='Conf 1' LIMIT 1];
        // Create the ticket object. Bind the conferecence Id to the ticket's lookup field.
        Ticket__c t = new Ticket__c(Name='T4', Conference__c=conf.Id, Price__c=20, Type__c=generalTypeValue);

        // Insert the ticket, which should trigger the revenue update.
        insert t;

        List<Ticket__c> newTickets = [SELECT Id, Conference__c, Price__c FROM Ticket__c WHERE Id = :t.Id];
        System.debug(newTickets);

        Conference__c updated = [SELECT Current_Revenue__c FROM Conference__c WHERE Id = :conf.Id];
        System.assertEquals(320, updated.Current_Revenue__c, 'Conference revenue should be 320, since there is an existing 300 and new ticket worth 20.');
    }

    @isTest
    static void testUpdateConferenceRevenue_Update() {
        // Try to get T2.
        Ticket__c t = [
            SELECT Id, Conference__c, Price__c FROM Ticket__c 
            WHERE Price__c = 200
            LIMIT 1
        ];

        // Save T2 clone and update original T2 to new 500 price.
        Ticket__c oldT = t.clone(false, true, false, false);
        oldT.Price__c = t.Price__c;
        t.Price__c = 500;
        update t;

        Conference__c conf = [SELECT Current_Revenue__c FROM Conference__c WHERE Id = :t.Conference__c];
        System.assertEquals(600, conf.Current_Revenue__c);
    }

    @isTest
    static void testUpdateConferenceRevenue_Delete() {
        Ticket__c t = [
            SELECT Id, Conference__c, Price__c 
            FROM Ticket__c 
            WHERE Price__c = 200
            LIMIT 1
        ];
        delete t;

        Conference__c conf = [SELECT Current_Revenue__c FROM Conference__c WHERE Id = :t.Conference__c];
        System.assertEquals(100, conf.Current_Revenue__c);
    }
}