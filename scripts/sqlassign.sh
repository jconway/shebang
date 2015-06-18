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

PGHOST="/tmp"
PGPORT="55605"
DBNAME="pgcon2015"
PGUSER="postgres"
DLM=" "

SQL="select 42 as the_answer"

the_answer="$(exec_sql "${PGHOST}" "${PGPORT}" \
                "${DBNAME}" "${PGUSER}" \
                "${DLM}" "${SQL}")"

echo "The answer is: ${the_answer}"

SQL="select pid, now() - state_change as age
     from pg_stat_activity
     where datname = current_database()
     and state = 'idle in transaction'"

while read pid age
do
  echo "pid/age: ${pid}/${age}"
done <<< "$(exec_sql "${PGHOST}" \
                     "${PGPORT}" \
                     "${DBNAME}" \
                     "${PGUSER}" \
                     "${DLM}" \
                     "${SQL}")"

