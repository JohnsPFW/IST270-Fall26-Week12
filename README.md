# IST 270 Week 12 Workshops

This repository gives you a GitHub Codespace with PostgreSQL and pgAdmin for two in-class workshops. The databases are ready when the Codespace finishes building. You do not need to install software, create the workshop databases, or run the starter SQL files yourself.

| Workshop | Database | What you will practice |
| --- | --- | --- |
| [Week 12a](workshops/week12a/README.md) | `week12a` | `INSERT`, `UPDATE`, `DELETE`, constraints, and `SELECT` |
| [Week 12b](workshops/week12b/README.md) | `week12b` | `INNER JOIN`, `LEFT JOIN`, and multi-table joins |

## Open pgAdmin

1. Open this repository as a GitHub Codespace. Wait for the setup to finish.
2. In the Codespace terminal, run `bash .devcontainer/create-my-pgadmin-account.sh` once. Choose a login email and password when prompted.
3. Open the **Ports** panel. Select the forwarded address for **pgAdmin 4** to open it in a browser tab.
4. Sign in with the pgAdmin email and password you chose. Expand **IST 270 Local PostgreSQL → Databases**. Both `week12a` and `week12b` should be listed.
5. For a workshop, right-click its database and choose **Query Tool**. Check the database name in the Query Tool tab before you execute SQL.

The pgAdmin login is separate from the PostgreSQL connection. If pgAdmin asks for the database password, enter `postgres`. The PostgreSQL server is `localhost` on port `5432`, with user `postgres` and password `postgres`.

If the server is missing in pgAdmin, right-click **Servers → Register → Server**. Give it any name; on **Connection**, use host `localhost`, port `5432`, maintenance database `postgres`, username `postgres`, and password `postgres`.

## Save and push your work to GitHub

pgAdmin changes the database inside your Codespace. Those database rows do not appear in GitHub automatically. To keep your work, copy the SQL you used in pgAdmin's Query Tool into the answer file in your Codespace:

- Week 12a: [`workshops/week12a/answers/week12a.sql`](workshops/week12a/answers/week12a.sql)
- Week 12b: [`workshops/week12b/answers/week12b.sql`](workshops/week12b/answers/week12b.sql)

If you changed a row with pgAdmin's data editor, add the equivalent SQL or a clear comment to your answer file so you can explain or recreate that change. Save the file with **Ctrl+S** (Windows/Linux) or **Cmd+S** (Mac).

To send the saved file to **your own GitHub repository** from the Codespace:

1. Select the **Source Control** icon in the left sidebar. Under **Changes**, find the answer file you edited.
2. Select the **+** next to that file to stage it. Check that only the files you intend to save are staged.
3. Enter a short commit message, such as `Complete Week 12a workshop`.
4. Select the arrow beside **Commit**, then **Commit & Push**. If your editor shows only **Commit**, select it and then choose **Sync Changes** or **Push**. Wait for the operation to finish.
5. Open your personal repository on github.com, refresh the page, and open the answer file. Confirm that your latest SQL appears there. If it does not, return to Source Control and check for an unpushed commit or an error message.

You can also use the Codespace terminal. Replace `week12a` with `week12b` in the file path and message when working on the second workshop:

```bash
git status
git add workshops/week12a/answers/week12a.sql
git commit -m "Complete Week 12a workshop"
git push origin main
```

**Save, commit, and push are three separate actions.** A saved file is still only in the Codespace until you push its commit. If the Codespace is deleted, pushed files remain in your GitHub repository; changes made only in the database or only in the Codespace may be lost. The workshops are practice activities. Follow any separate submission directions from your instructor.

For more detail, see [GitHub's guide to source control in a Codespace](https://docs.github.com/en/codespaces/developing-in-a-codespace/using-source-control-in-your-codespace).

## If something goes wrong

- If pgAdmin or PostgreSQL has stopped, run `bash .devcontainer/start-services.sh`.
- If you forgot your pgAdmin password, rerun `bash .devcontainer/create-my-pgadmin-account.sh` and use its reset option.
- To rebuild a workshop database, run `bash .devcontainer/reset-workshop.sh week12a` or `bash .devcontainer/reset-workshop.sh week12b`. The command asks before erasing changes in that database.
- If pgAdmin opens as a blank page, open it in a normal browser tab from **Ports** and hard refresh. If its web files are missing, run `bash .devcontainer/setup.sh`, then reload the tab.
