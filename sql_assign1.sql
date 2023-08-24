--Using a CTE, find out the total number of films rented for each rating (like 'PG', 'G', etc.) in the year 2005. 
--List the ratings that had more than 50 rentals.

WITH CTE_FILM_RATING AS
(

	SELECT  
		se_film.rating AS film_rating,
	    EXTRACT(YEAR FROM se_rental.rental_date) AS rental_year,
		COALESCE(COUNT(DISTINCT se_rental.rental_id),0) AS total_films_rented
	FROM public.film AS se_film
	LEFT OUTER JOIN public.inventory AS se_inventory
		ON se_film.film_id = se_inventory.film_id
	LEFT OUTER JOIN public.rental AS se_rental
		ON se_inventory.inventory_id = se_rental.inventory_id
	WHERE EXTRACT(YEAR FROM se_rental.rental_date) = 2005			
	GROUP BY 
		se_film.rating, 
		EXTRACT(YEAR FROM (se_rental.rental_date))
    
)

SELECT 
	film_rating,
	total_films_rented
FROM CTE_FILM_RATING
WHERE total_films_rented > 50
			  
			  

--: Identify the categories of films that have an average rental duration greater than 5 days. 
--Only consider films rated 'PG' or 'G'.

WITH CTE_CATEGORIES_AVERAGE_RENTAL_DURATION AS (
	SELECT 
		se_category.name AS category_name,
		CAST(se_film.rating AS TEXT) AS film_rating,
		ROUND(AVG ( EXTRACT(DAY FROM (se_rental.return_date - se_rental.rental_date))+ (EXTRACT(HOUR FROM (se_rental.return_date - se_rental.rental_date))/24)),2) AS duration_days
	FROM public.category AS se_category
	INNER JOIN public.film_category AS se_film_category
		ON se_film_category.category_id = se_category.category_id
	INNER JOIN public.film AS se_film
		ON se_film_category.film_id = se_film.film_id
	INNER JOIN public.inventory AS se_inventory 
		ON se_film_category.film_id = se_inventory.film_id
	INNER JOIN public.rental AS se_rental 
		ON se_inventory.inventory_id = se_rental.inventory_id
    GROUP BY 
		se_category.name, CAST(se_film.rating AS TEXT)
	HAVING 
		ROUND(AVG ( EXTRACT(DAY FROM (se_rental.return_date - se_rental.rental_date))+ (EXTRACT(HOUR FROM (se_rental.return_date - se_rental.rental_date))/24)),2) >5
)

SELECT 
	*
FROM CTE_CATEGORIES_AVERAGE_RENTAL_DURATION
WHERE film_rating IN ('PG', 'G')
ORDER BY 
	category_name




--: Determine the total rental amount collected from each customer. List only those customers 
--who have spent more than $100 in total.

SELECT 
	CONCAT(se_customer.first_name,' ',se_customer.last_name) AS customer_name,
	SUM(se_payment.amount) AS total_amount
FROM payment AS se_payment
INNER JOIN public.customer AS se_customer
	ON se_customer.customer_id = se_payment.customer_id
GROUP BY 
	CONCAT(se_customer.first_name,' ',se_customer.last_name)
HAVING 
	SUM(se_payment.amount) > 100


--: Create a temporary table containing the names and email addresses of customers who have rented
--more than 10 films.

CREATE TEMPORARY TABLE TEMP_NAMES_EMAILS AS
(
	SELECT 
		CONCAT(se_customer.first_name,' ',se_customer.last_name) AS customer_name,
		se_customer.email AS email,
		COUNT(se_rental.rental_id) AS rental_number
	FROM public.customer AS se_customer
	INNER JOIN public.rental AS se_rental
		ON se_customer.customer_id = se_rental.customer_id
	GROUP BY 
		CONCAT(se_customer.first_name,' ',se_customer.last_name),se_customer.email
	HAVING 
		COUNT(se_rental.rental_id) >10
)

--: From the temporary table created in Task 3.1, identify customers who have a Gmail email address
--(i.e., their email ends with '@gmail.com').

SELECT 
	*
FROM TEMP_NAMES_EMAILS
WHERE email LIKE  '_%@gmail.com'


--Start by creating a CTE that finds the total number of films rented for each category.
--Create a temporary table from this CTE.
--Using the temporary table, list the top 5 categories with the highest number of rentals.
--Ensure the results are in descending order.			  
			  
WITH CTE_TOTAL_FILM_CATEGORY AS
(

	SELECT  
		se_category.name AS category_name,
		COALESCE(COUNT(DISTINCT se_rental.rental_id),0) AS total_rentals	
	FROM public.category AS se_category
	LEFT OUTER JOIN public.film_category AS se_film_category
		ON se_film_category.category_id = se_category.category_id
	LEFT OUTER JOIN public.inventory AS se_inventory 
		ON se_film_category.film_id = se_inventory.film_id
	LEFT OUTER JOIN public.rental AS se_rental 
		ON se_inventory.inventory_id = se_rental.inventory_id
	GROUP BY 
		se_category.name 
)
CREATE TEMP TABLE TEMP_TOTAL_FILM_CATEGORY AS
(
	SELECT  
		se_category.name AS category_name,
		COALESCE(COUNT(DISTINCT se_rental.rental_id),0) AS total_rentals	
	FROM public.category AS se_category
	LEFT OUTER JOIN public.film_category AS se_film_category
		ON se_film_category.category_id = se_category.category_id
	LEFT OUTER JOIN public.inventory AS se_inventory 
		ON se_film_category.film_id = se_inventory.film_id
	LEFT OUTER JOIN public.rental AS se_rental 
		ON se_inventory.inventory_id = se_rental.inventory_id
	GROUP BY 
		se_category.name 
)

SELECT
	category_name,
	total_rentals
FROM TEMP_TOTAL_FILM_CATEGORY
ORDER BY 
	total_rentals
LIMIT 5
--: Identify films that have never been rented out. Use a combination of CTE and LEFT JOIN for this task.
WITH CTE_FILMS_RENTED AS
(
	SELECT 
		se_film.film_id AS films,
		se_film.title AS film_title,
		COALESCE(COUNT( se_rental.rental_id),0) AS total_rentals
	FROM public.film AS se_film
	LEFT OUTER JOIN public.inventory AS se_inventory
		ON se_film.film_id = se_inventory.film_id
	LEFT OUTER JOIN public.rental AS se_rental
		ON se_inventory.inventory_id = se_rental.inventory_id
	GROUP BY 
		se_film.film_id,  
		se_film.title 
)
SELECT 
	*				
FROM CTE_FILMS_RENTED				
WHERE 
	total_rentals = 0

--(INNER JOIN): Find the names of customers who rented films with a replacement cost greater than $20 and
--which belong to the 'Action' or 'Comedy' categories.

SELECT 
	DISTINCT CONCAT(se_customer.first_name,' ',se_customer.last_name) AS customer_name,
	se_film.title AS movie_title,
	se_category.name AS category_name,
	se_film.replacement_cost AS replacement_cost
FROM public.customer AS se_customer
INNER JOIN public.rental AS se_rental
	ON se_customer.customer_id = se_rental.customer_id
INNER JOIN public.inventory AS se_inventory
	ON se_rental.inventory_id = se_inventory.inventory_id
INNER JOIN public.film AS se_film
	ON se_film.film_id = se_inventory.film_id
INNER JOIN public.film_category AS se_film_category
	ON se_film.film_id = se_film_category.film_id
INNER JOIN public.category AS se_category
	ON se_film_category.category_id = se_category.category_id  
WHERE 
	se_film.replacement_cost>20 
AND LOWER(se_category.name) IN ('action', 'comedy')


--(LEFT JOIN): List all actors who haven't appeared in a film with a rating of 'R'.
SELECT DISTINCT 
	CONCAT(se_actor.first_name,' ',se_actor.last_name) AS actor_name,
	se_film.rating AS rating
FROM public.actor AS se_actor
LEFT OUTER JOIN public.film_actor AS se_film_actor
	ON se_actor.actor_id = se_film_actor.actor_id
LEFT OUTER JOIN public.film AS se_film
	ON se_film_actor.film_id = se_film.film_id 
	AND LOWER(CAST(se_film.rating AS TEXT)) != 'r'
WHERE 
	se_film.rating IS NOT NULL
	
	
--(Combination of INNER JOIN and LEFT JOIN): Identify customers who have never rented a film from the 'Horror' category.
SELECT DISTINCT
	CONCAT(se_customer.first_name,' ',se_customer.last_name) AS customer_name,
	se_film.title AS movie_title,
	se_category.name AS category_name	
FROM public.customer AS se_customer
INNER JOIN public.rental AS se_rental
	ON se_customer.customer_id = se_rental.customer_id
INNER JOIN public.inventory AS se_inventory
	ON se_rental.inventory_id = se_inventory.inventory_id
INNER JOIN public.film AS se_film
	ON se_film.film_id = se_inventory.film_id
LEFT OUTER JOIN public.film_category AS se_film_category
	ON se_film.film_id = se_film_category.film_id
LEFT OUTER JOIN public.category AS se_category
	ON se_film_category.category_id = se_category.category_id 
	AND LOWER(se_category.name) != 'horror'
WHERE 
	se_category.name IS NOT NULL
	
--(Multiple INNER JOINs): Find the names and email addresses of customers who rented films directed by a specific actor 
--(let's say, for the sake of this task, that the actor's first name is 'Nick' and last name is 'Wahlberg', 
--although this might not match actual data in the DVD Rental database).			  

SELECT 
	CONCAT(se_customer.first_name,' ',se_customer.last_name) AS customer_name,
	se_customer.email AS email,
	se_film.title AS movie,
	CONCAT(se_actor.first_name,' ',se_actor.last_name) AS actor_name
FROM public.customer AS se_customer
INNER JOIN public.rental AS se_rental
	ON se_customer.customer_id = se_rental.customer_id
INNER JOIN public.inventory AS se_inventory
	ON se_rental.inventory_id = se_inventory.inventory_id
INNER JOIN public.film AS se_film
	ON se_film.film_id = se_inventory.film_id
INNER JOIN public.film_actor AS se_film_actor
	ON se_film.film_id = se_film_actor.film_id 
INNER JOIN public.actor AS se_actor
	ON se_film_actor.actor_id = se_actor.actor_id
WHERE 
	LOWER(se_actor.first_name) = 'nick' AND LOWER(se_actor.last_name) = 'wahlberg'	 	  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  
			  