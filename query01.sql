/*
  Which bus stop has the largest population within 800 meters? As a rough
  estimation, consider any block group that intersects the buffer as being part
  of the 800 meter buffer.
*/

WITH

 -- bus stop inside philly

bus_stop_philly as (SELECT b.*
FROM septa.bus_stops AS b
JOIN azavea.neighborhoods AS n
ON ST_Within(b.geog::geometry, n.geog::geometry)
),

 -- join censusblock with population on geoid

census_block_pop as (

SELECT blocks.geoid, pops.total, blocks.geog
FROM census.blockgroups_2020 as blocks
INNER JOIN census.population_2020 as pops using (geoid)

),

 -- censusblock whitin 800m

bus_stops_800_pop as (
SELECT b.stop_id, sum(p.total) as estimated_pop_800m
FROM bus_stop_philly AS b
JOIN census_block_pop AS p
ON ST_dWithin(b.geog::geometry, p.geog::geometry, 0.008)
GROUP BY b.stop_id
)

 -- select largest

SELECT pop.stop_id, pop.estimated_pop_800m, stops.geog
FROM bus_stops_800_pop AS pop
INNER JOIN bus_stop_philly AS stops using(stop_id)
ORDER BY estimated_pop_800m DESC
LIMIT 8
