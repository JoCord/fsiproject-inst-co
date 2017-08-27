#!/bin/sh
#
#   ntp default config
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
progname=${0##*/}
version="1.0.5 - 18.4.2016"
ls="  "
retc=0

SOURCE="${BASH_SOURCE[0]}"
DIR="$( dirname "$SOURCE" )"
while [ -h "$SOURCE" ]; do 
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
  DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd )"
done

export progdir="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

if [ -z "${lxdir}" ]; then lxdir="/var/fsi"; fi
if [ -z "${lxconf}" ]; then lxconf="$lxdir/lxconf.sh"; fi
if [ -z "${lxfunc}" ]; then lxfunc="/usr/bin/lxfunc.sh"; fi
   
if [ -f $lxfunc ]; then
   #   echo Load $lxfunc  
   . $lxfunc
else
   echo Cannot find $lxfunc >/root/lxerror
   exit 100
fi
if [ -f $lxconf ]; then 
   #   echo Load $lxconf
   . $lxconf
else
   echo Cannot find $lxconf >/root/lxerror
   exit 100
fi

ntpcfg="/etc/ntp.conf"

infmsg "$ls Configure default NTP Installation v.$version"

debmsg "$ls  first search if one server given"
ntpconf=0
while read line; do
  ntpline=$(echo $line| cut -c -8)
  if [ "$ntpline" == "#ntpsrv:" ] ; then
     ntpsrv=$(echo $line| cut -d ":" -f 2 | awk '{print tolower($0)}' | awk '{$1=$1;print}' )
     infmsg "$ls   found uplink server: $ntpsrv"
     ntpconf=1
     break
  fi
done < "$lxdir/$ksfile"
while read line; do
  ntpline=$(echo $line| cut -c -10)
  if [ "$ntpline" == "#ntprange:" ] ; then
     ntprange=$(echo $line| cut -d ":" -f 2 | awk '{print tolower($0)}' | awk '{$1=$1;print}' )
     ntpmask=$(echo $line| cut -d ":" -f 2 | awk '{print tolower($0)}' | awk '{$1=$1;print}' )
     infmsg "$ls   found ntp network range to allow receive requests: $ntprange / $ntpmask"
     ntpconf=1
     break
  fi
done < "$lxdir/$ksfile"


if [ $ntpconf -eq 1 ]; then
   infmsg "$ls  found server(s) - start install"
   
   if [ $retc -eq 0 ]; then
      output=$(2>&1 rpm -qi ntp)
      inst=$?
      if [ $inst -ne 0 ]; then
         infmsg "$ls  install ntp"
         output=$(2>&1 yum -y install ntp)
         retc=$?
         if [ $retc -ne 0 ]; then
            tracemsg "$ls  output: [$output]"
            errmsg "cannot install ntp server"
         fi
      else
         infmsg "$ls  ntp already installed"
      fi
   fi
   
   cat > $ntpcfg <<"   EOF1"
   restrict default kod nomodify notrap nopeer noquery
   restrict 127.0.0.1
   EOF1
   
   infmsg "$ls  read ks.cfg for settings "
   debmsg "$ls   search ntprange"
   while read line; do
     ntpline=$(echo $line| cut -c -10)
     if [ "$ntpline" == "#ntprange:" ] ; then
        ntprange=$(echo $line| cut -d ":" -f 2 | awk '{print tolower($0)}' | awk '{$1=$1;print}' )
        ntpmask=$(echo $line| cut -d ":" -f 2 | awk '{print tolower($0)}' | awk '{$1=$1;print}' )
        infmsg "$ls   found ntp network range to allow receive requests: $ntprange / $ntpmask"
        infmsg "$ls   write server to ntp.conf ..."
        echo restrict $ntprange mask $ntpmask nomodify notrap >>$ntpcfg
        existrc=$?
        if [ $existrc -eq 1 ]; then
            errmsg "cannot add ntp range [$ntprange] to ntp conf [$ntpcfg] - abort"
            retc=99
            break 
        fi
     fi
   done < "$lxdir/$ksfile"
      
   cat >> $ntpcfg <<"   EOF1"
   
   driftfile /var/lib/ntp/drift
   
   EOF1
   
   infmsg "$ls  read ks.cfg for settings "
   debmsg "$ls   search ntpsrv"
   
   while read line; do
     ntpline=$(echo $line| cut -c -8)
     if [ "$ntpline" == "#ntpsrv:" ] ; then
        ntpsrv=$(echo $line| cut -d ":" -f 2 | awk '{print tolower($0)}' | awk '{$1=$1;print}' )
        infmsg "$ls   found server: $ntpsrv"
        infmsg "$ls   write server to ntp.conf ..."
        echo server $ntpsrv >>$ntpcfg
        existrc=$?
        if [ $existrc -eq 1 ]; then
            errmsg "cannot add ntp server [$ntpsrv] to ntp conf [$ntpcfg] - abort"
            retc=99
            break 
        fi
     fi
   done < "$lxdir/$ksfile"
   
   
   cat >> $ntpcfg <<"   EOF1"
   
   driftfile /var/lib/ntp/drift
   EOF1
   
   if [ $retc -eq 0 ]; then
      infmsg "$ls   configure ntpd start"
      if [ "$osmain" == "" ]; then
         errmsg "unknown linux version"
         retc=98
      elif [ $osmain -eq 5 ] || [ $osmain -eq 6 ]; then
         infmsg "$ls  configure autostart for ntp (5/6)"
         output=$(2>&1 chkconfig ntpd on)
         retc=$?
         if [ $retc -ne 0 ]; then
            tracemsg "$ls  output: [$output]"
            errmsg "cannot set auto start of ntpd"
         fi
      
      elif [ $osmain -eq 7 ]; then
         infmsg "$ls  configure autostart for ntp (7)"
         systemctl restart ntpd
         systemctl status ntpd
         systemctl enable ntpd
      
      else
         errmsg "unknown linux version"
         retc=99
      fi
   fi
else
   infmsg "$ls  no ntp server to configure found"
fi

if [ $retc -eq 1 ]; then
   errmsg "$ls  rc=1 means reboot - set to 2"
   retc=2
fi
infmsg "$ls $progname end rc=$retc"
exit $retc     
