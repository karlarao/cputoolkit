-- Karl Arao, Oracle ACE (bit.ly/karlarao), OCP-DBA, RHCE
-- cputoolkit
--
-- Installation: 
--   This tool doesn't need any installation, just unzip it on any directory
--   and follow the HOWTO sections below. The tool does select on sys.obj$
--   which is available on all the Oracle versions, yes you have to run this 
--   as SYS (local authentication)
--
-- Updates:
--   20130117 added 68vu5q46nu22s on sql_detail.sql to monitor SLOB readers.sql
--             also added the child_number on the last column
--   20130315 added turbostat which does sudo with password of "welcome1", change the password accordingly on the following 3 files:
--				instrument
--			    runcputoolkit-single
--				cputoolkit
--   20130901 modified the section 3 to add the ./instrument script
--   20130901 added sections 5 and 6
--

The files and folders: 
------------------------

README-cputoolkit.txt			    -- the README 

INSTRUMENTATION SCRIPTS      
   sql_detail, sql_detail.sql       -- 5secs sample of the SQL_ID that's generating the CPU load, output shows detailed SQL statistics (elapsed,lios,cpu wait,etc.)
   loadprof, loadprof.sql           -- 2secs sample of Load Profile.. similar to the AWR Load Profile section but fine grained samples
   gas, gas.sql                     -- 2secs sample of active sessions, output shows the session level numbers of elapsed and lios
   ash_detail, ash_detail.sql    	-- 5secs samples of CPU breakdown from blog post http://dboptimizer.com/2011/07/21/oracle-cpu-time/
   										this also includes the per SID CPU seconds breakdown and the total session CPU seconds consumed
   ash_workload, aveactn300.sql		-- 20secs samples from v$active_session_history showing top 2 AAS
   
BENCHMARK SCRIPTS   
   saturate						    -- the manual driver script of the 60secs sessions test case OR 1 CPU test case (instrumentation scripts are NOT executed)
                                        you can drive up to 6 databases using this script, this runs for 1hour
     orion_3_fts.sh
     orion_3_ftsall.sh
     orion_3_ftsallmulti.sh
   aas30							-- aas30 folder
      saturate						-- the manual driver script of the 30secs sessions test case OR 1/2 CPU test case (instrumentation scripts are NOT executed)
                                        you can drive up to 6 databases using this script, this runs for 1hour
        orion_3_fts.sh
        orion_3_ftsall.sh
        orion_3_ftsallmulti.sh
   runcputoolkit-single             -- the automatic driver script of the 60secs sessions test case OR 1 CPU test case (instrumentation scripts are executed)
                                        you can only drive 1 database using this script, this runs for 10mins
                                        the main purpose is to saturate specific number of CPUs which you can CTRL-C anytime
   runcputoolkit-auto               -- same as the runcputoolkit-single above, but here you enter the <start CPU> and <end CPU> to run the CPU benchmark from let's say 
                                        CPU#1 to CPU#24 of a 24CPU machine, each CPU increment (default is 1) runs for 10mins
     cputoolkit                     -- To change the auto interval from increments of 1 to 3 edit the line "for i in $(seq $1 1 $2)" to "for i in $(seq $1 3 $2)" of this file              
        
KILL AND CLEAN SCRIPTS   
   kill_sessions.sh					-- generates kill session SQLs from all running DBs with file name "TERMINATE_SESSIONS_<dbname>.SQL"
   									   	the terminate SQLs will be executed immediately, comment the "@TERMINATE_SESSIONS_$INST.SQL" on script 
   									   	to defer the immediate kill and just generate the kill SQL. 
   									   	This also purges from the shared pool just the SQL_ID that's generating the CPU load.
   clean                            -- cleans up the *txt files on the same directory
   tar_toolkit                      -- packages the toolkit in one TAR file            
      
The Section 1-4 below shows the HOWTO of this toolkit.. 
but if you want to know more about how I came up with 1CPU and 1/2CPU usage see the section "More on the behavior of the script" at the bottom.
      

################################################################################
SECTION 1: RUNNING THE TEST CASE - AUTOMATIC DRIVER SCRIPTS (recommended)
################################################################################

	1.a. saturate specific number of CPUs which you can CTRL-C anytime, runs for 10mins

	    ./runcputoolkit-single <num CPUs> <inst name>
	    ./runcputoolkit-single 4 dw      <-- saturate 4 CPUs on dw database

	1.b. automatically saturate specific number of CPUs by <start CPU> and <end CPU>, each CPU increment runs for 10mins
             
            before doing the auto runs make sure that the resource manager is turned off and CPU_COUNT is set to the number of max CPUs (threads)
            execute the following:

                 ./cpu_topology                          <-- gets the CPU config
                 ./cage_check.sh                         <-- gets the Resource Management (RM) & Scheduler config
                 sqlplus "/ as sysdba" @disable_rm.sql   <-- disables the scheduler windows, RM, & sets CPU_COUNT

            then execute the auto runs

	         ./runcputoolkit-auto <start CPU> <interval> <end CPU> <inst name>
	         ./runcputoolkit-auto 1 1 16 dw     <-- saturate CPU#1 to CPU#16 on dw database with 1 CPU interval

            you can also test the interval to set without running the benchmark by running the test-auto script
            I usually set the interval to 4 for 24,32,48 CPUs and 20 for 160 CPUs

                 ./test-auto 1 1 16     

			the runcputoolkit-auto test case will generate the following files 
			
				-rw-r--r-- 1 oracle dba   48499 Dec 11 12:16 1-sess-sql_detail.txt         
				-rw-r--r-- 1 oracle dba  357655 Dec 11 12:16 1-sess-loadprof.txt           
				-rw-r--r-- 1 oracle dba  280721 Dec 11 12:16 1-sess-gas.txt                
				-rw-r--r-- 1 oracle dba   86756 Dec 11 12:16 1-sess-ash_detail.txt         
				-rw-r--r-- 1 oracle dba  615031 Dec 11 12:16 1-sess-collectl-cpuverbose.txt
	                                                                           				
				...
				...
				...
				
				-rw-r--r-- 1 oracle dba   49326 Dec 11 14:48 16-sess-sql_detail.txt         
				-rw-r--r-- 1 oracle dba  380987 Dec 11 14:48 16-sess-loadprof.txt           
				-rw-r--r-- 1 oracle dba 1311327 Dec 11 14:48 16-sess-gas.txt                
				-rw-r--r-- 1 oracle dba  630406 Dec 11 14:48 16-sess-collectl-cpuverbose.txt
				-rw-r--r-- 1 oracle dba  145296 Dec 11 14:48 16-sess-ash_detail.txt         
                                                                            			
			then after the auto run do this:
			
				mkdir <testcase_folder_name>
				mv *txt <testcase_folder_name>
				cd <testcase_folder_name>
			
				for i in {1..33};
				do
				        cat $i-sess-loadprof.txt >> report_loadprof.txt
				        cat $i-sess-sql_detail.txt | grep "/" | tail -n1 >> report_sqldetail.txt
				done
			
			then grep on report_loadprof.txt for "Logical reads" to see the workload level behavior
			
				cat report_loadprof.txt | grep -i logical > report_logical.txt 	
				
			and view the report_sqldetail.txt to see the session level behavior, below are 16rows which corresponds to 16CPUs (increments)
			
				cat report_sqldetail.txt
			
				TM               ,      EXEC,      LIOS,   CPUSECS,  ELAPSECS,CPU_WAIT_SECS,  CPU_EXEC, ELAP_EXEC,CPU_WAIT_EXEC, LIOS_EXEC, LIOS_ELAP
				-----------------,----------,----------,----------,----------,-------------,----------,----------,-------------,----------,----------
				12/11/12 08:41:47,       609, 178422501,    597.76,    598.82,         1.06,       .98,       .98,            0, 292976.19, 297956.96
				12/11/12 08:51:48,      1197, 343892161,   1191.77,   1193.34,         1.57,         1,         1,            0, 287295.04, 288175.48
				12/11/12 09:01:51,      1828, 493073532,   1767.83,   1770.43,          2.6,       .97,       .97,            0, 269733.88, 278504.66
				12/11/12 09:11:54,      2431, 647484970,   2347.19,   2350.65,         3.47,       .97,       .97,            0, 266345.11, 275449.17
				12/11/12 09:21:58,      2587, 679741963,   2918.43,   2929.45,        11.03,      1.13,      1.13,            0, 262752.98, 232037.01
				12/11/12 09:32:09,      2735, 685868794,   3502.07,   3528.56,        26.49,      1.28,      1.29,          .01,  250774.7, 194376.46
				12/11/12 09:42:16,      2850, 692605617,   3986.49,   4075.67,        89.18,       1.4,      1.43,          .03, 243019.51, 169936.61
				12/11/12 09:52:24,      2914, 675167093,   4295.13,   4604.66,       309.54,      1.47,      1.58,          .11,  231697.7, 146626.88
				12/11/12 10:02:32,      2941, 695590028,   4342.78,   5190.95,       848.18,      1.48,      1.77,          .29,  236514.8, 134000.46
				12/11/12 10:12:42,      2959, 729134532,   4419.72,   5844.11,       1424.4,      1.49,      1.98,          .48, 246412.48, 124763.92
				12/11/12 10:22:57,      2985, 751946428,   4453.33,   6429.48,      1976.15,      1.49,      2.15,          .66, 251908.35, 116952.92
				12/11/12 10:33:09,      2977, 789225547,   4493.05,   7068.86,      2575.81,      1.51,      2.37,          .87, 265107.67,  111648.2
				12/11/12 10:43:21,      2992, 800822328,   4487.63,   7647.29,      3159.66,       1.5,      2.56,         1.06, 267654.52, 104719.71
				12/11/12 10:53:35,      2995, 808297558,   4508.67,   8262.54,      3753.87,      1.51,      2.76,         1.25, 269882.32,  97826.75
				12/11/12 11:03:50,      2985, 806798654,   4517.98,   8857.53,      4339.55,      1.51,      2.97,         1.45, 270284.31,  91086.21
				12/11/12 11:14:06,      2992, 810882399,   4531.78,   9485.92,      4954.15,      1.51,      3.17,         1.66, 271016.84,  85482.72

		
################################################################################
SECTION 2: RUNNING THE TEST CASE - MANUAL DRIVER SCRIPTS
################################################################################

	2.a. 30secs sessions - each user will consume 1/2 CPU and will run for 1hour
	
		cd aas30
		./saturate <number of sessions to create> <dbname> <number of sessions to create> <dbname> ...
		./saturate 4 dw				<-- run 4 x 30secs session on 1 DB
		./saturate 4 dw 4 oltp		<-- run 4 x 30secs sessions on each DB

	2.b. 60secs sessions - each user will consume 1 CPU and will run for 1hour
	
		./saturate <number of sessions to create> <dbname> <number of sessions to create> <dbname> ...
		./saturate 4 dw				<-- run 4 x 60secs session on 1 DB
		./saturate 4 dw 4 oltp		<-- run 4 x 60secs sessions on each DB
		

################################################################################
SECTION 3: MONITORING
################################################################################

	3.a. As the Oracle user on separate terminal windows
			
        ./sql_detail   
        ./loadprof
        ./gas
        ./ash_detail
        ./ash_workload		
		
    OR 

	3.b. just run the ./instrument script it also does sudo with password of welcome1, change the password accordingly

        3.c. then if you just want to quickly check the load on the server just execute (CTRL-C to cancel)
        
        ./check_load		

################################################################################
SECTION 4: STOPPING THE TEST CASE
################################################################################
		
	4.a. As the Oracle user 
		
		./die.sh 
			

################################################################################
SECTION 5: MISC scripts
################################################################################

	5.a. Check the instance caging configuration, also inside the script are the commands to turn ON/OFF the instance caging

		./cage_check.sh


################################################################################
SECTION 6: AIX support
################################################################################

	6.a. On the cputoolkit/aix folder are 6 files that are edited for AIX environments. 
			Copy the files on the root folder of cputoolkit to replace the linux version files.

			cd aix
			cp * ../

		Here's the summary of the files:

		-- on loadprof.sql
			had to comment the section "and s.intsize_csec < 7000" to show the loadprof

		-- on kill_sessions.sh
			dbms_shared_pool.purge(:name,'C',1); doesn't seem to work on aix environment so I had to make use of "alter system flush shared_pool;"
			beware of this script if you are running this on the prod environment, the linux version of this script is more prod friendly

		-- on runcputoolkit-single
			had to add the lparstat, vmstat, mpstat and comment the linux specific stuff

		-- on cputoolkit 
			had to change the "for i in $(seq $1 4 $2)" to "for i in 1 5 9 13 17" and add the lparstat, vmstat, mpstat
			change the "1 5 9 13 17" depending on the sequence you like and the number of CPUs you want to saturate

		-- on instrument
			had to add lparstat, vmstat, mpstat

		-- on die.sh 
			made use of "flush shared pool" and fuser -k on lparstat, vmstat, mpstat
			beware of this script if you are running this on the prod environment, the linux version of this script is more prod friendly




More on the behavior of the script:
-------------------------------------
	
	At the core of the toolkit is Tanel Poder's script called lotslios.sql (http://blog.tanelpoder.com/files/scripts/lotslios.sql) which he usually 
	use on his TPT class to show a CPU bound workload and he usually pass a number to set the intensity of the logical IOs which will also dictate 
	the elapsed time. 
	
	The trick here is to get the lotslios part to run at 1sec then from there you can just do a loop on how many seconds you want it to run (remember 
	1 loop = 1 sec) and on my Intel i7-2600K Sandy Bridge2 CPU setting the rownum to 10 million does the trick.. so if you have faster CPUs you might 
	have to change this to a higher value and even if you don't change the value it is a sustained CPU workload so the effect will be the same but the
	total runtime will be faster (depends on how fast your CPU against my R&D server).
	
	The simple PL/SQL code below runs a sustained 1 sec CPU loop for 1hour - this is the 60secs sessions (2.b) test case above
	
		declare
		        rcount number;
		begin
		        for j in 1..3600 loop
		
		        select /*+ ordered
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
	
	Now, if we add the dbms_lock.sleep(1); right after the 1 sec CPU section the whole PL/SQL elapsed time will be doubled - but this makes the 30secs 
	sessions (2.a) trick possible
		
		declare
		        rcount number;
		begin
		        for j in 1..3600 loop
		
		        select /*+ ordered
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
		        dbms_lock.sleep(1);
		        end loop;
		        end;
		/
	
	To show the difference in behavior, I'll set a scenario below:
	     	- the 1-60 data points below represent a 60secs time slice or let's say a 60secs interval
	     			- the ash_detail script on the section 3.a above makes use of 60secs ASH interval and v$ metric views which
	     				are 60secs in interval by default 
	     	- let's say the database server has 4CPUs.. so the total CPU capacity will be 60secs x 4CPUs = 240secs
	     	- which means the database server can supply 240secs of CPU power over a 60secs interval
	     	- in the case of aas60 (60secs sessions), 1 session is consuming 60secs of CPU power over a 60secs interval, so what does this mean?
	     			- the AAS CPU will be 
	     					(60secs requirement / 60secs interval) = 1
	     			- and the OS CPU % Utilization will be 
	     					(60secs requirement / 240secs capacity) = 25%
	     	- in the case of aas30 (30secs sessions), 1 session is consuming 30secs of CPU power over a 60secs interval, and the zeros you see 
	     		in between are the occurrence of dbms_lock.sleep(1); which is why only half of the 60secs interval is on CPU
	     			- the AAS CPU will be 
	     					(30secs requirement / 60secs interval) = .5
	     			- and the OS CPU % Utilization will be 
	     					(30secs requirement / 240secs capacity) = 12.5%
	     					
	     					     					
	                         data point | aas60  |   aas30
	                         -----------|--------|--------             
	                              1     | 1	     |   1
	                              2     | 1	     |   0
	                              3     | 1	     |   1
	                              4     | 1	     |   0
	                              5     | 1	     |   1
	                              6     | 1	     |   0
	                              7     | 1	     |   1
	                              8     | 1	     |   0
	                              9     | 1	     |   1
	                              10    | 1	     |   0
	                              .     | .      |   .
	                              .     | .      |   .
	                              60    | .      |   .
	                         -----------| -------|--------
	         Total Seconds =            | 60	 |   30
	         AAS CPU       =            | 1      |   .5
	         OS CPU % Util =            | 25%    |   12.5%
	
	Above is just an example of 1 session run for both aas60 and aas30. The HOWTO (2.a & 2.b) above shows the command options to 
	create more user sessions which translates to more AAS CPU usage, remember 1 AAS CPU = 1 CPU. 
	
	Also check on this link http://goo.gl/f5iYK to see my doodle about the script behavior and instrumentation.
	         


