/*generate temp tables for fair pay*/
/*
  Create the temporary tables required for generating 
  reports for first-cut at fair pay using glass door salary
  data. Ultimately, we should try to put enough information
  needed into our data warehouse which could be used to
  generate reports in the future. All of this code was
  written under an extreme time crunch. There are many
  hacks done to get around vertica's limitations (such
  as no pivot and minimal support for variables.)
  
  The tables here are temporary because they are specific to
  the hard-coded industry we are checking. Ideally, we could
  make a stored proc that takes industry name, but at time 
  of this writing, did not want to go down that rabbit hole
  because vertica has their own quirky way of handling 
  pseudo stored procedures. Also, I don't think they support
  returning tables.
*/

/*
  TMP_PARAM_CUR_INDUSTRY
  This is something of a hack to set parameters (e.g. min_jobs)
  Could use vertica params by placing a dollarsign{param_name}dollarsign 
  directly in code. I don't like that option because I have to deal with
  a dialog box and could not find a way to suppress that. Also,
  dialog box won't let me just hit the enter key to dismiss.
  I have to actually use my mouse to click on the "Done" button.
  (Tabbing to the button does not work for some reason.)
*/
/*
  Pop the next industry from the queue and store in parameter table.
*/
update TMP_PARAM_CUR_INDUSTRY 
set INDUSTRY = (
  select INDUSTRY 
  from TMP_INDUSTRY_QUEUE 
  order by id 
  limit 1
);

delete from TMP_INDUSTRY_QUEUE 
where id in (
  select ID 
  from TMP_INDUSTRY_QUEUE 
  order by id 
  limit 1
);

/*
  TMP_GD_SALARY_SUMMARY
  
  This a temp table to hold salary info for the specified
  industry. This is used as a base for multiple queries 
  for generating various fair trade reports.
*/

drop table if exists TMP_GD_SALARY_SUMMARY;
create table if not exists TMP_GD_SALARY_SUMMARY (
  JUST_INDY VARCHAR(255) NOT NULL,
  JOB VARCHAR(255) NOT NULL,
  COMPANY VARCHAR(255) NOT NULL,
  TICKER VARCHAR(255) NOT NULL,
  TOTAL INT NOT NULL,
  QUALITY_SCORE FLOAT NOT NULL,
  UNADJUSTED_AVG_BASE_HOURLY FLOAT NULL,
  UNADJUSTED_AVG_TOTAL_HOURLY FLOAT NULL,
  UNADJUSTED_AVG_BASE_HOURLY_COLA FLOAT NULL,
  UNADJUSTED_AVG_TOTAL_HOURLY_COLA FLOAT NULL,
  UNADJUSTED_AVG_BASE FLOAT NULL,
  UNADJUSTED_AVG_TOTAL FLOAT NULL,
  UNADJUSTED_AVG_BASE_COLA FLOAT NULL,
  UNADJUSTED_AVG_TOTAL_COLA FLOAT NULL
);

insert into TMP_GD_SALARY_SUMMARY
select distinct
  just_indy industry, 
  goc job,
  m.co_long_name company,
  s.ticker,
  count(goc) total,
  case
    when count(goc) < max(p.MIN_JOB_COUNT_PER_CO_SCORE_1) then 0.0
    when count(goc) < max(p.MIN_JOB_COUNT_PER_CO_SCORE_2) then 1.0
    when count(goc) < max(p.MIN_JOB_COUNT_PER_CO_SCORE_3) then 2.0
    else 3.0
  end quality_score,
  cast(round(avg(UNADJUSTEDBASEHOURLY),2) as numeric(36,2)) unadjusted_hourly_avg_base,
  cast(round(avg(UNADJUSTEDTOTALHOURLY),2) as numeric(36,2)) unadjusted_hourly_avg_total,
  cast(round(avg(UNADJUSTEDBASEHOURLY_COLA),2) as numeric(36,2)) unadjusted_hourly_avg_base_cola,
  cast(round(avg(UNADJUSTEDTOTALHOURLY_COLA),2) as numeric(36,2)) unadjusted_hourly_avg_total_cola, 
  cast(round(avg(UNADJUSTEDBASESALARY),2) as numeric(36,2)) unadjusted_avg_base,
  cast(round(avg(UNADJUSTEDTOTALSALARY),2) as numeric(36,2)) unadjusted_avg_total,
  cast(round(avg(UNADJUSTEDBASESALARY_COLA),2) as numeric(36,2)) unadjusted_avg_base_cola,
  cast(round(avg(UNADJUSTEDTOTALSALARY_COLA),2) as numeric(36,2)) unadjusted_avg_total_cola  
from LKP_GLASSDOOR_SALARY_DW s
join LKP_JUST_CO_SECTY_MASTER m on s.just_company_id = m.just_co_id
join TMP_PARAM_CUR_INDUSTRY p on s.just_indy = p.industry
where stateabbreviation <> 'PR' and goc is not null
group by just_indy, s.TICKER, m.co_long_name, GOC
having count(goc) >= max(p.MIN_JOB_COUNT_PER_CO_SCORE_1);

/*
  Prune companies and jobs that don't meet minimum criteria
  specified via temp parameters.
  No looping or if statements with vertica, so just iterate
  through say, 5 times. Should do the trick.
*/
delete from TMP_GD_SALARY_SUMMARY where job in (select job from TMP_GD_SALARY_SUMMARY join TMP_PARAM_CUR_INDUSTRY p on true group by job having count(company) < max(p.MIN_CO_PER_JOB));
delete from TMP_GD_SALARY_SUMMARY where company in (select company from TMP_GD_SALARY_SUMMARY join TMP_PARAM_CUR_INDUSTRY p on true group by company having count(job) < max(p.MIN_JOBS_PER_CO));
delete from TMP_GD_SALARY_SUMMARY where job in (select job from TMP_GD_SALARY_SUMMARY join TMP_PARAM_CUR_INDUSTRY p on true group by job having count(company) < max(p.MIN_CO_PER_JOB));
delete from TMP_GD_SALARY_SUMMARY where company in (select company from TMP_GD_SALARY_SUMMARY join TMP_PARAM_CUR_INDUSTRY p on true group by company having count(job) < max(p.MIN_JOBS_PER_CO));
delete from TMP_GD_SALARY_SUMMARY where job in (select job from TMP_GD_SALARY_SUMMARY join TMP_PARAM_CUR_INDUSTRY p on true group by job having count(company) < max(p.MIN_CO_PER_JOB));
delete from TMP_GD_SALARY_SUMMARY where company in (select company from TMP_GD_SALARY_SUMMARY join TMP_PARAM_CUR_INDUSTRY p on true group by company having count(job) < max(p.MIN_JOBS_PER_CO));
delete from TMP_GD_SALARY_SUMMARY where job in (select job from TMP_GD_SALARY_SUMMARY join TMP_PARAM_CUR_INDUSTRY p on true group by job having count(company) < max(p.MIN_CO_PER_JOB));
delete from TMP_GD_SALARY_SUMMARY where company in (select company from TMP_GD_SALARY_SUMMARY join TMP_PARAM_CUR_INDUSTRY p on true group by company having count(job) < max(p.MIN_JOBS_PER_CO));
delete from TMP_GD_SALARY_SUMMARY where job in (select job from TMP_GD_SALARY_SUMMARY join TMP_PARAM_CUR_INDUSTRY p on true group by job having count(company) < max(p.MIN_CO_PER_JOB));
delete from TMP_GD_SALARY_SUMMARY where company in (select company from TMP_GD_SALARY_SUMMARY join TMP_PARAM_CUR_INDUSTRY p on true group by company having count(job) < max(p.MIN_JOBS_PER_CO));


/*
  TMP_JOBS_OF_INTEREST
  
  List of all the jobs in the TMP_GD_SALARY_SUMMARY table.
*/
drop table if exists TMP_JOBS_OF_INTEREST;
create table if not exists TMP_JOBS_OF_INTEREST (
  JOB VARCHAR(255) NOT NULL
);

insert into TMP_JOBS_OF_INTEREST 
select job 
from TMP_GD_SALARY_SUMMARY 
group by job;

/*
  TMP_GD_COMPANIES_OF_INTEREST
   
  List of all companies that have records in TMP_GD_SALARY_SUMMARY table.
  This is used as a base for the hack for creating a header row. Id is used
  to identify the column. id is ordered 1-n, alphabetical by company name.
*/
drop table if exists TMP_GD_COMPANIES_OF_INTEREST;
create table if not exists TMP_GD_COMPANIES_OF_INTEREST (
  ID INT PRIMARY KEY,
  COMPANY VARCHAR(255) NOT NULL
);

insert into TMP_GD_COMPANIES_OF_INTEREST (id, company)
select rank() over (order by jobCnt desc, company) id, company from (
  select company, count(job) jobCnt
  from TMP_GD_SALARY_SUMMARY
  where quality_score > 0
  group by company
) t;

/*
  TMP_COMPANY_JOB_TOTALS
  
  Job totals per company, includes id and company name. Again, needed
  for simplyfying the header row issue.
*/
drop table if exists TMP_COMPANY_JOB_TOTALS;
create table if not exists TMP_COMPANY_JOB_TOTALS (
  TMP_COMPANY_ID INT NOT NULL,
  COMPANY VARCHAR(255) NOT NULL,
  JOB VARCHAR(255) NOT NULL, 
  RATE FLOAT NULL,
  SCORE INT NULL,
  RATE_RAW FLOAT NULL,
  SCORE_RAW INT NULL,
  TOTAL INT NULL
);

insert into TMP_COMPANY_JOB_TOTALS 
select c.id, c.company, s.job, s.unadjusted_avg_base_hourly_cola, r.raterank, s.unadjusted_avg_base_hourly, r.raterank_raw, s.total 
from TMP_GD_COMPANIES_OF_INTEREST c
join TMP_GD_SALARY_SUMMARY s on s.company = c.company
join (
  select 
    rank() over (partition by job order by unadjusted_avg_base_hourly_cola desc) raterank, 
    rank() over (partition by job order by unadjusted_avg_base_hourly desc) raterank_raw, 
    company,
    job
  from TMP_GD_SALARY_SUMMARY
) r on s.company = r.company and r.job = s.job;

/*
  Insert header into LKP_FAIRPAY_JOB_COMPANY_MATRIX
*/
insert into LKP_FAIRPAY_JOB_COMPANY_MATRIX
select 
  p.industry, 
  0 display_order, 
  0 value_type, 
  'Job' job,
  null just_co_id,
  null company_value,
  h.*,
  null company_job_score,
  null job_company_countc,
  null company_salary_count
from (
  select * 
  from (
    select company c1 from TMP_GD_COMPANIES_OF_INTEREST where id = 1 limit 1
  ) c1 
  left join (
    select company c2 from TMP_GD_COMPANIES_OF_INTEREST where id = 2 limit 1
  ) c2 on true 
  left join (
    select company c3 from TMP_GD_COMPANIES_OF_INTEREST where id = 3 limit 1
  ) c3 on true
  left join (
    select company c4 from TMP_GD_COMPANIES_OF_INTEREST where id = 4 limit 1
  ) c4 on true
  left join (
    select company c5 from TMP_GD_COMPANIES_OF_INTEREST where id = 5 limit 1
  ) c5 on true
  left join ( 
    select company c6 from TMP_GD_COMPANIES_OF_INTEREST where id = 6 limit 1
  ) c6 on true 
  left join (
    select company c7 from TMP_GD_COMPANIES_OF_INTEREST where id = 7 limit 1
  ) c7 on true 
  left join (
    select company c8 from TMP_GD_COMPANIES_OF_INTEREST where id = 8 limit 1
  ) c8 on true
  left join (
    select company c9 from TMP_GD_COMPANIES_OF_INTEREST where id = 9 limit 1
  ) c9 on true
  left join (
    select company c10 from TMP_GD_COMPANIES_OF_INTEREST where id = 10 limit 1
  ) c10 on true
  left join ( 
    select company c11 from TMP_GD_COMPANIES_OF_INTEREST where id = 11 limit 1
  ) c11 on true 
  left join (
    select company c12 from TMP_GD_COMPANIES_OF_INTEREST where id = 12 limit 1
  ) c12 on true 
  left join (
    select company c13 from TMP_GD_COMPANIES_OF_INTEREST where id = 13 limit 1
  ) c13 on true
  left join (
    select company c14 from TMP_GD_COMPANIES_OF_INTEREST where id = 14 limit 1
  ) c14 on true
  left join (
    select company c15 from TMP_GD_COMPANIES_OF_INTEREST where id = 15 limit 1
  ) c15 on true
  left join ( 
    select company c16 from TMP_GD_COMPANIES_OF_INTEREST where id = 16 limit 1
  ) c16 on true 
  left join (
    select company c17 from TMP_GD_COMPANIES_OF_INTEREST where id = 17 limit 1
  ) c17 on true 
  left join (
    select company c18 from TMP_GD_COMPANIES_OF_INTEREST where id = 18 limit 1
  ) c18 on true
  left join (
    select company c19 from TMP_GD_COMPANIES_OF_INTEREST where id = 19 limit 1
  ) c19 on true
  left join (
    select company c20 from TMP_GD_COMPANIES_OF_INTEREST where id = 20 limit 1
  ) c20 on true
  left join ( 
    select company c21 from TMP_GD_COMPANIES_OF_INTEREST where id = 21 limit 1
  ) c21 on true 
  left join (
    select company c22 from TMP_GD_COMPANIES_OF_INTEREST where id = 22 limit 1
  ) c22 on true 
  left join (
    select company c23 from TMP_GD_COMPANIES_OF_INTEREST where id = 23 limit 1
  ) c23 on true
  left join (
    select company c24 from TMP_GD_COMPANIES_OF_INTEREST where id = 24 limit 1
  ) c24 on true
  left join (
    select company c25 from TMP_GD_COMPANIES_OF_INTEREST where id = 25 limit 1
  ) c25 on true
  left join ( 
    select company c26 from TMP_GD_COMPANIES_OF_INTEREST where id = 26 limit 1
  ) c26 on true 
  left join (
    select company c27 from TMP_GD_COMPANIES_OF_INTEREST where id = 27 limit 1
  ) c27 on true 
  left join (
    select company c28 from TMP_GD_COMPANIES_OF_INTEREST where id = 28 limit 1
  ) c28 on true
  left join (
    select company c29 from TMP_GD_COMPANIES_OF_INTEREST where id = 29 limit 1
  ) c29 on true
  left join (
        select company c30 from TMP_GD_COMPANIES_OF_INTEREST where id = 30 limit 1
  ) c30 on true
  left join ( 
        select company c31 from TMP_GD_COMPANIES_OF_INTEREST where id = 31 limit 1
  ) c31 on true 
  left join (
        select company c32 from TMP_GD_COMPANIES_OF_INTEREST where id = 32 limit 1
  ) c32 on true 
  left join (
    select company c33 from TMP_GD_COMPANIES_OF_INTEREST where id = 33 limit 1
  ) c33 on true
  left join (
    select company c34 from TMP_GD_COMPANIES_OF_INTEREST where id = 34 limit 1
  ) c34 on true
  left join (
    select company c35 from TMP_GD_COMPANIES_OF_INTEREST where id = 35 limit 1
  ) c35 on true
  left join ( 
    select company c36 from TMP_GD_COMPANIES_OF_INTEREST where id = 36 limit 1
  ) c36 on true 
  left join (
    select company c37 from TMP_GD_COMPANIES_OF_INTEREST where id = 37 limit 1
  ) c37 on true 
  left join (
    select company c38 from TMP_GD_COMPANIES_OF_INTEREST where id = 38 limit 1
  ) c38 on true
  left join (
    select company c39 from TMP_GD_COMPANIES_OF_INTEREST where id = 39 limit 1
  ) c39 on true
  left join (
    select company c40 from TMP_GD_COMPANIES_OF_INTEREST where id = 40 limit 1
  ) c40 on true
  left join ( 
    select company c41 from TMP_GD_COMPANIES_OF_INTEREST where id = 41 limit 1
  ) c41 on true 
  left join (
    select company c42 from TMP_GD_COMPANIES_OF_INTEREST where id = 42 limit 1
  ) c42 on true 
  left join (
    select company c43 from TMP_GD_COMPANIES_OF_INTEREST where id = 43 limit 1
  ) c43 on true
  left join (
    select company c44 from TMP_GD_COMPANIES_OF_INTEREST where id = 44 limit 1
  ) c44 on true
  left join (
    select company c45 from TMP_GD_COMPANIES_OF_INTEREST where id = 45 limit 1
  ) c45 on true
  left join ( 
    select company c46 from TMP_GD_COMPANIES_OF_INTEREST where id = 46 limit 1
  ) c46 on true 
  left join (
    select company c47 from TMP_GD_COMPANIES_OF_INTEREST where id = 47 limit 1
  ) c47 on true 
  left join (
    select company c48 from TMP_GD_COMPANIES_OF_INTEREST where id = 48 limit 1
  ) c48 on true
  left join (
    select company c49 from TMP_GD_COMPANIES_OF_INTEREST where id = 49 limit 1
  ) c49 on true
  left join (
    select company c50 from TMP_GD_COMPANIES_OF_INTEREST where id = 50 limit 1
  ) c50 on true 
) h 
join TMP_PARAM_CUR_INDUSTRY p on true;

/*
  Insert data into LKP_FAIRPAY_JOB_COMPANY_MATRIX
  
  Jobs listed in rows 2-n
  Companies listed in first row, corresponding to c1-c50
  Note: If less than 50 companies, columns will be null
  If we ever a case where an industry has more that 50 companies with relevant data, 
  we will need to add columns
*/

/*
  unadjusted hourly cola
*/
insert into LKP_FAIRPAY_JOB_COMPANY_MATRIX
select distinct
  p.industry,
  1 display_order,
  1 value_type,
  j.job,
  null just_co_id,
  null company_value,
  max(c1.rate) c1, 
  max(c2.rate) c2, 
  max(c3.rate) c3, 
  max(c4.rate) c4, 
  max(c5.rate) c5, 
  max(c6.rate) c6, 
  max(c7.rate) c7, 
  max(c8.rate) c8, 
  max(c9.rate) c9, 
  max(c10.rate) c10,
  max(c11.rate) c11, 
  max(c12.rate) c12, 
  max(c13.rate) c13, 
  max(c14.rate) c14, 
  max(c15.rate) c15, 
  max(c16.rate) c16, 
  max(c17.rate) c17, 
  max(c18.rate) c18, 
  max(c19.rate) c19, 
  max(c20.rate) c20,
  max(c21.rate) c21, 
  max(c22.rate) c22, 
  max(c23.rate) c23, 
  max(c24.rate) c24, 
  max(c25.rate) c25, 
  max(c26.rate) c26, 
  max(c27.rate) c27, 
  max(c28.rate) c28, 
  max(c29.rate) c29, 
  max(c30.rate) c30,
  max(c31.rate) c31, 
  max(c32.rate) c32, 
  max(c33.rate) c33, 
  max(c34.rate) c34, 
  max(c35.rate) c35, 
  max(c36.rate) c36, 
  max(c37.rate) c37, 
  max(c38.rate) c38, 
  max(c39.rate) c39, 
  max(c40.rate) c40,
  max(c41.rate) c41, 
  max(c42.rate) c42, 
  max(c43.rate) c43, 
  max(c44.rate) c44, 
  max(c45.rate) c45, 
  max(c46.rate) c46, 
  max(c47.rate) c47, 
  max(c48.rate) c48, 
  max(c49.rate) c49, 
  max(c50.rate) c50,
  null company_job_score,
  null job_company_count,
  null company_salary_count
from TMP_JOBS_OF_INTEREST j
join TMP_GD_SALARY_SUMMARY s on j.job = s.job
join TMP_PARAM_CUR_INDUSTRY p on true
left join TMP_COMPANY_JOB_TOTALS c1 on c1.tmp_company_id = 1 and c1.company = s.company and c1.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c2 on c2.tmp_company_id = 2 and c2.company = s.company and c2.job = j.job
left join TMP_COMPANY_JOB_TOTALS c3 on c3.tmp_company_id = 3 and c3.company = s.company and c3.job = j.job
left join TMP_COMPANY_JOB_TOTALS c4 on c4.tmp_company_id = 4 and c4.company = s.company and c4.job = j.job
left join TMP_COMPANY_JOB_TOTALS c5 on c5.tmp_company_id = 5 and c5.company = s.company and c5.job = j.job
left join TMP_COMPANY_JOB_TOTALS c6 on c6.tmp_company_id = 6 and c6.company = s.company and c6.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c7 on c7.tmp_company_id = 7 and c7.company = s.company and c7.job = j.job
left join TMP_COMPANY_JOB_TOTALS c8 on c8.tmp_company_id = 8 and c8.company = s.company and c8.job = j.job
left join TMP_COMPANY_JOB_TOTALS c9 on c9.tmp_company_id = 9 and c9.company = s.company and c9.job = j.job
left join TMP_COMPANY_JOB_TOTALS c10 on c10.tmp_company_id = 10 and c10.company = s.company and c10.job = j.job
left join TMP_COMPANY_JOB_TOTALS c11 on c11.tmp_company_id = 11 and c11.company = s.company and c11.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c12 on c12.tmp_company_id = 12 and c12.company = s.company and c12.job = j.job
left join TMP_COMPANY_JOB_TOTALS c13 on c13.tmp_company_id = 13 and c13.company = s.company and c13.job = j.job
left join TMP_COMPANY_JOB_TOTALS c14 on c14.tmp_company_id = 14 and c14.company = s.company and c14.job = j.job
left join TMP_COMPANY_JOB_TOTALS c15 on c15.tmp_company_id = 15 and c15.company = s.company and c15.job = j.job
left join TMP_COMPANY_JOB_TOTALS c16 on c16.tmp_company_id = 16 and c16.company = s.company and c16.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c17 on c17.tmp_company_id = 17 and c17.company = s.company and c17.job = j.job
left join TMP_COMPANY_JOB_TOTALS c18 on c18.tmp_company_id = 18 and c18.company = s.company and c18.job = j.job
left join TMP_COMPANY_JOB_TOTALS c19 on c19.tmp_company_id = 19 and c19.company = s.company and c19.job = j.job
left join TMP_COMPANY_JOB_TOTALS c20 on c20.tmp_company_id = 20 and c20.company = s.company and c20.job = j.job
left join TMP_COMPANY_JOB_TOTALS c21 on c21.tmp_company_id = 21 and c21.company = s.company and c21.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c22 on c22.tmp_company_id = 22 and c22.company = s.company and c22.job = j.job
left join TMP_COMPANY_JOB_TOTALS c23 on c23.tmp_company_id = 23 and c23.company = s.company and c23.job = j.job
left join TMP_COMPANY_JOB_TOTALS c24 on c24.tmp_company_id = 24 and c24.company = s.company and c24.job = j.job
left join TMP_COMPANY_JOB_TOTALS c25 on c25.tmp_company_id = 25 and c25.company = s.company and c25.job = j.job
left join TMP_COMPANY_JOB_TOTALS c26 on c26.tmp_company_id = 26 and c26.company = s.company and c26.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c27 on c27.tmp_company_id = 27 and c27.company = s.company and c27.job = j.job
left join TMP_COMPANY_JOB_TOTALS c28 on c28.tmp_company_id = 28 and c28.company = s.company and c28.job = j.job
left join TMP_COMPANY_JOB_TOTALS c29 on c29.tmp_company_id = 29 and c29.company = s.company and c29.job = j.job
left join TMP_COMPANY_JOB_TOTALS c30 on c30.tmp_company_id = 30 and c30.company = s.company and c30.job = j.job
left join TMP_COMPANY_JOB_TOTALS c31 on c31.tmp_company_id = 31 and c31.company = s.company and c31.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c32 on c32.tmp_company_id = 32 and c32.company = s.company and c32.job = j.job
left join TMP_COMPANY_JOB_TOTALS c33 on c33.tmp_company_id = 33 and c33.company = s.company and c33.job = j.job
left join TMP_COMPANY_JOB_TOTALS c34 on c34.tmp_company_id = 34 and c34.company = s.company and c34.job = j.job
left join TMP_COMPANY_JOB_TOTALS c35 on c35.tmp_company_id = 35 and c35.company = s.company and c35.job = j.job
left join TMP_COMPANY_JOB_TOTALS c36 on c36.tmp_company_id = 36 and c36.company = s.company and c36.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c37 on c37.tmp_company_id = 37 and c37.company = s.company and c37.job = j.job
left join TMP_COMPANY_JOB_TOTALS c38 on c38.tmp_company_id = 38 and c38.company = s.company and c38.job = j.job
left join TMP_COMPANY_JOB_TOTALS c39 on c39.tmp_company_id = 39 and c39.company = s.company and c39.job = j.job
left join TMP_COMPANY_JOB_TOTALS c40 on c40.tmp_company_id = 40 and c40.company = s.company and c40.job = j.job
left join TMP_COMPANY_JOB_TOTALS c41 on c41.tmp_company_id = 41 and c41.company = s.company and c41.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c42 on c42.tmp_company_id = 42 and c42.company = s.company and c42.job = j.job
left join TMP_COMPANY_JOB_TOTALS c43 on c43.tmp_company_id = 43 and c43.company = s.company and c43.job = j.job
left join TMP_COMPANY_JOB_TOTALS c44 on c44.tmp_company_id = 44 and c44.company = s.company and c44.job = j.job
left join TMP_COMPANY_JOB_TOTALS c45 on c45.tmp_company_id = 45 and c45.company = s.company and c45.job = j.job
left join TMP_COMPANY_JOB_TOTALS c46 on c46.tmp_company_id = 46 and c46.company = s.company and c46.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c47 on c47.tmp_company_id = 47 and c47.company = s.company and c47.job = j.job
left join TMP_COMPANY_JOB_TOTALS c48 on c48.tmp_company_id = 48 and c48.company = s.company and c48.job = j.job
left join TMP_COMPANY_JOB_TOTALS c49 on c49.tmp_company_id = 49 and c49.company = s.company and c49.job = j.job
left join TMP_COMPANY_JOB_TOTALS c50 on c50.tmp_company_id = 50 and c50.company = s.company and c50.job = j.job
group by p.industry, j.job
order by job;

/*
  hourly cola score
*/
insert into LKP_FAIRPAY_JOB_COMPANY_MATRIX
select distinct
  p.industry,
  1 display_order,
  2 value_type,
  j.job,
  null just_co_id,
  null company_value,
  max(c1.score) c1, 
  max(c2.score) c2, 
  max(c3.score) c3, 
  max(c4.score) c4, 
  max(c5.score) c5, 
  max(c6.score) c6, 
  max(c7.score) c7, 
  max(c8.score) c8, 
  max(c9.score) c9, 
  max(c10.score) c10,
  max(c11.score) c11, 
  max(c12.score) c12, 
  max(c13.score) c13, 
  max(c14.score) c14, 
  max(c15.score) c15, 
  max(c16.score) c16, 
  max(c17.score) c17, 
  max(c18.score) c18, 
  max(c19.score) c19, 
  max(c20.score) c20,
  max(c21.score) c21, 
  max(c22.score) c22, 
  max(c23.score) c23, 
  max(c24.score) c24, 
  max(c25.score) c25, 
  max(c26.score) c26, 
  max(c27.score) c27, 
  max(c28.score) c28, 
  max(c29.score) c29, 
  max(c30.score) c30,
  max(c31.score) c31, 
  max(c32.score) c32, 
  max(c33.score) c33, 
  max(c34.score) c34, 
  max(c35.score) c35, 
  max(c36.score) c36, 
  max(c37.score) c37, 
  max(c38.score) c38, 
  max(c39.score) c39, 
  max(c40.score) c40,
  max(c41.score) c41, 
  max(c42.score) c42, 
  max(c43.score) c43, 
  max(c44.score) c44, 
  max(c45.score) c45, 
  max(c46.score) c46, 
  max(c47.score) c47, 
  max(c48.score) c48, 
  max(c49.score) c49, 
  max(c50.score) c50,
  null company_job_score,
  null job_company_count,
  null company_salary_count
from TMP_JOBS_OF_INTEREST j
join TMP_GD_SALARY_SUMMARY s on j.job = s.job
join TMP_PARAM_CUR_INDUSTRY p on true
left join TMP_COMPANY_JOB_TOTALS c1 on c1.tmp_company_id = 1 and c1.company = s.company and c1.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c2 on c2.tmp_company_id = 2 and c2.company = s.company and c2.job = j.job
left join TMP_COMPANY_JOB_TOTALS c3 on c3.tmp_company_id = 3 and c3.company = s.company and c3.job = j.job
left join TMP_COMPANY_JOB_TOTALS c4 on c4.tmp_company_id = 4 and c4.company = s.company and c4.job = j.job
left join TMP_COMPANY_JOB_TOTALS c5 on c5.tmp_company_id = 5 and c5.company = s.company and c5.job = j.job
left join TMP_COMPANY_JOB_TOTALS c6 on c6.tmp_company_id = 6 and c6.company = s.company and c6.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c7 on c7.tmp_company_id = 7 and c7.company = s.company and c7.job = j.job
left join TMP_COMPANY_JOB_TOTALS c8 on c8.tmp_company_id = 8 and c8.company = s.company and c8.job = j.job
left join TMP_COMPANY_JOB_TOTALS c9 on c9.tmp_company_id = 9 and c9.company = s.company and c9.job = j.job
left join TMP_COMPANY_JOB_TOTALS c10 on c10.tmp_company_id = 10 and c10.company = s.company and c10.job = j.job
left join TMP_COMPANY_JOB_TOTALS c11 on c11.tmp_company_id = 11 and c11.company = s.company and c11.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c12 on c12.tmp_company_id = 12 and c12.company = s.company and c12.job = j.job
left join TMP_COMPANY_JOB_TOTALS c13 on c13.tmp_company_id = 13 and c13.company = s.company and c13.job = j.job
left join TMP_COMPANY_JOB_TOTALS c14 on c14.tmp_company_id = 14 and c14.company = s.company and c14.job = j.job
left join TMP_COMPANY_JOB_TOTALS c15 on c15.tmp_company_id = 15 and c15.company = s.company and c15.job = j.job
left join TMP_COMPANY_JOB_TOTALS c16 on c16.tmp_company_id = 16 and c16.company = s.company and c16.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c17 on c17.tmp_company_id = 17 and c17.company = s.company and c17.job = j.job
left join TMP_COMPANY_JOB_TOTALS c18 on c18.tmp_company_id = 18 and c18.company = s.company and c18.job = j.job
left join TMP_COMPANY_JOB_TOTALS c19 on c19.tmp_company_id = 19 and c19.company = s.company and c19.job = j.job
left join TMP_COMPANY_JOB_TOTALS c20 on c20.tmp_company_id = 20 and c20.company = s.company and c20.job = j.job
left join TMP_COMPANY_JOB_TOTALS c21 on c21.tmp_company_id = 21 and c21.company = s.company and c21.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c22 on c22.tmp_company_id = 22 and c22.company = s.company and c22.job = j.job
left join TMP_COMPANY_JOB_TOTALS c23 on c23.tmp_company_id = 23 and c23.company = s.company and c23.job = j.job
left join TMP_COMPANY_JOB_TOTALS c24 on c24.tmp_company_id = 24 and c24.company = s.company and c24.job = j.job
left join TMP_COMPANY_JOB_TOTALS c25 on c25.tmp_company_id = 25 and c25.company = s.company and c25.job = j.job
left join TMP_COMPANY_JOB_TOTALS c26 on c26.tmp_company_id = 26 and c26.company = s.company and c26.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c27 on c27.tmp_company_id = 27 and c27.company = s.company and c27.job = j.job
left join TMP_COMPANY_JOB_TOTALS c28 on c28.tmp_company_id = 28 and c28.company = s.company and c28.job = j.job
left join TMP_COMPANY_JOB_TOTALS c29 on c29.tmp_company_id = 29 and c29.company = s.company and c29.job = j.job
left join TMP_COMPANY_JOB_TOTALS c30 on c30.tmp_company_id = 30 and c30.company = s.company and c30.job = j.job
left join TMP_COMPANY_JOB_TOTALS c31 on c31.tmp_company_id = 31 and c31.company = s.company and c31.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c32 on c32.tmp_company_id = 32 and c32.company = s.company and c32.job = j.job
left join TMP_COMPANY_JOB_TOTALS c33 on c33.tmp_company_id = 33 and c33.company = s.company and c33.job = j.job
left join TMP_COMPANY_JOB_TOTALS c34 on c34.tmp_company_id = 34 and c34.company = s.company and c34.job = j.job
left join TMP_COMPANY_JOB_TOTALS c35 on c35.tmp_company_id = 35 and c35.company = s.company and c35.job = j.job
left join TMP_COMPANY_JOB_TOTALS c36 on c36.tmp_company_id = 36 and c36.company = s.company and c36.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c37 on c37.tmp_company_id = 37 and c37.company = s.company and c37.job = j.job
left join TMP_COMPANY_JOB_TOTALS c38 on c38.tmp_company_id = 38 and c38.company = s.company and c38.job = j.job
left join TMP_COMPANY_JOB_TOTALS c39 on c39.tmp_company_id = 39 and c39.company = s.company and c39.job = j.job
left join TMP_COMPANY_JOB_TOTALS c40 on c40.tmp_company_id = 40 and c40.company = s.company and c40.job = j.job
left join TMP_COMPANY_JOB_TOTALS c41 on c41.tmp_company_id = 41 and c41.company = s.company and c41.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c42 on c42.tmp_company_id = 42 and c42.company = s.company and c42.job = j.job
left join TMP_COMPANY_JOB_TOTALS c43 on c43.tmp_company_id = 43 and c43.company = s.company and c43.job = j.job
left join TMP_COMPANY_JOB_TOTALS c44 on c44.tmp_company_id = 44 and c44.company = s.company and c44.job = j.job
left join TMP_COMPANY_JOB_TOTALS c45 on c45.tmp_company_id = 45 and c45.company = s.company and c45.job = j.job
left join TMP_COMPANY_JOB_TOTALS c46 on c46.tmp_company_id = 46 and c46.company = s.company and c46.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c47 on c47.tmp_company_id = 47 and c47.company = s.company and c47.job = j.job
left join TMP_COMPANY_JOB_TOTALS c48 on c48.tmp_company_id = 48 and c48.company = s.company and c48.job = j.job
left join TMP_COMPANY_JOB_TOTALS c49 on c49.tmp_company_id = 49 and c49.company = s.company and c49.job = j.job
left join TMP_COMPANY_JOB_TOTALS c50 on c50.tmp_company_id = 50 and c50.company = s.company and c50.job = j.job
group by p.industry, j.job
order by job;

/*
  total rate raw
*/
insert into LKP_FAIRPAY_JOB_COMPANY_MATRIX
select distinct
  p.industry,
  1 display_order,
  3 value_type,
  j.job,
  null just_co_id,
  null company_value,
  max(c1.rate_raw) c1, 
  max(c2.rate_raw) c2, 
  max(c3.rate_raw) c3, 
  max(c4.rate_raw) c4, 
  max(c5.rate_raw) c5, 
  max(c6.rate_raw) c6, 
  max(c7.rate_raw) c7, 
  max(c8.rate_raw) c8, 
  max(c9.rate_raw) c9, 
  max(c10.rate_raw) c10,
  max(c11.rate_raw) c11, 
  max(c12.rate_raw) c12, 
  max(c13.rate_raw) c13, 
  max(c14.rate_raw) c14, 
  max(c15.rate_raw) c15, 
  max(c16.rate_raw) c16, 
  max(c17.rate_raw) c17, 
  max(c18.rate_raw) c18, 
  max(c19.rate_raw) c19, 
  max(c20.rate_raw) c20,
  max(c21.rate_raw) c21, 
  max(c22.rate_raw) c22, 
  max(c23.rate_raw) c23, 
  max(c24.rate_raw) c24, 
  max(c25.rate_raw) c25, 
  max(c26.rate_raw) c26, 
  max(c27.rate_raw) c27, 
  max(c28.rate_raw) c28, 
  max(c29.rate_raw) c29, 
  max(c30.rate_raw) c30,
  max(c31.rate_raw) c31, 
  max(c32.rate_raw) c32, 
  max(c33.rate_raw) c33, 
  max(c34.rate_raw) c34, 
  max(c35.rate_raw) c35, 
  max(c36.rate_raw) c36, 
  max(c37.rate_raw) c37, 
  max(c38.rate_raw) c38, 
  max(c39.rate_raw) c39, 
  max(c40.rate_raw) c40,
  max(c41.rate_raw) c41, 
  max(c42.rate_raw) c42, 
  max(c43.rate_raw) c43, 
  max(c44.rate_raw) c44, 
  max(c45.rate_raw) c45, 
  max(c46.rate_raw) c46, 
  max(c47.rate_raw) c47, 
  max(c48.rate_raw) c48, 
  max(c49.rate_raw) c49, 
  max(c50.rate_raw) c50,
  null company_job_score,
  null job_company_count,
  null company_salary_count
from TMP_JOBS_OF_INTEREST j
join TMP_GD_SALARY_SUMMARY s on j.job = s.job
join TMP_PARAM_CUR_INDUSTRY p on true
left join TMP_COMPANY_JOB_TOTALS c1 on c1.tmp_company_id = 1 and c1.company = s.company and c1.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c2 on c2.tmp_company_id = 2 and c2.company = s.company and c2.job = j.job
left join TMP_COMPANY_JOB_TOTALS c3 on c3.tmp_company_id = 3 and c3.company = s.company and c3.job = j.job
left join TMP_COMPANY_JOB_TOTALS c4 on c4.tmp_company_id = 4 and c4.company = s.company and c4.job = j.job
left join TMP_COMPANY_JOB_TOTALS c5 on c5.tmp_company_id = 5 and c5.company = s.company and c5.job = j.job
left join TMP_COMPANY_JOB_TOTALS c6 on c6.tmp_company_id = 6 and c6.company = s.company and c6.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c7 on c7.tmp_company_id = 7 and c7.company = s.company and c7.job = j.job
left join TMP_COMPANY_JOB_TOTALS c8 on c8.tmp_company_id = 8 and c8.company = s.company and c8.job = j.job
left join TMP_COMPANY_JOB_TOTALS c9 on c9.tmp_company_id = 9 and c9.company = s.company and c9.job = j.job
left join TMP_COMPANY_JOB_TOTALS c10 on c10.tmp_company_id = 10 and c10.company = s.company and c10.job = j.job
left join TMP_COMPANY_JOB_TOTALS c11 on c11.tmp_company_id = 11 and c11.company = s.company and c11.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c12 on c12.tmp_company_id = 12 and c12.company = s.company and c12.job = j.job
left join TMP_COMPANY_JOB_TOTALS c13 on c13.tmp_company_id = 13 and c13.company = s.company and c13.job = j.job
left join TMP_COMPANY_JOB_TOTALS c14 on c14.tmp_company_id = 14 and c14.company = s.company and c14.job = j.job
left join TMP_COMPANY_JOB_TOTALS c15 on c15.tmp_company_id = 15 and c15.company = s.company and c15.job = j.job
left join TMP_COMPANY_JOB_TOTALS c16 on c16.tmp_company_id = 16 and c16.company = s.company and c16.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c17 on c17.tmp_company_id = 17 and c17.company = s.company and c17.job = j.job
left join TMP_COMPANY_JOB_TOTALS c18 on c18.tmp_company_id = 18 and c18.company = s.company and c18.job = j.job
left join TMP_COMPANY_JOB_TOTALS c19 on c19.tmp_company_id = 19 and c19.company = s.company and c19.job = j.job
left join TMP_COMPANY_JOB_TOTALS c20 on c20.tmp_company_id = 20 and c20.company = s.company and c20.job = j.job
left join TMP_COMPANY_JOB_TOTALS c21 on c21.tmp_company_id = 21 and c21.company = s.company and c21.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c22 on c22.tmp_company_id = 22 and c22.company = s.company and c22.job = j.job
left join TMP_COMPANY_JOB_TOTALS c23 on c23.tmp_company_id = 23 and c23.company = s.company and c23.job = j.job
left join TMP_COMPANY_JOB_TOTALS c24 on c24.tmp_company_id = 24 and c24.company = s.company and c24.job = j.job
left join TMP_COMPANY_JOB_TOTALS c25 on c25.tmp_company_id = 25 and c25.company = s.company and c25.job = j.job
left join TMP_COMPANY_JOB_TOTALS c26 on c26.tmp_company_id = 26 and c26.company = s.company and c26.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c27 on c27.tmp_company_id = 27 and c27.company = s.company and c27.job = j.job
left join TMP_COMPANY_JOB_TOTALS c28 on c28.tmp_company_id = 28 and c28.company = s.company and c28.job = j.job
left join TMP_COMPANY_JOB_TOTALS c29 on c29.tmp_company_id = 29 and c29.company = s.company and c29.job = j.job
left join TMP_COMPANY_JOB_TOTALS c30 on c30.tmp_company_id = 30 and c30.company = s.company and c30.job = j.job
left join TMP_COMPANY_JOB_TOTALS c31 on c31.tmp_company_id = 31 and c31.company = s.company and c31.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c32 on c32.tmp_company_id = 32 and c32.company = s.company and c32.job = j.job
left join TMP_COMPANY_JOB_TOTALS c33 on c33.tmp_company_id = 33 and c33.company = s.company and c33.job = j.job
left join TMP_COMPANY_JOB_TOTALS c34 on c34.tmp_company_id = 34 and c34.company = s.company and c34.job = j.job
left join TMP_COMPANY_JOB_TOTALS c35 on c35.tmp_company_id = 35 and c35.company = s.company and c35.job = j.job
left join TMP_COMPANY_JOB_TOTALS c36 on c36.tmp_company_id = 36 and c36.company = s.company and c36.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c37 on c37.tmp_company_id = 37 and c37.company = s.company and c37.job = j.job
left join TMP_COMPANY_JOB_TOTALS c38 on c38.tmp_company_id = 38 and c38.company = s.company and c38.job = j.job
left join TMP_COMPANY_JOB_TOTALS c39 on c39.tmp_company_id = 39 and c39.company = s.company and c39.job = j.job
left join TMP_COMPANY_JOB_TOTALS c40 on c40.tmp_company_id = 40 and c40.company = s.company and c40.job = j.job
left join TMP_COMPANY_JOB_TOTALS c41 on c41.tmp_company_id = 41 and c41.company = s.company and c41.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c42 on c42.tmp_company_id = 42 and c42.company = s.company and c42.job = j.job
left join TMP_COMPANY_JOB_TOTALS c43 on c43.tmp_company_id = 43 and c43.company = s.company and c43.job = j.job
left join TMP_COMPANY_JOB_TOTALS c44 on c44.tmp_company_id = 44 and c44.company = s.company and c44.job = j.job
left join TMP_COMPANY_JOB_TOTALS c45 on c45.tmp_company_id = 45 and c45.company = s.company and c45.job = j.job
left join TMP_COMPANY_JOB_TOTALS c46 on c46.tmp_company_id = 46 and c46.company = s.company and c46.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c47 on c47.tmp_company_id = 47 and c47.company = s.company and c47.job = j.job
left join TMP_COMPANY_JOB_TOTALS c48 on c48.tmp_company_id = 48 and c48.company = s.company and c48.job = j.job
left join TMP_COMPANY_JOB_TOTALS c49 on c49.tmp_company_id = 49 and c49.company = s.company and c49.job = j.job
left join TMP_COMPANY_JOB_TOTALS c50 on c50.tmp_company_id = 50 and c50.company = s.company and c50.job = j.job
group by p.industry, j.job
order by job;

/*
  total score raw
*/
insert into LKP_FAIRPAY_JOB_COMPANY_MATRIX
select distinct
  p.industry,
  1 display_order,
  4 value_type,
  j.job,
  null just_co_id,
  null company_value,
  max(c1.score_raw) c1, 
  max(c2.score_raw) c2, 
  max(c3.score_raw) c3, 
  max(c4.score_raw) c4, 
  max(c5.score_raw) c5, 
  max(c6.score_raw) c6, 
  max(c7.score_raw) c7, 
  max(c8.score_raw) c8, 
  max(c9.score_raw) c9, 
  max(c10.score_raw) c10,
  max(c11.score_raw) c11, 
  max(c12.score_raw) c12, 
  max(c13.score_raw) c13, 
  max(c14.score_raw) c14, 
  max(c15.score_raw) c15, 
  max(c16.score_raw) c16, 
  max(c17.score_raw) c17, 
  max(c18.score_raw) c18, 
  max(c19.score_raw) c19, 
  max(c20.score_raw) c20,
  max(c21.score_raw) c21, 
  max(c22.score_raw) c22, 
  max(c23.score_raw) c23, 
  max(c24.score_raw) c24, 
  max(c25.score_raw) c25, 
  max(c26.score_raw) c26, 
  max(c27.score_raw) c27, 
  max(c28.score_raw) c28, 
  max(c29.score_raw) c29, 
  max(c30.score_raw) c30,
  max(c31.score_raw) c31, 
  max(c32.score_raw) c32, 
  max(c33.score_raw) c33, 
  max(c34.score_raw) c34, 
  max(c35.score_raw) c35, 
  max(c36.score_raw) c36, 
  max(c37.score_raw) c37, 
  max(c38.score_raw) c38, 
  max(c39.score_raw) c39, 
  max(c40.score_raw) c40,
  max(c41.score_raw) c41, 
  max(c42.score_raw) c42, 
  max(c43.score_raw) c43, 
  max(c44.score_raw) c44, 
  max(c45.score_raw) c45, 
  max(c46.score_raw) c46, 
  max(c47.score_raw) c47, 
  max(c48.score_raw) c48, 
  max(c49.score_raw) c49, 
  max(c50.score_raw) c50,
  null company_job_score,
  null job_company_count,
  null company_salary_count
from TMP_JOBS_OF_INTEREST j
join TMP_GD_SALARY_SUMMARY s on j.job = s.job
join TMP_PARAM_CUR_INDUSTRY p on true
left join TMP_COMPANY_JOB_TOTALS c1 on c1.tmp_company_id = 1 and c1.company = s.company and c1.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c2 on c2.tmp_company_id = 2 and c2.company = s.company and c2.job = j.job
left join TMP_COMPANY_JOB_TOTALS c3 on c3.tmp_company_id = 3 and c3.company = s.company and c3.job = j.job
left join TMP_COMPANY_JOB_TOTALS c4 on c4.tmp_company_id = 4 and c4.company = s.company and c4.job = j.job
left join TMP_COMPANY_JOB_TOTALS c5 on c5.tmp_company_id = 5 and c5.company = s.company and c5.job = j.job
left join TMP_COMPANY_JOB_TOTALS c6 on c6.tmp_company_id = 6 and c6.company = s.company and c6.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c7 on c7.tmp_company_id = 7 and c7.company = s.company and c7.job = j.job
left join TMP_COMPANY_JOB_TOTALS c8 on c8.tmp_company_id = 8 and c8.company = s.company and c8.job = j.job
left join TMP_COMPANY_JOB_TOTALS c9 on c9.tmp_company_id = 9 and c9.company = s.company and c9.job = j.job
left join TMP_COMPANY_JOB_TOTALS c10 on c10.tmp_company_id = 10 and c10.company = s.company and c10.job = j.job
left join TMP_COMPANY_JOB_TOTALS c11 on c11.tmp_company_id = 11 and c11.company = s.company and c11.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c12 on c12.tmp_company_id = 12 and c12.company = s.company and c12.job = j.job
left join TMP_COMPANY_JOB_TOTALS c13 on c13.tmp_company_id = 13 and c13.company = s.company and c13.job = j.job
left join TMP_COMPANY_JOB_TOTALS c14 on c14.tmp_company_id = 14 and c14.company = s.company and c14.job = j.job
left join TMP_COMPANY_JOB_TOTALS c15 on c15.tmp_company_id = 15 and c15.company = s.company and c15.job = j.job
left join TMP_COMPANY_JOB_TOTALS c16 on c16.tmp_company_id = 16 and c16.company = s.company and c16.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c17 on c17.tmp_company_id = 17 and c17.company = s.company and c17.job = j.job
left join TMP_COMPANY_JOB_TOTALS c18 on c18.tmp_company_id = 18 and c18.company = s.company and c18.job = j.job
left join TMP_COMPANY_JOB_TOTALS c19 on c19.tmp_company_id = 19 and c19.company = s.company and c19.job = j.job
left join TMP_COMPANY_JOB_TOTALS c20 on c20.tmp_company_id = 20 and c20.company = s.company and c20.job = j.job
left join TMP_COMPANY_JOB_TOTALS c21 on c21.tmp_company_id = 21 and c21.company = s.company and c21.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c22 on c22.tmp_company_id = 22 and c22.company = s.company and c22.job = j.job
left join TMP_COMPANY_JOB_TOTALS c23 on c23.tmp_company_id = 23 and c23.company = s.company and c23.job = j.job
left join TMP_COMPANY_JOB_TOTALS c24 on c24.tmp_company_id = 24 and c24.company = s.company and c24.job = j.job
left join TMP_COMPANY_JOB_TOTALS c25 on c25.tmp_company_id = 25 and c25.company = s.company and c25.job = j.job
left join TMP_COMPANY_JOB_TOTALS c26 on c26.tmp_company_id = 26 and c26.company = s.company and c26.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c27 on c27.tmp_company_id = 27 and c27.company = s.company and c27.job = j.job
left join TMP_COMPANY_JOB_TOTALS c28 on c28.tmp_company_id = 28 and c28.company = s.company and c28.job = j.job
left join TMP_COMPANY_JOB_TOTALS c29 on c29.tmp_company_id = 29 and c29.company = s.company and c29.job = j.job
left join TMP_COMPANY_JOB_TOTALS c30 on c30.tmp_company_id = 30 and c30.company = s.company and c30.job = j.job
left join TMP_COMPANY_JOB_TOTALS c31 on c31.tmp_company_id = 31 and c31.company = s.company and c31.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c32 on c32.tmp_company_id = 32 and c32.company = s.company and c32.job = j.job
left join TMP_COMPANY_JOB_TOTALS c33 on c33.tmp_company_id = 33 and c33.company = s.company and c33.job = j.job
left join TMP_COMPANY_JOB_TOTALS c34 on c34.tmp_company_id = 34 and c34.company = s.company and c34.job = j.job
left join TMP_COMPANY_JOB_TOTALS c35 on c35.tmp_company_id = 35 and c35.company = s.company and c35.job = j.job
left join TMP_COMPANY_JOB_TOTALS c36 on c36.tmp_company_id = 36 and c36.company = s.company and c36.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c37 on c37.tmp_company_id = 37 and c37.company = s.company and c37.job = j.job
left join TMP_COMPANY_JOB_TOTALS c38 on c38.tmp_company_id = 38 and c38.company = s.company and c38.job = j.job
left join TMP_COMPANY_JOB_TOTALS c39 on c39.tmp_company_id = 39 and c39.company = s.company and c39.job = j.job
left join TMP_COMPANY_JOB_TOTALS c40 on c40.tmp_company_id = 40 and c40.company = s.company and c40.job = j.job
left join TMP_COMPANY_JOB_TOTALS c41 on c41.tmp_company_id = 41 and c41.company = s.company and c41.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c42 on c42.tmp_company_id = 42 and c42.company = s.company and c42.job = j.job
left join TMP_COMPANY_JOB_TOTALS c43 on c43.tmp_company_id = 43 and c43.company = s.company and c43.job = j.job
left join TMP_COMPANY_JOB_TOTALS c44 on c44.tmp_company_id = 44 and c44.company = s.company and c44.job = j.job
left join TMP_COMPANY_JOB_TOTALS c45 on c45.tmp_company_id = 45 and c45.company = s.company and c45.job = j.job
left join TMP_COMPANY_JOB_TOTALS c46 on c46.tmp_company_id = 46 and c46.company = s.company and c46.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c47 on c47.tmp_company_id = 47 and c47.company = s.company and c47.job = j.job
left join TMP_COMPANY_JOB_TOTALS c48 on c48.tmp_company_id = 48 and c48.company = s.company and c48.job = j.job
left join TMP_COMPANY_JOB_TOTALS c49 on c49.tmp_company_id = 49 and c49.company = s.company and c49.job = j.job
left join TMP_COMPANY_JOB_TOTALS c50 on c50.tmp_company_id = 50 and c50.company = s.company and c50.job = j.job
group by p.industry, j.job
order by job;

/*
  total for job
*/
insert into LKP_FAIRPAY_JOB_COMPANY_MATRIX
select distinct
  p.industry,
  1 display_order,
  5 value_type,
  j.job,
  null just_co_id,
  null company_value,
  max(c1.total) c1, 
  max(c2.total) c2, 
  max(c3.total) c3, 
  max(c4.total) c4, 
  max(c5.total) c5, 
  max(c6.total) c6, 
  max(c7.total) c7, 
  max(c8.total) c8, 
  max(c9.total) c9, 
  max(c10.total) c10,
  max(c11.total) c11, 
  max(c12.total) c12, 
  max(c13.total) c13, 
  max(c14.total) c14, 
  max(c15.total) c15, 
  max(c16.total) c16, 
  max(c17.total) c17, 
  max(c18.total) c18, 
  max(c19.total) c19, 
  max(c20.total) c20,
  max(c21.total) c21, 
  max(c22.total) c22, 
  max(c23.total) c23, 
  max(c24.total) c24, 
  max(c25.total) c25, 
  max(c26.total) c26, 
  max(c27.total) c27, 
  max(c28.total) c28, 
  max(c29.total) c29, 
  max(c30.total) c30,
  max(c31.total) c31, 
  max(c32.total) c32, 
  max(c33.total) c33, 
  max(c34.total) c34, 
  max(c35.total) c35, 
  max(c36.total) c36, 
  max(c37.total) c37, 
  max(c38.total) c38, 
  max(c39.total) c39, 
  max(c40.total) c40,
  max(c41.total) c41, 
  max(c42.total) c42, 
  max(c43.total) c43, 
  max(c44.total) c44, 
  max(c45.total) c45, 
  max(c46.total) c46, 
  max(c47.total) c47, 
  max(c48.total) c48, 
  max(c49.total) c49, 
  max(c50.total) c50,
  null company_job_score,
  null job_company_count,
  null company_salary_count
from TMP_JOBS_OF_INTEREST j
join TMP_GD_SALARY_SUMMARY s on j.job = s.job
join TMP_PARAM_CUR_INDUSTRY p on true
left join TMP_COMPANY_JOB_TOTALS c1 on c1.tmp_company_id = 1 and c1.company = s.company and c1.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c2 on c2.tmp_company_id = 2 and c2.company = s.company and c2.job = j.job
left join TMP_COMPANY_JOB_TOTALS c3 on c3.tmp_company_id = 3 and c3.company = s.company and c3.job = j.job
left join TMP_COMPANY_JOB_TOTALS c4 on c4.tmp_company_id = 4 and c4.company = s.company and c4.job = j.job
left join TMP_COMPANY_JOB_TOTALS c5 on c5.tmp_company_id = 5 and c5.company = s.company and c5.job = j.job
left join TMP_COMPANY_JOB_TOTALS c6 on c6.tmp_company_id = 6 and c6.company = s.company and c6.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c7 on c7.tmp_company_id = 7 and c7.company = s.company and c7.job = j.job
left join TMP_COMPANY_JOB_TOTALS c8 on c8.tmp_company_id = 8 and c8.company = s.company and c8.job = j.job
left join TMP_COMPANY_JOB_TOTALS c9 on c9.tmp_company_id = 9 and c9.company = s.company and c9.job = j.job
left join TMP_COMPANY_JOB_TOTALS c10 on c10.tmp_company_id = 10 and c10.company = s.company and c10.job = j.job
left join TMP_COMPANY_JOB_TOTALS c11 on c11.tmp_company_id = 11 and c11.company = s.company and c11.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c12 on c12.tmp_company_id = 12 and c12.company = s.company and c12.job = j.job
left join TMP_COMPANY_JOB_TOTALS c13 on c13.tmp_company_id = 13 and c13.company = s.company and c13.job = j.job
left join TMP_COMPANY_JOB_TOTALS c14 on c14.tmp_company_id = 14 and c14.company = s.company and c14.job = j.job
left join TMP_COMPANY_JOB_TOTALS c15 on c15.tmp_company_id = 15 and c15.company = s.company and c15.job = j.job
left join TMP_COMPANY_JOB_TOTALS c16 on c16.tmp_company_id = 16 and c16.company = s.company and c16.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c17 on c17.tmp_company_id = 17 and c17.company = s.company and c17.job = j.job
left join TMP_COMPANY_JOB_TOTALS c18 on c18.tmp_company_id = 18 and c18.company = s.company and c18.job = j.job
left join TMP_COMPANY_JOB_TOTALS c19 on c19.tmp_company_id = 19 and c19.company = s.company and c19.job = j.job
left join TMP_COMPANY_JOB_TOTALS c20 on c20.tmp_company_id = 20 and c20.company = s.company and c20.job = j.job
left join TMP_COMPANY_JOB_TOTALS c21 on c21.tmp_company_id = 21 and c21.company = s.company and c21.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c22 on c22.tmp_company_id = 22 and c22.company = s.company and c22.job = j.job
left join TMP_COMPANY_JOB_TOTALS c23 on c23.tmp_company_id = 23 and c23.company = s.company and c23.job = j.job
left join TMP_COMPANY_JOB_TOTALS c24 on c24.tmp_company_id = 24 and c24.company = s.company and c24.job = j.job
left join TMP_COMPANY_JOB_TOTALS c25 on c25.tmp_company_id = 25 and c25.company = s.company and c25.job = j.job
left join TMP_COMPANY_JOB_TOTALS c26 on c26.tmp_company_id = 26 and c26.company = s.company and c26.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c27 on c27.tmp_company_id = 27 and c27.company = s.company and c27.job = j.job
left join TMP_COMPANY_JOB_TOTALS c28 on c28.tmp_company_id = 28 and c28.company = s.company and c28.job = j.job
left join TMP_COMPANY_JOB_TOTALS c29 on c29.tmp_company_id = 29 and c29.company = s.company and c29.job = j.job
left join TMP_COMPANY_JOB_TOTALS c30 on c30.tmp_company_id = 30 and c30.company = s.company and c30.job = j.job
left join TMP_COMPANY_JOB_TOTALS c31 on c31.tmp_company_id = 31 and c31.company = s.company and c31.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c32 on c32.tmp_company_id = 32 and c32.company = s.company and c32.job = j.job
left join TMP_COMPANY_JOB_TOTALS c33 on c33.tmp_company_id = 33 and c33.company = s.company and c33.job = j.job
left join TMP_COMPANY_JOB_TOTALS c34 on c34.tmp_company_id = 34 and c34.company = s.company and c34.job = j.job
left join TMP_COMPANY_JOB_TOTALS c35 on c35.tmp_company_id = 35 and c35.company = s.company and c35.job = j.job
left join TMP_COMPANY_JOB_TOTALS c36 on c36.tmp_company_id = 36 and c36.company = s.company and c36.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c37 on c37.tmp_company_id = 37 and c37.company = s.company and c37.job = j.job
left join TMP_COMPANY_JOB_TOTALS c38 on c38.tmp_company_id = 38 and c38.company = s.company and c38.job = j.job
left join TMP_COMPANY_JOB_TOTALS c39 on c39.tmp_company_id = 39 and c39.company = s.company and c39.job = j.job
left join TMP_COMPANY_JOB_TOTALS c40 on c40.tmp_company_id = 40 and c40.company = s.company and c40.job = j.job
left join TMP_COMPANY_JOB_TOTALS c41 on c41.tmp_company_id = 41 and c41.company = s.company and c41.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c42 on c42.tmp_company_id = 42 and c42.company = s.company and c42.job = j.job
left join TMP_COMPANY_JOB_TOTALS c43 on c43.tmp_company_id = 43 and c43.company = s.company and c43.job = j.job
left join TMP_COMPANY_JOB_TOTALS c44 on c44.tmp_company_id = 44 and c44.company = s.company and c44.job = j.job
left join TMP_COMPANY_JOB_TOTALS c45 on c45.tmp_company_id = 45 and c45.company = s.company and c45.job = j.job
left join TMP_COMPANY_JOB_TOTALS c46 on c46.tmp_company_id = 46 and c46.company = s.company and c46.job = j.job 
left join TMP_COMPANY_JOB_TOTALS c47 on c47.tmp_company_id = 47 and c47.company = s.company and c47.job = j.job
left join TMP_COMPANY_JOB_TOTALS c48 on c48.tmp_company_id = 48 and c48.company = s.company and c48.job = j.job
left join TMP_COMPANY_JOB_TOTALS c49 on c49.tmp_company_id = 49 and c49.company = s.company and c49.job = j.job
left join TMP_COMPANY_JOB_TOTALS c50 on c50.tmp_company_id = 50 and c50.company = s.company and c50.job = j.job
group by p.industry, j.job
order by job;

drop table if exists TMP_JOBS_OF_INTEREST;
drop table if exists TMP_GD_COMPANIES_OF_INTEREST;
drop table if exists TMP_COMPANY_JOB_TOTALS;
drop table if exists TMP_GD_SALARY_SUMMARY;

