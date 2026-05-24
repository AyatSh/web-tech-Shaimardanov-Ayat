DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'cinema_db') THEN
        EXECUTE 'CREATE DATABASE cinema_db';
    END IF;
END $$;

CREATE SCHEMA IF NOT EXISTS cinema;

DROP TABLE IF EXISTS
    cinema.payments,
    cinema.tickets,
    cinema.sessions,
    cinema.film_genre,
    cinema.film_director,
    cinema.halls,
    cinema.films,
    cinema.directors,
    cinema.genres,
    cinema.countries,
    cinema.customers
CASCADE;

CREATE TABLE IF NOT EXISTS cinema.genres (
    genre_id    SERIAL PRIMARY KEY,
    name        VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS cinema.countries (
    country_id  SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    code        CHAR(2) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS cinema.directors (
    director_id SERIAL PRIMARY KEY,
    full_name   VARCHAR(150) NOT NULL,        
    birth_date  DATE,
    country_id  INT REFERENCES cinema.countries(country_id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS cinema.films (
    film_id       SERIAL PRIMARY KEY,
    title         VARCHAR(200) NOT NULL,     
    release_year  INT NOT NULL,
    duration_min  INT NOT NULL CHECK (duration_min > 0),  
    rating        NUMERIC(3,1) CHECK (rating BETWEEN 0 AND 10),
    country_id    INT REFERENCES cinema.countries(country_id) ON DELETE SET NULL,
    status        VARCHAR(20) NOT NULL DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'now_showing', 'archived'))
);

CREATE TABLE IF NOT EXISTS cinema.halls (
    hall_id     SERIAL PRIMARY KEY,
    name        VARCHAR(60) NOT NULL UNIQUE,
    capacity    INT NOT NULL CHECK (capacity > 0),
    hall_type   VARCHAR(20) NOT NULL DEFAULT 'standard' CHECK (hall_type IN ('standard', 'imax', 'vip', '4dx'))
);

CREATE TABLE IF NOT EXISTS cinema.customers (
    customer_id  SERIAL PRIMARY KEY,
    email        VARCHAR(120) NOT NULL UNIQUE,
    full_name    VARCHAR(150) NOT NULL,
    phone        VARCHAR(15),
    gender       VARCHAR(10) NOT NULL CHECK (gender IN ('M', 'F', 'Other')),
    birth_date   DATE,
    loyalty_pts  INT NOT NULL DEFAULT 0 CHECK (loyalty_pts >= 0),
    created_at   TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS cinema.sessions (
    session_id   SERIAL PRIMARY KEY,
    film_id      INT NOT NULL REFERENCES cinema.films(film_id) ON DELETE RESTRICT,
    hall_id      INT NOT NULL REFERENCES cinema.halls(hall_id) ON DELETE RESTRICT,
    start_time   TIMESTAMP NOT NULL CHECK (start_time > TIMESTAMP '2026-01-01 00:00:00'),
    price        NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    seats_left   INT NOT NULL CHECK (seats_left >= 0)
);

CREATE TABLE IF NOT EXISTS cinema.film_genre (
    film_genre_id SERIAL PRIMARY KEY,
    film_id       INT NOT NULL REFERENCES cinema.films(film_id) ON DELETE CASCADE,
    genre_id      INT NOT NULL REFERENCES cinema.genres(genre_id) ON DELETE CASCADE,
    UNIQUE (film_id, genre_id)
);

CREATE TABLE IF NOT EXISTS cinema.film_director (
    film_director_id SERIAL PRIMARY KEY,
    film_id          INT NOT NULL REFERENCES cinema.films(film_id) ON DELETE CASCADE,
    director_id      INT NOT NULL REFERENCES cinema.directors(director_id) ON DELETE CASCADE,
    role             VARCHAR(60) NOT NULL DEFAULT 'director',
    UNIQUE (film_id, director_id)
);

CREATE TABLE IF NOT EXISTS cinema.tickets (
    ticket_id    SERIAL PRIMARY KEY,
    session_id   INT NOT NULL REFERENCES cinema.sessions(session_id) ON DELETE RESTRICT,
    customer_id  INT NOT NULL REFERENCES cinema.customers(customer_id) ON DELETE RESTRICT,
    seat_number  VARCHAR(10) NOT NULL,
    status       VARCHAR(20) NOT NULL DEFAULT 'reserved' CHECK (status IN ('reserved', 'confirmed', 'cancelled', 'used')),
    booked_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (session_id, seat_number)
);

CREATE TABLE IF NOT EXISTS cinema.payments (
    payment_id    SERIAL PRIMARY KEY,
    ticket_id     INT NOT NULL REFERENCES cinema.tickets(ticket_id) ON DELETE RESTRICT,
    amount        NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
    method        VARCHAR(20) NOT NULL DEFAULT 'card' CHECK (method IN ('card', 'cash', 'online', 'wallet')),
    paid_at       TIMESTAMP NOT NULL DEFAULT NOW(),
    status        VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'refunded'))
);

ALTER TABLE cinema.sessions
    ADD COLUMN IF NOT EXISTS start_date DATE
    GENERATED ALWAYS AS (CAST(start_time AS DATE)) STORED;

ALTER TABLE cinema.customers
    ADD COLUMN IF NOT EXISTS signup_source VARCHAR(40) DEFAULT 'website';

ALTER TABLE cinema.customers
    ALTER COLUMN phone TYPE VARCHAR(20);

ALTER TABLE cinema.customers
    RENAME COLUMN loyalty_pts TO loyalty_points;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_film_release_year'
          AND conrelid = 'cinema.films'::regclass
    ) THEN
        ALTER TABLE cinema.films
            ADD CONSTRAINT chk_film_release_year
            CHECK (release_year BETWEEN 1888 AND 2100);
    END IF;
END $$;

ALTER TABLE cinema.sessions
    ALTER COLUMN seats_left SET DEFAULT 100;

TRUNCATE TABLE
    cinema.payments,
    cinema.tickets,
    cinema.film_genre,
    cinema.film_director,
    cinema.sessions,
    cinema.films,
    cinema.halls,
    cinema.directors,
    cinema.genres,
    cinema.countries,
    cinema.customers
RESTART IDENTITY CASCADE;

INSERT INTO cinema.genres (name) VALUES
    ('Action'),
    ('Drama'),
    ('Comedy'),
    ('Thriller'),
    ('Sci-Fi'),
    ('Animation'),
    ('Horror'),
    ('Romance');

INSERT INTO cinema.countries (name, code) VALUES
    ('United States', 'US'),
    ('United Kingdom', 'GB'),
    ('France',         'FR'),
    ('South Korea',    'KR'),
    ('Kazakhstan',     'KZ');

INSERT INTO cinema.directors (full_name, birth_date, country_id) VALUES
    ('Christopher Nolan', DATE '1970-07-30', (SELECT country_id FROM cinema.countries WHERE code = 'GB')),
    ('Bong Joon-ho',      DATE '1969-09-14', (SELECT country_id FROM cinema.countries WHERE code = 'KR')),
    ('Greta Gerwig',       DATE '1983-08-04', (SELECT country_id FROM cinema.countries WHERE code = 'US')),
    ('Ridley Scott',      DATE '1937-11-30', (SELECT country_id FROM cinema.countries WHERE code = 'GB'));

INSERT INTO cinema.films (title, release_year, duration_min, rating, country_id, status) VALUES
    ('Interstellar',    2014, 169, 8.6, (SELECT country_id FROM cinema.countries WHERE code = 'US'), 'now_showing'),
    ('Parasite',        2019, 132, 8.5, (SELECT country_id FROM cinema.countries WHERE code = 'KR'), 'now_showing'),
    ('Barbie',          2023, 114, 7.0, (SELECT country_id FROM cinema.countries WHERE code = 'US'), 'now_showing'),
    ('Gladiator II',    2024, 148, 7.3, (SELECT country_id FROM cinema.countries WHERE code = 'US'), 'upcoming'),
    ('The Dark Knight', 2008, 152, 9.0, (SELECT country_id FROM cinema.countries WHERE code = 'US'), 'archived');

INSERT INTO cinema.film_genre (film_id, genre_id)
SELECT f.film_id, g.genre_id
FROM (VALUES
    ('Interstellar',    'Sci-Fi'),
    ('Interstellar',    'Drama'),
    ('Parasite',        'Thriller'),
    ('Parasite',        'Drama'),
    ('Barbie',          'Comedy'),
    ('Barbie',          'Drama'),
    ('Gladiator II',    'Action'),
    ('Gladiator II',    'Drama'),
    ('The Dark Knight', 'Action'),
    ('The Dark Knight', 'Thriller')
) AS x(film_title, genre_name)
JOIN cinema.films  f ON f.title = x.film_title
JOIN cinema.genres g ON g.name  = x.genre_name;

INSERT INTO cinema.film_director (film_id, director_id, role)
SELECT f.film_id, d.director_id, x.role
FROM (VALUES
    ('Interstellar',    'Christopher Nolan', 'director'),
    ('Parasite',        'Bong Joon-ho',      'director'),
    ('Barbie',          'Greta Gerwig',      'director'),
    ('Gladiator II',    'Ridley Scott',      'director'),
    ('The Dark Knight', 'Christopher Nolan', 'director')
) AS x(film_title, director_name, role)
JOIN cinema.films     f ON f.title     = x.film_title
JOIN cinema.directors d ON d.full_name = x.director_name;

INSERT INTO cinema.halls (name, capacity, hall_type) VALUES
    ('Hall 1',  200, 'standard'),
    ('Hall 2',  120, 'vip'),
    ('Hall 3',  350, 'imax'),
    ('Hall 4',   80, '4dx');

INSERT INTO cinema.sessions (film_id, hall_id, start_time, price, seats_left) VALUES
    (
        (SELECT film_id FROM cinema.films  WHERE title = 'Interstellar'),
        (SELECT hall_id FROM cinema.halls  WHERE name  = 'Hall 3'),
        TIMESTAMP '2026-04-10 18:00:00', 3500.00, 300
    ),
    (
        (SELECT film_id FROM cinema.films  WHERE title = 'Parasite'),
        (SELECT hall_id FROM cinema.halls  WHERE name  = 'Hall 1'),
        TIMESTAMP '2026-04-11 20:00:00', 2800.00, 180
    ),
    (
        (SELECT film_id FROM cinema.films  WHERE title = 'Barbie'),
        (SELECT hall_id FROM cinema.halls  WHERE name  = 'Hall 2'),
        TIMESTAMP '2026-04-12 15:30:00', 2500.00, 100
    ),
    (
        (SELECT film_id FROM cinema.films  WHERE title = 'Gladiator II'),
        (SELECT hall_id FROM cinema.halls  WHERE name  = 'Hall 3'),
        TIMESTAMP '2026-04-15 21:00:00', 3800.00, 340
    ),
    (
        (SELECT film_id FROM cinema.films  WHERE title = 'The Dark Knight'),
        (SELECT hall_id FROM cinema.halls  WHERE name  = 'Hall 1'),
        TIMESTAMP '2026-04-20 17:00:00', 2200.00, 190
    );

INSERT INTO cinema.customers (email, full_name, phone, gender, birth_date, loyalty_points) VALUES
    ('asel.nurova@mail.kz',     'Asel Nurova',     '+77012345678', 'F', DATE '1995-06-14', 120),
    ('damir.seitkali@mail.kz',  'Damir Seitkali',  '+77023456789', 'M', DATE '1990-03-22',  85),
    ('zhanna.bekova@gmail.com', 'Zhanna Bekova',   '+77034567890', 'F', DATE '1998-11-05',  40),
    ('arman.tuleev@mail.kz',    'Arman Tuleev',    '+77045678901', 'M', DATE '1987-07-30', 200),
    ('lena.kim@gmail.com',      'Lena Kim',        '+77056789012', 'F', DATE '2000-01-18',  10);

INSERT INTO cinema.tickets (session_id, customer_id, seat_number, status) VALUES
    (
        (SELECT session_id FROM cinema.sessions
         WHERE film_id = (SELECT film_id FROM cinema.films WHERE title = 'Interstellar')
           AND CAST(start_time AS DATE) = DATE '2026-04-10'),
        (SELECT customer_id FROM cinema.customers WHERE email = 'asel.nurova@mail.kz'),
        'G7', 'confirmed'
    ),
    (
        (SELECT session_id FROM cinema.sessions
         WHERE film_id = (SELECT film_id FROM cinema.films WHERE title = 'Parasite')
           AND CAST(start_time AS DATE) = DATE '2026-04-11'),
        (SELECT customer_id FROM cinema.customers WHERE email = 'damir.seitkali@mail.kz'),
        'D4', 'confirmed'
    ),
    (
        (SELECT session_id FROM cinema.sessions
         WHERE film_id = (SELECT film_id FROM cinema.films WHERE title = 'Barbie')
           AND CAST(start_time AS DATE) = DATE '2026-04-12'),
        (SELECT customer_id FROM cinema.customers WHERE email = 'zhanna.bekova@gmail.com'),
        'B2', 'reserved'
    ),
    (
        (SELECT session_id FROM cinema.sessions
         WHERE film_id = (SELECT film_id FROM cinema.films WHERE title = 'Gladiator II')
           AND CAST(start_time AS DATE) = DATE '2026-04-15'),
        (SELECT customer_id FROM cinema.customers WHERE email = 'arman.tuleev@mail.kz'),
        'K12', 'confirmed'
    ),
    (
        (SELECT session_id FROM cinema.sessions
         WHERE film_id = (SELECT film_id FROM cinema.films WHERE title = 'The Dark Knight')
           AND CAST(start_time AS DATE) = DATE '2026-04-20'),
        (SELECT customer_id FROM cinema.customers WHERE email = 'lena.kim@gmail.com'),
        'C9', 'cancelled'
    );

INSERT INTO cinema.payments (ticket_id, amount, method, status) VALUES
    (
        (SELECT t.ticket_id FROM cinema.tickets t
         JOIN cinema.customers c ON c.customer_id = t.customer_id
         WHERE c.email = 'asel.nurova@mail.kz' AND t.seat_number = 'G7'),
        3500.00, 'card', 'completed'
    ),
    (
        (SELECT t.ticket_id FROM cinema.tickets t
         JOIN cinema.customers c ON c.customer_id = t.customer_id
         WHERE c.email = 'damir.seitkali@mail.kz' AND t.seat_number = 'D4'),
        2800.00, 'online', 'completed'
    ),
    (
        (SELECT t.ticket_id FROM cinema.tickets t
         JOIN cinema.customers c ON c.customer_id = t.customer_id
         WHERE c.email = 'zhanna.bekova@gmail.com' AND t.seat_number = 'B2'),
        2500.00, 'wallet', 'pending'
    ),
    (
        (SELECT t.ticket_id FROM cinema.tickets t
         JOIN cinema.customers c ON c.customer_id = t.customer_id
         WHERE c.email = 'arman.tuleev@mail.kz' AND t.seat_number = 'K12'),
        3800.00, 'cash', 'completed'
    ),
    (
        (SELECT t.ticket_id FROM cinema.tickets t
         JOIN cinema.customers c ON c.customer_id = t.customer_id
         WHERE c.email = 'lena.kim@gmail.com' AND t.seat_number = 'C9'),
        2200.00, 'card', 'refunded'
    );

UPDATE cinema.customers c
SET loyalty_points = loyalty_points + (
    SELECT COALESCE(SUM(p.amount) / 100, 0)::INT
    FROM cinema.payments p
    JOIN cinema.tickets t ON t.ticket_id = p.ticket_id
    WHERE t.customer_id = c.customer_id
      AND p.status = 'completed'
);

UPDATE cinema.films f
SET status = 'archived'
FROM (
    SELECT DISTINCT s.film_id
    FROM cinema.sessions s
    WHERE NOT EXISTS (
        SELECT 1 FROM cinema.tickets t
        WHERE t.session_id = s.session_id
          AND t.status IN ('reserved', 'confirmed')
    )
) sub
WHERE f.film_id = sub.film_id
  AND f.status  = 'now_showing';

BEGIN;
    DELETE FROM cinema.payments
    WHERE status IN ('refunded', 'pending')
      AND paid_at < CURRENT_TIMESTAMP - INTERVAL '90 days'
    RETURNING payment_id, ticket_id, amount, status, paid_at;
ROLLBACK;

DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'cinema_readonly') THEN
        REASSIGN OWNED BY cinema_readonly TO CURRENT_USER;
        DROP OWNED BY cinema_readonly;
        DROP ROLE cinema_readonly;
    END IF;
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'cinema_writer') THEN
        REASSIGN OWNED BY cinema_writer TO CURRENT_USER;
        DROP OWNED BY cinema_writer;
        DROP ROLE cinema_writer;
    END IF;
END $$;

CREATE ROLE cinema_readonly;
CREATE ROLE cinema_writer;

GRANT USAGE ON SCHEMA cinema TO cinema_readonly, cinema_writer;

GRANT SELECT ON ALL TABLES IN SCHEMA cinema TO cinema_readonly;

GRANT INSERT, UPDATE ON cinema.tickets  TO cinema_writer;
GRANT INSERT, UPDATE ON cinema.payments TO cinema_writer;

REVOKE UPDATE ON cinema.payments FROM cinema_writer;