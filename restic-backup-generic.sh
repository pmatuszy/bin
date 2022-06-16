#!/bin/bash
# 2022.05.16 - v. 1.7 - changed pgrep -f to pgrep -x
# 2022.05.16 - v. 1.6 - a lot of changes in functionality and integration with healthchecks
# 2022.05.12 - v. 1.5 - commented out echos for sending emails (they are no longer needed)
#                       added stderr redirection to stdout in restic invocation
# 2022.05.06 - v. 1.4 - added RUN_BEFORE_BACKUP and RUN_AFTER_BACKUP
# 2022.05.06 - v. 1.3 - added check if we are run from CRON
# 2022.05.04 - v. 1.2 - added healthcheck support, remove sensitive data from the script itself
# 2021.04.16 - v. 1.1 - small change to exit message when XDG_CACHE_HOME is not defined
# 2021.04.14 - v. 1.0 - added checks for RESTIC_BIN and XDG_CACHE_HOME, overhauld of the script
# 2021.04.11 - v. 0.2 - added /bin/bash as the first line of the script
# 2021.04.10 - v. 0.1 - initial release

. "${RESTIC_BACKUP_ENV_FILE}"

export RUN_BEFORE_BACKUP="${RUN_BEFORE_BACKUP:-}"
export RUN_AFTER_BACKUP="${RUN_AFTER_BACKUP:-}"

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^${RESTIC_BACKUP_NAME}"|awk '{print $2}')
fi

if [ -f /encrypted/root/scripts/repo-pass-info.sh ];then
  REPO_PASS_INFO=/encrypted/root/scripts/repo-pass-info.sh
fi

if [ -f /root/repo-pass-info.sh ];then
  REPO_PASS_INFO=/root/repo-pass-info.sh
fi

if [ -f "$REPO_PASS_INFO" ]; then
  . "$REPO_PASS_INFO"
else
  m=$(
    echo '#####################################################'
    echo '#####################################################'
    echo
    echo "${REPO_PASS_INFO} nie moze byc znaleziony. Wychodze"
    echo
    echo '#####################################################'
    echo '#####################################################' )
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
  exit 4
fi

# check if we are run from the cron
CRON=$(pstree -s $$ | grep -q cron && echo true || echo false)

if $CRON ; then
  mail_subject=" ( `/bin/hostname`  - `date '+%Y.%m.%d %H:%M:%S'`) $(basename $0)"
  # mail_adressee=matuszyk+`/bin/hostname`@matuszyk.com
  # exec 2>&1 > >( strings | aha | /usr/bin/mailx -r root@`hostname` -a 'Content-Type: text/html' -s "$mail_subject" "$mail_adressee")
fi

export RESTIC_BIN=$(type -fP restic)

if [ ! -f "$RESTIC_BIN" ]; then
  m=$(
    echo '#####################################################'
    echo '#####################################################'
    echo
    echo "restic binary defined as ${RESTIC_BIN} nie moze byc znaleziony. Wychodze"
    echo
    echo '#####################################################'
    echo '#####################################################' )
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
  exit 2
fi

if [ -d "/root/restic-cache-dir" ]; then
  export XDG_CACHE_HOME="/root/restic-cache-dir"
fi

if [ -d "/encrypted/root/restic-cache-dir" ]; then
  export XDG_CACHE_HOME="/encrypted/root/restic-cache-dir"
fi

if [ ! -d "$XDG_CACHE_HOME" ] ; then
   m=$(
   echo "XDG_CACHE_HOME ($XDG_CACHE_HOME)  nie istnieje"
   echo "WYCHODZE ..." )
   /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
   exit 4
fi

if pgrep -x "${RESTIC_BIN}" > /dev/null ; then
  m=$(
    echo '#####################################################'
    echo '#####################################################'
    echo
    echo "${RESTIC_BIN} dziala, wiec nie startuje nowej instancji a po prostu koncze dzialanie skryptu"
    echo ; ps -ef|grep "${RESTIC_BIN}" ; echo
    echo
    echo '#####################################################'
    echo '#####################################################' )
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
  exit 2
fi

if [ ! -d "$XDG_CACHE_HOME" ] ; then
  m=$(
    echo "$XDG_CACHE_HOME nie istnieje"
    echo "WYCHODZE ..." )
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
  exit 1
fi

/usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 -o /dev/null "$HEALTHCHECK_URL"/start 2>/dev/null

export run_before_backup_log=$( eval $RUN_BEFORE_BACKUP 2>&1 ) 

backup_log=$( echo ; echo "RESTIC_REPOSITORY = $RESTIC_REPOSITORY" ; echo ; date '+%Y.%m.%d %H:%M' ; echo ;
              eval ${RESTIC_BIN} --cleanup-cache --iexclude=${MY_EXCLUDES} --iexclude-file=${MY_EXCLUDE_FILE} backup / $WHAT_TO_BACKUP_ON_TOP_OF_ROOT 2>&1 ; exit $? )
kod_powrotu=$?

export run_after_backup_log=$( eval $RUN_AFTER_BACKUP 2>&1 )

m=$( echo ; echo "~~~~~~~~~~~~~~~~~~~~~~~~~"
     echo kod powrotu z backupu: $kod_powrotu ; echo "~~~~~~~~~~~~~~~~~~~~~~~~~" ; echo ;
     ${RESTIC_BIN} --cleanup-cache                          snapshots 2>&1 )

if (( $kod_powrotu != 0 )); then
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$run_before_backup_log $backup_log $m $run_after_backup_log" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$run_before_backup_log $backup_log $m $run_after_backup_log" -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

. /root/bin/_script_footer.sh
