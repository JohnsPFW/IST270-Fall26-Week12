# Week 10b The Event Management JOIN

Use the `week10b` database in pgAdmin. This workshop combines data from separate tables so a result can show names instead of just IDs. The Codespace has already loaded four venues, three events, five attendees, and five registrations. Save your queries in [`answers/week10b.sql`](answers/week10b.sql).

## 1 Inspect the data

Open **Query Tool** on `week10b`. Run these queries one at a time and inspect the results:

```sql
SELECT * FROM Venues ORDER BY VenueID;
SELECT * FROM Events ORDER BY EventID;
SELECT * FROM Attendees ORDER BY AttendeeID;
SELECT * FROM Registrations ORDER BY RegistrationID;
```

The Summit Arena has no event. Eve Holt has no registration. Alice Johnson has two registrations. These cases will help you see which rows a join keeps.

## 2 Join events to venues

Run this query. Notice how `VenueID` connects the two tables and how the result shows a venue name.

```sql
SELECT e.EventName, e.EventDate, v.VenueName, v.City
FROM Events AS e
INNER JOIN Venues AS v ON e.VenueID = v.VenueID;
```

## 3 Compare INNER JOIN and LEFT JOIN

Run both queries and compare their rows. The first returns five registration rows from four distinct attendees. The second returns those rows plus Eve Holt with a `NULL` registration ID.

```sql
SELECT a.FirstName, a.LastName, r.RegistrationID
FROM Attendees AS a
INNER JOIN Registrations AS r ON a.AttendeeID = r.AttendeeID;

SELECT a.FirstName, a.LastName, r.RegistrationID
FROM Attendees AS a
LEFT JOIN Registrations AS r ON a.AttendeeID = r.AttendeeID;
```

Write a SQL comment in your answer file explaining why the number of result rows differs from the number of distinct attendees.

## 4 Chain joins

Build a check-in list for Global Tech Summit. The result should show Alice Johnson and Bob Smith.

```sql
SELECT a.FirstName, a.LastName, e.EventName
FROM Attendees AS a
INNER JOIN Registrations AS r ON a.AttendeeID = r.AttendeeID
INNER JOIN Events AS e ON r.EventID = e.EventID
WHERE e.EventName = 'Global Tech Summit';
```

## 5 Your queries

Save and run a query for each question:

1. Which venue has no events? Use `LEFT JOIN` and check for `NULL` on the event side.
2. Which events is Alice Johnson registered for? Join three tables and filter by her first and last name.
3. What is the complete registration list with attendee full name, event name, and venue name? Join all four tables, starting from `Registrations`.

For every join, decide which table's rows must remain in the result. Check your row count against the starter data before you move on.
