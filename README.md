# IST 270 Week 10 Workshops

This repository gives you a GitHub Codespace with PostgreSQL and pgAdmin for two in-class workshops. The databases are ready when the Codespace finishes building. You do not need to install software, create the workshop databases, or run the starter SQL files yourself.

| Workshop | Database | What you will practice |
| --- | --- | --- |
| [Week 10a](workshops/week10a/README.md) | `week10a` | `INSERT`, `UPDATE`, `DELETE`, constraints, and `SELECT` |
| [Week 10b](workshops/week10b/README.md) | `week10b` | `INNER JOIN`, `LEFT JOIN`, and multi-table joins |

## Open pgAdmin

1. Open this repository as a GitHub Codespace. Wait for the setup to finish.
2. In the Codespace terminal, run `bash .devcontainer/create-my-pgadmin-account.sh` once. Choose a login email and password when prompted.
3. Open the **Ports** panel. Select the forwarded address for **pgAdmin 4** to open it in a browser tab.
4. Sign in with the pgAdmin email and password you chose. Expand **IST 270 Local PostgreSQL → Databases**. Both `week10a` and `week10b` should be listed.
5. For a workshop, right-click its database and choose **Query Tool**. Check the database name in the Query Tool tab before you execute SQL.

The pgAdmin login is separate from the PostgreSQL connection. If pgAdmin asks for the database password, enter `postgres`. The PostgreSQL server is `localhost` on port `5432`, with user `postgres` and password `postgres`.

If the server is missing in pgAdmin, right-click **Servers → Register → Server**. Give it any name; on **Connection**, use host `localhost`, port `5432`, maintenance database `postgres`, username `postgres`, and password `postgres`.

## Save your work

The database lives inside the Codespace. Save the SQL you write in the answer files linked from each workshop, then commit your files to your repository. If the Codespace is deleted, your committed files remain available, but changes made only inside the database do not.

The workshops are practice activities. Follow any separate submission directions from your instructor.

## If something goes wrong

- If pgAdmin or PostgreSQL has stopped, run `bash .devcontainer/start-services.sh`.
- If you forgot your pgAdmin password, rerun `bash .devcontainer/create-my-pgadmin-account.sh` and use its reset option.
- To rebuild a workshop database, run `bash .devcontainer/reset-workshop.sh week10a` or `bash .devcontainer/reset-workshop.sh week10b`. The command asks before erasing changes in that database.
- If pgAdmin opens as a blank page, open it in a normal browser tab from **Ports** and hard refresh. If its web files are missing, run `bash .devcontainer/setup.sh`, then reload the tab.
