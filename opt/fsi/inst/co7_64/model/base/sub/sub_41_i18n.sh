#!/bin/sh
#
#   change default language to english
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
version="1.0.2 - 24.2.2016"
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

infmsg "$ls default language settings v.$version"

changelang="en_US.UTF-8"
changefont="latarcyrheb-sun16"

while read line; do
  cfgline=$(echo $line| cut -c -6)
  if [ "$cfgline" == "#lang:" ] ; then
     changelang=$(echo $line| cut -d ":" -f 2 | awk '{print tolower($0)}' | awk '{$1=$1;print}' )
     infmsg "$ls found config to change lang to: $changelang"
     break
  fi
done < "$lxdir/$ksfile"
while read line; do
  cfgline=$(echo $line| cut -c -6)
  if [ "$cfgline" == "#font:" ] ; then
     changefont=$(echo $line| cut -d ":" -f 2 | awk '{print tolower($0)}' | awk '{$1=$1;print}' )
     infmsg "$ls found config to change font to: $changefont"
     break
  fi
done < "$lxdir/$ksfile"

if [ "$changelang" != "" ]; then
   infmsg "$ls change lang to: $changelang"
   infmsg "$ls change font to: $changefont"
   if [ "$osmain" == "" ]; then
      errmsg "unknown linux version"
      retc=98
   elif [ $osmain -eq 5 ] || [ $osmain -eq 6 ]; then
      debmsg "$ls  set language in i18n (5/6)"
      colrm 1 9 >/etc/sysconfig/i18n << EOFini
         LANG="$changelang"
         SYSFONT="$changefont"
EOFini
      retc=$?         
   elif [ $osmain -eq 7 ]; then
      debmsg "$ls  set language in locale.conf (7)"
      colrm 1 9 >/etc/locale.conf << EOFini
         LANG="$changelang"
         SYSFONT="$changefont"
EOFini
      retc=$?         
   else
      errmsg "unknown linux version"
      retc=99
   fi
fi

if [ $retc -eq 1 ]; then
   debmsg "$ls  rc=1 means reboot, change to 2"
   retc=2
fi
infmsg "$ls $progname end rc=$retc"
exit $retc
