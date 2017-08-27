#!/bin/sh
#
#   Post-Install-Script after RedHat Anaconda Install
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
ver="1.00.07 - 12.6.2015"
retc=0
ls=""
progname=${0##*/}
SOURCE="${BASH_SOURCE[0]}"
DIR="$( dirname "$SOURCE" )"
while [ -h "$SOURCE" ]
do 
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
  DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd )"
done

export progdir="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

logmsg "INFO   : Install Linux $lxtree v $ver"
logmsg "INFO   :  set env variable"

fsimount="/opt/fsi/inst/"$lxtree"/ks"
lxconf=$lxdir"/lxconf.sh"
kspath="/mnt/fsisrv"
ksfile=$lxtree".cfg"
stagefile=$lxdir"/lxinst.stage"

logmsg "INFO   :  create local mount dir for fsi server "
mkdir $kspath
rc=$?
if [ $rc -ne 0 ]; then
   logmsg "ERROR   : cannot create local mount dir - abort (rc=$rc)"
   exit $rc
fi
  
logmsg "INFO   :  download install script linux"
wget http://$fsisrv/fsi/$lxtree/ks/lxinst.sh -P $lxdir
rc=$?
if [ $rc -ne 0 ]; then
   logmsg "ERROR   : cannot wget lxinst.sh - abort (rc=$rc)"
   exit $rc
fi

logmsg "INFO   :  download function lib linux"
wget http://$fsisrv/fsi/$lxtree/ks/etc/lxfunc.sh -P $lxdir
rc=$?
if [ $rc -ne 0 ]; then
   logmsg "ERROR   : cannot wget lxfunc.sh - abort (rc=$rc)"
   exit $rc
fi

if [ -f $lxdir/lxfunc.sh ] ; then
    . $lxdir/lxfunc.sh
else
    logmsg "ERROR  : cannot load lx functions"
    echo "ERROR  : cannot load lx functions - abort [$rc]" >$lxerror
    exit 99
fi


infmsg " write env variable in conf file"   
echo export lxconf=$lxconf >>$lxconf
echo export lxdir=$lxdir >>$lxconf
echo export lxerror=$lxerror >>$lxconf
echo export lxver=$lxver >>$lxconf
echo export lxarch=$lxarch >>$lxconf
echo export lxtree=$lxtree >>$lxconf
echo export fsisrv=$fsisrv >>$lxconf
echo export fsimount=$fsimount >>$lxconf
echo export kspath=$kspath >>$lxconf
echo export ksfile=$ksfile >>$lxconf
echo export logfile=$logfile >>$lxconf
echo export stagefile=$stagefile >>$lxconf


infmsg " run chmod"
chmod 0777 $lxdir/lxinst.sh
rc=$?
if [ $rc -ne 0 ]; then
   errmsg "cannot chmod lxinst.sh - abort (rc=$rc)"
   exit $rc
fi

infmsg " backup org rc.local"
/bin/cp -f -p /etc/rc.d/rc.local $lxdir/rc.local.sik
rc=$?
if [ $rc -ne 0 ]; then
   errmsg " cannot backup rd.local - abort (rc=$rc)"
   exit $rc
fi

infmsg " extend rc.local"
echo "$lxdir/lxinst.sh ">>/etc/rc.d/rc.local
rc=$?
if [ $rc -ne 0 ]; then
   errmsg "cannot extend rc.local - abort (rc=$rc)"
   exit $rc
fi

infmsg " chmod rc.local"
chmod +x /etc/rc.d/rc.local
rc=$?
if [ $rc -ne 0 ]; then
   errmsg "cannot chmod rc.local - abort (rc=$rc)"
   exit $rc
fi

tracemsg " set stage to 2"
echo 2 >$stagefile
rc=$?
if [ $rc -ne 0 ]; then
   errmsg "cannot set stagefile $stagefile - abort (rc=$rc)"
   exit $rc
fi

infmsg "End - $progname [$rc]"
