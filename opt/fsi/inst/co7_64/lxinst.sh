#!/bin/sh
#
#   Customize-Script for Post-Installation CentOS Server
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
ver="2.00.10 - 09.05.2017"
retc=0
ls=""
progname=${0##*/}
SOURCE="${BASH_SOURCE[0]}"
DIR="$( dirname "$SOURCE" )"
while [ -h "$SOURCE" ]; do
   SOURCE="$(readlink "$SOURCE")"
   [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
   DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd )"
done

export progdir="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

mac="none"
kspath="none"
stage=0
stagefirst=2
export lxdir="/var/fsi"
export lxconf="$lxdir/lxconf.sh"
export lxfunc="$lxdir/lxfunc.sh"
export localtemp="/tmp/fsi" # stage beachten

if [ -f $lxfunc ]; then
   echo Load $lxfunc
   . $lxfunc
else
   echo Cannot find $lxfunc >/root/lxerror
   exit 99
fi
if [ -f $lxconf ]; then
   echo Load $lxconf
   . $lxconf
else
   echo Cannot find $lxconf >/root/lxerror
   exit 99
fi

infmsg "Start $progname ver $ver"
warte 2
# Stage run ?
tracemsg " Search stagefile $stagefile"
if [ -e $stagefile ] ; then
   while read line ; do stage=$line ; done < $stagefile
   debmsg " Stage $stage"
else
   errmsg "something wrong - no stage file."
   exit 99
fi

infmsg " Running on $(hostname -s)"

if [ -d $kspath/log ]; then
   infmsg " fsi server already mounted"
else
   infmsg " mount fsi server"
   tracemsg "  fsi srv: $fsisrv"
   tracemsg "  fsi mount: $fsimount"
   tracemsg "  ks path: $kspath"
   if [ ! -d $kspath ]; then
      OUTPUT=$(2>&1 mkdir -p $kspath)
      retc=$?
      if [ $retc -ne 0 ]; then
         logmsg "ERROR cannot create dir $kspath = $OUTPUT - abort"
      fi 
   fi   
   if [ $retc -eq 0 ]; then
      tracemsg "  cmd: mount -t nfs $fsisrv:$fsimount $kspath"
      mount -t nfs $fsisrv:$fsimount $kspath
      retc=$?
      if [ $retc -eq 0 ]; then
         tracemsg " mount ok"
         # output=$(ls -lisaR $kspath)
         # tracemsg "  fsi: $output"
      else
         errmsg "cannot mount fsi server - abort"
      fi
   fi
fi

if [ $retc -eq 0 ]; then
   if [ "$mac" == "none" ]; then
      debmsg " detec mac"
      macp=""
      if [ "$osmain" == "" ]; then
         errmsg "unknown linux version"
         retc=98
      elif [ $osmain -eq 5 ] || [ $osmain -eq 6 ]; then
         debmsg "  try detec mac (5/6)"
         macp=$(/sbin/ifconfig -a eth0 | /bin/grep -m 1 -i "ethernet " | tr -s " " | cut -d " " -f 5 | tr '[:upper:]' '[:lower:]')
      elif [ $osmain -eq 7 ]; then
         debmsg "  try detec mac (7)"
         macp=$(/sbin/ifconfig -a eth0 | /bin/grep -m 1 -i "ether " | tr -s " " | cut -d " " -f 3 | tr '[:upper:]' '[:lower:]')
      else
         errmsg "unknown linux version"
         retc=99
      fi
      
      tracemsg "  found mac [$macp]"
      if [ "$macp" == "" ]; then
         t=$(/sbin/ifconfig -a eth0)
         errmsg "eth0: $t"
         errmsg "cannot detect mac - abort"
         retc=99
      elif [[ ! "$macp" =~ $macregex ]]; then
         tracemsg "  mac reg: $macregex"
         errmsg "mac [$macp] is not a valid mac format adress - abort"
         retc=98
      else
         export macd=$(echo $macp | tr ':' '-')
         export mac=${macp//:/}
         debmsg "  mac found [$mac]"
         echo export mac=$mac >>$lxconf
         infmsg "  mac found [$macd]"
         echo export macd=$macd >>$lxconf
         echo export localtemp=$localtemp >>$lxconf
      fi
   else
      debmsg " get mac from config"
      debmsg "  mac found [$mac]"
      infmsg "  mac found [$macd]"
   fi
fi

if [ $retc -eq 0 ]; then
   if [ $stage -eq $stagefirst ]; then
      infmsg " First run configurations started"
#      if [ $retc -eq 0 ]; then
#         if [ -f $lxdir/$ksfile ]; then
#            debmsg "  delete old ks config file"
#            OUTPUT=$(/bin/rm -f $lxdir/$ksfile)
#            retc=$?
#            if [ $retc -ne 0 ]; then
#               errmsg "cannot delete old ks config file $ksfile - abort (rc=$retc)"
#               errmsg "Output: $OUTPUT"
#            fi
#         fi
#      fi
      if [ $retc -eq 0 ]; then
         if [ ! -f $lxdir/$ksfile ]; then
            infmsg " download ks config"
            OUTPUT=$(2>&1 wget http://$fsisrv/pxe/sys/$macd/$ksfile -P $lxdir)
            retc=$?
            if [ $retc -ne 0 ]; then
               errmsg "cannot wget $ksfile - abort (rc=$retc)"
               errmsg "Output: $OUTPUT"
            fi
         else
            infmsg " found fsi $lxdir/$ksfile - take this one"
         fi
      fi
   fi
   
   if [ $retc -eq 0 ]; then
      if [ -f $lxdir/$ksfile ]; then
         tracemsg "  search ks file for model string"
         model=$(awk '/^#model: / {print tolower($2)}' "$lxdir/$ksfile")
         if [ "$model" == "" ]; then
            infmsg " ==> no model found - base linux installation"
            model="base"
            infmsg " ==> model: $model"
         else
            infmsg " ==> model: $model"
         fi
      else
         tracemsg "  lxdir: $lxdir"
         tracemsg "  ksfile: $ksfile"
         errmsg "  no ks file $ksfile found"
         retc=99
      fi
   fi
   
   if [ $retc -eq 0 ]; then
      if [ $stage -eq $stagefirst ]; then
         # Copy tools - viupdate, createvm
         if [ $retc -eq 0 ]; then
            base_model_tools_path="$kspath/model/base/tools"
            tracemsg "   base tools path: $base_model_tools_path"
            infmsg " search base model tools .."
            files=$(shopt -s nullglob dotglob; echo $base_model_tools_path/*)
            if (( ${#files} )); then
               infmsg " found base model tools - copy tools"
               OUTPUT=$(2>&1 /bin/cp -p -f $base_model_tools_path/* /usr/bin/)
               retc=$?
               if [ $retc -ne 0 ] ; then
                  errmsg "cannot copy base tool files - abort rc=$retc"
                  errmsg "Output: $OUTPUT"
               else
                  tracemsg "  copy tools ok"
               fi
            else
               debmsg "  no base tools found"
            fi
            copylog
         fi
         if [ $retc -eq 0 ]; then
            model_tools_path="$kspath/model/$model/tools"
            tracemsg "   tools path: $model_tools_path"
            infmsg " search model tools .."
            files=$(shopt -s nullglob dotglob; echo $model_tools_path/*)
            if (( ${#files} )); then
               infmsg " found model tools - copy tools"
               OUTPUT=$(2>&1 /bin/cp -p -f $model_tools_path/* /usr/bin/)
               retc=$?
               if [ $retc -ne 0 ] ; then
                  errmsg "cannot copy tool files - abort rc=$retc"
                  errmsg "Output: $OUTPUT"
               else
                  tracemsg "  copy tools ok"
               fi
            else
               debmsg "  no tools found"
            fi
            copylog
         fi
         
         # 3rd Party RPMS
         if [ $retc -eq 0 ]; then
            debmsg "  search and copy additional rpms"
            base_model_rpm_path="$kspath/model/base/rpm"
            tracemsg "   base rpm path: $base_model_rpm_path"
            infmsg " search base additional rpms"
            files=$(shopt -s nullglob dotglob; echo $base_model_rpm_path/*)
            if (( ${#files} )); then
               infmsg "  Copy 3rd party RPMs"
               if [ ! -d $localtemp ]; then
                  OUTPUT=$(2>&1 mkdir $localtemp )
                  retc=$?
                  if [ $retc -ne 0 ]; then
                     errmsg "cannot create local temp path : $localtemp"
                     errmsg "output [$retc]: $OUTPUT"
                  fi
               fi
               if [ $retc -eq 0 ]; then
                  OUTPUT=$(2>&1 /bin/cp -p -f $base_model_rpm_path/* $localtemp/)
                  retc=$?
                  if [ $retc -ne 0 ]; then
                     errmsg "cannot copy rpm files - abort"
                     errmsg "Output: $OUTPUT"
                  else
                     tracemsg "   copy ok"
                  fi
               fi
               copylog
            else
               debmsg "   no base files in rpm found"
            fi

            if [ $retc -eq 0 ]; then
               debmsg "  search and copy additional rpms"
               model_rpm_path="$kspath/model/$model/rpm"
               tracemsg "   rpm path: $model_rpm_path"
               infmsg " search model additional rpms"
               files=$(shopt -s nullglob dotglob; echo $model_rpm_path/*)
               if (( ${#files} )); then
                  infmsg "  Copy 3rd party RPMs"
                  if [ ! -d $localtemp ]; then
                     OUTPUT=$(2>&1 mkdir $localtemp )
                     retc=$?
                     if [ $retc -ne 0 ]; then
                        errmsg "cannot create local temp path : $localtemp"
                        errmsg "output [$retc]: $OUTPUT"
                     fi
                  fi
                  if [ $retc -eq 0 ]; then
                     OUTPUT=$(2>&1 /bin/cp -p -f $model_rpm_path/* $localtemp/)
                     retc=$?
                     if [ $retc -ne 0 ]; then
                        errmsg "cannot copy rpm files - abort"
                        errmsg "Output: $OUTPUT"
                     else
                        tracemsg "   copy ok"
                     fi
                  fi
                  copylog
               else
                  debmsg "   no files in rpm found"
               fi
            fi
            
            if [ $retc -eq 0 ]; then
               debmsg "   search and copy base additional installation scripts"
               base_model_inst_path="$kspath/model/base/inst"
               tracemsg "   base inst path: $base_model_inst_path"
               infmsg " search base inst scripts"
               files=$(shopt -s nullglob dotglob; echo $base_model_inst_path/*)
               if (( ${#files} )); then
                  if [ ! -d $localtemp ]; then
                     OUTPUT=$(2>&1 mkdir $localtemp )
                     retc=$?
                     if [ $retc -ne 0 ]; then
                        errmsg "cannot create local temp path : $localtemp"
                        errmsg "output [$retc]: $OUTPUT"
                     fi
                  fi
                  if [ $retc -eq 0 ]; then
                     infmsg "  Copy base 3rd party install routines"
                     OUTPUT=$(2>&1 /bin/cp -p -f $base_model_inst_path/inst*.sh $localtemp/)
                     retc=$?
                     if [ $retc -ne 0 ]; then
                        errmsg "cannot copy install files - abort rc=$retc"
                        errmsg "Output: $OUTPUT"
                     else
                        debmsg "   copy ok"
                     fi
                  fi
               else
                  debmsg "   no base inst routines found"
               fi
            fi
            copylog

            if [ $retc -eq 0 ]; then
               debmsg "   search and copy additional installation scripts"
               model_inst_path="$kspath/model/$model/inst"
               tracemsg "   inst path: $model_inst_path"
               infmsg " search model inst scripts"
               files=$(shopt -s nullglob dotglob; echo $model_inst_path/*)
               if (( ${#files} )); then
                  if [ ! -d $localtemp ]; then
                     OUTPUT=$(2>&1 mkdir $localtemp )
                     retc=$?
                     if [ $retc -ne 0 ]; then
                        errmsg "cannot create local temp path : $localtemp"
                        errmsg "output [$retc]: $OUTPUT"
                     fi
                  fi
                  if [ $retc -eq 0 ]; then
                     infmsg "  Copy 3rd party install routines"
                     OUTPUT=$(2>&1 /bin/cp -p -f $model_inst_path/inst*.sh $localtemp/)
                     retc=$?
                     if [ $retc -ne 0 ]; then
                        errmsg "cannot copy install files - abort rc=$retc"
                        errmsg "Output: $OUTPUT"
                     else
                        debmsg "   copy ok"
                     fi
                  fi
               else
                  debmsg "   no inst routines found"
               fi
            fi

            if [ $retc -eq 0 ]; then
               infmsg "  Install 3rd party packages"
               files=$(shopt -s nullglob dotglob; echo $localtemp/inst_*.sh)
               if (( ${#files} )); then
                  infmsg "  found 3rd party install routines"
                  for Scripts in $localtemp/inst_*.sh; do
                     if [ $retc -eq 0 ]; then
                        debmsg "   => call script $Scripts"
                        $Scripts
                        retc=$?
                        if [ $retc -ne 0 ]; then
                           errmsg "running $Scripts - abort rc=$retc"
                           copylog
                        else
                           debmsg "   script $Scripts ended with rc=$retc"
                           copylog
                        fi
                     fi
                  done
                  if [ $retc -eq 0 ]; then
                     infmsg "  All 3rd party installation running"
                     copylog
                  fi
               else
                  infmsg "  no 3rd party install routines found"
               fi
            fi
         fi
         
         # Subroutines copy
         if [ $retc -eq 0 ]; then
            debmsg "   search and copy base sub routines ..."
            base_model_sub_path="$kspath/model/base/sub"
            tracemsg "   base sub path: $base_model_sub_path"
            infmsg " search base sub routines"
            files=$(shopt -s nullglob dotglob; echo $base_model_sub_path/sub*)
            if (( ${#files} )); then
               if [ ! -d $localtemp ]; then
                  OUTPUT=$(2>&1 mkdir $localtemp )
                  retc=$?
                  if [ $retc -ne 0 ]; then
                     errmsg "cannot create local temp path : $localtemp"
                     errmsg "output [$retc]: $OUTPUT"
                  fi
               fi
               if [ $retc -eq 0 ]; then
                  infmsg " found base sub routines - copy them ..."
                  OUTPUT=$(2>&1 /bin/cp -p -f $base_model_sub_path/sub* $localtemp/)
                  retc=$?
                  if [ $retc -ne 0 ]; then
                     errmsg "cannot copy base sub routine files - abort"
                     errmsg "Output: $OUTPUT"
                  else
                     debmsg "   copy base sub routines ok"
                  fi
               fi
            else
               tracemsg "   no base sub routines found"
            fi
            copylog
         fi
         
         if [ $retc -eq 0 ]; then
            debmsg "   search and copy sub routines ..."
            model_sub_path="$kspath/model/$model/sub"
            tracemsg "   sub path: $model_sub_path"
            infmsg " search model sub routines"
            # dircontent=$(ls $model_sub_path/sub*)
            # tracemsg "   dir content: $dircontent"
            files=$(shopt -s nullglob dotglob; echo $model_sub_path/sub*)
            if (( ${#files} )); then
               if [ ! -d $localtemp ]; then
                  OUTPUT=$(2>&1 mkdir $localtemp )
                  retc=$?
                  if [ $retc -ne 0 ]; then
                     errmsg "cannot create local temp path : $localtemp"
                     errmsg "output [$retc]: $OUTPUT"
                  fi
               fi
               if [ $retc -eq 0 ]; then
                  infmsg " found model sub routines - copy them ..."
                  OUTPUT=$(2>&1 /bin/cp -p -f $model_sub_path/sub* $localtemp/)
                  retc=$?
                  if [ $retc -ne 0 ]; then
                     errmsg "cannot copy sub routine files - abort"
                     errmsg "Output: $OUTPUT"
                  else
                     debmsg "   copy sub routines ok"
                  fi
               fi
            else
               tracemsg "   no sub routines found"
            fi
            copylog
         fi
         
      else
         debmsg "  not first install step"
      fi
   fi
   
   # Subroutines start
   if [ $retc -eq 0 ] && [ $stage -le 100 ]; then
      tracemsg "   search and start sub routines now ..."
      #dircontent=$(ls $localtemp/sub_*.sh)
      #tracemsg "   sub routines: $dircontent"
      files=$(shopt -s nullglob dotglob; echo $localtemp/sub_*.sh*)
      if (( ${#files} )); then
         infmsg " Start sub routines"
         infmsg "  Start at stage $stage"
         for Subs in $localtemp/sub_*.sh; do
            # tracemsg "   rc: [$retc]"
            if [ $retc -eq 0 ]; then
               tracemsg "   found [$Subs]"
               level=${Subs:13:2}          # /tmp/fsi/sub_ abschneiten
               level=${level##+(0)}
               echo $level >$stagefile
               tracemsg "   Set stage: $level"
               tracemsg "   Stage first: $stagefirst"
               tracemsg "   Org stage: $stage"
               if [[ $stage -eq $stagefirst ]] || [[ $level -gt $stage ]] ; then
                  infmsg "   call script [$Subs] now ..."
                  $Subs
                  retc=$?
                  tracemsg "   rc=[$retc]"
                  if [ $retc -eq 0 ]; then
                     infmsg "   script [$Subs] ended with rc=0"
                     sleep 5
                  elif [ $retc -eq 1 ] ; then
                     infmsg "   script [$Subs] ended with rc=1 ==> reboot now!"
                     copylog
                     restart
                  else
                     errmsg "running $Subs abort with error rc=$retc"
                  fi
                  copylog
               else
                  tracemsg "   $Subs already run"
                  # read -p "Taschte drücken"
               fi
            fi
         done
      else
         debmsg "  no sub routines found - ignore"
      fi
      if [ $retc -eq 0 ]; then
         infmsg " End sub routine installation"
         stage=1000
         copylog
         echo $stage >$stagefile
      fi
   fi
   
   if [ $stage -eq 1000 ]; then
      if [ $retc -eq 0 ]; then
         if [[ "$lxtree" =~ ^rh ]] || [[ "$lxtree" =~ ^co ]]; then
            movefile=(
               /root/anaconda-ks.cfg
               /root/ks-post.log
               /root/install.log
               /root/install.log.syslog
            )
            for ((i=0; i<${#movefile[*]}; i++)); do
               if [ -f ${movefile[$i]} ]; then
                  debmsg "$ls   move: ${movefile[$i]}"
                  output=$(2>&1 mv -f ${movefile[$i]} -t /var/fsi)
                  retc=$?
                  if [ $retc -ne 0 ]; then
                     tracemsg "$ls  output: [$output]"
                     errmsg "cannot move file [${movefile[$i]}]"
                     break
                  fi
               else
                  debmsg "$ls  ${movefile[$i]} does not exist - ignore"
               fi
            done
         else
            errmsg "unknown linux distri"
            retc=99
         fi
      fi
      if [ $retc -eq 0 ]; then
         infmsg " last reboot preperations - restore org rc.local"
         if [ -f /etc/rc.d/rc.local ]; then
            infmsg "  delete old rc.local file"
            OUTPUT=$(/bin/rm -f /etc/rc.d/rc.local)
            retc=$?
            if [ $retc -ne 0 ]; then
               errmsg "cannot delete old rc.local file - abort (rc=$retc)"
               errmsg "Output: $OUTPUT"
            fi
            copylog
         fi
      fi
      
      if [ $retc -eq 0 ]; then
         infmsg "  copy old file .."
         /bin/cp -f -p $lxdir/rc.local.sik /etc/rc.d/rc.local
         retc=$?
         if [ $retc -ne 0 ]; then
            errmsg "cannot restore rd.local - abort (rc=$retc)"
            exit $retc
         fi
         copylog
      fi
      
      if [ $retc -eq 0 ]; then
         if [ -d $localtemp ]; then
            OUTPUT=$(2>&1 rm -fR $localtemp )
            retc=$?
            if [ $retc -ne 0 ]; then
               errmsg "cannot delete local temp path : $localtemp"
               errmsg "output [$retc]: $OUTPUT"
            fi
         fi
      fi
   fi   
fi

tracemsg "  end rc [$retc]"
if [ $retc -eq 0 ]; then
   infmsg "Installation ended rc=0 - restart"
   OUTPUT=$(2>&1 sed -i '/^export logfile/ s%.*%export logfile=/var/fsi/fsisys.log%' $lxconf )
   retc=$?
   if [ $retc -ne 0 ]; then
      errmsg "cannot change logfile name"
      errmsg "output [$retc]: $OUTPUT"
   fi
   restart
else
   errmsg "Installation ended with error rc=$retc - abort"
   copylog
   sleep 10
fi

# END