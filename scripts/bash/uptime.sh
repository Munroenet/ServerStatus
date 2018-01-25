#!/bin/bash
###
### uptime.sh: Generate the JSON info required for ServerStatus
###   https://github.com/Munzy/ServerStatus
###
### Copyright 2014 by Davy Chan <imchandave@gmail.com>
###
### Last updated: 2014-09-22
###

###
### Configfile is in the format:
###   pidfile="/pathname/filename" #comments begin with a '#'
###   # This is a comment
###   outfile=/path/to/file/can/be/enclosed/in/double/quotes
###   sleep=integer_value_of_seconds
###   daemon=true # close STDIN/STDOUT/STDERR and fork to background
###
### External dependencies:
###   /bin/cat, /bin/date, /bin/df, /bin/rm, /bin/sleep

G_SLEEP_SECS=0
G_OUTFILE=""
G_PIDFILE=""
G_HDDTOTAL=0
G_HDDFREE=0
CAT_CMD='/bin/cat'
DATE_CMD='/bin/date'
DF_CMD='/bin/df'
RM_CMD='/bin/rm'
SLEEP_CMD='/bin/sleep'

declare -A ARRAY

usage() {
  ${CAT_CMD} <<EOM >&2
usage: $0 [...]
  --sleep secs: re-run $0 after secs of time
  --outfile file:      write JSON to file
  --pidfile file:      write PID to file
  --config file:       read configs from file
  --daemon true|false: close STDIN, STDOUT, & STDERR and chdir("/")
                       Note: --daemon must be the last option specified

EOM
}

cleanup() {
  if [ x"${G_PIDFILE}"x != x""x ]; then
    if [ -f ${G_PIDFILE} ]; then
      ${RM_CMD} -f ${G_PIDFILE}
    fi
  fi
  exit 0
}

trap 'cleanup' 1 15 3

disk_info() {
  ### Assuming /bin/df output is in the following format:
  ###   Filesystem 1K-Blocks Used Available Use% Mounted on
  ###
  local FS=$1
  G_HDDTOTAL=0
  G_HDDFREE=0
  local FSYS DSTOTAL DSUSED DSAVAIL DSPER FMOUNT
  while read -r FSYS DSTOTAL DSUSED DSAVAIL DSPER FMOUNT; do if [ x"${FMOUNT}"x = x"${FS}"x ]; then G_HDDTOTAL=${DSTOTAL}; G_HDDFREE=${DSAVAIL}; break; fi; done <<<"$(${DF_CMD} ${FS})"
}

sec2human() {
  local TIME=$1
  local RET=""
  local SECONDS=0 MINS=0; local HOURS=0; local DAYS=0

  SECONDS=$(( $TIME % 60 ))
  MINS=$(( $TIME / 60)); MINS=$(( $MINS % 60 ))
  HOURS=$(( $TIME / 60 / 60 ))
  DAYS=$(( $HOURS / 24 ))
  HOURS=$(( $HOURS % 24 ))
  if [ $DAYS -gt 0 ]; then
    RET="${DAYS} day"; [ $DAYS -gt 1 ] && RET="${RET}s"
  else
    RET="${HOURS}:${MINS}:${SECONDS}"
  fi
  echo "${RET}"
}

GetUptime() {
  local U
  read -d'.' U < /proc/uptime
  ARRAY['uptime']=$(sec2human $U)
}

GetMemInfo() {
  ### Assuming /proc/meminfo output is in the following format:
  ###   Label: Kilobytes kB
  ###
  local MEMTOTAL=1 MEMFREE=0 MEMCACHE=0 MEMMATH=0
  local MEMLEVEL="" JUNK
  local MEMORY
  local KEY VALUE

  while read KEY VALUE JUNK; do
    if [ x"${KEY}"x = x"MemTotal:"x ]; then
      MEMTOTAL="${VALUE}"
    elif [ x"${KEY}"x = x"MemFree:"x ]; then
      MEMFREE="${VALUE}"
    elif [ x"${KEY}"x = x"Cached:"x ]; then
      MEMCACHE="${VALUE}"
    fi
  done < /proc/meminfo
  MEMMATH=$(( $MEMCACHE + $MEMFREE ))
  MEMORY=$(( $MEMMATH * 100 / $MEMTOTAL ))
  if [ $MEMORY -gt 50 ]; then
    MEMLEVEL="success"
  elif [ $MEMORY -lt 51 ]; then
    MEMLEVEL="warning"
  elif [ $MEMORY -lt 36 ]; then
    MEMLEVEL="danger"
  fi
  MEMORY="${MEMORY}%"
  ARRAY['memory']='<div class="progress progress-striped active">
<div class="bar bar-'${MEMLEVEL}'" style="width: '${MEMORY}';">'${MEMORY}'</div>
</div>'
}

AddHDDTotal() {
  local HDDTOTAL=$1
  local RET=""
  local UNITS='MB'
  local DIVISOR=1024

  [ ! -f '/proc/vz/veinfo' ] && DIVISOR=1000
  if [ -f '/root/00README.stats' ]; then
    RET=$(( $HDDTOTAL / $DIVISOR ))
    if [ $RET -gt 999 ]; then
      UNITS='GB'
      RET=$(( $RET / $DIVISOR ))
      if [ $RET -gt 999 ]; then
        UNITS='TB'
        RET=$(( $RET / $DIVISOR ))
      fi
    fi
    RET="(${RET}${UNITS})"
  fi
  echo ${RET}
}

GetStorage() {
  local HDDLEVEL=""
  local HDD
  local HDD_PRESENT=""

  disk_info '/'
  HDD=$(($G_HDDFREE * 100 / $G_HDDTOTAL))
  if [ $HDD -gt 50 ]; then
    HDDLEVEL="success"
  elif [ $HDD -lt 51 ]; then
    HDDLEVEL="warning"
  elif [ $HDD -lt 36 ]; then
    HDDLEVEL="danger"
  fi
  HDD="${HDD}%"
#  HDD_PRESENT=$(AddHDDTotal $G_HDDTOTAL)
  ARRAY['hdd']='<div class="progress progress-striped active">
<div class="bar bar-'${HDDLEVEL}'" style="width: '${HDD}';">'${HDD}${HDD_PRESENT}'</div>
</div>'
}

GetLoadAvg() {
  ### Assuming /proc/loadavg output is in the following format:
  ###   now.load five.load fifteen.load cpus/sch recent_pid
  ###
  local LOAD="0.0" JUNK
  if [ -r /proc/loadavg ]; then
    read INT JUNK < /proc/loadavg
    LOAD="${INT}"
  fi
  ARRAY['load']="${LOAD}"
}

GetOnlineStatus() {
  ARRAY['online']='<div class="progress">
<div class="bar bar-success" style="width: 100%"><small>Up</small></div>
</div>'
}

GetTimestamp() {
  ARRAY['timestamp']=$($DATE_CMD +'%s')
}

mk_json() {
  local KEY VALUE JSON_STR="{"
  for KEY in ${!ARRAY[@]}; do
    VALUE=${ARRAY["${KEY}"]}
    VALUE=${VALUE//'"'/\\'"'}
    VALUE=${VALUE//$'\n'/\\n}
    VALUE=${VALUE//\//\\\/}
    JSON_STR=${JSON_STR}'"'${KEY}'"':'"'${VALUE}'",'
  done
  JSON_STR=${JSON_STR%,}
  JSON_STR="${JSON_STR}"'}'
  echo "${JSON_STR}"
}

Daemonize() {
  if [ x"${G_OUTFILE}"x = x""x -o x"${G_PIDFILE}"x = x""x ]; then
    echo "ERR: --daemon must be preceeded by --pidfile -and --outfile." >&2
    exit 1
  fi
  if [ x"${G_OUTFILE:0:1}"x != x"/"x ]; then
    echo "ERR: outfile must be a full pathname." >&2
    exit 1
  fi
  cd /
  exec 0>&-
  exec 1>&-
  exec 2>&-
}

ProcessCmdOptions() {
  local ARG=$1 ARG1=$2
  local CONFIG_FILE
  if [ x"${ARG}"x = x"--sleep"x ]; then
    G_SLEEP_SECS=$ARG1
  elif [ x"${ARG}"x = x"--outfile"x ]; then
    G_OUTFILE=$ARG1
  elif [ x"${ARG}"x = x"--pidfile"x ]; then
    G_PIDFILE=$ARG1
    [ $G_SLEEP_SECS -eq 0 ] && G_SLEEP_SECS=120
  elif [ x"${ARG}"x = x"--config"x ]; then
    CONFIG_FILE=$ARG1
    local KEY VALUE
    if [ ! -r $CONFIG_FILE ]; then
      echo "ERR: configfile ${CONFIG_FILE} does not exist!" >&2
      exit 1
    fi
    while read LINE; do
      [ x"${LINE:0:1}"x = x"#"x ] && continue
      IFS='=' read -r KEY VALUE <<<"${LINE}"
      KEY=${KEY/# /}; KEY=${KEY/% /};
      KEY=${KEY/\"/}; KEY=${KEY/%\"/};
      VALUE=${VALUE/%#*/}; VALUE=${VALUE/# /}; VALUE=${VALUE/% */}
      VALUE=${VALUE/\"/}; VALUE=${VALUE/%\"/}
      ProcessCmdOptions "--${KEY}" "${VALUE}"
    done <$CONFIG_FILE
  elif [ x"${ARG}"x = x"--daemon"x ]; then
    [ x"${ARG1}"x = x"true"x ] && G_DAEMONIZE=true
  else
    usage; exit 1
  fi
}

###
### MAIN
###
while [ x"$1"x != x""x ]; do
  ARG=$1; shift;
  while [ x"${ARG:0:2}"x = x"--"x ]; do
    ProcessCmdOptions "${ARG}" "$1"
    shift
    break
  done
done

[ x"${SLEEP}"x != x""x ] && G_SLEEP_SECS=${SLEEP}
[ x"${OUTFILE}"x != x""x ] && G_OUTFILE=${OUTFILE}
[ x"${PIDFILE}"x != x""x ] && G_PIDFILE=${PIDFILE}
[ x"${DAEMON}"x = x"true"x ] && G_DAEMONIZE='true'
[ x"${DAEMON}"x = x"false"x ] && G_DAEMONIZE='false'

do_main() {
  while :; do
    GetUptime
    GetMemInfo
    GetStorage
    GetLoadAvg
    GetOnlineStatus
    GetTimestamp
    A=$(mk_json)
    if [ x"${G_OUTFILE}"x != x""x ]; then
      echo $A > ${G_OUTFILE}
    else
      echo $A
    fi
    if [ ${G_SLEEP_SECS} -eq 0 ]; then
      break
    fi
    ${SLEEP_CMD} $G_SLEEP_SECS
  done
  cleanup
}

umask 022
if [ x"${G_PIDFILE}"x != x""x ]; then
  echo "$$" > $G_PIDFILE
fi

if [ x"${G_DAEMONIZE}"x = x"true"x ]; then
  Daemonize
  do_main &
  if [ x"${G_PIDFILE}"x != x""x ]; then
    echo "$!" > $G_PIDFILE
  fi
else
  do_main
fi