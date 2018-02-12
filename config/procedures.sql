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

/*Create Dashboard Tables from excel data*/
DELIMITER //
CREATE OR REPLACE PROCEDURE proc_create_dsh_tables_excel()
BEGIN
    SET @@foreign_key_checks = 0;
    /*National MOS*/
    TRUNCATE dsh_mos;
    INSERT INTO dsh_mos(facility_mos, cms_mos, supplier_mos, data_year, data_month, data_date, drug)
    SELECT 
        IFNULL(ROUND(SUM(fs.total)/fn_get_national_amc(k.drug_id, DATE_FORMAT(str_to_date(CONCAT(k.period_year,k.period_month),'%Y%b%d'),'%Y-%m-01') ),1),0) AS facility_mos,
        IFNULL(ROUND(k.soh_total/fn_get_national_amc(k.drug_id, DATE_FORMAT(str_to_date(CONCAT(k.period_year,k.period_month),'%Y%b%d'),'%Y-%m-01') ),1),0) AS cms_mos,
        IFNULL(ROUND(k.supplier_total/fn_get_national_amc(k.drug_id, DATE_FORMAT(str_to_date(CONCAT(k.period_year,k.period_month),'%Y%b%d'),'%Y-%m-01')),1),0) AS supplier_mos,
        k.period_year,
        k.period_month,
        STR_TO_DATE(CONCAT_WS('-', k.period_year, k.period_month, '01'),'%Y-%b-%d') AS data_date,
        d.name
    FROM tbl_kemsa k
    INNER JOIN tbl_stock fs ON fs.drug_id = k.drug_id AND fs.period_month = k.period_month AND fs.period_year = k.period_year
    INNER JOIN vw_drug_list d ON d.id = k.drug_id
    GROUP BY d.name, k.period_month, k.period_year;
    /*Facility Consumption*/
    TRUNCATE dsh_consumption;
    INSERT INTO dsh_consumption(total, data_year, data_month, data_date, sub_county, county, facility, drug)
    SELECT 
        SUM(cf.total) AS total,
        cf.period_year AS data_year,
        cf.period_month AS data_month,
        STR_TO_DATE(CONCAT_WS('-', cf.period_year, cf.period_month, '01'),'%Y-%b-%d') AS data_date,
        cs.name AS sub_county,
        c.name AS county,
        f.name AS facility,
        d.name AS drug
    FROM tbl_consumption cf 
    INNER JOIN vw_drug_list d ON cf.drug_id = d.id
    INNER JOIN tbl_facility f ON cf.facility_id = f.id
    INNER JOIN tbl_subcounty cs ON cs.id = f.subcounty_id
    INNER JOIN tbl_county c ON c.id = cs.county_id
    GROUP by drug,facility,county,sub_county,data_month,data_year;
    /*Facility Patients*/
    TRUNCATE dsh_patient;
    INSERT INTO dsh_patient(total, data_year, data_month, data_date, sub_county, county, facility, partner, regimen, age_category, regimen_service, regimen_line, nnrti_drug, nrti_drug, regimen_category)
    SELECT
        SUM(rp.total) AS total,
        rp.period_year AS data_year,
        rp.period_month AS data_month,
        STR_TO_DATE(CONCAT_WS('-', rp.period_year, rp.period_month, '01'),'%Y-%b-%d') AS data_date,
        cs.name AS sub_county,
        c.name AS county,
        f.name AS facility,
        p.name AS partner,
        CONCAT_WS(' | ', r.code, r.name) AS regimen,
        CASE 
            WHEN ct.name LIKE '%adult%' OR ct.name LIKE '%mother%' THEN 'adult' 
            WHEN ct.name LIKE '%paediatric%' OR ct.name  LIKE '%child%' THEN 'paed'
            ELSE NULL
        END AS age_category,
        s.name AS regimen_service,
        l.name AS regimen_line,
        nn.name AS nnrti_drug,
        n.name AS nrti_drug,
        ct.name AS regimen_category
    FROM tbl_patient rp
    INNER JOIN tbl_regimen r ON rp.regimen_id = r.id
    INNER JOIN tbl_service s ON s.id = r.service_id
    INNER JOIN tbl_line l ON l.id = r.line_id
    INNER JOIN tbl_category ct ON ct.id = r.category_id
    LEFT JOIN tbl_nrti n ON n.regimen_id = r.id
    LEFT JOIN tbl_nnrti nn ON nn.regimen_id = r.id
    INNER JOIN tbl_facility f ON rp.facility_id = f.id
    LEFT JOIN tbl_partner p ON p.id = f.partner_id
    INNER JOIN tbl_subcounty cs ON cs.id = f.subcounty_id
    INNER JOIN tbl_county c ON c.id = cs.county_id
    GROUP by regimen_category,nrti_drug,nnrti_drug,regimen_line,regimen_service,age_category,regimen,facility,county,sub_county,data_month,data_year;
    /*ADT Sites*/
    TRUNCATE dsh_site;
    INSERT INTO dsh_site(facility, county, subcounty, partner, installed, version, internet, active_patients, coordinator, backup)
    SELECT 
        f.name facility,
        c.name county,
        sb.name subcounty,
        p.name partner,
        IF(i.id IS NOT NULL, 'yes', 'no') installed,
        i.version,
        IF(i.is_internet = 1, 'yes', 'no') internet,
        i.active_patients,
        u.name coordinator,
        IF(b.id IS NOT NULL, 'yes', 'no') backup
    FROM tbl_facility f 
    INNER JOIN tbl_subcounty sb ON sb.id = f.subcounty_id
    INNER JOIN tbl_county c ON c.id = sb.county_id
    INNER JOIN tbl_partner p ON p.id = f.partner_id
    LEFT JOIN tbl_install i ON f.id = i.facility_id
    LEFT JOIN tbl_backup b ON b.facility_id = f.id
    LEFT JOIN tbl_user u ON u.id = i.user_id
    WHERE f.category LIKE '%central%'
    GROUP BY f.id;
    SET @@foreign_key_checks = 1;
END//
DELIMITER ;