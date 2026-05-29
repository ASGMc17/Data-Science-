create schema capstone;
use capstone;

-- 1. Determine the number of flights that are delayed on various days of the week
SELECT 
    dayofweek, COUNT(*) AS delayed_flights
FROM
    airlines
WHERE
    delay = 1
GROUP BY dayofweek
ORDER BY dayofweek;

-- 2. Determine the number of delayed flights for various airlines
SELECT 
    airline, COUNT(*) AS delayed_airline
FROM
    airlines
WHERE
    delay = 1
GROUP BY airline
ORDER BY delayed_airline DESC;

-- 3. Determine how many delayed flights land at airports with at least 10 runways
SELECT 
    COUNT(*) AS delayed_flights_runways
FROM
    airlines a
        JOIN
    airports ap ON a.airportto = ap.iata_code
        JOIN
    (SELECT 
        airport_ref
    FROM
        runways
    GROUP BY airport_ref
    HAVING COUNT(*) >= 10) r ON ap.id = r.airport_ref
WHERE
    a.delay = 1;

-- 4. Compare the number of delayed flights at airports higher than average elevation and those that are lower than average elevation for both source and destination airports
-- Source airports
SELECT 
    CASE
        WHEN
            ap.elevation_ft > (SELECT 
                    AVG(elevation_ft)
                FROM
                    airports)
        THEN
            'Above Average Elevation'
        ELSE 'Below or Equal Average Elevation'
    END AS elevation_category,
    COUNT(*) AS delayed_flights
FROM
    airlines a
        JOIN
    airports ap ON a.airportfrom = ap.iata_code
WHERE
    a.delay = 1
GROUP BY elevation_category;

-- Destination Airport
SELECT 
    CASE
        WHEN
            ap.elevation_ft > (SELECT 
                    AVG(elevation_ft)
                FROM
                    airports)
        THEN
            'Above Average Elevation'
        ELSE 'Below or Equal Average Elevation'
    END AS elevation_category,
    COUNT(*) AS delayed_flights
FROM
    airlines a
        JOIN
    airports ap ON a.airportto = ap.iata_code
WHERE
    a.delay = 1
GROUP BY elevation_category;
