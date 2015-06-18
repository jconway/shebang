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

SLEEPTIME=10
LOCKFILE="${OUTDIR}/${BASENAME}.lock"
echo "Attempt to grab lock in non-blocking mode..."
interlock "${LOCKFILE}" ${NOWAIT}
rv=$?
if [[ $rv -ne 0 ]]
then
  echo "Attempt to grab lock in blocking mode..."
  interlock "${LOCKFILE}" ${BLOCK}
fi

echo "sleeping ${SLEEPTIME} seconds locked"
sleep ${SLEEPTIME}
echo "done ${SLEEPTIME} seconds"

echo "unlocking..."
interlock "${LOCKFILE}" ${UNLOCK}
SLEEPTIME=5
echo "sleeping ${SLEEPTIME} seconds unlocked"
sleep ${SLEEPTIME}
echo "done ${SLEEPTIME} seconds"
