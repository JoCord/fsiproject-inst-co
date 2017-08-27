#!/bin/sh
#
#   sub-10_disable_nm.sh - disable network manager
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
version="1.0.3 - 21.4.2016"
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

infmsg "$ls Disable network manager v.$version"

disable_nm=0

while read line; do
  ovtline=$(echo $line| cut -c -12)
  if [ "$ovtline" == "#disable_nm:" ] ; then
     disable_nm=$(echo $line| cut -d ":" -f 2 | awk '{print tolower($0)}' | awk '{$1=$1;print}' )
     debmsg "$ls   disable nm: [$disable_nm]"
     break
  fi
done < "$lxdir/$ksfile"

if [ "$disable_nm" == "1" ] || [ "$disable_nm" == "yes" ] || [ "$disable_nm" == "true" ] || [ "$disable_nm" == "enable" ]; then
   infmsg "$ls  found config to disable Network Manager"
   output=$(2>&1 rpm -qi NetworkManager)
   inst=$?
   if [ $inst -ne 0 ]; then
      infmsg "$ls Network Manager is not installed"
   else
      infmsg "$ls Network Manager is installed - disabled start and use"

      if [ "$osmain" == "" ]; then
         errmsg "unknown linux version"
         retc=98
      elif [ $osmain -eq 5 ] || [ $osmain -eq 6 ]; then
         debmsg "$ls  found version 5 or 6"
         infmsg "$ls check if service is running"
         output=$(2>&1 service NetworkManager status)
         running=$?
         if (( ! $running )); then
            infmsg "$ls fist stop service"
            output=$(2>&1 service NetworkManager stop)
            retc=$?
         else
            infmsg "$ls service actually not running"
         fi
         if (( ! $retc )); then
            infmsg "$ls disable auto start"
            output=$(2>&1 chkconfig NetworkManager off)
            retc=$?
         fi
      elif [ $osmain -eq 7 ]; then
         debmsg "$ls  found version 7"
         infmsg "$ls check if service is running"
         output=$(2>&1 systemctl status NetworkManager)
         running=$?    # 3 if not running
         if (( ! $running )); then
            infmsg "$ls fist stop service"
            output=$(2>&1 systemctl stop NetworkManager)
            retc=$?
         fi
         if (( ! $retc )); then
            infmsg "$ls disable auto start"
            output=$(2>&1 systemctl disable NetworkManager)
            retc=$?
         fi
      else
         errmsg "unknown linux version"
         retc=99
      fi
   fi
else
   infmsg "$ls  found no config to disable Network Manager - go on"
fi

if [ $retc -eq 1 ]; then
   errmsg "$ls  rc=1 means reboot - set to 2"
   retc=2
fi
infmsg "$ls $progname end rc=$retc"
exit $retc     
