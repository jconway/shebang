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

SCHEMA="$1"
FNAME="$2"
ARGTYPS="$3"
SQLFILE="$4"

SQL="select pg_get_functiondef(p.oid)
from pg_catalog.pg_proc p
join pg_catalog.pg_namespace n on n.oid = p.pronamespace
where nspname = '${SCHEMA}'
and proname = '${FNAME}'
and proargtypes = '${ARGTYPS}'"

FDEF=$(exec_sql "${PGHOST}" "${PGPORT}" "${DBNAME}" \
                "${PGUSER}" "${DLM}" "${SQL}")

echo "${FDEF}" > "${SQLDIR}/${SQLFILE}"
