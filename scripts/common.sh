# common.sh: library of common variables and functions

# error on undefined shell variables
set -u

#############
# variables #
#############
# debug options
readonly DEBUG=0
set +x

# base name of outer script
if [[ "${0:0:1}" == "-" || "${0}" == "/bin/bash" ]]
then
  readonly BASENAME="loginshell"
  readonly BASEDIR="./"
else
  readonly BASENAME="$(basename $0)"
  readonly BASEDIR="$(readlink -m $(dirname $0))"
  # exit on error
  set -e
fi

# location for any output files
readonly OUTDIR="${BASEDIR}/output"
# make sure it exists
mkdir -p ${OUTDIR}

# location for any sql files
readonly SQLDIR="${BASEDIR}/sql"
# make sure it exists
mkdir -p ${SQLDIR}

# Interlock ENUM
readonly UNLOCK=0
readonly NOWAIT=1
readonly BLOCK=2

# often useful for log output and filenames
NOW=$(date +"%Y%m%d-%H%M%S")

# to print all output to both log file and stdout
# change LOGOUTPUT to 1
LOGOUTPUT=0
if [[ -t 1 ]] && [[ LOGOUTPUT -eq 1 ]]
then
	OUTPUTLOG="${OUTDIR}/${BASENAME}_${NOW}.log"
	exec > >(tee -a "${OUTPUTLOG}")
	exec 2>&1
fi

# source_file: source (include) a needed shell script
# in standard way
function source_file ()
{
  local SHFILE="$1"
  
  if [[ -r "${SHFILE}" ]]
  then
    source "${SHFILE}"
  else
    echo "ERROR: unable to source file ${SHFILE}"
    exit 1
  fi
}

################################################################################
# exec_sql: Send SQL string to an arbitrary PostgreSQL cluster
################################################################################
function exec_sql
{
    local PGHOST="$1"
    local PGPORT="$2"
    local DBNAME="$3"
    local PGUSER="$4"
    local DLM="$5"
    local SQL="$6"

    if [[ $DEBUG -eq 1 ]]
    then
        echo "${SQL}" >&2
    fi

    echo "${SQL}" | \
         psql -v ON_ERROR_STOP=1 \
              -qAt -F "${DLM}" \
              -h ${PGHOST} -p ${PGPORT} -U ${PGUSER} -d ${DBNAME}
}

################################################################################
# exec_sql_file: Send SQL file to an arbitrary PostgreSQL cluster
################################################################################
function exec_sql_file ()
{
    local PGHOST="$1"
    local PGPORT="$2"
    local DBNAME="$3"
    local PGUSER="$4"
    local DLM="$5"
    local SQLFILE="$6"

    psql -v ON_ERROR_STOP=1 \
         -qAt -F "${DLM}" \
         -h ${PGHOST} -p ${PGPORT} -U ${PGUSER} -d $DBNAME \
         -f "${SQLFILE}"
}

# interlock: prevent concurrent access to section of code
# LOCKNAME: fully qualified name of lock file
# LOCKTYPE:
#   UNLOCK - remove previous lock
#   NOWAIT - exit with ERROR on conflict
#   BLOCK  - block/wait on conflict
function interlock
{
  local LOCKNAME="$1"
  local LOCKTYPE="$2"
  # note: FD intentionally left global for possible unlock

  # do not exit on error during this function
  set +e

  if [[ ${LOCKTYPE} -ne ${UNLOCK} ]]
  then
    if [[ ${LOCKTYPE} -eq ${NOWAIT} ]]
    then
      action="--nonblock"
    else
      action=""
    fi
    exec {FD}> "${LOCKNAME}"
    flock --exclusive ${action} ${FD}
    rv=$?
    if [[ $rv -ne 0 ]]
    then
      echo "could not obtain lock - ${LOCKNAME}"
    fi
  else
    flock --unlock ${FD}
    rv=$?
    if [[ $rv -ne 0 ]]
    then
      echo "could not unlock ${LOCKNAME}"
    fi
  fi
  return $rv
}

################################################################################
# sqlfunc_match: determine if specific version of a function is installed
################################################################################
function sqlfunc_match
{
    local PGHOST="$1"
    local PGPORT="$2"
    local DBNAME="$3"
    local PGUSER="$4"
    local DLM="$5"
    local SCHEMA="$6"
    local FNAME="$7"
    local ARGTYPS="$8"
    local FUNCMD5="$9"
    local SQL="
               select count(1) from pg_catalog.pg_proc
               where pronamespace=(select oid from pg_catalog.pg_namespace
                                   where nspname='${SCHEMA}')
               and proname='${FNAME}'
               and proargtypes = '${ARGTYPS}'::oidvector
               and md5(pg_get_functiondef(oid)) = '${FUNCMD5}'
    "

    echo $( exec_sql "${PGHOST}" "${PGPORT}" "${DBNAME}" "${PGUSER}" "${DLM}" "${SQL}" )
}

################################################################################
# cr_sql_func: CREATE OR REPLACE sql function if it does not exist or if
# it does not match the function md5 of the provided sql script
################################################################################
function cr_sql_func
{
    local PGHOST="$1"
    local PGPORT="$2"
    local DBNAME="$3"
    local PGUSER="$4"
    local DLM="$5"
    local SQLFILE="$6"

    local FQ_SQLFILE="${SQLDIR}/${SQLFILE}"

    # install the needed function if it does not exist or is wrong version
    local SCHEMA=$(cut -d "." -f 1 <<< ${SQLFILE})
    local FNAME=$((cut -d "." -f 2 <<< ${SQLFILE}) | cut -d "-" -f 1)
    local ARGTYPS=$((cut -d "." -f 2 <<< ${SQLFILE}) | cut -d "-" -f 2 | tr '_' ' ')
    local FUNCMD5=$(md5sum ${FQ_SQLFILE} | cut -d " " -f 1)

    funcmatch=$( sqlfunc_match "${PGHOST?}" "${PGPORT?}" "${DBNAME?}" "${PGUSER?}" "${DLM}" "${SCHEMA}" "${FNAME}" "${ARGTYPS}" "${FUNCMD5}" )
    if [[ $funcmatch -ne 1 ]]
    then
      echo "Executing ${SQLFILE} to install/replace ${SCHEMA}.${FNAME}"
      sqlout=$(exec_sql_file "${PGHOST}" "${PGPORT}" "${DBNAME}" "${PGUSER}" "${DLM}" "${FQ_SQLFILE}")
    fi
}

# array_len:  ${#ARRAY[@]}
# array_push: ARRAY[${#ARRAY[@]}]="${ELEMENT}"
# array_pop:  unset ARRAY[$((${#ARRAY[@]} - 1))]
# array_exec: for (( i=${#ARRAY[@]} - 1; i>=0; i-- )); do eval ${ARRAY[$i]}; done
