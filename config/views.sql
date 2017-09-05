/*Drug List*/
CREATE OR REPLACE VIEW vw_drug_list AS
	SELECT
		d.id, IF(g.abbreviation = '', CONCAT_WS(' ', g.name, CONCAT_WS(' ', d.strength, f.name)), CONCAT_WS(') ', CONCAT_WS(' (', g.name, g.abbreviation), CONCAT_WS(' ', d.strength, f.name))) name, d.packsize pack_size
	FROM tbl_drug d
	INNER JOIN tbl_generic g ON g.id = d.generic_id
	INNER JOIN tbl_formulation f ON f.id = d.formulation_id
	ORDER BY id

/*Install List*/
CREATE OR REPLACE VIEW vw_install_list AS
	SELECT 
		f.mflcode, 
		UCASE(f.name) facility_name, 
		UCASE(c.name) county, 
		UCASE(sb.name) subcounty, 
		IF(i.is_internet = 1, 'YES', 'NO') has_internet,
		i.active_patients,
		UCASE(i.contact_name) contact_name,
		REPLACE(i.contact_phone, '254','0') contact_phone,
		UCASE(u.name) assigned_to,
		i.version adt_version,
		IF(b.id IS NOT NULL, 'YES', 'NO') has_backup
	FROM tbl_install i
	INNER JOIN tbl_facility f ON f.id = i.facility_id
	INNER JOIN tbl_subcounty sb ON sb.id = f.subcounty_id
	INNER JOIN tbl_county c ON c.id = sb.county_id
	INNER JOIN tbl_user u ON u.id = i.user_id
	LEFT JOIN tbl_backup b ON b.facility_id = f.id