-- ============================================================================
-- IST 270 — In-Class Workshop (Week 10b): The Event Management JOIN
-- The Event Management database
--
-- Creates the schema and starting rows for the Week 10b workshop.
--
-- The Codespace setup loads this file automatically into week10b.
-- ============================================================================

-- DDL for the Event Management Database

-- Parent table: Venues
CREATE TABLE Venues (
    VenueID     SERIAL PRIMARY KEY,
    VenueName   VARCHAR(100) NOT NULL,
    City        VARCHAR(50),
    Capacity    INTEGER CHECK (Capacity > 0)
);

-- Parent table: Attendees
CREATE TABLE Attendees (
    AttendeeID  SERIAL PRIMARY KEY,
    FirstName   VARCHAR(50) NOT NULL,
    LastName    VARCHAR(50) NOT NULL,
    Email       VARCHAR(100) UNIQUE
);

-- Child table: Events (Depends on Venues)
CREATE TABLE Events (
    EventID     SERIAL PRIMARY KEY,
    EventName   VARCHAR(100) NOT NULL,
    EventDate   DATE,
    VenueID     INTEGER NOT NULL,
    CONSTRAINT fk_venue
        FOREIGN KEY(VenueID)
        REFERENCES Venues(VenueID)
);

-- Child/Linking table: Registrations (Depends on Events and Attendees)
CREATE TABLE Registrations (
    RegistrationID  SERIAL PRIMARY KEY,
    EventID         INTEGER NOT NULL,
    AttendeeID      INTEGER NOT NULL,
    RegistrationDate DATE DEFAULT CURRENT_DATE,
    CONSTRAINT fk_event
        FOREIGN KEY(EventID)
        REFERENCES Events(EventID)
        ON DELETE CASCADE,
    CONSTRAINT fk_attendee
        FOREIGN KEY(AttendeeID)
        REFERENCES Attendees(AttendeeID)
        ON DELETE CASCADE
);
-- ===========================================================================
-- DATA
-- ===========================================================================

-- 1. Populate 'Venues'
INSERT INTO Venues (VenueName, City, Capacity) VALUES
('The Summit Arena', 'Chicago', 15000),
('Riverside Convention Hall', 'Chicago', 3000),
('Indie Music Garage', 'New York', 800),
('Grand City Park', 'New York', 50000);

-- 2. Populate 'Attendees'
--    Eve Holt has not registered for any events — she is the LEFT JOIN
--    example in Part 3 of the workshop.
INSERT INTO Attendees (FirstName, LastName, Email) VALUES
('Alice', 'Johnson', 'alice@example.com'),
('Bob', 'Smith', 'bob@example.com'),
('Charlie', 'Brown', 'charlie@example.com'),
('David', 'Lee', 'david@example.com'),
('Eve', 'Holt', 'eve@example.com');

-- 3. Populate 'Events'
INSERT INTO Events (EventName, EventDate, VenueID) VALUES
('Global Tech Summit', '2026-10-20', (SELECT VenueID FROM Venues WHERE VenueName = 'Riverside Convention Hall')),
('Indie Fest 2026', '2026-08-15', (SELECT VenueID FROM Venues WHERE VenueName = 'Indie Music Garage')),
('Food Truck Fair', '2026-09-01', (SELECT VenueID FROM Venues WHERE VenueName = 'Grand City Park'));

-- 4. Populate 'Registrations'
INSERT INTO Registrations (EventID, AttendeeID) VALUES
((SELECT EventID FROM Events WHERE EventName = 'Global Tech Summit'), (SELECT AttendeeID FROM Attendees WHERE Email = 'alice@example.com')),
((SELECT EventID FROM Events WHERE EventName = 'Global Tech Summit'), (SELECT AttendeeID FROM Attendees WHERE Email = 'bob@example.com')),
((SELECT EventID FROM Events WHERE EventName = 'Indie Fest 2026'), (SELECT AttendeeID FROM Attendees WHERE Email = 'charlie@example.com')),
((SELECT EventID FROM Events WHERE EventName = 'Food Truck Fair'), (SELECT AttendeeID FROM Attendees WHERE Email = 'alice@example.com')),
((SELECT EventID FROM Events WHERE EventName = 'Food Truck Fair'), (SELECT AttendeeID FROM Attendees WHERE Email = 'david@example.com'));
