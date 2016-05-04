#!/bin/bash
#
# Check instance caging configuration
#
# ./cage_check.sh
#
# then do the following to reconfigure instance caging:
#
# Turn OFF instance caging:
#   alter system set resource_manager_plan='' scope=both sid='&INST';
#   alter system set cpu_count=&CPU_COUNT scope=both sid='&INST';
#  -- run ./cage_check.sh first and take note of current RESOURCE_PLAN in 
#  -- in case you want to revert to previous settings
#   execute dbms_scheduler.set_attribute('MONDAY_WINDOW','RESOURCE_PLAN','');
#   execute dbms_scheduler.set_attribute('TUESDAY_WINDOW','RESOURCE_PLAN','');
#   execute dbms_scheduler.set_attribute('WEDNESDAY_WINDOW','RESOURCE_PLAN','');
#   execute dbms_scheduler.set_attribute('THURSDAY_WINDOW','RESOURCE_PLAN','');
#   execute dbms_scheduler.set_attribute('FRIDAY_WINDOW','RESOURCE_PLAN','');
#   execute dbms_scheduler.set_attribute('SATURDAY_WINDOW','RESOURCE_PLAN','');
#   execute dbms_scheduler.set_attribute('SUNDAY_WINDOW','RESOURCE_PLAN','');
#   execute DBMS_AUTO_TASK_ADMIN.DISABLE;
#
# Turn ON instance caging:
#   alter system set resource_manager_plan=default_plan scope=both sid='&INST';
#   alter system set cpu_count=&CPU_COUNT scope=both sid='&INST';
#


ps -ef | grep pmon | grep -v grep | grep -v perl | grep -v ASM | grep `echo $ORACLE_SID` | \
while read PMON; do
   INST=`echo $PMON | awk {' print $8 '} | cut -f3 -d_`
  echo "instance: $INST"

  export ORACLE_SID=$INST
  export ORAENV_ASK=NO
  . oraenv

  sqlplus -s /nolog <<-EOF
  connect / as sysdba

  set lines 200
  select 'Connected to: '|| INSTANCE_NAME from v\$instance;

spool cage_check.log
show parameter resource_manager_plan
show parameter cpu_count

set lines 300
col window_name format a17
col RESOURCE_PLAN format a25
col LAST_START_DATE format a50
col duration format a15
col enabled format a5
select window_name, RESOURCE_PLAN, LAST_START_DATE, DURATION, enabled from DBA_SCHEDULER_WINDOWS;

spool off
  set echo on
  set feedback on


EOF
echo '-----'
echo
echo
done
