
spool snapper.txt append
@snapper.sql ash=sql_id+sid+event+wait_class+module+service+blocking_session+p2+p3,stats,gather=a 5 1 "select sid from v$session where sql_id in ('9fx889bgz15h3','68vu5q46nu22s') and rownum < 2"
spool off
exit

