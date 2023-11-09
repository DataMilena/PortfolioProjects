/*

Cleaning IMDB Movies Dataset in SQL Queries

*/ 

SELECT * FROM MovieProject.dbo.imdb_movies 

-- DELETE unused columns -- 

ALTER TABLE MovieProject.dbo.imdb_movies 
DROP COLUMN Poster_Link, Overview

-- Adding id column to perform INNER JOIN later in Data Exploration -- 

ALTER TABLE imdb_movies 
ADD id INT PRIMARY KEY IDENTITY(1,1)

-- Handling NULL Data-- 
-- Changing NULL values in Certificate column to 'U' ('Universal'), as this is the most common Film classification -- 

  SELECT Certificate, CASE
               WHEN Certificate IS NULL THEN 'U'
			   ELSE Certificate
  END FROM dbo.imdb_movies

  UPDATE dbo.imdb_movies 
  SET Certificate = CASE
               WHEN Certificate IS NULL THEN 'U'
			   ELSE Certificate
  END

  -- Changing NULL Values in Gross Column to the average Gross -- 
  -- Frist: Convert type to BIGINT -- 

UPDATE imdb_movies 
SET Gross = REPLACE(Gross, ',', '')

ALTER TABLE imdb_movies 
ALTER COLUMN Gross BIGINT; 

-- Fill NULL Values with average gross -- 

WITH my_cte AS (
      SELECT [Gross], COALESCE([Gross], AVG([Gross]) Over()) AS repl_with_avg
	  FROM imdb_movies
)
UPDATE my_cte
SET [Gross] = repl_with_avg

SELECT Gross FROM imdb_movies;

  -- Changing NULL Values in Meta_score Column 0 -- 

 UPDATE imdb_movies 
 SET Meta_score = ISNULL(Meta_score, 0) 
 

  -- Removing "min" after Runtime-Column -- 
  
UPDATE imdb_movies 
SET Runtime = REPLACE(Runtime, ' min', '') 

ALTER TABLE imdb_movies 
ALTER COLUMN Runtime INT; 