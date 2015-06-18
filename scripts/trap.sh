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

if [[ $# -eq 1 ]]
then
    THROWERR="1"
else
    THROWERR="0"
fi

function clean_up {
    for (( i=${#ARRAY[@]} - 1; i>=0; i-- ))
    do
        eval ${ARRAY[$i]}
    done
	exit 1
}

declare -a ARRAY
SQL="truncate table t1"
ELEMENT="echo 'exit trap: truncating table t1';
         exec_sql \"${PGHOST}\" \"${PGPORT}\" \"${DBNAME}\" \
                  \"${PGUSER}\" \"${DLM}\" \"${SQL}\""
ARRAY[0]="${ELEMENT}"

SQL="insert into t2 values(1),(2),(3),(4)"
ELEMENT="echo 'exit trap: inserting into table t2';
         exec_sql \"${PGHOST}\" \"${PGPORT}\" \"${DBNAME}\" \
                  \"${PGUSER}\" \"${DLM}\" \"${SQL}\""
ARRAY[${#ARRAY[@]}]="${ELEMENT}"

trap 'clean_up' SIGINT ERR

SQL="insert into t1 values(1),(2),(3)"
echo "script: inserting into table t1"
exec_sql "${PGHOST}" "${PGPORT}" "${DBNAME}" \
         "${PGUSER}" "${DLM}" "${SQL}"

SQL="truncate table t2"
echo "script: truncating table t2"
exec_sql "${PGHOST}" "${PGPORT}" "${DBNAME}" \
         "${PGUSER}" "${DLM}" "${SQL}"

SQL="select count(1) from t1"
echo "t1 count: $(exec_sql "${PGHOST}" "${PGPORT}" "${DBNAME}" \
                           "${PGUSER}" "${DLM}" "${SQL}")"

SQL="select count(1) from t2"
echo "t2 count: $(exec_sql "${PGHOST}" "${PGPORT}" "${DBNAME}" \
                           "${PGUSER}" "${DLM}" "${SQL}")"

if [[ $THROWERR -eq 1 ]]
then
    echo "ctl-c to get SIGINT, after 5 seconds force error"
    sleep 5
    false
else
    echo "Completed successfully"
fi
