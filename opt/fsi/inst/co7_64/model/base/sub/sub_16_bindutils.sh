#!/bin/sh
#
#   install bind-utils
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


infmsg "$ls Install bind utils v.$version"

inst_bin=0
while read line; do
  ovtline=$(echo $line| cut -c -16)
  if [ "$ovtline" == "#inst_bindutils:" ] ; then
     inst_bin=$(echo $line| cut -d ":" -f 2 | awk '{print tolower($0)}' | awk '{$1=$1;print}' )
     infmsg "$ls   inst bind utils: [$inst_bin]"
     break
  fi
done < "$lxdir/$ksfile"

if [ "$inst_bin" == "1" ] || [ "$inst_bin" == "yes" ] || [ "$inst_bin" == "true" ] || [ "$inst_bin" == "enable" ]; then
   infmsg "$ls  found config to install bind utils"
   output=$(2>&1 rpm -qi bind-utils)
   inst=$?
   if [ $inst -ne 0 ]; then
      infmsg "$ls  install bind utils"
      output=$(2>&1 yum -y install bind-utils)
      retc=$?
      if [ $retc -ne 0 ]; then
         tracemsg "$ls  output: [$output]"
         errmsg "cannot install bind utils"
      fi
   else
      infmsg "$ls  bind utils already installed"
   fi
else
   infmsg "$ls  find no config to install bind utils - go on"
fi   

if [ $retc -eq 1 ]; then
   errmsg "$ls  rc=1 means reboot - set to 2"
   retc=2
fi
infmsg "$ls $progname end rc=$retc"
exit $retc     
