
Do the following:

1)	Untar the file as oracle user at /home/oracle/dba/cputoolkit

cd /home/oracle/dba/cputoolkit  (if the directory does not exist, mkdir -p /home/oracle/dba/cputoolkit)
tar -xjvpf cputoolkit.tar.bz2
chmod 755 *

2)	On another terminal window login as oracle then go to /home/oracle/dba/cputoolkit

sh cpu_topology                                      <-- gets the CPU config (outputs cpu_topology.log)
sh cage_check.sh                                     <-- gets the Resource Management (RM) & Scheduler config (outputs cage_check.log)
sqlplus "/ as sysdba" @disable_rm.sql                <-- disables the scheduler windows, RM, & sets CPU_COUNT

3)	Run the benchmark
a.	If it's a RAC environment and if "dw" is the database name, that's going to be dw1 on the script parameter if you are running it on  instance #1
b.	If the server has 160 max CPUs you can do the benchmark by 20 CPUs increment, and per increment it will run for 10 minutes
c.	While the benchmark is running it generates a lot of instrumentation logs (ash, load profile, etc.)

./runcputoolkit-auto <start CPU> <interval> <end CPU> <inst name>
./runcputoolkit-auto 1 20 161 dw1
run for 1 CPU/s
run for 21 CPU/s
run for 41 CPU/s
run for 61 CPU/s
run for 81 CPU/s
run for 101 CPU/s
run for 121 CPU/s
run for 141 CPU/s
run for 161 CPU/s

4)	After the run, do this.. basically putting all txt and log files to a folder then just tar it then send it to me

mkdir <testcase_folder_name>
mv *txt <testcase_folder_name>
mv *log <testcase_folder_name>

Also put the the RM config back by looking at the following files and re-enable everything that has been disabled 

disable_rm.log
cage_check.log

--re-enable
   execute dbms_scheduler.set_attribute('MONDAY_WINDOW','RESOURCE_PLAN','<before setting>');
   execute dbms_scheduler.set_attribute('TUESDAY_WINDOW','RESOURCE_PLAN','<before setting>');
   execute dbms_scheduler.set_attribute('WEDNESDAY_WINDOW','RESOURCE_PLAN','<before setting>');
   execute dbms_scheduler.set_attribute('THURSDAY_WINDOW','RESOURCE_PLAN','<before setting>');
   execute dbms_scheduler.set_attribute('FRIDAY_WINDOW','RESOURCE_PLAN','<before setting>');
   execute dbms_scheduler.set_attribute('SATURDAY_WINDOW','RESOURCE_PLAN','<before setting>');
   execute dbms_scheduler.set_attribute('SUNDAY_WINDOW','RESOURCE_PLAN','<before setting>');
   execute DBMS_AUTO_TASK_ADMIN.ENABLE;
   alter system set resource_manager_plan=<before setting> scope=both sid='&INST';
   


5)	Whenever you want to kill the run just execute the die.sh script

sh die.sh





-Karl
