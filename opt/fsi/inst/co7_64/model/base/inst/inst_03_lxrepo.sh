#!/bin/sh
#
#   install linux os base repos
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
ver="1.0.5 - 18.4.2016"
ls="  "
retc=0
infmsg "$ls Install OS base repo"


if [[ "$lxtree" =~ ^rh ]]; then
   infmsg "$ls  install RedHat repos"
   rh_cfg="/etc/yum.repos.d/fsirh.repo" 

   if [ $retc -eq 0 ]; then
      infmsg "$ls  create new config $rh_cfg"
      colrm 1 9 > $rh_cfg <<'      EOF'
         [redhat]
         name=RedHat Enterprise Linux - x86_64
         baseurl=http://##FSISRV##/repos/redhat/$releasever/os/x86_64
         failovermethod=priority
         enabled=1
         gpgcheck=1
         gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
      EOF
      retc=$?
   fi

   if [ $retc -eq 0 ]; then
      infmsg "$ls   change fsi server"
      sed -i "s/##FSISRV##/$fsisrv/g" "$rh_cfg" 
      retc=$?
   fi   

elif [[ "$lxtree" =~ ^co ]]; then
   infmsg "$ls  install CentOS repos"

   repocfg="/etc/yum.repos.d/CentOS-Base.repo"
   if [ -f $repocfg ]; then
      infmsg "$ls   move old config"
      cp $repocfg{,.org}
      retc=$?
   fi
   
   if [ $retc -eq 0 ]; then
      infmsg "$ls  change host name"
      /bin/sed -i "/^#baseurl.*/ s/mirror.centos.org/$fsisrv\/repos/" "$repocfg"
      retc=$?
   fi
   
   if [ $retc -eq 0 ]; then
      infmsg "$ls  enable baseurl"
      /bin/sed -i "/^#baseurl.*/ s/#baseurl/baseurl/" "$repocfg"
      retc=$?
   fi
   
   if [ $retc -eq 0 ]; then
      infmsg "$ls  disable mirrorlist"
      /bin/sed -i "s/mirrorlist/#mirrorlist/" "$repocfg"
      retc=$?
   fi

else
   errmsg "unknow linux tree - abort"
   retc=99
fi

infmsg "$ls End repo installation rc=$retc "
exit $retc

