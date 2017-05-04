#!/bin/bash
###############################################################################
# Licensed Materials - Property of IBM Copyright IBM Corporation 2016. All Rights Reserved.
# U.S. Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP
# Schedule Contract with IBM Corp.
#
# Contributors:
#  IBM Corporation - initial API and implementation
###############################################################################
HEAT_PLUGIN_DIR='/usr/lib/heat'
RHEL7=false
#DB='mysql'

if grep -q -i "release 7" /etc/redhat-release ; then
  RHEL7=true
  #DB='mariadb'
fi

TIMESTAMP=`date +%s`
temp_dir='engine.info.'$TIMESTAMP

declare -a OSservicesName=('heat' 'keystone');
declare -a logDirs=('heat' 'keystone');
declare -a osServices=('openstack-heat-engine.service' 'openstack-heat-api.service' 'openstack-heat-api-cfn.service' 'openstack-heat-api-cloudwatch.service' 'openstack-keystone.service');

while getopts "d:i:s:v:eactplh" opt; do
  case $opt in
    a)
      ARCHIVE=true
      ;;
    c)
      CONFIG=true
      ;;
    d)
      DEBUG=$OPTARG
      ;;
    e)
      PBACKUP=true
      ;;
    i)
      INFO=$OPTARG
      ;;
    l)
      LOG=true
      ;;
    p)
      CPERFORM=true
      ;;
    s)
      STATUS=$OPTARG
      ;;
    t)
      TAIL=true
      ;;
    v)
      VERBOSE=$OPTARG
      ;;
    h)
      echo "Usage: # source keystonerc"
      echo "       # source clientrc"
      echo "       # ./engine_tools.sh [OPTIONS]"
      echo "  -a use this option to store all the configuration and log files into a tar file"
      echo "     Example: # ./engine_tools.sh -c -a"
      echo "  -c collect UCDP engine services' configuration files"
      echo "     Example: # ./engine_tools.sh -c"
      echo "  -d with [ on|off|status ] to modify/view heat debug setting"
      echo "     Example: # ./engine_tools.sh -d off -s restart"
      echo "  -e create a copy of UCDP engine plugin"
      echo "     Example: # ./engine_tools.sh -e"
      echo "  -i [ system|openstack|all ] to collect system/openstack/all info"
      echo "     Example: # ./engine_tools.sh -i all"
      echo "  -l to collect heat and keystone logs"
      echo "     Example: # ./engine_tools.sh -l"
      echo "  -p check heat's performance. This option also redirect the performance's output to heat_performance.#.out"
      echo "     Example: # ./engine_tools.sh -p"
      echo "  -s [restart] to control OpenStack services"
      echo "     Example: # ./engine_tools.sh -s restart"
      echo "  -t tail the heat's engine log"
      echo "     Example: # ./engine_tools.sh -d on -s restart -t"
      echo "  -v with [ on|off|status ] to modify/view heat debug setting"
      echo "     Example: # ./engine_tools.sh -v off -s restart"
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done
if [ "$#" -eq 0 ]; then
   echo "usage: $0 [OPTIONS]"
   echo "Example: $0 -h"
   exit 1
fi

runOSServices () {
  ps -U heat | tail -n +2 | awk {'print $1'} | xargs --no-run-if-empty kill -9
}

collectSysInfo () {
  printHeader 'OS Version'
  cat /etc/redhat-release ;
  printHeader 'Firewall'
  if [ "$RHEL7" = false ] ; then
    service iptables status
    service ip6tables status
  else
    systemctl status firewalld ;
  fi
  printHeader 'Keystone and Heat Service Connections'
  netstat -tan | grep -E ":8000|:8003|:8004|:5000|:35357"
  printHeader 'Physical Memory'
  free -h ;
  printHeader 'ulimit'
  ulimit -a
  printHeader 'Available Diskspace'
  df -h ;
  printHeader 'Engine Logs (/var/log/)'
  for i in "${logDirs[@]}"
    do
      echo $i ;
      du -h /var/log/$i/ ;
    done
}
printHeader(){
  printf "\n## $1 ##"
  printf "\n+----------------------------------------+\n"
}

collectOSInfo(){
  printHeader 'OpenStack Env Variables'
  env | grep "^OS_"
  printHeader 'Endpoint List'
  if [ "$RHEL7" = true ] ; then
    openstack endpoint list
    printHeader 'Users'
    openstack user list
  else
    keystone endpoint-list
    printHeader 'Users'
    keystone user-list
  fi
  printHeader 'Stack List'
  heat stack-list
  printHeader 'OpenStack Heat RPM Package Info'
  rpm -q --whatprovides openstack-heat
  rpm -q --whatprovides openstack-keystone
  printf "\n"
}

copyConf(){
  mkdir -p conf.$TIMESTAMP/
  cp /etc/heat/heat.conf conf.$TIMESTAMP/heat.conf
  cp /etc/keystone/keystone.conf conf.$TIMESTAMP/keystone.conf
  cp /etc/keystone/policy.json conf.$TIMESTAMP/policy.json
  cp /etc/resolv.conf conf.$TIMESTAMP/resolv.conf
  cp /etc/hosts conf.$TIMESTAMP/hosts
}

copyLog(){
  mkdir -p logs.$TIMESTAMP/logs
  for i in "${logDirs[@]}"
    do
      cp -r /var/log/$i logs.$TIMESTAMP/logs
  done
}

copyHeatPlugins(){
  mkdir ./plugin.$TIMESTAMP
  cp -r $HEAT_PLUGIN_DIR ./plugin.$TIMESTAMP
}

checkHeatPerf(){
  x=1
  date
  while [ $x -le 3 ]
  do
    sleep 5
    printHeader "Test $x"
    printHeader "CPU"
    ps -eo uname,pid,ppid,nlwp,pcpu,pmem,psr,start_time,time,args | egrep -E "heat|keystone|PID" | egrep -v -E "grep|tee"
    START=$(($(date +%s%N)/1000000))
    printHeader "heat stack-list"
    heat stack-list
    END=$(($(date +%s%N)/1000000))
    DIFF=$(( $END - $START ))
    printHeader "heat stack-list took ~$DIFF microsecond(s)."
    x=$(( $x + 1 ))
  done
}

if [ ! -z "$DEBUG" ]; then
   case $DEBUG in
    on)
      sed -i "s|^#debug=|debug=|g" /etc/heat/heat.conf
      sed -i "s|^debug=.*|debug=True|g" /etc/heat/heat.conf ;
      cat /etc/heat/heat.conf | grep "^debug=" ;
        ;;
    off)
      sed -i "s|^#debug=|debug=|g" /etc/heat/heat.conf
      sed -i "s|^debug=.*|debug=False|g" /etc/heat/heat.conf ;
      cat /etc/heat/heat.conf | grep "^debug=" ;
        ;;
    status)
      cat /etc/heat/heat.conf | grep -E "^debug=|^#debug=" ;
        ;;
    * )
      echo "This script does not recognize your command.";
      exit 1
        ;;
  esac
fi

if [ ! -z "$VERBOSE" ]; then
   case $VERBOSE in
    on)
      sed -i "s|^#verbose=|verbose=|g" /etc/heat/heat.conf
      sed -i "s|^verbose=.*|verbose=True|g" /etc/heat/heat.conf ;
      cat /etc/heat/heat.conf | grep "^verbose=" ;
        ;;
    off)
      sed -i "s|^#verbose=|verbose=|g" /etc/heat/heat.conf
      sed -i "s|^verbose=.*|verbose=False|g" /etc/heat/heat.conf ;
      cat /etc/heat/heat.conf | grep "^verbose=" ;
        ;;
    status)
      cat /etc/heat/heat.conf | grep -E "^verbose=|^#verbose=" ;
        ;;
    * )
      echo "This script does not recognize your command.";
      exit 1
        ;;
  esac
fi

if [ ! -z "$STATUS" ]; then
  case $STATUS in
    restart )
      runOSServices $STATUS ;
        ;;
    * )
      echo "This script does not recognize your command.";
      exit 1
        ;;
  esac
fi

if [ ! -z "$INFO" ]; then
  mkdir -p sysinfo.$TIMESTAMP
    case $INFO in
      system)
        collectSysInfo | tee sysinfo.$TIMESTAMP/systemInfo.txt
        ;;
      openstack)
        collectOSInfo | tee sysinfo.$TIMESTAMP/OSInfo.txt
          ;;
      all)
        collectSysInfo | tee sysinfo.$TIMESTAMP/systemInfo.txt
        collectOSInfo | tee sysinfo.$TIMESTAMP/OSInfo.txt
          ;;
      * )
        echo "This script does not recognize your command.";
        exit 1
          ;;
    esac
fi

if [ "$CONFIG" = true ] ; then
  copyConf
fi

if [ "$LOG" = true ] ; then
  copyLog
fi

if [ "$PBACKUP" = true ] ; then
  copyHeatPlugins
fi

if [ "$CPERFORM" = true ] ; then
  checkHeatPerf | tee heat_performance.$TIMESTAMP.out
fi

if [ "$ARCHIVE" = true ] ; then
  mkdir -p $temp_dir
  if [ -e "heat_performance.$TIMESTAMP.out" ]; then
    mv ./heat_performance.$TIMESTAMP.out ./$temp_dir/
    mv ./$temp_dir/heat_performance.$TIMESTAMP.out ./$temp_dir/heat_performance.out
  fi
  if [ -d "plugin.$TIMESTAMP" ] ; then
    mv ./plugin.$TIMESTAMP ./$temp_dir/
    mv ./$temp_dir/plugin.$TIMESTAMP ./$temp_dir/plugin
  fi
  if [ -d "logs.$TIMESTAMP" ] ; then
    mv ./logs.$TIMESTAMP ./$temp_dir/
    mv ./$temp_dir/logs.$TIMESTAMP ./$temp_dir/logs
  fi
  if [ -d "conf.$TIMESTAMP" ] ; then
    mv ./conf.$TIMESTAMP ./$temp_dir/
    mv ./$temp_dir/conf.$TIMESTAMP ./$temp_dir/conf
  fi
  if [ -d "sysinfo.$TIMESTAMP" ] ; then
    mv ./sysinfo.$TIMESTAMP ./$temp_dir/
    mv ./$temp_dir/sysinfo.$TIMESTAMP ./$temp_dir/sysinfo
  fi
  if [ "$(ls -A ./$temp_dir)" ]; then
    tar -zcvf $temp_dir.tar.gz $temp_dir
    echo 'Saved collected info in' $temp_dir.tar.gz
  fi
  rm -rf $temp_dir
fi

if [ "$TAIL" = true ] ; then
  tail -fn0 /var/log/heat/engine.log
fi
