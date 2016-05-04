# purpose: execute multiple SELECT count(*) on 1 database
# usage: sh orion_3_ftsall.sh 4
#

(( n=0 ))
while (( n<$1 ));do
(( n=n+1 ))
./orion_3_fts.sh &
done
