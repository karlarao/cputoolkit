-- run ./cage_check.sh first and take note of current RESOURCE_PLAN in
-- in case you want to revert to previous settings
--
-- NOTE: the script will only modify on current instance 
-- you can also set the CPU_COUNT or just hit ENTER to use current settings 
-- the rest of script will just disable the scheduler windows


COLUMN name NEW_VALUE _instname NOPRINT
select instance_name name from v$instance;

spool disable_rm.log

show parameter resource_manager_plan
   alter system set resource_manager_plan='' scope=both sid='&_instname';
show parameter cpu_count
   alter system set cpu_count=&CPU_COUNT scope=both sid='&_instname';

select '--------------- BEFORE ---------------' from dual;

set echo on
set lines 300
col window_name format a17
col RESOURCE_PLAN format a25
col LAST_START_DATE format a50
col duration format a15
col enabled format a5
select window_name, RESOURCE_PLAN, LAST_START_DATE, DURATION, enabled from DBA_SCHEDULER_WINDOWS;

   execute dbms_scheduler.set_attribute('MONDAY_WINDOW','RESOURCE_PLAN','');
   execute dbms_scheduler.set_attribute('TUESDAY_WINDOW','RESOURCE_PLAN','');
   execute dbms_scheduler.set_attribute('WEDNESDAY_WINDOW','RESOURCE_PLAN','');
   execute dbms_scheduler.set_attribute('THURSDAY_WINDOW','RESOURCE_PLAN','');
   execute dbms_scheduler.set_attribute('FRIDAY_WINDOW','RESOURCE_PLAN','');
   execute dbms_scheduler.set_attribute('SATURDAY_WINDOW','RESOURCE_PLAN','');
   execute dbms_scheduler.set_attribute('SUNDAY_WINDOW','RESOURCE_PLAN','');
   execute DBMS_AUTO_TASK_ADMIN.DISABLE;
set echo off

select '--------------- AFTER ---------------' from dual;

set lines 300
col window_name format a17
col RESOURCE_PLAN format a25
col LAST_START_DATE format a50
col duration format a15
col enabled format a5
select window_name, RESOURCE_PLAN, LAST_START_DATE, DURATION, enabled from DBA_SCHEDULER_WINDOWS;

spool off
exit
