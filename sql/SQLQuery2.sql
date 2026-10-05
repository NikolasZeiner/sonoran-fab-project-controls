USE SonoranFabControls;

SELECT TOP 20 * FROM purchase_orders ORDER BY total_cost DESC;

SELECT status, COUNT(*) AS pos, SUM(total_cost) AS spend 
	FROM purchase_orders GROUP BY status;

SELECT area_id, SUM(budget_at_completion) AS bac 
	FROM weekly_cost WHERE week_ending = '2026-09-25'
	GROUP BY area_id ORDER BY bac DESC;

SELECT week_ending, SUM(planned_value_cum) AS pv,
		SUM(earned_value_cum) AS ev, SUM(actual_cost_cum) AS ac
	FROM weekly_cost WHERE area_id = 'A1'
	GROUP BY week_ending ORDER BY week_ending;

SELECT * FROM schedule_activities
	WHERE percent_complete > 0 AND percent_complete < 1
	ORDER BY planned_finish;
SELECT delivery_flag, COUNT(*) AS pos, SUM(total_cost) AS spend
	FROM vw_procurement_status
	GROUP BY delivery_flag
	ORDER BY pos DESC;

SELECT supplier_name, delivered_pos, late_pos,
       CAST(on_time_rate AS DECIMAL(4,2)) AS on_time_rate,
       open_spend_at_risk
	FROM vw_supplier_scorecard
	ORDER BY on_time_rate;

SELECT area_name, schedule_flag, COUNT(*) AS activities
	FROM vw_schedule_status
	GROUP BY area_name, schedule_flag
	ORDER BY area_name, schedule_flag;

SELECT activity_name, area_name, planned_percent, percent_complete, schedule_flag
	FROM vw_schedule_status
	WHERE schedule_flag IN ('Past Due', 'Behind Pace')
	ORDER BY area_name;

SELECT area_name, discipline,
       CAST(cpi AS DECIMAL(4,2)) AS cpi,
       CAST(spi AS DECIMAL(4,2)) AS spi,
       ev, ac, pv
	FROM vw_cost_performance_weekly
	WHERE week_ending = '2026-09-25'
	ORDER BY cpi;

SELECT area_name,
       CAST(cpi AS DECIMAL(4,2)) AS cpi,
       CAST(spi AS DECIMAL(4,2)) AS spi,
       bac, eac, eac - bac AS projected_overrun
	FROM vw_area_performance_weekly
	WHERE week_ending = '2026-09-25'
	ORDER BY cpi;

UPDATE project_settings SET status_date = '2026-06-26';

SELECT delivery_flag, COUNT(*) AS pos
	FROM vw_procurement_status
	GROUP BY delivery_flag;

UPDATE project_settings SET status_date = '2026-09-25';
SELECT * FROM project_settings;


USE SonoranFabControls;
GO

CREATE OR ALTER VIEW vw_area_report_detail AS
SELECT 'Cost' AS section, c.week_ending, c.area_id, c.area_name, c.area_manager,
       c.discipline AS group_name,
       CAST(NULL AS VARCHAR(20))  AS item_id,
       CAST(NULL AS VARCHAR(100)) AS item_name,
       CAST(c.cpi AS DECIMAL(10,4)) AS metric_1,
       CAST(c.spi AS DECIMAL(10,4)) AS metric_2,
       CAST(c.cost_variance AS DECIMAL(14,2))     AS amount_1,
       CAST(c.schedule_variance AS DECIMAL(14,2)) AS amount_2,
       CAST(NULL AS DATE) AS date_1,
       CAST(NULL AS DATE) AS date_2,
       CAST(NULL AS INT)  AS days_value,
       CAST(NULL AS VARCHAR(20)) AS flag
FROM vw_cost_performance_weekly c
UNION ALL
SELECT 'Activity', ps.status_date, s.area_id, s.area_name, a.area_manager,
       s.discipline, s.activity_id, s.activity_name,
       s.percent_complete, s.planned_percent,
       s.budget_cost, NULL,
       s.planned_finish, NULL,
       s.days_past_planned_finish, s.schedule_flag
FROM vw_schedule_status s
JOIN areas a ON a.area_id = s.area_id
CROSS JOIN project_settings ps
WHERE s.schedule_flag IN ('Past Due', 'Behind Pace')
UNION ALL
SELECT 'Purchase Order', ps.status_date, p.area_id, p.area_name, a.area_manager,
       p.supplier_name, p.po_number, p.item_description,
       NULL, NULL,
       p.total_cost, NULL,
       p.need_by_date, p.promised_date,
       p.days_late_projected, p.delivery_flag
FROM vw_procurement_status p
JOIN areas a ON a.area_id = p.area_id
CROSS JOIN project_settings ps
WHERE p.delivery_flag IN ('At Risk', 'Overdue');
GO

SELECT area_name, section, COUNT(*) AS row_count
FROM vw_area_report_detail
WHERE section <> 'Cost' OR week_ending = '2026-09-25'
GROUP BY area_name, section
ORDER BY area_name, section;

