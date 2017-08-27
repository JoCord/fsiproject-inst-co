#!/bin/sh
#
#   install RepoForge repo
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
ver="1.0.1 - 15.9.2015"
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

infmsg "$ls Install repoforge repo"

#repo_forge: yes
inst_repo=0
while read line; do
  ksline=$(echo $line| cut -c -12)
  if [ "$ksline" == "#repo_forge:" ] ; then
     inst_repo=$(echo $line| cut -d ":" -f 2 | awk '{print tolower($0)}' | awk '{$1=$1;print}' )
     debmsg "$ls   repo forge: [$inst_repo]"
     break
  fi
done < "$lxdir/$ksfile"

if [ "$inst_repo" == "1" ] || [ "$inst_repo" == "yes" ] || [ "$inst_repo" == "true" ] || [ "$inst_repo" == "enable" ]; then
   infmsg "$ls  configure repoforge repository"
   repo_cfg="/etc/yum.repos.d/rpmforge.repo" 
   
   if [ $retc -eq 0 ]; then
      infmsg "$ls  install repo key"
      rpm --import http://$fsisrv/repos/repoforge/RPM-GPG-KEY.dag.txt
      retc=$?
   fi
   
   
   if [ $retc -eq 0 ]; then
      infmsg "$ls  install repo rpm"
      yum -y localinstall http://$fsisrv/repos/repoforge/redhat/el${osmain}/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.3-1.el${osmain}.rf.x86_64.rpm
      retc=$?
   
   #   if [ "$osmain" == "" ]; then
   #      errmsg "unknown linux version"
   #      retc=98
   #   elif [ $osmain -eq 5 ]; then
   #      debmsg "$ls  found version 5: install rpmforge"
   #      yum -y localinstall http://$fsisrv/repos/repoforge/redhat/el5/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.3-1.el5.rf.x86_64.rpm
   #      retc=$?
   #   elif [ $osmain -eq 6 ]; then
   #      debmsg "$ls  found version 6: install rpmforge"
   #      yum -y localinstall http://$fsisrv/repos/repoforge/redhat/el6/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
   #      retc=$?
   #   elif [ $osmain -eq 7 ]; then
   #      debmsg "$ls  found version 7: install rpmforge"
   #      yum -y localinstall http://$fsisrv/repos/repoforge/redhat/el7/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.3-1.el7.rf.x86_64.rpm
   #      retc=$?
   #   else
   #      errmsg "unknown linux version"
   #      retc=99
   #   fi      
   fi
   
   if [ -f $repo_cfg ]; then
      infmsg "$ls  backup old config"
      mv $repo_cfg{,.org}
      retc=$?
   fi
   
   if [ $retc -eq 0 ]; then
      infmsg "$ls  create new config $repo_cfg"
      colrm 1 9 > $repo_cfg <<"      EOF"
         [rpmforge]
         name = RHEL $releasever - RPMforge.net - dag
         baseurl = http://##SRV##/repos/repoforge/redhat/##VER##/en/$basearch/rpmforge
         enabled = 1
         protect = 0
         gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmforge-dag
         gpgcheck = 1
         exclude=perl-XML-SAX-Base
         
         [rpmforge-extras]
         name = RHEL $releasever - RPMforge.net - extras
         baseurl = http://##SRV##/repos/repoforge/redhat/##VER##/en/$basearch/extras
         enabled = 0
         protect = 0
         gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmforge-dag
         gpgcheck = 1
         
         [rpmforge-testing]
         name = RHEL $releasever - RPMforge.net - testing
         baseurl = http://##SRV##/repos/repoforge/redhat/##VER##/en/$basearch/testing
         enabled = 0
         protect = 0
         gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmforge-dag
         gpgcheck = 1
      EOF
      retc=$?
   fi
   
   if [ $retc -eq 0 ]; then
      infmsg "$ls   change centos org base url"
      sed -i "s/##SRV##/$fsisrv/g" "$repo_cfg" 
      retc=$?
   fi   
   
   if [ $retc -eq 0 ]; then
      infmsg "$ls   change repo version"
      sed -i "s/##VER##/el$osmain/g" "$repo_cfg" 
      retc=$?
   fi   
else
   infmsg "$ls  repoforge repository will not configure"
fi

if [ $retc -eq 1 ]; then
   debmsg "$ls  rc=1 means reboot, change to 2"
   retc=2
fi
infmsg "$ls End repo installation rc=$retc "
exit $retc

