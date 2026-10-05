
USE SonoranFabControls;
GO

CREATE OR ALTER VIEW vw_procurement_status AS
SELECT
    po.po_number,
    po.area_id,
    a.area_name,
    po.supplier_id,
    s.supplier_name,
    po.discipline,
    po.category,
    po.item_description,
    po.total_cost,
    po.order_date,
    po.need_by_date,
    po.promised_date,
    po.actual_delivery_date,
    po.status,
    
    CASE WHEN po.status = 'Delivered'
         THEN DATEDIFF(DAY, po.need_by_date, po.actual_delivery_date) END AS days_late_actual,
   
    CASE WHEN po.status IN ('Open', 'In Transit')
         THEN DATEDIFF(DAY, po.need_by_date, po.promised_date) END AS days_late_projected,
    CASE
        WHEN po.status = 'Cancelled' THEN 'Cancelled'
        WHEN po.status = 'Delivered' AND po.actual_delivery_date > po.need_by_date THEN 'Delivered Late'
        WHEN po.status = 'Delivered' THEN 'Delivered On Time'
        WHEN po.need_by_date < ps.status_date THEN 'Overdue'
        WHEN po.promised_date > po.need_by_date THEN 'At Risk'
        ELSE 'On Track'
    END AS delivery_flag
FROM purchase_orders po
JOIN areas a      ON a.area_id = po.area_id
JOIN suppliers s  ON s.supplier_id = po.supplier_id
CROSS JOIN project_settings ps;
GO

CREATE OR ALTER VIEW vw_supplier_scorecard AS
SELECT
    supplier_id,
    supplier_name,
    COUNT(*)                                                         AS total_pos,
    SUM(CASE WHEN delivery_flag IN ('Delivered Late', 'Delivered On Time') THEN 1 ELSE 0 END) AS delivered_pos,
    SUM(CASE WHEN delivery_flag = 'Delivered Late' THEN 1 ELSE 0 END) AS late_pos,
    CAST(SUM(CASE WHEN delivery_flag = 'Delivered On Time' THEN 1 ELSE 0 END) AS DECIMAL(6,2))
        / NULLIF(SUM(CASE WHEN delivery_flag IN ('Delivered Late', 'Delivered On Time') THEN 1 ELSE 0 END), 0)
                                                                     AS on_time_rate,
    SUM(CASE WHEN delivery_flag IN ('At Risk', 'Overdue') THEN total_cost ELSE 0 END) AS open_spend_at_risk
FROM vw_procurement_status
GROUP BY supplier_id, supplier_name;
GO

CREATE OR ALTER VIEW vw_schedule_status AS
WITH base AS (
    SELECT
        sa.*,
        a.area_name,
        ps.status_date,

        CASE
            WHEN ps.status_date <= sa.planned_start  THEN 0.0
            WHEN ps.status_date >= sa.planned_finish THEN 1.0
            ELSE CAST(DATEDIFF(DAY, sa.planned_start, ps.status_date) AS DECIMAL(10,4))
                 / NULLIF(DATEDIFF(DAY, sa.planned_start, sa.planned_finish), 0)
        END AS planned_percent
    FROM schedule_activities sa
    JOIN areas a ON a.area_id = sa.area_id
    CROSS JOIN project_settings ps
)
SELECT
    activity_id, area_id, area_name, discipline, activity_name,
    planned_start, planned_finish, actual_start, actual_finish,
    percent_complete,
    CAST(planned_percent AS DECIMAL(4,2))                  AS planned_percent,
    budget_cost,
    budget_cost * planned_percent                          AS planned_value,
    budget_cost * percent_complete                         AS earned_value,
    CASE WHEN planned_finish < status_date AND percent_complete < 1
         THEN DATEDIFF(DAY, planned_finish, status_date) END AS days_past_planned_finish,
    CASE
        WHEN percent_complete >= 1 THEN 'Complete'
        WHEN planned_finish < status_date THEN 'Past Due'
        WHEN percent_complete < planned_percent - 0.10 THEN 'Behind Pace'
        WHEN percent_complete = 0 AND planned_percent = 0 THEN 'Not Started'
        ELSE 'On Track'
    END AS schedule_flag
FROM base;
GO

CREATE OR ALTER VIEW vw_cost_performance_weekly AS
SELECT
    wc.week_ending,
    wc.area_id,
    a.area_name,
    a.area_manager,
    wc.discipline,
    wc.budget_at_completion                                   AS bac,
    wc.planned_value_cum                                      AS pv,
    wc.earned_value_cum                                       AS ev,
    wc.actual_cost_cum                                        AS ac,
    wc.earned_value_cum - wc.actual_cost_cum                  AS cost_variance,
    wc.earned_value_cum - wc.planned_value_cum                AS schedule_variance,
    wc.earned_value_cum / NULLIF(wc.actual_cost_cum, 0)       AS cpi,
    wc.earned_value_cum / NULLIF(wc.planned_value_cum, 0)     AS spi,
    wc.earned_value_cum / NULLIF(wc.budget_at_completion, 0)  AS percent_complete,
    wc.budget_at_completion / NULLIF(wc.earned_value_cum / NULLIF(wc.actual_cost_cum, 0), 0) AS eac
FROM weekly_cost wc
JOIN areas a ON a.area_id = wc.area_id;
GO

CREATE OR ALTER VIEW vw_area_performance_weekly AS
SELECT
    week_ending, area_id, area_name, area_manager,
    SUM(bac) AS bac, SUM(pv) AS pv, SUM(ev) AS ev, SUM(ac) AS ac,
    SUM(ev) - SUM(ac)                    AS cost_variance,
    SUM(ev) - SUM(pv)                    AS schedule_variance,
    SUM(ev) / NULLIF(SUM(ac), 0)         AS cpi,
    SUM(ev) / NULLIF(SUM(pv), 0)         AS spi,
    SUM(ev) / NULLIF(SUM(bac), 0)        AS percent_complete,
    SUM(bac) / NULLIF(SUM(ev) / NULLIF(SUM(ac), 0), 0) AS eac
FROM vw_cost_performance_weekly
GROUP BY week_ending, area_id, area_name, area_manager;
GO

SELECT area_name, CAST(cpi AS DECIMAL(4,2)) AS cpi, CAST(spi AS DECIMAL(4,2)) AS spi
FROM vw_area_performance_weekly
WHERE week_ending = (SELECT status_date FROM project_settings)
ORDER BY area_id;
