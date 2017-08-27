#!/bin/sh
#
#   ipv6 disable
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

infmsg "$ls Disable ipv6 v.$version"

disable_ipv6=0
while read line; do
  ovtline=$(echo $line| cut -c -14)
  if [ "$ovtline" == "#disable_ipv6:" ] ; then
     disable_ipv6=$(echo $line| cut -d ":" -f 2 | awk '{print tolower($0)}' | awk '{$1=$1;print}' )
     infmsg "$ls   disable ip v6: [$disable_ipv6]"
     break
  fi
done < "$lxdir/$ksfile"

if [ "$disable_ipv6" == "1" ] || [ "$disable_ipv6" == "yes" ] || [ "$disable_ipv6" == "true" ] || [ "$disable_ipv6" == "enable" ]; then
   infmsg "$ls  found disable ipv6 config"

   out=$(sysctl -w net.ipv6.conf.all.disable_ipv6=1)
   retc=$?
   if [ $retc -ne 0 ]; then
      errmsg "cannot set net.ipv6.conf.all.disable_ipv6=1"
   fi

   if [ $retc -eq 0 ]; then
      out=$(sysctl -w net.ipv6.conf.default.disable_ipv6=1) 
      if [ $retc -ne 0 ]; then
         errmsg "cannot set net.ipv6.conf.default.disable_ipv6=1"
      fi
   fi
   
else
   infmsg "$ls  found no option to disable ipv6"
fi

if [ $retc -eq 1 ]; then
   debmsg "$ls  rc=1 means reboot, change to 2"
   retc=2
fi
infmsg "$ls $progname end rc=$retc"
exit $retc
