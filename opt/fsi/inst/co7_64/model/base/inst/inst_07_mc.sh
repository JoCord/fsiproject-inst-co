#!/bin/sh
#
#   inst_07_mc.sh - install mc
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
ver="1.0.12 - 3.5.2016"
ls="  "
retc=0
infmsg "$ls Install & Configure mc"

output=$(2>&1 rpm -qi mc)
inst=$?
if [ $inst -ne 0 ]; then
   infmsg "$ls  no mc installed - try to install now ..."
   output=$(2>&1 yum -y install bind)
   retc=$?
   if [ $retc -ne 0 ]; then
      tracemsg "$ls  output: [$output]"
      errmsg "cannot install mc"
   fi
else
   infmsg "$ls  mc already installed"
fi

if [ $retc -eq 0 ]; then
   infmsg "$ls  install rpm ok"
   infmsg "$ls  create config dir"
   if [ "$osmain" == "" ]; then
      OUTPUT="unknown linux"
      retc=98
   elif [ $osmain -eq 5 ] || [ $osmain -eq 6 ]; then
      debmsg "$ls  found version 5 or 6"
      OUTPUT=$(2>&1 mkdir /root/.mc)
      retc=$?
   elif [ $osmain -eq 7 ]; then
      debmsg "$ls  found version 7"
      OUTPUT=$(2>&1 mkdir -p /root/.config/mc)
   else
      OUTPUT="unknown linux"
      retc=99
   fi
   if [ $retc -ne 0 ]; then
      errmsg "creating mc config dir: $OUTPUT - abort"
      retc=98
   fi
fi

if [ $retc -eq 0 ]; then
   infmsg "$ls  config dir created"
   infmsg "$ls  copy mc settings in config dir"
   
   if [ "$osmain" == "" ]; then
      CP_OUTPUT="unknown linux"
      retc=98
   elif [ $osmain -eq 5 ] || [ $osmain -eq 6 ]; then
      debmsg "$ls  found version 5 or 6"
      tracemsg "$ls  copy ini"
      CP_OUTPUT=$(2>&1 cp -f $localtemp/ini.mc /root/.mc/ini)
      retc=$?
   elif [ $osmain -eq 7 ]; then
      debmsg "$ls  found version 7"
      tracemsg "$ls  copy ini"
      CP_OUTPUT=$(2>&1 cp -f $localtemp/ini.mc7 /root/.config/mc/ini)
      retc=$?
      if [ $retc -eq 0 ]; then
         tracemsg "$ls  copy panels"
         CP_OUTPUT=$(2>&1 cp -f $localtemp/panels.mc7 /root/.config/mc/panels.ini)
         retc=$?
      fi
   else
      CP_OUTPUT="unknown linux"
      retc=99
   fi
   if [ $retc -ne 0 ]; then
      errmsg "copy mc config: $CP_OUTPUT - abort"
      retc=98
   else
      infmsg "$ls  mc settings copy ok"
   fi
fi

if [ $retc -eq 1 ]; then
   errmsg "$ls  rc=1 means reboot - set to 2"
   retc=2
fi
infmsg "$ls End $progname installation rc=$retc "
exit $retc