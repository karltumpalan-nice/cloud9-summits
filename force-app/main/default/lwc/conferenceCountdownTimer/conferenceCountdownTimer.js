import { LightningElement, api, wire, track } from 'lwc';

import getConferenceDetails from '@salesforce/apex/ConferenceController.getConferenceDetails';

const FIELDS = [
    'Start_Date__c',
    'End_Date__c'
];

export default class ConferenceCountdownTimer extends LightningElement {
    // Provided by the record page context
    @api recordId;

    conferenceStartDateTime;
    conferenceEndDateTime;
    intervalId;

    // The component should track this property to rerender UI if there are changes
    @track countdownText;

    // Bind with the ConferenceControllr
    @wire(getConferenceDetails, { conferenceId: '$recordId' })
    wiredConference({ error, data }) {
        console.log(data);
        if (data) {
            this.conferenceStartDateTime = data.Start_Date__c
            this.conferenceEndDateTime = data.End_Date__c
        } else if (error) {
            // handle default fallback.
            this.conferenceStartDateTime = null;
            this.conferenceEndDateTime = null;
        }
    }

    connectedCallback() {
        this.intervalId = setInterval(() => {
            this.getRemainingDateTime();
        }, 1000);
    }

    disconnectedCallback() {
        clearInterval(this.intervalId);
    }

    getRemainingDateTime() {
        const currentDateTime = Date.now();
        const confStartDate =new Date(this.conferenceStartDateTime);
        const confEndDate = new Date(this.conferenceEndDateTime);

        if (!confStartDate || (confStartDate && !confEndDate)) {
            this.countdownText = 'Conference dates unavailable';
            return;
        }

        if (currentDateTime < confStartDate) {
            this.countdownText = `Conference starts in ${this.getFormattedTime(confStartDate - currentDateTime)}`;
        } else if (currentDateTime >= confStartDate && currentDateTime <= confEndDate) {
            this.countdownText = `Conference ends in ${this.getFormattedTime(confEndDate - currentDateTime)}`;
        } else {
            this.countdownText = 'Conference has ended';
        }
    }

    getFormattedTime(ms) {
        // Returns a formatted string like "1d 2h 3m 4s"
        let totalSeconds = Math.floor(ms / 1000);
        const days = Math.floor(totalSeconds / 86400);
        totalSeconds %= 86400;
        const hours = Math.floor(totalSeconds / 3600);
        totalSeconds %= 3600;
        const minutes = Math.floor(totalSeconds / 60);
        const seconds = totalSeconds % 60;
        let parts = [];
        if (days) parts.push(`${days}d`);
        if (hours) parts.push(`${hours}h`);
        if (minutes) parts.push(`${minutes}m`);
        if (seconds || parts.length === 0) parts.push(`${seconds}s`);
        return parts.join(' ');
    }
}