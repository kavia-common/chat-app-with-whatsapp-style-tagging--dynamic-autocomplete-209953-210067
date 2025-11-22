# ApplicationDatabase

This directory contains the PostgreSQL setup for the chat application, including:
- schema.sql: database schema for users, messages, tags, message-tag relations, and tag suggestions.
- seed.sql: idempotent seed data for demo users, tags, suggestions, and sample messages.
- startup.sh: script to bootstrap a local PostgreSQL instance (on a custom port), create the database and user, and apply schema and seed.
- backup_db.sh / restore_db.sh: utility scripts to back up and restore the database.
- db_visualizer/: a lightweight Node-based viewer to browse your DB.

Environment
- DB Name: myapp
- DB User: appuser
- DB Password: dbuser123
- DB Port: 5000 (PostgreSQL server binds to this port)
- Connection URI: postgresql://appuser:dbuser123@localhost:5000/myapp

Quick Start
1) Start PostgreSQL and apply schema + seed
   ./startup.sh

   The script:
   - Initializes and starts PostgreSQL (if not running)
   - Creates database "myapp" and user "appuser"
   - Grants permissions
   - Applies schema.sql and seed.sql idempotently

   After running, a db_connection.txt file is created with a ready-to-use psql command.

2) Connect to the database
   psql -h localhost -U appuser -d myapp -p 5000
   Or:
   $(cat db_connection.txt)

3) Re-run schema or seed manually (idempotent)
   PGPASSWORD="dbuser123" psql -h localhost -p 5000 -U appuser -d myapp -f schema.sql
   PGPASSWORD="dbuser123" psql -h localhost -p 5000 -U appuser -d myapp -f seed.sql

4) Optional: View data with the simple DB viewer
   source db_visualizer/postgres.env
   cd db_visualizer
   npm install
   npm start
   Open http://localhost:3000 and use the Postgres option.

Backup and Restore
- Create backup:
  ./backup_db.sh
  Produces database_backup.sql (for PostgreSQL) in this directory.

- Restore from backup:
  ./restore_db.sh
  Detects the SQL backup and restores to the local database instance.

Notes
- All SQL artifacts must reside under ApplicationDatabase/. Do not place or edit .sql files outside this directory.
- The seed is idempotent and safe to run multiple times.
- Indexes are created for frequent queries:
  - "Message".user_id
  - "Tag".value, "Tag".type
  - "TagSuggestion".trigger

Troubleshooting
- If PostgreSQL is already running on port 5000, startup.sh skips launching a new instance and proceeds to applying schema/seed.
- If you change credentials, update:
  - DB_USER, DB_PASSWORD, DB_NAME, DB_PORT in startup.sh
  - db_visualizer/postgres.env if you use the viewer.

Security
- Credentials are for local development only. For production, configure via environment variables and secrets management. Do not hardcode secrets in code.

```diff
Important
- This database is designed for the BackendAPIService to consume.
- Use the provided tables to implement message CRUD and dynamic tag suggestions triggered by '@' and '#'.
```
