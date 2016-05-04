#!/bin/bash

ps -ef | grep pmon | grep -v grep | grep -v perl | grep -v ASM | grep `echo $ORACLE_SID` | \
while read PMON; do
   INST=`echo $PMON | awk {' print $8 '} | cut -f3 -d_`
  echo "instance: $INST"

  export ORACLE_SID=$INST
  export ORAENV_ASK=NO
  . oraenv

  sqlplus -s /nolog <<-EOF
  connect / as sysdba

  set head off
  set lines 200
  select 'Connected to: '|| INSTANCE_NAME from v\$instance;
  spool TERMINATE_SESSIONS_$INST.SQL

select /* usercheck */ 'alter system disconnect session '''||s.sid||','||s.serial#||''''||' post_transaction;'
from v\$process p, v\$session s, v\$sqlarea sa
where p.addr=s.paddr
and   s.username is not null
and   s.sql_address=sa.address(+)
and   s.sql_hash_value=sa.hash_value(+)
and   sa.sql_text NOT LIKE '%usercheck%'
and   lower(sa.sql_text) LIKE '%cputoolkit%'
order by status desc;

  spool off
  set echo on
  set feedback on

@TERMINATE_SESSIONS_$INST.SQL

alter system flush shared_pool;

--var name varchar2(50)
--BEGIN
--  select /* usercheck */ address||','||hash_value into :name
--  from v\$sqlarea
--  where sql_text NOT LIKE '%usercheck%'
--  and   lower(sql_text) NOT LIKE '%declare%'
--  and   lower(sql_text) LIKE '%cputoolkit%';

-- dbms_shared_pool.purge(:name,'C',1);
-- END;
-- /
-- undef name

! rm TERMINATE_SESSIONS_$INST.SQL

EOF
echo '-----'
echo
echo
done
