BEGIN;
WITH films_data AS (
    SELECT
        'Inception' AS title,
        'A thief who steals corporate secrets through dream-sharing technology.' AS description,
        2010 AS release_year,
        (SELECT language_id FROM language WHERE lower(name) = 'english') AS language_id,
        7 AS rental_duration,
        4.99 AS rental_rate,        
        148 AS length,
        'PG-13'::mpaa_rating AS rating
    UNION ALL
    SELECT
        'Interstellar',
        'A team travels through a wormhole in space to ensure humanity survival.',
        2014,
        (SELECT language_id FROM language WHERE lower(name) = 'english'),
        14,
        9.99,
        169,
        'PG-13'::mpaa_rating
    UNION ALL
    SELECT
        'Fight Club',
        'An insomniac office worker forms an underground fight club.',
        1999,
        (SELECT language_id FROM language WHERE lower(name) = 'english'),
        21,
        19.99,
        139,
        'R'::mpaa_rating
),
insert_films AS (
    INSERT INTO film (
        title, description, release_year, language_id,
        rental_duration, rental_rate, length, rating, last_update
    )
    SELECT
        f.title, f.description, f.release_year, f.language_id,
        f.rental_duration, f.rental_rate, f.length, f.rating, CURRENT_DATE
    FROM films_data f
    WHERE NOT EXISTS (
        SELECT 1 FROM film WHERE title = f.title
    )
    RETURNING film_id, title
)
SELECT * FROM insert_films;
INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Leonardo', 'DiCaprio', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name='Leonardo' AND last_name='DiCaprio'
);

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Joseph', 'Gordon-Levitt', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name='Joseph' AND last_name='Gordon-Levitt'
);

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Matthew', 'McConaughey', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name='Matthew' AND last_name='McConaughey'
);
INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Anne', 'Hathaway', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name='Anne' AND last_name='Hathaway'
);
INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Brad', 'Pitt', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name='Brad' AND last_name='Pitt'
);

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Edward', 'Norton', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name='Edward' AND last_name='Norton'
);

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name='Leonardo' AND last_name='DiCaprio'),
    (SELECT film_id FROM film WHERE title='Inception'),
    CURRENT_DATE
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name='Joseph' AND last_name='Gordon-Levitt'),
    (SELECT film_id FROM film WHERE title='Inception'),
    CURRENT_DATE
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name='Matthew' AND last_name='McConaughey'),
    (SELECT film_id FROM film WHERE title='Interstellar'),
    CURRENT_DATE
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name='Anne' AND last_name='Hathaway'),
    (SELECT film_id FROM film WHERE title='Interstellar'),
    CURRENT_DATE
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name='Brad' AND last_name='Pitt'),
    (SELECT film_id FROM film WHERE title='Fight Club'),
    CURRENT_DATE
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name='Edward' AND last_name='Norton'),
    (SELECT film_id FROM film WHERE title='Fight Club'),
    CURRENT_DATE
ON CONFLICT DO NOTHING;

INSERT INTO inventory (film_id, store_id, last_update)
SELECT
    f.film_id,
    (SELECT store_id FROM store LIMIT 1),
    CURRENT_DATE
FROM film f
WHERE f.title IN ('Inception','Interstellar','Fight Club')
AND NOT EXISTS (
    SELECT 1 FROM inventory i
    WHERE i.film_id = f.film_id
);

UPDATE customer
SET
    first_name = 'Ayat',
    last_name  = 'Shaymardanov',
    email      = 'ayat@example.com',
    address_id = (SELECT address_id FROM address LIMIT 1),
    last_update = CURRENT_DATE
WHERE customer_id = (
    SELECT c.customer_id
    FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT r.rental_id) >= 43
       AND COUNT(DISTINCT p.payment_id) >= 43
    LIMIT 1
);

SELECT * FROM payment
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name='Ayat' AND last_name='Shaymardanov'
);

DELETE FROM payment
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name='Ayat' AND last_name='Shaymardanov'
);

SELECT * FROM rental
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name='Ayat' AND last_name='Shaymardanov'
);

DELETE FROM rental
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name='Ayat' AND last_name='Shaymardanov'
);
WITH rented AS (
    INSERT INTO rental (
        rental_date,
        inventory_id,
        customer_id,
        return_date,
        staff_id,
        last_update
    )
    SELECT
        CURRENT_DATE,
        i.inventory_id,
        c.customer_id,
        CURRENT_DATE + (f.rental_duration * INTERVAL '1 day'),
        (SELECT staff_id FROM staff LIMIT 1),
        CURRENT_DATE
    FROM inventory i
    JOIN film f ON i.film_id = f.film_id
    JOIN customer c ON c.first_name='Ayat' AND c.last_name='Shaymardanov'
    WHERE f.title IN ('Inception','Interstellar','Fight Club')
    AND NOT EXISTS (
        SELECT 1 FROM rental r
        WHERE r.inventory_id = i.inventory_id
        AND r.customer_id = c.customer_id
    )
    RETURNING rental_id, inventory_id
)

INSERT INTO payment (
    customer_id,
    staff_id,
    rental_id,
    amount,
    payment_date
)
SELECT
    (SELECT customer_id FROM customer WHERE first_name='Ayat' AND last_name='Shaymardanov'),
    (SELECT staff_id FROM staff LIMIT 1),
    r.rental_id,
    9.99,
    '2017-01-15'
FROM rented r;


COMMIT;