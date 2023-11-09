/*

IMDB Movies Dataset Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views

*/

SELECT * FROM MovieProject.dbo.imdb_movies


-- Number of total votes -- 

SELECT SUM(CAST(No_of_Votes AS INT)) AS TotalVotes 
FROM imdb_movies

-- Top voted movies -- 

SELECT TOP 10 Series_Title, IMDB_Rating 
FROM imdb_movies
ORDER BY 2 DESC

SELECT TOP 10
    Series_Title,
    No_of_votes,
    IMDb_Rating
FROM imdb_movies
ORDER BY No_of_votes DESC,
IMDB_Rating DESC

-- Using CTE and Window Function to rank highest rated movies --

WITH MovieRanks AS (
    SELECT
        Series_Title,
        IMDB_Rating,
        RANK() OVER (ORDER BY IMDB_Rating DESC) AS RatingRank
    FROM imdb_movies
)
SELECT
    Series_Title,
    IMDB_Rating
FROM MovieRanks
WHERE RatingRank <= 10;

-- Using SELF JOIN to compare Meta_score with IMDB_Rating of top rated movies -- 

SELECT TOP 10
    m.Series_Title,
    m.IMDB_Rating,
    ms.Meta_score
FROM MovieProject.dbo.imdb_movies m
JOIN MovieProject.dbo.imdb_movies ms 
ON m.id = ms.id
ORDER BY m.IMDB_Rating DESC

-- Top 10 rated movies: total earnings --

SELECT TOP 10 Series_Title, IMDB_Rating, Gross 
FROM imdb_movies
ORDER BY 2 DESC

-- Movies with highest total earnings -- 

SELECT TOP 10 
Series_Title, 
IMDB_Rating, 
Gross
FROM imdb_movies
ORDER BY 3 DESC


-- Gross earnings over time: Shows overall trend in movie earnings -- 

 SELECT
        Released_Year,
        SUM(Gross) AS CumulativeGross
    FROM imdb_movies
    GROUP BY Released_Year


-- IMDB rating distribution --

SELECT
    IMDB_Rating,
    COUNT(*) AS Count
FROM imdb_movies
GROUP BY IMDB_Rating
ORDER BY IMDB_Rating;

-- Maximum movies released in Year -- 

SELECT TOP 10 Released_Year, 
COUNT(Series_Title) AS Max_movies
FROM imdb_movies
GROUP BY Released_Year 
ORDER BY 2 DESC

-- Most common Directors -- 

SELECT TOP 10
    Director,
    COUNT(*) AS MovieCount
FROM imdb_movies
GROUP BY Director
ORDER BY MovieCount DESC;

-- Directors with highest Gross -- 

SELECT TOP 10 Director, 
SUM(Gross) AS Total_Gross
FROM imdb_movies
GROUP BY Director
ORDER BY 2 DESC


-- Using Window Function to rank Directors by Average IMDB Rating of their movies to identify top directors -- 

SELECT
    Director,
    AVG(IMDB_Rating) AS AvgDirectorRating,
	Count(Series_Title) AS MovieCount,
    DENSE_RANK() OVER (ORDER BY AVG(IMDB_Rating) DESC) AS DirectorRank
FROM imdb_movies 
GROUP BY Director
HAVING Count(Series_Title) > 5

-- Finding Top 10 Movie Genres -- 

SELECT TOP 10
    Genre,
    AVG(IMDB_Rating) AS AverageRating
FROM imdb_movies
GROUP BY Genre
ORDER BY AverageRating DESC

-- Creating Temp Table to store the split genre values -- 


CREATE TABLE #SplitGenre (
    Series_Title NVARCHAR(255),
    Genre NVARCHAR(255),
    IMDB_Rating DECIMAL(2, 1),
	Gross BIGINT
);

-- Inserting split genre values along into the temporary table

INSERT INTO #SplitGenre (Series_Title, Genre, IMDB_Rating, Gross)
SELECT
    Series_Title,
    LTRIM(RTRIM(value)) AS Genre, -- Triming leading and trailing spaces
    IMDB_Rating,
	Gross
FROM imdb_movies
CROSS APPLY STRING_SPLIT(Genre, ',');

-- Now I have a local temporary table #SplitGenre populated with the split genre values and IMDB ratings.

SELECT *
FROM #SplitGenre;

-- TOP 10 genres by the average rating -- 

SELECT TOP 10
    Genre,
    AVG(IMDb_Rating) AS AverageRating
FROM #SplitGenre
GROUP BY Genre
ORDER BY AverageRating DESC

-- Top 10 most common genres -- 

SELECT TOP 10
    Genre,
    COUNT(*) AS GenreCount
FROM #SplitGenre
GROUP BY Genre
ORDER BY GenreCount DESC

-- Top 10 Genres that generate highest gross -- 

SELECT TOP 10 
Genre, SUM(Gross) AS TotalGross
FROM #SplitGenre
GROUP BY Genre
ORDER BY 2 DESC


-- Summary Statistics Temp Table: 
-- contains summary statistics for various aspects of your data (mean, median, and standard deviation of IMDb ratings) or gross earnings. 
-- These statistics can be helpful for visualizing data distributions.

SELECT
    IMDB_Rating AS Statistic,
    AVG(IMDB_Rating) AS Mean,
    ISNULL(STDEV(IMDB_Rating), 0) AS StandardDeviation,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY IMDb_Rating) OVER() AS Median,
	Gross AS Gross_Statistic,
    AVG(Gross) AS MeanGrossEarnings,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Gross) OVER() AS MedianGrossEarnings,
    STDEV(Gross) AS StandardDeviationGrossEarnings
FROM imdb_movies
GROUP BY IMDB_Rating, Gross


-- Creating a View that compiles data about all movie stars, showcasing the number of movies they've appeared in
-- This view is useful for identifying the most prolific stars --

CREATE VIEW TopStars AS
SELECT StarName, COUNT(*) AS MovieCount
FROM (
    SELECT Star1 AS StarName FROM imdb_movies
    UNION ALL
    SELECT Star2 AS StarName FROM imdb_movies
    UNION ALL
    SELECT Star3 AS StarName FROM imdb_movies
	UNION ALL
	SELECT Star4 AS StarName FROM imdb_movies
) AS Stars
GROUP BY StarName;

SELECT *
FROM TopStars
ORDER BY 2 DESC;

-- Alternative without Creating a View -- 

SELECT
    StarName,
    COUNT(*) AS MovieCount,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS StarRank
FROM (
    SELECT Star1 AS StarName FROM imdb_movies
    UNION ALL
    SELECT Star2 AS StarName FROM imdb_movies
    UNION ALL
    SELECT Star3 AS StarName FROM imdb_movies
) AS Stars
GROUP BY StarName;


-- Showing Meta_Score over the Years to identify trends in movie quality over time -- 

SELECT Released_Year, 
AVG(CAST(Meta_Score AS INT)) AS AvgMetaScore
FROM imdb_movies
WHERE Meta_Score <> 0 
AND Meta_score <> 'PG'
GROUP BY Released_Year
ORDER BY AvgMetaScore DESC


