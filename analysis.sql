-- Airline Operations Analysis | PostgreSQL
-- Synthetic flight records for analytical practice; not operational airline data.
DROP TABLE IF EXISTS flights;
CREATE TABLE flights (
 flight_id INT PRIMARY KEY, flight_date DATE, airline VARCHAR(25), origin VARCHAR(20),
 destination VARCHAR(20), scheduled_departure TIME, actual_departure TIME,
 passengers INT, capacity INT, status VARCHAR(20)
);
INSERT INTO flights VALUES
(1,'2026-02-01','SkyWays','Pune','Delhi','08:00','08:18',142,180,'Completed'),
(2,'2026-02-01','AirMetro','Mumbai','Bengaluru','09:30','09:25',165,180,'Completed'),
(3,'2026-02-02','SkyWays','Delhi','Pune','14:00','15:05',151,180,'Completed'),
(4,'2026-02-02','AirMetro','Pune','Goa','11:15',NULL,0,150,'Cancelled'),
(5,'2026-02-03','SkyWays','Mumbai','Delhi','18:20','18:42',170,180,'Completed'),
(6,'2026-02-03','AirMetro','Bengaluru','Mumbai','07:45','07:50',130,160,'Completed'),
(7,'2026-02-04','SkyWays','Pune','Delhi','08:00','08:10',158,180,'Completed'),
(8,'2026-02-04','AirMetro','Goa','Pune','16:30','17:25',118,150,'Completed'),
(9,'2026-02-05','SkyWays','Delhi','Mumbai','20:00','20:03',176,180,'Completed'),
(10,'2026-02-05','AirMetro','Mumbai','Bengaluru','09:30',NULL,0,180,'Cancelled'),
(11,'2026-02-06','SkyWays','Pune','Goa','12:00','12:12',135,150,'Completed'),
(12,'2026-02-06','AirMetro','Bengaluru','Delhi','15:10','16:00',144,160,'Completed');
-- 1. Operational KPIs
SELECT COUNT(*) AS scheduled_flights,
 COUNT(*) FILTER (WHERE status='Completed') AS completed,
 COUNT(*) FILTER (WHERE status='Cancelled') AS cancelled,
 ROUND(100.0*COUNT(*) FILTER (WHERE status='Cancelled')/COUNT(*),2) AS cancellation_pct
FROM flights;
-- 2. Load factor
SELECT airline, ROUND(100.0*SUM(passengers)/NULLIF(SUM(capacity),0),2) AS load_factor_pct
FROM flights WHERE status='Completed' GROUP BY airline;
-- 3. Delay minutes for completed flights
SELECT flight_id, airline, origin, destination,
 GREATEST(0,EXTRACT(EPOCH FROM (actual_departure-scheduled_departure))/60) AS delay_minutes
FROM flights WHERE status='Completed';
-- 4. On-time departure rate (15-minute tolerance)
WITH delays AS (
 SELECT *, EXTRACT(EPOCH FROM (actual_departure-scheduled_departure))/60 AS delay_min
 FROM flights WHERE status='Completed'
)
SELECT airline, COUNT(*) AS flights,
 ROUND(100.0*COUNT(*) FILTER (WHERE delay_min<=15)/COUNT(*),2) AS on_time_pct
FROM delays GROUP BY airline;
-- 5. Route demand
SELECT origin,destination,COUNT(*) AS flights,SUM(passengers) AS passengers
FROM flights GROUP BY origin,destination ORDER BY passengers DESC;
-- 6. Airline punctuality comparison
SELECT airline, ROUND(AVG(EXTRACT(EPOCH FROM (actual_departure-scheduled_departure))/60),1) AS avg_delay_min
FROM flights WHERE status='Completed' GROUP BY airline;
-- 7. Daily completion trend
SELECT flight_date, COUNT(*) AS scheduled,
 COUNT(*) FILTER (WHERE status='Completed') AS completed
FROM flights GROUP BY flight_date ORDER BY flight_date;
-- 8. Low-load flight review (<70%)
SELECT flight_id, airline, origin,destination,passengers,capacity,
 ROUND(100.0*passengers/NULLIF(capacity,0),1) AS load_factor_pct
FROM flights WHERE status='Completed' AND passengers::numeric/capacity < 0.70;
