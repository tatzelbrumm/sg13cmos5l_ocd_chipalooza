#!/bin/bash
# Logged runner for the custom-pad harness test.
# Usage: run.sh NN name -- command args...
# Runs the command in the current directory, tees stdout/stderr to
# docs/custom_pads/logs/NN_name.{out,err}, appends a journal entry to
# docs/custom_pads/RUNLOG.md (UTC time, command, cwd, exit status, log files).
H=/home/user/v2test/docs/slot7_v2_test
nn=$1; name=$2; shift 2; [ "$1" = "--" ] && shift
out=$H/logs/${nn}_${name}.out; err=$H/logs/${nn}_${name}.err
t0=$(date -u +%Y-%m-%dT%H:%M:%SZ)
"$@" > >(tee "$out") 2> >(tee "$err" >&2)
rc=$?
sleep 0.2
t1=$(date -u +%Y-%m-%dT%H:%M:%SZ)
{
  echo
  echo "### ${nn} ${name}"
  echo "- start ${t0}, end ${t1}"
  echo "- cwd: \`$(pwd)\`"
  printf -- '- command: `%s`\n' "$*"
  echo "- exit status: ${rc}"
  echo "- logs: \`logs/${nn}_${name}.out\`, \`logs/${nn}_${name}.err\`"
} >> $H/RUNLOG.md
exit $rc
