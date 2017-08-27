#!/bin/sh
#
#   install epel repo
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
ver="1.0.6 - 18.4.2016"
ls="  "
retc=0

if [ -z $lxdir ]; then
   echo "$ls load lxconf.sh"
   . /var/fsi/lxconf.sh
fi
if [ -z $osmain ]; then
   echo "$ls load lxfunc.sh"
   . /var/fsi/lxfunc.sh
fi

infmsg "$ls Install epel repo"

#repo_epel: yes
inst_repo=0
while read line; do
  ksline=$(echo $line| cut -c -11)
  if [ "$ksline" == "#repo_epel:" ] ; then
     inst_repo=$(echo $line| cut -d ":" -f 2 | awk '{print tolower($0)}' | awk '{$1=$1;print}' )
     debmsg "$ls   epel: [$inst_repo]"
     break
  fi
done < "$lxdir/$ksfile"

if [ "$inst_repo" == "1" ] || [ "$inst_repo" == "yes" ] || [ "$inst_repo" == "true" ] || [ "$inst_repo" == "enable" ]; then
   infmsg "$ls  configure epel repository"

   repo_cfg="/etc/yum.repos.d/epel.repo" 
   
   if [ -f $repo_cfg ]; then
      infmsg "$ls  backup old config"
      mv $repo_cfg{,.org}
      retc=$?
   fi
   
   if [ $retc -eq 0 ]; then
      infmsg "$ls  install repo key"
      rpm --import http://$fsisrv/repos/epel/RPM-GPG-KEY-EPEL-$osmain
      retc=$?
   fi
   
   if [ $retc -eq 0 ]; then
      infmsg "$ls  install repo files"
      tracemsg "$ls  cmd: yum -y localinstall http://$fsisrv/repos/epel/epel-release-latest-$cover.noarch.rpm"
      yum -y localinstall http://$fsisrv/repos/epel/epel-release-latest-${osmain}.noarch.rpm
      retc=$?
   fi
   
   if [ $retc -eq 0 ]; then
      infmsg "$ls  create new config $repo_cfg"
      colrm 1 9 > $repo_cfg <<"      EOF"
         [epel]
         name=Extra Packages Enterprise Linux - x86_64
         baseurl=http://##FSISRV##/repos/epel/##OSVER##/x86_64
         failovermethod=priority
         enabled=1
         gpgcheck=1
         gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-$releasever
      EOF
   
      retc=$?
   fi
   
   if [ $retc -eq 0 ]; then
      infmsg "$ls   change centos org base url"
      sed -i "s/##FSISRV##/$fsisrv/g" "$repo_cfg" 
      retc=$?
   fi   
   if [ $retc -eq 0 ]; then
      infmsg "$ls   change centos org base url"
      sed -i "s/##OSVER##/${osmain}/g" "$repo_cfg" 
      retc=$?
   fi   
else
   infmsg "$ls  epel repository will not configure"
fi

if [ $retc -eq 1 ]; then
   debmsg "$ls  rc=1 means reboot, change to 2"
   retc=2
fi
infmsg "$ls End repo installation rc=$retc "
exit $retc

