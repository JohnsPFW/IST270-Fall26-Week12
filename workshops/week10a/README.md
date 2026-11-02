# Week 10a Manipulating and Querying Data

In this workshop you will add, change, remove, and find data in the Tutoring Center database. Use pgAdmin in your Codespace and select the `week10a` database. The starter data is already loaded: Grace Hopper and Alan Turing are tutors; Ada Lovelace, Katherine Johnson, and Marie Curie are students. Save the SQL you write in [`answers/week10a.sql`](answers/week10a.sql).

## 1 Check the starting data

Open **Query Tool** on `week10a` and run these one at a time. The Query Tool results grid shows the rows returned by `SELECT`.

```sql
SELECT * FROM Tutors ORDER BY TutorID;
SELECT * FROM Students ORDER BY StudentID;
```

## 2 Insert a row in pgAdmin

Expand `week10a → Schemas → public → Tables`. Right-click **tutors → View/Edit Data → All Rows**. In the data grid, choose **Add new row**. Leave `tutorid` blank and enter `Dorothy`, `Vaughan`, and `dorothy@example.com` for the first name, last name, and email. Choose **Save Data Changes**. The `SERIAL` column supplies the ID.

Return to Query Tool and verify with `SELECT * FROM Tutors ORDER BY TutorID;`. The data editor changes table data; the Query Tool is where you write SQL.

## 3 Insert with SQL

Run this in Query Tool, then run the verification query again:

```sql
INSERT INTO Tutors (FirstName, LastName, Email)
VALUES ('Annie', 'Easley', 'annie@example.com');
```

In your answer file, record the verification query and a short SQL comment comparing the two insertion methods.

## 4 Insert several students

Use one `INSERT` statement for both rows, then query `Students` to confirm them:

```sql
INSERT INTO Students (FirstName, LastName, Major) VALUES
('Mary', 'Jackson', 'Mathematics'),
('Mae', 'Jemison', 'Engineering');
```

## 5 Observe a constraint

Run the statement below. PostgreSQL should reject it because Grace's email is already present. Read the error in pgAdmin's **Messages** tab. Record the constraint named in the error. The rejected row is not inserted.

```sql
INSERT INTO Tutors (FirstName, LastName, Email)
VALUES ('New', 'Tutor', 'grace@navy.mil');
```

Run this statement separately from other inserts so the expected error does not interrupt them.

## 6 Update and delete safely

First, find Katherine's actual `StudentID`:

```sql
SELECT * FROM Students WHERE FirstName = 'Katherine' AND LastName = 'Johnson';
```

Use that ID in an `UPDATE` that changes her major to `Applied Mathematics`. Include a `WHERE` clause. Run the same `SELECT` to verify. Before deleting Marie Curie, use a `SELECT` to identify her ID. Then delete only her row and verify the result. Save each `SELECT`, `UPDATE`, and `DELETE` in your answer file. Never run an `UPDATE` or `DELETE` without checking the rows your `WHERE` clause selects.

## 7 Workshop challenge

Add at least three subjects, link tutors to subjects in `TutorSubjects`, and add at least two appointments. The appointment columns are `AppointmentDateTime`, `Location`, `TutorID`, and `StudentID`. Use IDs you have checked in the parent tables, and use a timestamp with a time zone, such as `'2026-11-05 14:00-05'`.

Write `SELECT` queries that answer these questions:

1. Which appointments are in a location you chose?
2. Which subjects can one tutor teach? Join `TutorSubjects` to `Subjects` so the result shows subject names.
3. Which students have `Mathematics` as their major?

Run each query, inspect the results, and save the SQL in your answer file. The habit to keep: preview the target rows with `SELECT` before `UPDATE` or `DELETE`.
