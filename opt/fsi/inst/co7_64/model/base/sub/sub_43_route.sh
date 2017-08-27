#!/bin/sh
#
#   add additional routes
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
version="1.0.1 - 16.10.2015"
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

infmsg "$ls Start adding additional routes v$version"

networkdir="/etc/sysconfig/network-scripts"
infmsg "$ls add additional routes v.$version"

if [ $retc -eq 0 ]; then
   infmsg "$ls  search addroute config"
   if [ -f $lxdir/$ksfile ]; then
      while read line; do
         ksline=$(echo $line| cut -c -10)
         if [ "$ksline" == "#addroute:" ] ; then
            routenet=$(echo $line| cut -d " " -f 2)
            tracemsg "$ls  target route net: $routenet"
            routenm=$(echo $line| cut -d " " -f 3)
            tracemsg "$ls  netmask: $routenm"
            routegw=$(echo $line| cut -d " " -f 4)
            tracemsg "$ls  gateway: $routegw"
            routenic=""
            routenic=$(echo $line| cut -d " " -f 5)
            tracemsg "$ls  route nic: $routenic"
            
            if [ "$routenic" != "" ]; then
               echo "$routenet/$routenm via $routegw dev $routenic" >>"$networkdir/route-$routenic"
               retc=$?
               if [ $retc -ne 0 ]; then
                  errmsg "error creating route file - rc=$retc"
               fi
            else
               errmsg "cannot get all route informations from ks file - abort"
               retc=44
            fi
         fi
      done < $lxdir/$ksfile
   else
      errmsg "cannot find $lxdir/$ksfile - abort"
      retc=99
   fi
fi

infmsg "$ls $progname end rc=$retc"
exit $retc
