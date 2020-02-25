/*Project submission for SM Vivier*/
/*Query 1: Which category of family-friendly films are the most popular?*/
WITH t1 AS (
            SELECT f.title title,
            c.name category_name,
            r.rental_date AS rent_date
            FROM film f
            JOIN film_category fc
            ON f.film_id = fc.film_id
            JOIN inventory i
            ON f.film_id = i.film_id
            JOIN category c
            ON fc.category_id = c.category_id
            JOIN rental r
            ON i.inventory_id = r.inventory_id
            GROUP BY 1,2,3
            ORDER BY 1,2)

SELECT CASE WHEN category_name = 'Animation' THEN 'Animation'
            WHEN category_name = 'Children' THEN 'Children'
            WHEN category_name = 'Classics' THEN 'Classics'
            WHEN category_name = 'Comedy' THEN 'Comedy'
            WHEN category_name = 'Family' THEN 'Family'
            ELSE 'Music' END AS category_name,
            COUNT (*) AS rental_count
FROM t1
GROUP BY 1
ORDER BY 2 DESC

/*Query 3: What is the distribution like of the most popular family-friendly film categories regarding the rental duration*/
WITH t1 AS (
            SELECT f.title title,
            c.name category_name,
            f.rental_duration
            FROM film f
            JOIN film_category fc
            ON f.film_id = fc.film_id
            JOIN inventory i
            ON f.film_id = i.film_id
            JOIN category c
            ON fc.category_id = c.category_id
            JOIN rental r
            ON i.inventory_id = r.inventory_id
            GROUP BY 1,2,3
            ORDER BY 1,2)

SELECT title,
       category_name,
       CASE WHEN category_name = 'Animation' THEN 'Animation'
            WHEN category_name = 'Children' THEN 'Children'
            WHEN category_name = 'Classics' THEN 'Classics'
            WHEN category_name = 'Comedy' THEN 'Comedy'
            WHEN category_name = 'Family' THEN 'Family'
            ELSE 'Music' END AS category_name,
       rental_duration,
       NTILE(4) OVER (PARTITION BY rental_duration ORDER BY category_name) AS standard_quartile
FROM t1
GROUP BY 1,2,3,4
ORDER BY 2 DESC

/*Query 4: What was the monthly total of payments made by individual customers during each month of 2007? */
WITH t1 AS(
    SELECT c.customer_id,
           p.customer_id,
           p.amount amount_paid,
           c.first_name,
           p.payment_date,
           c.last_name,
           CONCAT(c.first_name,' ',c.last_name) AS full_name,
           DATE_TRUNC('month',p.payment_date) AS pay_mon
           FROM film f
           JOIN inventory i
           ON f.film_id = i.film_id
           JOIN rental r
           ON i.film_id = r.rental_id
           JOIN payment p
           ON r.rental_id = p.customer_id
           JOIN customer c
           ON r.rental_id = c.store_id
           GROUP BY 1,2,3,4,5,6
           ORDER BY 7)
SELECT pay_mon,
       full_name,
       COUNT(*) num_payments,
       SUM(amount_paid) total_paid
FROM t1
GROUP BY 1,2
ORDER BY 2,1

/*Query 5: What were the total amount of payments and the revenue for each month in 2007?*/
WITH t1 AS(
    SELECT c.customer_id,
           p.customer_id,
           p.amount amount_paid,
           c.first_name,
           p.payment_date,
           c.last_name,
           CONCAT(c.first_name,' ',c.last_name) AS full_name,
           DATE_TRUNC('month',p.payment_date) AS pay_mon
           FROM film f
           JOIN inventory i
           ON f.film_id = i.film_id
           JOIN rental r
           ON i.film_id = r.rental_id
           JOIN payment p
           ON r.rental_id = p.customer_id
           JOIN customer c
           ON r.rental_id = c.store_id
           GROUP BY 1,2,3,4,5,6
           ORDER BY 7)
SELECT DATE_TRUNC('month',pay_mon) as month_payment,
       COUNT(*) num_payments,
       SUM(amount_paid) total_paid
FROM t1
GROUP BY 1
ORDER BY 1

/*Query 6: Who are the top 10 paying customers in 2007?*/
WITH t1 AS(
    SELECT c.customer_id,
           p.customer_id,
           p.amount amount_paid,
           c.first_name,
           p.payment_date,
           c.last_name,
           CONCAT(c.first_name,' ',c.last_name) AS full_name,
           DATE_TRUNC('month',p.payment_date) AS pay_mon
           FROM film f
           JOIN inventory i
           ON f.film_id = i.film_id
           JOIN rental r
           ON i.film_id = r.rental_id
           JOIN payment p
           ON r.rental_id = p.customer_id
           JOIN customer c
           ON r.rental_id = c.store_id
           GROUP BY 1,2,3,4,5,6
           ORDER BY 7)
SELECT pay_mon,
       full_name,
       COUNT(*) num_payments,
       SUM(amount_paid) AS total_paid
FROM t1
GROUP BY 1,2
ORDER BY 4 DESC
LIMIT 10

/*Query 7: WHich individual customer had the largest pay difference in the months of 2007?*/
WITH t1 AS(
    SELECT c.customer_id,
           p.customer_id,
           p.amount amount_paid,
           c.first_name,
           p.payment_date,
           c.last_name,
           CONCAT(c.first_name,' ',c.last_name) AS full_name,
           DATE_TRUNC('month',p.payment_date) AS pay_mon
           FROM film f
           JOIN inventory i
           ON f.film_id = i.film_id
           JOIN rental r
           ON i.film_id = r.rental_id
           JOIN payment p
           ON r.rental_id = p.customer_id
           JOIN customer c
           ON r.rental_id = c.store_id
           GROUP BY 1,2,3,4,5,6
           ORDER BY 7),
    t2 AS(
    SELECT pay_mon,
           full_name,
           amount_paid,
           COUNT(*) num_payments,
           SUM(amount_paid) OVER(PARTITION BY full_name ORDER BY amount_paid) AS total_paid
   FROM t1
   GROUP BY 1,2,3
   ORDER BY 2,1
           )

   SELECT pay_mon,
          full_name,
          num_payments,
          total_paid,
          LAG(total_paid) OVER (PARTITION BY full_name ORDER BY total_paid) AS lag,
          total_paid - LAG(total_paid) OVER (PARTITION BY full_name ORDER BY total_paid) AS lag_difference
  FROM t2
  GROUP BY 1,2,4,3
  ORDER BY 2,1

/*Query 8: How do the two stores compare in their count of rental orders during every month for all the years we have data for?*/
WITH t1 AS(
          SELECT DATE_PART('month',r.rental_date) AS month,
                 DATE_PART('year', r.rental_date) AS year,
                 i.store_id AS store_id,
                 r.rental_id AS rental_id
          FROM film f
          JOIN inventory i
          ON f.film_id = i.film_id
          JOIN rental r
          ON i.inventory_id = r.inventory_id
          GROUP BY 3,4
          ORDER BY 1,2,3)

SELECT month,
       year,
       store_id,
       COUNT(*) number_rentals
FROM t1
GROUP BY 1,2,3
ORDER BY 1,2,4
