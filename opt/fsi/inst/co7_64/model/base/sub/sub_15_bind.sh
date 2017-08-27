#!/bin/sh
#
#   install bind 
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
version="1.0.1 - 25.2.2016"
ls="  "
retc=0

SOURCE="${BASH_SOURCE[0]}"
DIR="$( dirname "$SOURCE" )"
while [ -h "$SOURCE" ]
do 
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

bindconf="no"


infmsg "$ls Configure bind v.$version"

infmsg "$ls  first search if bind must install"
while read line; do
  ntpline=$(echo $line| cut -c -6)
  if [ "$ntpline" == "#bind:" ] ; then
     bindconf=$(echo $line| cut -d ":" -f 2 | awk '{print tolower($0)}' | awk '{$1=$1;print}' )
     debmsg "$ls  nstall bind => $bindconf"
     break
  fi
done < "$lxdir/$ksfile"

if [ "$bindconf"  == "no" ] || [ "$bindconf" == "false" ] || [ "$bindconf" == "disable" ]; then
   infmsg "$ls do not install bind - ignore"
else
   infmsg "$ls start install bind"

   output=$(2>&1 rpm -qi bind)
   inst=$?
   if [ $inst -ne 0 ]; then
      infmsg "$ls  install bind server and utils"
      output=$(2>&1 yum -y install bind)
      retc=$?
      if [ $retc -ne 0 ]; then
         tracemsg "$ls  output: [$output]"
         errmsg "cannot install bind and utils"
      fi
   else
      infmsg "$ls  bind already installed"
   fi
      
   if [ $retc -eq 0 ]; then
      infmsg "$ls  set named to start at boot"
      output=$(2>&1 chkconfig named on)
      retc=$?
      if [ $retc -ne 0 ]; then
         tracemsg "$ls  output: [$output]"
         errmsg "cannot auto start of named"
      fi
   fi
fi


if [ $retc -eq 1 ]; then
   errmsg "$ls  rc=1 means reboot - set to 2"
   retc=2
fi
infmsg "$ls install bind end rc=$retc"
exit $retc     
