#!/bin/sh
#
#   register to rh
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
version="1.0.0 - 15.4.2016"
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

infmsg "$ls register system v.$version"

rhreg=false

if [ $retc -ne 0 ]; then
   if [ -f $lxdir/$ksfile ]; then
      while read line; do
         ksline=$(echo $line| cut -c -7)
         if [ "$ksline" == "#regrh:" ] ; then
            rhuser=$(echo $line| cut -d " " -f 2)
            rhpw=$(echo $line| cut -d " " -f 3)
            tracemsg "$ls  rh user: $rhuser / rh pw: $rhpw"
            if [ -z $rhuser ] || [ -z $rhpw ]; then
               warnmsg "$ls  noch rh user or password configure - do not register this system"
            else
               infmsg "$ls  register this server to rh ..."
               out=$(/usr/sbin/subscription-manager register --servicelevel=NONE --username $rhuser --password $rhpw --auto-attach --autosubscribe)
               retc=$?
               if [ $retc -ne 0 ]; then
                  errmsg "cannot register server"
                  errmsg "[$out]"
               else
                  infmsg "$ls  system registered"
                  tracemsg "[$out]"
                  rhreg=true
               fi
            fi
         fi
      done < $lxdir/$ksfile
   else
      errmsg "cannot find $lxdir/$ksfile - abort"
      retc=99
   fi
fi

if [ $retc -ne 0 ]; then
   echo rhreg=$rhreg >>$lxconf
fi

infmsg "$ls $progname end rc=$retc"
exit $retc
