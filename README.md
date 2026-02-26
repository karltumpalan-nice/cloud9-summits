### Project

**The Scenario:**

You are building the backend and core interface for "CloudNine Summits." The goal is to manage the lifecycle of tech conferences, ensuring data integrity for events, speakers, and attendees, and implementing custom logic using code.

---

### Phase 1: Data Modeling (The Skeleton)

*Focus: Custom Objects, Standard Objects, Relationships, Fields.*

**1. Standard Objects:**

- **Accounts:** Use this for **Sponsors** (e.g., "Google," "Salesforce").
- **Contacts:** Use this for **Attendees** and **Speakers**.

**2. Custom Objects:**

- **Conference (Parent):** Tracks the main event (Name, Date, Location, Total Budget, Status).
- **Session (Child):** Tracks individual talks within a conference (Title, Date/Time, Room Number, Capacity).
- **Speaker Engagement (Junction Object):** Connects a **Contact** (Speaker) to a **Session**. *Why? Because one speaker can speak at multiple sessions, and one session might have multiple speakers.*
- **Ticket (Child):** Connects a **Contact** (Attendee) to a **Conference**. Tracks payment status and ticket type (VIP, Early Bird, General).

**3. Key Relationships:**

- **Master-Detail:** Conference (Master) to Session (Detail). If you delete the Conference, the Sessions should disappear.
- **Lookup:** Ticket to Contact. If you delete a Contact, you might want to keep the financial record of the Ticket.

---

### Phase 2: User Interface & Quality Data (The Skin)

*Focus: Page Layouts, Lightning App Builder, Validation Rules.*

**1. The "Conference" Layout:**

- Create a **Path** based on the `Status` field (Planned -> Registration Open -> In Progress -> Completed).
- Add a **Rich Text Component** on the Lightning Page to display a warning if the `Total Budget` exceeds $50,000.

**2. Validation Rules (Logic):**

- **No Time Travel:** The `Conference Date` cannot be in the past.
- **VIP Consistency:** If a Ticket Type is "VIP," the Price must be greater than $500.
- **Room Capacity:** A Session cannot have `Seats Available` < 0.

---

### Phase 3: Security (The Shield)

*Focus: Profiles, Roles, Permission Sets.*

**1. Profiles:**

- **"Event Manager":** Can Create, Read, Edit, and Delete (CRED) Conferences and Sessions.
- **"Sales Intern":** Can only Read Conferences but Create/Edit Tickets. They should *not* see the `Total Budget` field on the Conference (Field Level Security).

**2. Organization-Wide Defaults (OWD):**

- Set **Tickets** to **Private**.
- Create a **Sharing Rule**: Tickets are only visible to the owner of the Ticket (the sales rep) and the Event Manager role.

---

### Phase 4: Developer Challenges (The Brain - Code)

*Focus: Apex Triggers, Apex Classes, LWC.*

This becomes the core "automation" component of your project since Flow has been removed.

**1. Apex Trigger (Data Integrity):**

- **Challenge:** A Speaker cannot be booked for two Sessions at the same time.
- **Solution:** Write a `before insert/update` trigger on the **Speaker Engagement** (Junction) object. It should query existing sessions for that speaker and add an error to the record if the times overlap.

**2. Apex Trigger (Aggregation):**

- **Challenge:** Real-time calculation of revenue without using Roll-Up Summary fields (simulating a scenario where MD relationships aren't possible or limits are hit).
- **Solution:** Write an `after insert/update/delete` trigger on the **Ticket** object. When a ticket is saved, query all tickets for that specific Conference, sum the amounts, and update the `Current Revenue` field on the Conference object.

**3. Apex Class (Asynchronous):**

- **Challenge:** Data cleanup.
- **Solution:** Write a Scheduled Apex class (Batchable) that runs every weekend to find "Pending" tickets that haven't been modified in 30 days and changes their status to "Refunded"


**4. Lightning Web Component (LWC):**

- **Challenge:** The Event Managers want a visual "Countdown Timer" on the Conference page.
- **Solution:** Build a simple LWC that takes the `Conference Date`, calculates the time remaining from `Now()`, and displays it dynamically (e.g., "5 Days, 4 Hours left!") directly on the Lightning Record Page.