#!/bin/sh
#
#   configure boot screen
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
version="1.0.1 - 20.4.2015"
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

infmsg "$ls Configure boot v.$version"

if [ "$osmain" == "" ]; then
   errmsg "unknown linux version"
   retc=98
elif [ $osmain -eq 5 ] || [ $osmain -eq 6 ]; then
   infmsg "$ls  found version 5 or 6"
   grubcfg="/boot/grub/grub.conf"
   
   if [ -f $grubcfg ]; then
      infmsg "$ls   backup old config"
      cp $grubcfg{,.org}
      retc=$?
      if [ $retc -ne 0 ]; then
         errmsg "cannot backup $grubcfg"
      fi
   fi
   
   if [ $retc -eq 0 ]; then
      infmsg "$ls  del quiet and rhgb parameter"
      sed -i s'/rhgb quiet//'g $grubcfg
      retc=$?
      if [ $retc -ne 0 ]; then
         errmsg "cannot del quiet and rhgb in $grubcfg"
      fi
   fi
elif [ $osmain -eq 7 ]; then
   infmsg "$ls  found version 7"
   debmsg "  delete quiet boot mode"
   /usr/bin/sed -i '/^GRUB_CMDLINE_LINUX.*/ s/rhgb quiet//' "/etc/default/grub"
   rc=$?
   if [ $rc -ne 0 ]; then
      errmsg "cannot del grub2 quiet mode - abort (rc=$rc)"
      exit $rc
   fi

   debmsg "  start grub2 config"
   /usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg
   rc=$?
   if [ $rc -ne 0 ]; then
      errmsg "cannot recreate grub2 config - abort (rc=$rc)"
      exit $rc
   fi
else
   errmsg "unknown linux version"
   retc=99
fi

if [ $retc -eq 1 ]; then
   debmsg "$ls  rc=1 means reboot, change to 2"
   retc=2
fi
infmsg "$ls End boot configure rc=$retc"
exit $retc
