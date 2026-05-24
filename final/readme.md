# Cinema Database

## Domain Description
A cinema booking and management database for a movie theater. It stores films, genres, directors, countries, halls, sessions, customers, tickets, and payments. The schema supports session scheduling, ticket booking, payment tracking, loyalty points, and role-based access control.

## Database Schema Name
- Schema: `cinema`
- Database: `cinema_db`

## Run Instructions
1. Place the SQL script in a `.sql` file.
2. Connect to PostgreSQL as a user with permission to create databases and roles.
3. Run the script, for example:
   - `psql -U postgres -f path/to/script.sql`
4. The script will:
   - create `cinema_db` if it does not exist
   - create schema `cinema`
   - create tables, constraints, and relationships
   - insert sample data
   - create roles and grant permissions

## Design Decisions
- Used `cinema` schema to isolate application objects.
- Tables are normalized with separate entities for genres, countries, directors, films, halls, customers, sessions, tickets, and payments.
- Many-to-many relationships are represented by `cinema.film_genre` and `cinema.film_director`.
- Status fields use `CHECK` constraints to enforce valid values.
- A generated column `start_date` is derived from `start_time` in `cinema.sessions`.
- Customer loyalty points are updated based on completed payments.
- Roles `cinema_readonly` and `cinema_writer` are created with limited permissions.
- Cleanup and idempotency are supported with `DROP TABLE IF EXISTS`, `TRUNCATE ... RESTART IDENTITY CASCADE`, and conditional role cleanup.