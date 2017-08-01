/*National AMC*/
DELIMITER //
CREATE OR REPLACE FUNCTION fn_get_national_amc(pm_drug_id integer, pm_period_date date) RETURNS INT(10)
    DETERMINISTIC
BEGIN
    DECLARE amc INT(10);

    SELECT (SUM(total)/6) INTO amc 
    FROM tbl_consumption
    WHERE DATE_FORMAT(STR_TO_DATE(CONCAT_WS('-', period_year, period_month), '%Y-%b'), '%Y-%m-01') >= DATE_SUB(pm_period_date, INTERVAL 6 MONTH)
    AND DATE_FORMAT(STR_TO_DATE(CONCAT_WS('-', period_year, period_month), '%Y-%b'), '%Y-%m-01') <= pm_period_date
    AND drug_id = pm_drug_id;

    RETURN (amc);
END//
DELIMITER ;