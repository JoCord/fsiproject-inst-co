#
#   Function script
#
#   This program is free software; you can redistribute it and/or modify it under the 
#   terms of the GNU General Public License as published by the Free Software Foundation;
#   either version 3 of the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#   See the GNU General Public License for more details.
#  
#   You should have received a copy of the GNU General Public License along with this program; 
#   if not, see <http://www.gnu.org/licenses/>.
# 
export funcver="1.0.01 - 1.9.2016"
export hostname=$(hostname -s)
export ipregex="\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
export macregex="^([0-9a-f]{2}[:-]){5}([0-9a-f]{2})$"
export osver=$(sed -n 's/^.*[ ]\([0-9]\.[0-9]*\)[ .].*/\1/p' /etc/redhat-release)
export osmain=${osver%%.*}


export debug="trace"   # write to file
export deb2scr="yes"   # write to screen

# Logging
tracemsg() {
    if [ "$debug" == "trace" ] || [ "$debug" == "press" ] || [ "$debug" == "sleep" ] ; then
        logmsg "TRACE  : $1" 3
    fi
}
debmsg() {
    if [ "$debug" == "debug" ] || [ "$debug" == "trace" ] || [ "$debug" == "press" ] || [ "$debug" == "sleep" ]; then
        logmsg "DEBUG  : $1" 7
    fi
}
warnmsg() {
    logmsg "WARN   : $1" 4
}
infmsg() {
    logmsg "INFO   : $1" 2
}
errmsg() {
    logmsg "ERROR  : $1" 5
}

function logmsg() {
   local timestamp=$(date +%H:%M:%S)
   local datetimestamp=$(date +%Y.%m.%d)"-"${timestamp}
   tmpmsg=$1
   tmp=${tmpmsg:0:5}
#   if [ "$deb2scr" == "yes" ] || ( [ "$tmp" != "DEBUG" ] && [ "$tmp" != "TRACE" ] ); then
    if [ "$deb2scr" == "yes" ]; then
      tput -T xterm setaf $2
      echo $timestamp "$1"
      tput -T xterm sgr0
   fi
   local progname=${0##*/}
   local pidnr=$$
#   printf "%-19s : %-6d - %-30s %s\n" $datetimestamp,000 $pidnr $progname "$1" >>$logfile
   printf "%-19s : %-6d - %-19s %s\n" $datetimestamp $pidnr $progname "$1" >>$logfile
   if [ -d "$kspath/log" ]; then
      printf "%-19s : %-6d - %-19s %s\n" $datetimestamp $pidnr $progname "$1" >>$kspath/log/${HOSTNAME%%.*}.log
   fi
}

change() {
   tracemsg "Function [$FUNCNAME] startet"
   local suche=$1
   local ersetze=$2
   local datei=$3
   local retc=0
   debmsg "  search [$suche]"
   debmsg "  change to [$ersetze]"
   debmsg "  file [$datei]"
   OUTPUT=$(2>&1 sed -i s%$suche%$ersetze%g $datei)
   retc=$?
   if [ $retc -ne 0 ]; then
      errmsg "cannot change $suche with $ersetze in $datei - $retc"
      errmsg "$OUTPUT"
   else
      debmsg "  ok"
   fi
   tracemsg "Function [$FUNCNAME] ended - rc=$retc"
   return $retc
}

function warte() {
   wend=$1
   wtime=$2
   if [ -z $wend ]; then
      waitend=10
   else
      waitend=$wend
   fi
   if [ -z $wtime ]; then
      waittime=15
   else  
      waittime=$wtime
   fi
   waitcount=0
   echo -n $(date +%H:%M:%S)" INFO   : $ls     Waiting ."
   while [ $waitcount -le $waitend ]; do
      echo -n "."
      sleep $waittime
      waitcount=$((waitcount+1))
   done
   echo " ok"
}


function isvarset(){
   local v="$1"
   [[ ! ${!v} && ${!v-unset} ]] && return 1 || return 0
}

function srvonline() {
   tracemsg "$ls  Function [$FUNCNAME] startet"
   ls="$ls  "
   debmsg "$ls server [$1] online ?"
   local srv=$1
   if [ -z $srv ]; then
      errmsg "no server given"
      exit 99
   fi
   ping $srv -c 1  >/dev/nul 2>&1
   online=$?
   if [ $online -eq 0 ]; then
      tracemsg "$ls srv: $1 - online"
   elif [ $online -eq 1 ]; then
      tracemsg "$ls srv: $1 -  "
   elif [ $online -eq 2 ]; then
      tracemsg "$ls srv: $1 - unknown server"
   else  
      tracemsg "$ls srv: $1 - unknown error $online"
   fi
   ls=${ls:0:${#ls}-2}
   tracemsg "$ls  Function [$FUNCNAME] ended"
   # bash >4.2: ls=${ls:0:-2}  
   return $online
}

function copylog() {
   tracemsg "$ls  Function [$FUNCNAME] startet"
   ls="$ls  "
   local retc=0
   if [ -d "$kspath/log/" ]; then
      debmsg "$ls Returncode before log copy rc=[$retc]"
      debmsg "$ls copy log file to fsi server"

      host=$(hostname -s)
      OUTPUT=$(/bin/cp -f $logfile "$kspath/log/$host.log")
      retc=$?
      if [ $retc -ne 0 ]; then
         errmsg "error during copy logfile to server - abort (rc=$retc)"
         errmsg "Output: $OUTPUT"
      fi
    else
      warnmsg "$ls  no $kspath/log/ exist - abort copy logfile"
    fi
   ls=${ls:0:${#ls}-2}
   tracemsg "$ls  Function [$FUNCNAME] ended"
   # bash >4.2: ls=${ls:0:-2}  
   return $retc
}

function restart() {
   tracemsg "$ls  Function [$FUNCNAME] startet"
   ls="$ls  "
   copylog
   local retc=$?
   infmsg "$ls  Wait 10 sec to reboot !"
   sleep 10
   reboot
   read -p "$ls  Waiting for reboot ..."      
   exit $retc  # never come here
}

change_param() {
   tracemsg "Function [$FUNCNAME] startet"
   local suche=$1
   local param=$2
   local datei=$3
   local retc=0
   debmsg "  search [$suche]"
   debmsg "  change to [$param]"
   debmsg "  file [$datei]"
   OUTPUT=$(2>&1 sed -i '/^'$suche'=/{h;s/=.*/='$param'/};${x;/^$/{s//'$suche'='$param'/;H};x}' $datei)
   retc=$?
   if [ $retc -ne 0 ]; then
      errmsg "cannot change $suche with $param in $datei - $retc"
      errmsg "$OUTPUT"
   else
      debmsg "  ok"
   fi
   tracemsg "Function [$FUNCNAME] ended - rc=$retc"
   return $retc
}

export -f warte
export -f change
export -f logmsg
export -f errmsg
export -f infmsg
export -f warnmsg
export -f debmsg
export -f tracemsg
export -f isvarset
export -f srvonline
export -f copylog
export -f restart
export -f change_param

# Variable part from install script

