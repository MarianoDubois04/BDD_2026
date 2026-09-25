USE sakila;
--1
CREATE TABLE `directors`(
    directors_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    movies_directed INT,
    PRIMARY KEY (directors_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--2
--DROP VIEW IF EXISTS sakila;
--CREATE VIEW `Top 5 actors` AS
INSERT INTO `directors`(first_name, last_name, movies_directed)
    SELECT a.first_name, a.last_name, COUNT(fa.actor_id)
    FROM film_actor AS fa
    INNER JOIN actor AS a ON fa.actor_id=a.actor_id
    GROUP BY fa.actor_id
    ORDER BY COUNT(fa.actor_id) desc
    LIMIT 5;

--3
ALTER TABLE customer
ADD `premium_customer` BOOLEAN NOT NULL DEFAULT FALSE;

--4
UPDATE customer
SET `premium_customer`=TRUE
WHERE EXISTS(
    SELECT customer_id
    FROM payment AS p
    WHERE customer.customer_id = p.customer_id
    GROUP BY customer_id
    ORDER BY SUM(amount) desc
    LIMIT 10
);

--5
SELECT rating, COUNT(rating)
FROM film
GROUP BY rating
ORDER BY COUNT(rating) desc;

--6
SELECT MAX(p.payment_date)
FROM payment p
UNION
SELECT MIN(p.payment_date)
FROM payment p;

SELECT MAX(payment_date), MIN(payment_date)
FROM payment;

--7
SELECT AVG(amount)
FROM payment
GROUP BY MONTH(payment_date);

--8
SELECT a.district, COUNT(rental_id)
FROM customer AS c
INNER JOIN address AS a ON c.address_id=a.address_id
INNER JOIN rental AS r ON c.customer_id=r.customer_id
GROUP BY a.district
ORDER BY COUNT(rental_id) DESC
LIMIT 10;

--9
ALTER TABLE 