public with sharing class ProjectCommentExtension {
    private Project_Comment__c pc;

    public List<StakeholderRow> stakeholderRows { get; private set; }
    public String recipientList { get; set; }
    public Id lastToggledRowId { get; set; }
    public Boolean lastToggledRowValue { get; set; }

    public class StakeholderRow {
        public Id id { get; set; }
        public String name { get; set; }
        // public String email { get; set; }
        public Boolean selected { get; set; }
        public StakeholderRow(Id id, String name, Boolean selected){
            this.id = id;
            this.name = name;
            // this.email = email;
            this.selected = selected;
        }
    }

    public ProjectCommentExtension(ApexPages.StandardController stdController) {
        pc = (Project_Comment__c)stdController.getRecord();
        loadStakeholders();
    }

    public Project_Comment__c getPc() {
        return pc;
    }

    private void loadStakeholders() {
        stakeholderRows = new List<StakeholderRow>();
        // Query the project stakeholders related to the Project (replace object/fields as needed)
        for (Project_Stakeholder__c ps : [
            SELECT Id, Name, Receive_Project_Email__c
            FROM Project_Stakeholder__c
            WHERE Project__c = :pc.Project__c
        ]) {
            Boolean sel = true; // default selected; adjust logic if needed
            stakeholderRows.add(new StakeholderRow(ps.Id, ps.Name, ps.Receive_Project_Email__c));
        }
        System.debug('Loaded stakeholders: ' + stakeholderRows);
        buildRecipientList();
    }

    public void buildRecipientList() {
        List<String> names = new List<String>();
        for (StakeholderRow r : stakeholderRows) {
            if (r.selected) names.add(r.name);
        }
        recipientList = names.isEmpty() ? '' : String.join(names, ';');
        System.debug('Built recipient list: ' + recipientList);
    }

    public PageReference applyRecipients() {
        // If a specific row was toggled, update that wrapper row's selected value
        System.debug('Applying recipients! Last toggled row id: ' + lastToggledRowId + ', value: ' + lastToggledRowValue);
        if (lastToggledRowId != null) {
            for (StakeholderRow r : stakeholderRows) {
                if (r.id == lastToggledRowId) {
                    System.debug('Toggling row for ' + r.name + ' to ' + lastToggledRowValue);
                    // assign the passed (new) boolean value directly
                    if (lastToggledRowValue != null) r.selected = lastToggledRowValue;
                    break;
                }
            }
        }
        buildRecipientList();
        // clear tracking fields so future actions are explicit
        lastToggledRowId = null;
        lastToggledRowValue = null;
        return null;
    }
}