#!/bin/bash

# 2022.12.13 - v. 0.6 - hostname specified with start (works with or without domainaname)
# 2022.09.30 - v. 0.5 - checking if we have access to remote repo
# 2022.05.18 - v. 0.4 - added removing git-pull.sh and gill-push.sh from $HOME/bin
#                       added set -o options at the beginning
# 2021.05.12 - v. 0.3 - added copying .[a-zA-Z0-9]
# 2021.04.08 - v. 0.2 - added HOST-SPECIFIC directory copy
# 2020.11.27 - v. 0.1 - initial release

# exit when your script tries to use undeclared variables
set -o nounset
set -o pipefail

echo
cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo ; echo

echo
echo "Do you want to do kind of git pull and configure local scripts? [y/N]"
read -t 60 -n 1 p     # read one character (-n) with timeout of 5 seconds
echo
echo
if [ "${p}" == 'y' -o  "${p}" == 'y' ]; then
  cd $HOME
  mkdir -p $HOME/bin


  # sprawdzam, czy mam dostep do zdalnego repo
  git ls-remote git+ssh://git@github.com/pmatuszy/github-bin.git 2>&1 >/dev/null
  if (( $? != 0 )); then
    echo  ; echo ; echo "Nie mam dostepu do zdalnego repozytorium.... WYCHODZE" ; echo ; echo
    exit 2
  fi

  rm -rf $HOME/github-bin/*
  rm -rf $HOME/github-bin/.git
  git clone git+ssh://git@github.com/pmatuszy/github-bin.git
  cp -v github-bin/* $HOME/bin

  cp -v github-bin/HOST-SPECIFIC/`hostname`/* $HOME/bin
  cp -v github-bin/HOST-SPECIFIC/`hostname`.*/* $HOME/bin
 
  cp -v github-bin/HOST-SPECIFIC/`hostname`*/.[a-zA-Z0-9]* $HOME   2>/dev/null
  cp -v github-bin/HOST-SPECIFIC/`hostname`.*/.[a-zA-Z0-9]* $HOME   2>/dev/null

  rm $HOME/bin/git-pull.sh $HOME/bin/git-push.sh
  cd github-bin
  git status
else
  echo "no means no - I am exiting..."
  exit 1
fi
