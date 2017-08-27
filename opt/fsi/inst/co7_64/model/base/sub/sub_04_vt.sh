#!/bin/sh
#
#   install open vm tools
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
version="1.0.3 - 26.2.2016"
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


repo_cfg="/etc/yum.repos.d/vmware.repo" 


infmsg "$ls Install VM Tools v.$version"

inst_vt=0
while read line; do
  ovtline=$(echo $line| cut -c -9)
  if [ "$ovtline" == "#inst_vt:" ] ; then
     inst_vt=$(echo $line| cut -d ":" -f 2 | awk '{print tolower($0)}' | awk '{$1=$1;print}' )
     infmsg "$ls   inst vm tools: [$inst_vt]"
     break
  fi
done < "$lxdir/$ksfile"

if [ "$inst_vt" == "1" ] || [ "$inst_vt" == "yes" ] || [ "$inst_vt" == "true" ] || [ "$inst_vt" == "enable" ]; then
   
   if [ "$osmain" == "" ]; then
      errmsg "unknown linux version"
      retc=98
   elif [ $osmain -eq 7 ] || [ $osmain -eq 6 ]; then
      debmsg "$ls  found version 7 or 6"
      infmsg "$ls  install flag found - install open vm tools"
      output=$(yum -y install open-vm-tools)
      retc=$?
      if [[ $retc -ne 0 ]]; then
         errmsg "cannot install open vm tools rc=$retc"
         errmsg "output: $output"
      fi
   elif [ $osmain -eq 5 ]; then
      debmsg "$ls  found version 7"

      infmsg "$ls  install vmware-tools"
      infmsg "$ls  create new yum config $repo_cfg"
      colrm 1 9 > $repo_cfg <<"      EOF"
         [vmware]
         name=VMware Packages - x86_64
         baseurl=http://##FSISRV##/repos/vmware/rhel5_x86_64
         failovermethod=priority
         enabled=1
         gpgcheck=1
         gpgkey=file:///etc/pki/rpm-gpg/VMWARE-PACKAGING-GPG-RSA-KEY.pub
      EOF
   
      if [ $retc -eq 0 ]; then
         infmsg "$ls   change centos org base url"
         sed -i "s/##FSISRV##/$fsisrv/g" "$repo_cfg" 
         retc=$?
      fi   

      if [ $retc -eq 0 ]; then
         infmsg "$ls   get gpg key"
         output=$(2>&1 wget http://$fsisrv/repos/vmware/VMWARE-PACKAGING-GPG-RSA-KEY.pub -O /etc/pki/rpm-gpg/VMWARE-PACKAGING-GPG-RSA-KEY.pub)
         retc=$?
      fi

      if [ $retc -eq 0 ]; then
         infmsg "$ls   install vmware-tools"
         output=$(2>&1 yum -y install vmware-tools-core vmware-tools-plugins-autoUpgrade)
         retc=$?
      fi
   else
      errmsg "unknown linux version"
      retc=99
   fi

else
   infmsg "$ls  no install flag found or false/disable/no/0"
fi

if [ $retc -eq 1 ]; then
   debmsg "$ls  rc=1 means reboot, change to 2"
   retc=2
fi
infmsg "$ls $progname end rc=$retc"
exit $retc
