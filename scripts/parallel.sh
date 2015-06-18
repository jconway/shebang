#!/bin/bash
# resolve canonical script directory name
BASEDIR=$(readlink -m $(dirname $0))

# find the function library and use it
COMMON_LIB="${BASEDIR}/common.sh"
if [[ -r "${COMMON_LIB}" ]]
then
  # if common.sh found, include it here
  source "${COMMON_LIB}"
else
  echo "ERROR: unable to source file ${COMMON_LIB}"
  exit 1
fi

PGHOST_1="/tmp"
PGHOST_2="/tmp"
PGHOST_3="/tmp"
PGPORT="55605"
DBNAME="pgcon2015"
PGUSER="postgres"
DLM=" "

SLEEPTIME=5
SQL1="select 42 as the_answer, pg_sleep(${SLEEPTIME})"
SQL2="select 43 as the_answer, pg_sleep(${SLEEPTIME})"
SQL3="select 44 as the_answer, pg_sleep(${SLEEPTIME})"
coproc p1 { exec_sql "${PGHOST_1}" "${PGPORT}" "${DBNAME}" "${PGUSER}" "${DLM}" "${SQL1}" ; }
coproc p2 { exec_sql "${PGHOST_2}" "${PGPORT}" "${DBNAME}" "${PGUSER}" "${DLM}" "${SQL2}" ; }
coproc p3 { exec_sql "${PGHOST_3}" "${PGPORT}" "${DBNAME}" "${PGUSER}" "${DLM}" "${SQL3}" ; }
coproc p4 { sleep 1 ; }
wait
read buf1 <&${p1}; echo "buf1=${buf1}"
read buf2 <&${p2}; echo "buf2=${buf2}"
read buf3 <&${p3}; echo "buf3=${buf3}"
