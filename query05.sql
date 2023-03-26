/*
Rate neighborhoods by their bus stop accessibility for wheelchairs. Use Azavea's neighborhood dataset from OpenDataPhilly along with an appropriate dataset from the Septa GTFS bus feed. Use the [GTFS documentation](https://gtfs.org/reference/static/) for help. Use some creativity in the metric you devise in rating neighborhoods.
*/

/*
Descriptions : 
To assess the accessibility of public transportation for wheelchair users, I first determined that the average speed of a normal wheelchair is 0.7 m/s. I then established a criterion that if the distance between a station and a home takes more than 5 minutes to traverse at that speed, it cannot be considered accessible. To create a buffer zone that accounts for this criterion, I multiplied the speed by 60 (to convert from m/s to m/min) and by 5 (to cover a 5-minute distance), resulting in a buffer of 210 m.

I designated this buffer zone as the "transit accessible zone for wheelchairs" and multiply it by popular density of each neighborhood to obtain the "bus stop accessibility for wheelchairs index", which represents the proportion of the people that falls within the transit accessible zone for wheelchairs."

*/

/*
Rate neighborhoods by their bus stop accessibility for wheelchairs. Use Azavea's neighborhood dataset from OpenDataPhilly along with an appropriate dataset from the Septa GTFS bus feed. Use the [GTFS documentation](https://gtfs.org/reference/static/) for help. Use some creativity in the metric you devise in rating neighborhoods.
*/

/*
Descriptions : 
To assess the accessibility of public transportation for wheelchair users, I first determined that the average speed of a normal wheelchair is 0.7 m/s. I then established a criterion that if the distance between a station and a home takes more than 5 minutes to traverse at that speed, it cannot be considered accessible. To create a buffer zone that accounts for this criterion, I multiplied the speed by 60 (to convert from m/s to m/min) and by 5 (to cover a 5-minute distance), resulting in a buffer of 210 m.

I designated this buffer zone as the "transit accessible zone for wheelchairs" and multiply it by popular density of each neighborhood to obtain the "bus stop accessibility for wheelchairs index", which represents the proportion of the people that falls within the transit accessible zone for wheelchairs."

*/

WITH

-- calculate neighborhood pop

block_pop AS (
SELECT geoid, b.total, a.geog
FROM census.blockgroups_2020 AS a
INNER JOIN census.population_2020 AS b USING (geoid)
),

neigh_pop AS (
SELECT n.name, p.total, n.geog
FROM azavea.neighborhoods AS n
INNER JOIN block_pop AS p
  ON ST_Within(ST_Transform(p.geog::geometry, 4236), ST_Transform(n.geog::geometry, 4236))
),

neight_pop_tot AS (
SELECT name, SUM(total) AS pop
FROM neigh_pop
GROUP BY name
),

-- bus_stop with wheelchair boarding

bus_wheelchair AS (
SELECT * 
FROM septa.bus_stops
WHERE wheelchair_boarding = '1'
),

-- generate intersections of 210m buffer with each neighborhood

step1 AS (
SELECT n.name, ST_Area(n.geog) AS n_area, 
ST_Area(ST_Intersection(ST_Buffer(b.geog::geography, 210), n.geog::geography)) AS inter_area,
ST_Intersection(ST_Buffer(b.geog::geography, 210), n.geog::geography) AS inter_geog,
n.geog AS n_geog
FROM bus_wheelchair AS b
INNER JOIN azavea.neighborhoods AS n 
  ON ST_DWithin(b.geog::geography, n.geog::geography, 210)
),

-- calculate total accessible area by neighborhood

step2 AS (
SELECT name, SUM(inter_area) AS access_area
FROM step1
GROUP BY name
),

-- join pop data

step3 AS (
SELECT *
FROM step2
INNER JOIN neight_pop_tot USING (name)
)

-- calculate accessibility_metric

SELECT DISTINCT name AS neighborhood_name, a.access_area/b.n_area*a.pop AS accessibility_metric, b.n_geog
FROM step3 AS a
INNER JOIN step1 AS b USING (name)
ORDER BY accessibility_metric DESC
LIMIT 5;




















