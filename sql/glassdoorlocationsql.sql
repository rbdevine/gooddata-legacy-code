SELECT * FROM LKP_CITY_FIPS

SELECT * FROM STG_GLASSDOORSALARY; 
SELECT * FROM LKP_FIPS;
SELECT * FROM STG_FIPSMATCH;

SELECT LKP_CITY_FIPS.STATE_COUNTY_FIPS, LKP_CITY_FIPS.CITY_NAME, LKP_CITY_FIPS.STATE_ABBREVIATION, 
SUBSTRING(STG_GLASSDOORSALARY.METRONAME,0,POSITION(', ' IN STG_GLASSDOORSALARY.METRONAME) AS GLASSDOORCITY 


SELECT SUBSTRING(STG_GLASSDOORSALARY.METRONAME,0,POSITION(', ' IN STG_GLASSDOORSALARY.METRONAME)) AS GLASSDOORCITY 
FROM STG_GLASSDOORSALARY

//SELECT * INTO LKP_CITY_FIPS_TMP FROM LKP_CITY_FIPS
//SELECT COUNT(*) FROM LKP_CITY_FIPS_TMP

DROP TABLE LKP_CITY_FIPS
CREATE TABLE IF NOT EXISTS LKP_CITY_FIPS (
        STATE_FIPS VARCHAR(255),
	STATE_ABBREVIATION VARCHAR(255),
	STATE_NAME VARCHAR(255),
	COUNTY_FIPS VARCHAR(255),
	COUNTY_NAME VARCHAR(255),
	STATE_COUNTY_FIPS VARCHAR(255),
	CITY_FIPS VARCHAR(255),
	CITY_NAME VARCHAR(255)	
);

DELETE FROM LKP_CITY_FIPS

INSERT INTO LKP_CITY_FIPS SELECT 
LKP_CITY_FIPS_TMP.STATE_FIPS,
LKP_CITY_FIPS_TMP.STATE_ABBREVIATION,
UPPER(STG_FIPSMATCH."STATE"),
LKP_CITY_FIPS_TMP.COUNTY_FIPS,
LKP_CITY_FIPS_TMP.COUNTY_NAME,
LKP_CITY_FIPS_TMP.STATE_COUNTY_FIPS,
LKP_CITY_FIPS_TMP.CITY_FIPS,
LKP_CITY_FIPS_TMP.CITY_NAME

FROM LKP_CITY_FIPS_TMP

LEFT JOIN STG_FIPSMATCH ON LKP_CITY_FIPS_TMP.STATE_COUNTY_FIPS = STG_FIPSMATCH.AREA_FIPS

SELECT STATE_NAME, STATE_ABBREVIATION FROM LKP_CITY_FIPS WHERE STATE_NAME IS NOT NULL

SELECT "STATE", AREA_FIPS FROM STG_FIPSMATCH  ORDER BY "STATE";
SELECT STATE_ABBREVIATION, STATE_NAME, STATE_COUNTY_FIPS 
FROM LKP_CITY_FIPS WHERE STATE_ABBREVIATION = 'CO' ORDER BY STATE_COUNTY_FIPS

SELECT * FROM LKP_CITY_FIPS WHERE STATE_NAME = NULL

UPDATE LKP_CITY_FIPS SET STATE_NAME = 'ALASKA' WHERE STATE_ABBREVIATION = 'AK'
UPDATE LKP_CITY_FIPS SET STATE_NAME = 'HAWAII' WHERE STATE_ABBREVIATION = 'HI'
UPDATE LKP_CITY_FIPS SET STATE_NAME = 'PUERTO RICO' WHERE STATE_ABBREVIATION = 'PR'
UPDATE LKP_CITY_FIPS SET STATE_NAME = 'VIRGINIA' WHERE STATE_ABBREVIATION = 'VA'

select * from lkp_city_fips where city_name = 'Rio Grande City'

select metroname from stg_glassdoorsalary where metroname like '%City%' and
metroname != 'Salt Lake City, UT' and metroname != 'New York City, NY' and
metroname != 'Oklahoma City, OK' and metroname != 'Atlantic City, NJ' and
metroname != 'Kansas City, MO' and metroname != 'Iowa City, IA' and
metroname != 'Panama City, FL' and metroname != 'Yuba City, CA' and
metroname != 'Johnson City, TN' and metroname != 'Mason City, IA' and
metroname != 'Oil City, PA' and metroname != 'Sioux City, IA' and
metroname != 'Carson City, NV' and metroname != 'Bay City, MI' and
metroname != 'Traverse City, MI' and metroname != 'Morgan City, LA' and 
metroname != 'Lake Havasu City, AZ' and metroname != 'Elizabeth City, NC' and
metroname != 'Morehead City, NC' and metroname != 'Jefferson City, MO' and
metroname != 'Lake City, FL' and metroname != 'Michigan City, IN' and
metroname != 'Rapid City, SD' and metroname != 'Alexander City, AL' and
metroname != 'Ocean City, NJ' and metroname != 'Union City, TN' and
metroname != 'Forest City, NC' and metroname != 'Ponca City, OK' and
metroname != 'Crescent City, CA' and metroname != 'Garden City, KS' and
metroname != 'Forrest City, AR' and metroname != 'Canon City, CO' and
metroname != 'Brigham City, UT' and metroname != 'Garden City, KS' and
metroname != 'Silver City, NM' and metroname != 'Cedar City, UT' and
metroname != 'Elk City, OK' and metroname != 'Yazoo City, MS' and
metroname != 'Bay City, TX' and metroname != 'Heber City, UT' and
metroname != 'Central City, KY' and metroname != 'Dodge City, KS' and
metroname != 'Rio Grande City, TX'
select stg_glassdoorsalary.metroname, stg_glassdoorsalary.cityname, stg_glassdoorsalary.statename,  
lkp_city_fips.city_name, lkp_city_fips.state_name 
--select count(*) 
from stg_glassdoorsalary left join lkp_city_fips on lkp_city_fips.city_name = STG_GLASSDOORSALARY.cityname
where stg_glassdoorsalary.metroname is not null and
--stg_glassdoorsalary.metroname != 'Puerto Rico' and 
--stg_glassdoorsalary.metroname != 'Hawaiian Islands' and
--stg_glassdoorsalary.metroname != 'York-Hanover, PA' and
lkp_city_fips.city_name is null;
select lkp_city_fips.city_name, STATE_NAME, STATE_COUNTY_FIPS 
from lkp_city_fips where STATE_name like '%HAWAII%' order by city_name

--and stg_glassdoorsalary.statename = 'Florida'

select count(*) from stg_glassdoorsalary where metroname is null;

select stg_glassdoorsalary.cityname from stg_glassdoorsalary
UPDATE STG_GLASSDOORSALARY SET metroname = 
--where city_name is null

select * from lkp_city_fips

select stg_glassdoorsalary.metroname, stg_glassdoorsalary.cityname, stg_glassdoorsalary.statename,  
lkp_city_fips.city_name, lkp_city_fips.state_name, lkp_city_fips.state_county_fips
--select count(*) 
from stg_glassdoorsalary left join lkp_city_fips on lkp_city_fips.city_name = STG_GLASSDOORSALARY.cityname

select metroname, statename, cityname from stg_glassdoorsalary 
WHERE CITYNAME LIKE '%HANOVER%'
select lkp_city_fips.city_name, STATE_NAME from lkp_city_fips where city_name like '%POLK%' and state_name like '%PENN%'