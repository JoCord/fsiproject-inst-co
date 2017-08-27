#!/bin/sh
#
#   create nfs mounts
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
version="1.0.8 - 25.2.2016"
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

fstab="/etc/fstab"

infmsg "$ls create fsi nfs repo mounts v.$version"

if [ $retc -eq 0 ]; then
   infmsg "$ls  create repo dirs"
   if [ -f $lxdir/$ksfile ]; then
      while read line; do
         ksline=$(echo $line| cut -c -11)
         if [ "$ksline" == "#repomount:" ] ; then
            mountp=$(echo $line| cut -d " " -f 3 | awk '{print tolower($0)}')
            tracemsg "$ls  mountp: $mountp"
            if [ "$mountp" != "" ]; then
               output=$(2>&1 mkdir -p $mountp)
               retc=$?
               if [ $retc -ne 0 ]; then
                  errmsg "error creating dir $mountp - rc=$retc"
                  errmsg "[$output]"
               else
                  exportname=$(echo $line| cut -d " " -f 2)
                  tracemsg "$ls  export: $exportname"
                  if [ "$exportname" != "" ]; then
                     debmsg "$ls  search if export already configure in $fstab"
                     out=$(grep "$exportname" $fstab)
                     notfound=$?
                     if (( $notfound )); then
                        infmsg "$ls  add export: $exportname to $fstab"
                        echo "$exportname $mountp nfs defaults 0 0 " >>$fstab
                        retc=$?
                        if [ $retc -ne 0 ]; then
                           errmsg "error adding mount to $fstab - rc=$retc"
                        fi
                     else
                        infmsg "$ls  mount point [$exportname] [$mountp] already exist"
                     fi
                  else
                     errmsg "cannot find export in ks"
                     retc=55
                  fi
               fi
            else
               errmsg "cannot get mount point from ks file - abort"
               retc=44
            fi
         fi
      done < $lxdir/$ksfile
   else
      errmsg "cannot find $lxdir/$ksfile - abort"
      retc=99
   fi
fi

infmsg "$ls End nfs mount rc=$retc"
exit $retc
