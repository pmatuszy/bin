#!/bin/bash

# 2023.01.17 - v. 0.5 - dodano random delay jesli skrypt jest wywolywany nieinteraktywnie
# 2022.05.16 - v. 0.3 - commented out sending emails sections
# 2022.05.03 - v. 0.2 - added healthcheck support
# 2021.xx.xx - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

export MAX_RANDOM_DELAY_IN_SEC=${MAX_RANDOM_DELAY_IN_SEC:-50}
tty 2>&1 >/dev/null
if (( $? != 0 )); then      # we set RANDOM_DELAY only when running NOT from terminal
  export RANDOM_DELAY=$((RANDOM % $MAX_RANDOM_DELAY_IN_SEC ))
  sleep $RANDOM_DELAY
else
  echo ; echo "Interactive session detected: I will NOT introduce RANDOM_DELAY..."
fi

if [ `wget yt2podcast.com:8080 -qO - |grep .xml|wc -l` -gt 0 ];then 
   # echo dziala strona yt2podcast.com:8080 | strings | aha | /usr/bin/mailx -r root@`hostname` -a 'Content-Type: text/html' -s "(`hostname --short`) OK - strona yt2podcast.com:8080 dziala" matuszyk+`hostname`@matuszyk.com
   /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
else 
   # echo "!!! NIE dziala strona yt2podcast.com:8080" | strings | aha | /usr/bin/mailx -r root@`hostname` -a 'Content-Type: text/html' -s "(`hostname --short`) PROBLEM - strona yt2podcast.com:8080 NIE dziala" matuszyk+`hostname`@matuszyk.com
   /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
fi

. /root/bin/_script_footer.sh
