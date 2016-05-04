# This is the main script 
export DATE=$(date +%Y%m%d%H%M%S%N)

sqlplus -s /NOLOG <<! &
connect / as sysdba

declare
        rcount number;
begin
        -- 600/60=10 minutes of workload
        for j in 1..3600 loop

		-- lotslios by Tanel Poder
        select /*+ cputoolkit ordered
                                use_nl(b) use_nl(c) use_nl(d)
                                full(a) full(b) full(c) full(d) */
                            count(*)
                            into rcount
                        from
                            sys.obj$ a,
                            sys.obj$ b,
                            sys.obj$ c,
                            sys.obj$ d
                        where
                            a.owner# = b.owner#
                        and b.owner# = c.owner#
                        and c.owner# = d.owner#
                        and rownum <= 10000000;

        end loop;
        end;
/

exit;
!

