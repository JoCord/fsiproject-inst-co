#!/bin/sh
#
#   change resolv.conf
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
version="1.0.1 - 21.10.2015"
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

infmsg "$ls change resolv.conf v.$version"

resolvconf="/etc/resolv.conf"

kssearch=""

if [ -f $lxdir/$ksfile ]; then
   while read line; do
      ksline=$(echo $line| cut -c -8)
      if [ "$ksline" == "#search:" ] ; then
         kssearch=$(echo $line| cut -d " " -f 2)
         tracemsg "$ls  ks.cfg search domain: $kssearch"
         if [ "$kssearch" != "" ]; then
            infmsg "$ls  found search domain in ks.cfg [$kssearch]"
         else
            warnmsg "$ls  no search domain in ks.cfg - ignore"
         fi
      fi
   done < $lxdir/$ksfile
else
   errmsg "cannot find $lxdir/$ksfile - abort"
   retc=99
fi

if [ $retc -eq 0 ]; then
   if [ "$kssearch" == "" ]; then
      infmsg "$ls  no search domain found in ks.cfg - try hostname suffix"
      hsearch=$(hostname -d)
      if [ "$hsearch" != "" ]; then
         infmsg "$ls  found search domain from hostname [$hsearch]"
      else
         warnmsg "$ls  no search domain found from hostname - ignore"
      fi
   fi
fi
if [ $retc -eq 0 ]; then
   foundsearch=$(grep -ie "^search " $resolvconf)
   foundrc=$?
   if [ $foundrc -eq 0 ]; then
      foundsearch=$(echo $foundsearch | cut -d " " -f 2)
      infmsg "$ls  found search domain in resolv.conf [$foundsearch]"
      if [ -z "$foundsearch" ] && [ -z "$kssearch" ] && [ -z $hsearch ]; then
         errmsg "cannot find search domain in ks.cfg, hostname nor in resolv.conf"
         retc=99
      elif [ ! -z "$kssearch" ]; then
         infmsg "$ls  take ks.cfg search override"
         sed -i "/search / s/.*/search $kssearch/" $resolvconf
         retc=$?
         if [ $retc -ne 0 ]; then
            errmsg "cannot add [$kssearch] to $resolvconf"
         fi
      else
         infmsg "$ls  do not change resolv.conf"
      fi
   else
      infmsg "$ls  no search domain in resolv.conf - try to add"
      if [ ! -z "$kssearch" ]; then
         infmsg "$ls  take ks.cfg search domain"
         echo "search $kssearch" >>$resolvconf
         retc=$?
         if [ $retc -ne 0 ]; then
            errmsg "cannot add [$kssearch] to $resolvconf"
         fi
      elif [ ! -z "$hsearch" ]; then
         infmsg "$ls  take search domain from hostname"
         echo "search $hsearch" >>$resolvconf
         retc=$?
         if [ $retc -ne 0 ]; then
            errmsg "cannot add [$hsearch] to $resolvconf"
         fi
      else
         errmsg "no domain search to add - abort"
         retc=98
      fi
   fi
fi

if [ $retc -eq 0 ]; then
   infmsg "$ls  delete save resolv.conf"
   if [ -f $resolvconf.save ]; then
      /bin/rm -f $resolvconf.save
   fi
fi

infmsg "$ls $progname end rc=$retc"
exit $retc
