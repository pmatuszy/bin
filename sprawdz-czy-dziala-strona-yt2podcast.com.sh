#!/bin/bash

# 2023.04.13 - v. 0.6 - added how_many_retries and retry_delay
# 2023.01.17 - v. 0.5 - dodano random delay jesli skrypt jest wywolywany nieinteraktywnie
# 2022.05.16 - v. 0.3 - commented out sending emails sections
# 2022.05.03 - v. 0.2 - added healthcheck support
# 2021.xx.xx - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

url=yt2podcast.com:8080
blad=1
how_many_retries=6
retry_delay=10

while (( $blad != 0 && $how_many_retries != 0 )) ; do
  if [ `wget $url -qO - |grep .xml|wc -l` -gt 0 ];then 
    /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
    blad=0
  else 
    /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
    let how_many_retries=how_many_retries-1
    sleep $retry_delay
  fi
done

. /root/bin/_script_footer.sh

exit $?

#####
# new crontab entry

*/5 * * * * /root/bin/sprawdz-czy-dziala-strona-yt2podcast.com.sh
