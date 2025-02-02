USE [ppreporting]
GO
/****** Object:  StoredProcedure [dbo].[Risk_Index]    Script Date: 3/21/2019 3:29:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--============================================= 
-- Author:    Eric Born 
-- Create date: 1 February 2016 
-- Description:  Calculates patient show/no-show ratio and risk. 
-- Rebuilds table each day to ensure all previous show/no show data is captured.
-- Low risk			100-90% show rate
-- Low-Medium risk	89-76%  show rate
-- Medium risk		75-66%  show rate
-- Medium-High risk	65-51%  show rate
-- High risk		50-0%	show rate
-- =============================================

ALTER PROCEDURE [dbo].[Risk_Index] 

AS 
BEGIN 

--
drop table pt_risk
--Use fixed date range as we want all appointment data for all patients
DECLARE @startDate  date = '20060101'
DECLARE @endDate	date = '20201231'

--Create table to store risk data
CREATE TABLE pt_risk
			(
				person_id		UNIQUEIDENTIFIER	NULL,
				name			VARCHAR(MAX)		NULL,
				risk			VARCHAR(15)			NULL,
				total_appts		INT					NULL,
				show			INT					NULL,
				no_show			INT					NULL,
				canceled		INT					NULL,
				showR			INT					NULL,
				no_showR		INT					NULL,
				canceledR		INT					NULL
			)
--Gather all distinct patients
INSERT INTO pt_risk
	SELECT DISTINCT a.person_id as person_id,
	CONCAT (first_name, ' ', last_name) as name,
	NULL					AS risk,
	0						AS total_appts,
	0						AS show,
	0						AS no_show,
	0						AS canceled,
	0						AS showR,
	0						AS no_showR,
	0						AS canceledR
	from NGProd.dbo.appointments a
	where a.appt_date >= convert(date,@startDate) and a.appt_date <= convert(date,@endDate) and a.event_id != '6257266B-ECD8-40FC-9BBB-0BEFFBE64840' 
	and enc_id IS NOT NULL and a.last_name NOT LIKE '%test%'

--TOTAL appointments during set time period
--exclude reschedules as they technically close 1st appt and create a 2nd
SELECT a.person_id AS pid, COUNT(a.person_id) AS num 
INTO #temp1 
FROM NGProd.dbo.appointments a
join pt_risk p on p.person_id = a.person_id
where a.appt_date >= @startDate and a.appt_date <= @endDate and a.event_id != '6257266B-ECD8-40FC-9BBB-0BEFFBE64840' and a.resched_ind = 'N'
group by a.person_id

--Add TOTAL appointment count to risk table
UPDATE pt_risk
set total_appts = t.num
from pt_risk p
join #temp1 t
on p.person_id = t.pid 

--KEPT appointments during set time period
SELECT a.person_id AS pid, COUNT(a.person_id) AS num 
INTO #temp2 
FROM NGProd.dbo.appointments a
join pt_risk p on p.person_id = a.person_id
where a.appt_date >= @startDate and a.appt_date <= @endDate and a.event_id != '6257266B-ECD8-40FC-9BBB-0BEFFBE64840'
and a.appt_kept_ind = 'Y' and a.resched_ind = 'N' and a.last_name NOT LIKE '%test%' and a.enc_id NOT LIKE 'NULL'
group by a.person_id

--Add KEPT appointment kept count to risk table
UPDATE pt_risk
set show = t.num
from pt_risk p
join #temp2 t
on p.person_id = t.pid

--CANCELED appointments during set time period
SELECT a.person_id AS pid, COUNT(a.person_id) AS num 
INTO #temp3
FROM NGProd.dbo.appointments a
join pt_risk p on p.person_id = a.person_id
where a.appt_date >= @startDate and a.appt_date <= @endDate and a.event_id != '6257266B-ECD8-40FC-9BBB-0BEFFBE64840'
and a.appt_kept_ind = 'N' and a.resched_ind = 'N' and a.delete_ind = 'N' and a.cancel_ind = 'Y' and a.last_name NOT LIKE '%test%'
group by a.person_id

--Add CANCELED appt count to risk table
UPDATE pt_risk
set canceled = t.num
from pt_risk p
join #temp3 t
on p.person_id = t.pid

--MISSED appointments during set time period
SELECT a.person_id AS pid, COUNT(a.person_id) AS num 
INTO #temp4 
FROM NGProd.dbo.appointments a
join pt_risk p on p.person_id = a.person_id
where a.appt_date >= @startDate and a.appt_date <= @endDate and a.event_id != '6257266B-ECD8-40FC-9BBB-0BEFFBE64840'
and a.appt_kept_ind = 'N' and a.resched_ind = 'N' and a.delete_ind = 'N' and a.cancel_ind = 'N' and a.last_name NOT LIKE '%test%'
group by a.person_id

--Add MISSED appt count to risk table
UPDATE pt_risk
set no_show = t.num
from pt_risk p
join #temp4 t
on p.person_id = t.pid

--Calculate show, no-show and cancel percents
SELECT person_id, ((100 * show) / NULLIF(total_appts , 0)) AS showR, ((100 * no_show) / NULLIF(total_appts , 0)) AS no_showR, ((100 * canceled) / NULLIF(total_appts , 0)) AS canceledR 
INTO #temp5
FROM pt_risk

UPDATE pt_risk
SET no_showR = t.no_showR, canceledR = t.canceledR, showR = t.showR
FROM pt_risk p
JOIN #temp5 t
ON p.person_id = t.person_id

--Apply risk based on show percents
SELECT showR, risk = 
	CASE WHEN showR >= 90 THEN 'Low'
		 WHEN showR	>= 76 and showR <= 89 THEN 'Low-Medium'
		 WHEN showR	>= 66 and showR <= 75 THEN 'Medium'
		 WHEN showR	>= 51 and showR <= 65 THEN 'Medium-High'
		 ELSE 'High'
		 END, 
	person_id
INTO #temp6 
FROM pt_risk 
 
UPDATE pt_risk
SET risk = t.risk
FROM pt_risk p
JOIN #temp6 t
ON p.person_id = t.person_id

select * from pt_risk

drop table #temp1
drop table #temp2
drop table #temp3
drop table #temp4
drop table #temp5
drop table #temp6

END