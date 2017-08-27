#!/bin/sh
#
#   install nfs daemon
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
version="1.0.4 - 24.2.2016"
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

infmsg "$ls install nfsd v.$version"

if [ $retc -eq 0 ]; then
   output=$(2>&1 rpm -qi nfs-utils)
   inst=$?
   if [ $inst -ne 0 ]; then
      infmsg "$ls  install nfsd server"
      output=$(2>&1 yum -y install nfs-utils)
      retc=$?
      if [ $retc -ne 0 ]; then
         tracemsg "$ls  output: [$output]"
         errmsg "cannot install nfs daemon"
      fi
   else
      infmsg "$ls  nfs-utils already installed"
   fi
fi

if [ $retc -eq 0 ]; then
   infmsg "$ls  nfsd start"
   
   if [ "$osmain" == "" ]; then
      errmsg "unknown linux version"
      retc=98
   elif [ $osmain -eq 5 ] || [ $osmain -eq 6 ]; then
      debmsg "$ls  found version 5 or 6"
      output=$(2>&1 service nfs start)
      retc=$?
      if [ $retc -ne 0 ]; then
         tracemsg "$ls  output: [$output]"
         errmsg "cannot start nfs"
      fi
   elif [ $osmain -eq 7 ]; then
      debmsg "$ls  found version 7"
      output=$(2>&1 systemctl start nfs-server)
      retc=$?
      if [ $retc -ne 0 ]; then
         tracemsg "$ls  output: [$output]"
         errmsg "cannot start nfs"
      fi
   else
      errmsg "unknown linux version"
      retc=99
   fi
fi

if [ $retc -eq 0 ]; then
   infmsg "$ls  configure nfsd for boot start"
   if [ "$osmain" == "" ]; then
      errmsg "unknown linux version"
      retc=98
   elif [ $osmain -eq 5 ] || [ $osmain -eq 6 ]; then
      debmsg "$ls  found version 5 or 6"
      output=$(2>&1 chkconfig nfs on)
      retc=$?
      if [ $retc -ne 0 ]; then
         tracemsg "$ls  output: [$output]"
         errmsg "cannot configure autostart nfs"
      fi
   elif [ $osmain -eq 7 ]; then
      debmsg "$ls  found version 7"
      output=$(2>&1 systemctl enable nfs-server)
      retc=$?
      if [ $retc -ne 0 ]; then
         tracemsg "$ls  output: [$output]"
         errmsg "cannot configure autostart nfs"
      fi
   else
      errmsg "unknown linux version"
      retc=99
   fi
fi

if [ $retc -eq 1 ]; then
   errmsg "$ls  rc=1 means reboot - set to 2"
   retc=2
fi
infmsg "$ls $progname end rc=$retc"
exit $retc
