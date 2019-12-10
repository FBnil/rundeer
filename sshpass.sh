if [ 0"$DEBUG" -gt 0 ];then
  set -x
fi

/usr/bin/sshpass -e $@
