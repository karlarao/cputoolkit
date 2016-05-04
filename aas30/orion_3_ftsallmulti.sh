# purpose: driver to execute SELECT count(*) on multiple databases
# usage: sh orion_3_ftsallmulti.sh 4 dbm1
#

export ORACLE_SID=$2
export ORAENV_ASK=NO
. oraenv

(( n=0 ))
while (( n<$1 ));do
(( n=n+1 ))
./orion_3_fts.sh $1 $2 &
done
