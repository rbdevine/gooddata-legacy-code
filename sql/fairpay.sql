"select $Job:=job, $C1:=c1, $C2:=c2, $C3:=c3 from TMP_JOB_COMPANY_MATRIX_MASTER_WITH_HEADER where job = 'asm' or header=1 order by header desc, job;"
