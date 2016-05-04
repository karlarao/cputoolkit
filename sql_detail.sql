
set lines 300
spool sql_detail.txt append
col c format 99
set colsep ','
select /* sql_id_exec */
to_char(sysdate,'MM/DD/YY HH24:MI:SS') tm, 
executions exec,
buffer_gets lios,
round(cpu_time/1000000,2) cpusecs,
round(elapsed_time/1000000,2) elapsecs, 
round((elapsed_time-cpu_time)/1000000,2) cpu_wait_secs,
round((cpu_time/1000000)/executions,2) cpu_exec, 
round((elapsed_time/1000000)/executions,2) elap_exec,
round(((elapsed_time-cpu_time)/1000000)/executions,2) cpu_wait_exec,
round(buffer_gets/executions,2) lios_exec,
round(buffer_gets/(elapsed_time/1000000),2) lios_elap,
round((round((elapsed_time/1000000)/executions,2) * 1000000) / round(buffer_gets/(elapsed_time/1000000),2),2) us_lio,
child_number c
from v$sql
where sql_id in ('9fx889bgz15h3','68vu5q46nu22s');
spool off
