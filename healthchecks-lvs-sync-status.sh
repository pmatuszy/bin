#!/bin/bash

# 2023.11.02 - v. 0.5 - bugfix: if no lvs present no error is returned
# 2023.07.18 - v. 0.4 - bugfix: redirected 2> to stdout
# 2023.02.28 - v. 0.3 - curl with kod_powrotu
# 2023.01.03 - v. 0.2 - bug fixed - when no lvs'm the status should be ok
# 2022.12.29 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

m=$( echo " "; echo "aktualna data: `date '+%Y.%m.%d %H:%M'`" ; echo ; 
     cat $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo ; echo
     ile_vol=$(lvs 2>&1 | wc -l)
     if (( $ile_vol == 0 ));then    # if there are no lvs we exit with no error code
       exit 0
     fi

     if [ $(lvs -o 'sync_percent' 2>&1 |sort|uniq|grep -v -e '^[[:space:]]*$'| grep -v 100.00|wc -l) -eq 1 ];then
       exit 0
     else
       exit 1
     fi
   )
kod_powrotu=$?

/usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/${kod_powrotu} 2>/dev/null

. /root/bin/_script_footer.sh

exit $kod_powrotu
#####
# new crontab entry

@reboot /root/bin/healthchecks-lvs-sync-status.sh

0 * * * * /root/bin/healthchecks-lvs-sync-status.sh

