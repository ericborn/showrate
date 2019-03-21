--============================================= 
-- Author:    Eric Born 
-- Create date: 1 Nov 2017
-- Last Modified: 21 March 2019
-- Modifications: 21 Mar 2019 - Cleaned up code, removed commented sections

-- Description: Used to extract appointment related data for analysis with R
-- =============================================

SELECT 
	    'kept' =
	     CASE
			WHEN a.appt_kept_ind = 'y' THEN 1
			ELSE 0
		END
	   ,'age' = (CONVERT(int,CONVERT(char(8),appt_date,112))-CONVERT(char(8),p.date_of_birth,112))/10000 
	   ,'day' = 
		 CASE 
			WHEN DATEPART(dw, appt_date) = (2) THEN 'Monday'
			WHEN DATEPART(dw, appt_date) = (3) THEN 'Tuesday'
			WHEN DATEPART(dw, appt_date) = (4) THEN 'Wednesday'
			WHEN DATEPART(dw, appt_date) = (5) THEN 'Thursday'
			WHEN DATEPART(dw, appt_date) = (6) THEN 'Friday'
			WHEN DATEPART(dw, appt_date) = (7) THEN 'Saturday'
		 END
		 ,DATEDIFF(DAY,a.appt_date, a.create_timestamp) AS apptDiff 
		 ,a.begintime AS 'time', e.event, lm.location_name AS 'loc' 
		 ,pt.risk		 
INTO #t --drop table #t
FROM appointments a
JOIN events e					ON a.event_id	 = e.event_id
JOIN ppreporting.dbo.loc lm			ON a.location_id = lm.location_id
JOIN ppreporting.dbo.pt_risk pt ON a.person_id	 = pt.person_id
JOIN person p					ON a.person_id	 = p.person_id
WHERE appt_date >= '20180101' AND appt_date <= '20180630'
AND   p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND a.delete_ind = 'N' AND a.cancel_ind = 'N'
AND e.event NOT IN ('Walk-In Non Exam', 'Walk-In Exam', 'Walk-In MA', 'Walk-In ECP'
					,'Same Day-Exam', 'Same Day-Non Exam',	'FP-Satellite'
					,'Same Day-MA', 'Same Day-Extended', 'Same Day-Procedure' 
					,'Z-Clinic Closed', 'Blocked', 'Z-Staff Meeting/Downtime')

select * from #t