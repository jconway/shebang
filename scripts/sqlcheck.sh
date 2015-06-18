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
SQLFILE="public.testfunc-23.sql"

# verify the correct version of the SQL function is installed
cr_sql_func "${PGHOST}" "${PGPORT}" "${DBNAME}" "${PGUSER}" "${DLM}" "${SQLFILE}"
# now use it
SQL="select public.testfunc(42)"
exec_sql "${PGHOST}" "${PGPORT}" "${DBNAME}" "${PGUSER}" "${DLM}" "${SQL}"
