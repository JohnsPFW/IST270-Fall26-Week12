-- ============================================================================
-- IST 270 — In-Class Workshop (Week 12a): Manipulating and Querying Data
-- The Tutoring Center database
--
-- Creates the schema and starting rows for the Week 12a workshop.
--
-- The Codespace setup loads this file automatically into week12a.
-- ============================================================================

-- IST 270: DDL-Only Schema Script
-- This script creates all the empty tables for the Tutoring Center database.
-- Note the order: Parent tables (no foreign keys) are created first.

--
-- 1. PARENT TABLES
-- (These tables can be created in any order, as they don't depend on others)
--

-- The Tutors table
CREATE TABLE Tutors (
    TutorID         SERIAL PRIMARY KEY,
    FirstName       VARCHAR(50) NOT NULL,
    LastName        VARCHAR(50) NOT NULL,
    Email           VARCHAR(100) NOT NULL UNIQUE
);

-- The Students table
CREATE TABLE Students (
    StudentID       SERIAL PRIMARY KEY,
    FirstName       VARCHAR(50) NOT NULL,
    LastName        VARCHAR(50) NOT NULL,
    Major           VARCHAR(100)
);

-- The Subjects table
CREATE TABLE Subjects (
    SubjectID       SERIAL PRIMARY KEY,
    SubjectName     VARCHAR(100) NOT NULL UNIQUE
);


--
-- 2. CHILD / LINKING TABLES
-- (These tables MUST be created after their parents)
--

-- The Appointments table (Child of Tutors and Students)
CREATE TABLE Appointments (
    AppointmentID       SERIAL PRIMARY KEY,
    AppointmentDateTime TIMESTAMPTZ NOT NULL,
    Location            VARCHAR(255),
    TutorID             INTEGER,
    StudentID           INTEGER NOT NULL,

    -- Foreign key links to the Tutors table
    CONSTRAINT fk_tutor
        FOREIGN KEY(TutorID)
        REFERENCES Tutors(TutorID)
        ON DELETE SET NULL, -- If a tutor is deleted, set this field to NULL

    -- Foreign key links to the Students table
    CONSTRAINT fk_student
        FOREIGN KEY(StudentID)
        REFERENCES Students(StudentID)
        ON DELETE CASCADE -- If a student is deleted, their appointments are also deleted
);

-- The TutorSubjects table (M:N Linking Table for Tutors and Subjects)
CREATE TABLE TutorSubjects (
    TutorID         INTEGER NOT NULL,
    SubjectID       INTEGER NOT NULL,

    -- Composite Primary Key ensures a tutor isn't listed for the same subject twice
    CONSTRAINT pk_tutor_subjects PRIMARY KEY (TutorID, SubjectID),

    -- Foreign key links to the Tutors table
    CONSTRAINT fk_tutor_link
        FOREIGN KEY(TutorID)
        REFERENCES Tutors(TutorID)
        ON DELETE CASCADE, -- If a tutor is deleted, remove their subject qualifications

    -- Foreign key links to the Subjects table
    CONSTRAINT fk_subject_link
        FOREIGN KEY(SubjectID)
        REFERENCES Subjects(SubjectID)
        ON DELETE CASCADE -- If a subject is deleted, remove it from all tutors
);
-- ===========================================================================
-- DATA — the starting point for the workshop
-- ===========================================================================

-- Starting data for the workshop. Students insert additional rows.
INSERT INTO Tutors (FirstName, LastName, Email) VALUES ('Grace', 'Hopper', 'grace@navy.mil');

INSERT INTO Tutors (FirstName, LastName, Email) VALUES ('Alan', 'Turing', 'alan@bletchleypark.org');

INSERT INTO Students (FirstName, LastName, Major) VALUES
('Ada', 'Lovelace', 'Mathematics'),
('Katherine', 'Johnson', 'Physics'),
('Marie', 'Curie', 'Chemistry');

-- ===========================================================================
-- Students then complete the workshop challenge:
--   * INSERT at least three Subjects
--   * INSERT rows into the TutorSubjects linking table
--   * INSERT at least two Appointments
--   * Answer the three questions at the end of the workshop
-- ===========================================================================
