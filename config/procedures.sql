/*Ordering Facilities*/
DELIMITER //
CREATE OR REPLACE PROCEDURE proc_save_facility(
    IN facility_code VARCHAR(20), 
    IN facility_name VARCHAR(150),
    IN county_name VARCHAR(30)
    )
BEGIN
    DECLARE county,master,subcounty,facility INT DEFAULT NULL;
    SET facility_name = REPLACE(facility_name, "'", "");
    SET facility_code = REPLACE(facility_code, "'", "");
    SET county_name = REPLACE(county_name, "'", "");

    SELECT id INTO facility FROM tbl_facility WHERE UPPER(mflcode) = UPPER(facility_code);
    IF (facility IS NULL) THEN
        SELECT id INTO county FROM tbl_county WHERE LOWER(name) = LOWER(county_name);
        SELECT id INTO subcounty FROM tbl_subcounty WHERE county_id = county LIMIT 1;
        INSERT INTO tbl_facility(name, mflcode, subcounty_id) VALUES(facility_name, facility_code, subcounty);
    END IF;
END//
DELIMITER ;

/*Facility Patients*/
DELIMITER //
CREATE OR REPLACE PROCEDURE proc_save_patient(
    IN facility_code VARCHAR(20), 
    IN regimen_code VARCHAR(6),
    IN patient_total INT(11),
    IN p_month VARCHAR(3),
    IN p_year INT(4)
    )
BEGIN
    DECLARE facility,regimen INT DEFAULT NULL;
    SET facility_code = REPLACE(facility_code, "'", "");
    SET regimen_code = REPLACE(regimen_code, "'", "");

    SELECT id INTO facility FROM tbl_facility WHERE UPPER(mflcode) = UPPER(facility_code);
    SELECT id INTO regimen FROM tbl_regimen WHERE UPPER(code) = UPPER(regimen_code);

    IF NOT EXISTS(SELECT * FROM tbl_patient WHERE period_year = p_year AND period_month = p_month AND regimen_id = regimen AND facility_id = facility) THEN
        INSERT INTO tbl_patient(total, period_year, period_month, regimen_id, facility_id) VALUES(patient_total, p_year, p_month, regimen, facility);
    ELSE
        UPDATE tbl_patient SET total = patient_total WHERE period_year = p_year AND period_month = p_month AND regimen_id = regimen AND facility_id = facility;
    END IF;
END//
DELIMITER ;

/*Facility Consumption*/
DELIMITER //
CREATE OR REPLACE PROCEDURE proc_save_consumption(
    IN facility_code VARCHAR(20),
    IN drug_name VARCHAR(255), 
    IN packsize VARCHAR(20),
    IN p_year INT(4),
    IN p_month VARCHAR(3),
    IN consumption_total INT(11)
    )
BEGIN
    DECLARE facility,drug INT DEFAULT NULL;
    SET facility_code = REPLACE(facility_code, "'", "");
    SET drug_name = REPLACE(drug_name, "'", "");

    SELECT id INTO facility FROM tbl_facility WHERE UPPER(mflcode) = UPPER(facility_code);
    SELECT id INTO drug FROM vw_drug_list WHERE UPPER(name) = UPPER(drug_name) AND UPPER(pack_size) = UPPER(packsize);

    IF NOT EXISTS(SELECT * FROM tbl_consumption WHERE period_year = p_year AND period_month = p_month AND facility_id = facility AND drug_id = drug) THEN
        INSERT INTO tbl_consumption(total, period_year, period_month, facility_id, drug_id) VALUES(consumption_total, p_year, p_month, facility, drug);
    ELSE
        UPDATE tbl_consumption SET total = consumption_total WHERE period_year = p_year AND period_month = p_month AND facility_id = facility AND drug_id = drug; 
    END IF;
END//
DELIMITER ;

/*Facility Stocks*/
DELIMITER //
CREATE OR REPLACE PROCEDURE proc_save_stock(
    IN facility_code VARCHAR(20),
    IN drug_name VARCHAR(255), 
    IN packsize VARCHAR(20),
    IN p_year INT(4),
    IN p_month VARCHAR(3),
    IN soh_total INT(11)
    )
BEGIN
    DECLARE facility,drug INT DEFAULT NULL;
    SET facility_code = REPLACE(facility_code, "'", "");
    SET drug_name = REPLACE(drug_name, "'", "");

    SELECT id INTO facility FROM tbl_facility WHERE UPPER(mflcode) = UPPER(facility_code);
    SELECT id INTO drug FROM vw_drug_list WHERE UPPER(name) = UPPER(drug_name) AND UPPER(pack_size) = UPPER(packsize);

    IF NOT EXISTS(SELECT * FROM tbl_stock WHERE period_year = p_year AND period_month = p_month AND facility_id = facility AND drug_id = drug) THEN
        INSERT INTO tbl_stock(total, period_year, period_month, facility_id, drug_id) VALUES(soh_total, p_year, p_month, facility, drug);
    ELSE
        UPDATE tbl_stock SET total = soh_total WHERE period_year = p_year AND period_month = p_month AND facility_id = facility AND drug_id = drug; 
    END IF;
END//
DELIMITER ;

/*Kemsa Stocks*/
DELIMITER //
CREATE OR REPLACE PROCEDURE proc_save_kemsa(
    IN drug_name VARCHAR(255), 
    IN packsize VARCHAR(20),
    IN p_year INT(4),
    IN p_month VARCHAR(3),
    IN issue INT(11),
    IN soh INT(11),
    IN supplier INT(11),
    IN received INT(11)
    )
BEGIN
    DECLARE drug INT DEFAULT NULL;
    SET drug_name = REPLACE(drug_name, "'", "");

    SELECT id INTO drug FROM vw_drug_list WHERE UPPER(name) = UPPER(drug_name) AND UPPER(pack_size) = UPPER(packsize);

    IF NOT EXISTS(SELECT * FROM tbl_kemsa WHERE period_year = p_year AND period_month = p_month AND drug_id = drug) THEN
        INSERT INTO tbl_kemsa(issue_total, soh_total, supplier_total, received_total, period_year, period_month, drug_id) VALUES(issue, soh, supplier, received, p_year, p_month, drug);
    ELSE
        UPDATE tbl_kemsa SET issue_total = issue, soh_total = soh, supplier_total = supplier, received_total = received WHERE period_year = p_year AND period_month = p_month AND drug_id = drug; 
    END IF;
END//
DELIMITER ;