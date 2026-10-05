USE SonoranFabControls;
GO

DELETE FROM weekly_cost;
DELETE FROM schedule_activities;
DELETE FROM purchase_orders;
DELETE FROM suppliers;
DELETE FROM areas;
GO

BULK INSERT areas               FROM 'C:\PersonalProjects\Sonoran_Fab_Project_Controls\data\areas.csv'               WITH (FORMAT = 'CSV', FIRSTROW = 2);
BULK INSERT suppliers           FROM 'C:\PersonalProjects\Sonoran_Fab_Project_Controls\data\suppliers.csv'           WITH (FORMAT = 'CSV', FIRSTROW = 2);
BULK INSERT purchase_orders     FROM 'C:\PersonalProjects\Sonoran_Fab_Project_Controls\data\purchase_orders.csv'     WITH (FORMAT = 'CSV', FIRSTROW = 2);
BULK INSERT schedule_activities FROM 'C:\PersonalProjects\Sonoran_Fab_Project_Controls\data\schedule_activities.csv' WITH (FORMAT = 'CSV', FIRSTROW = 2);
BULK INSERT weekly_cost         FROM 'C:\PersonalProjects\Sonoran_Fab_Project_Controls\data\weekly_cost.csv'         WITH (FORMAT = 'CSV', FIRSTROW = 2);
GO

SELECT 'areas' AS table_name, COUNT(*) AS row_count FROM areas
UNION ALL SELECT 'suppliers', COUNT(*) FROM suppliers
UNION ALL SELECT 'purchase_orders', COUNT(*) FROM purchase_orders
UNION ALL SELECT 'schedule_activities', COUNT(*) FROM schedule_activities
UNION ALL SELECT 'weekly_cost', COUNT(*) FROM weekly_cost;
