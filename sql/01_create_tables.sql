CREATE DATABASE SonoranFabControls;
GO
USE SonoranFabControls;
GO

CREATE TABLE project_settings (
    project_name   VARCHAR(100) NOT NULL,
    status_date    DATE         NOT NULL
);
INSERT INTO project_settings VALUES ('Sonoran Fab Project', '2026-09-25');

CREATE TABLE areas (
    area_id        VARCHAR(5)   PRIMARY KEY,
    area_name      VARCHAR(100) NOT NULL,
    area_manager   VARCHAR(100) NOT NULL
);

CREATE TABLE suppliers (
    supplier_id    VARCHAR(5)   PRIMARY KEY,
    supplier_name  VARCHAR(100) NOT NULL,
    category       VARCHAR(50)  NOT NULL
);

CREATE TABLE purchase_orders (
    po_number             VARCHAR(20)   PRIMARY KEY,
    area_id               VARCHAR(5)    NOT NULL REFERENCES areas(area_id),
    supplier_id           VARCHAR(5)    NOT NULL REFERENCES suppliers(supplier_id),
    discipline            VARCHAR(50)   NOT NULL,
    category              VARCHAR(50)   NOT NULL,
    item_description      VARCHAR(100)  NOT NULL,
    quantity              INT           NOT NULL,
    unit_cost             DECIMAL(12,2) NOT NULL,
    total_cost            DECIMAL(14,2) NOT NULL,
    order_date            DATE          NOT NULL,
    need_by_date          DATE          NOT NULL,
    promised_date         DATE          NOT NULL,
    actual_delivery_date  DATE          NULL,
    status                VARCHAR(20)   NOT NULL
);

CREATE TABLE schedule_activities (
    activity_id       VARCHAR(10)   PRIMARY KEY,
    area_id           VARCHAR(5)    NOT NULL REFERENCES areas(area_id),
    discipline        VARCHAR(50)   NOT NULL,
    activity_name     VARCHAR(100)  NOT NULL,
    planned_start     DATE          NOT NULL,
    planned_finish    DATE          NOT NULL,
    actual_start      DATE          NULL,
    actual_finish     DATE          NULL,
    percent_complete  DECIMAL(4,2)  NOT NULL,
    budget_cost       DECIMAL(14,2) NOT NULL
);

CREATE TABLE weekly_cost (
    week_ending            DATE          NOT NULL,
    area_id                VARCHAR(5)    NOT NULL REFERENCES areas(area_id),
    discipline             VARCHAR(50)   NOT NULL,
    budget_at_completion   DECIMAL(14,2) NOT NULL,
    planned_value_cum      DECIMAL(14,2) NOT NULL,
    earned_value_cum       DECIMAL(14,2) NOT NULL,
    actual_cost_cum        DECIMAL(14,2) NOT NULL,
    PRIMARY KEY (week_ending, area_id, discipline)
);
GO
