# 2020.11.27 - v. 0.3 - changed rm to remove files from the directory not the whole directory
# 2020.11.26 - v. 0.2 - added second section with 'git pull'
# 2020.10.20 - v. 0.1 - initial release

echo "Do you want to do git push? [y/N]"
read -t 5 -n 1 p     # read one character (-n) with timeout of 5 seconds
echo
echo
if [ "${p}" == 'y' -o  "${p}" == 'y' ]; then
  git add *
  git commit -m \""new push from `hostname` @ `date '+%Y.%m.%d %H:%M:%S'`"\"
  git push
else
  echo "no means no - I am exiting..."
  exit 1
fi
echo
echo
echo "Do you want to do kind of git pull and configure local scripts? [y/N]"
read -t 5 -n 1 p     # read one character (-n) with timeout of 5 seconds
echo
echo
if [ "${p}" == 'y' -o  "${p}" == 'y' ]; then
  cd $HOME
  rm -rf $HOME/github-bin/*
  rm -rf $HOME/github-bin/.git
  git clone git+ssh://git@github.com/pmatuszy/github-bin.git
  cp -v github-bin/* $HOME/bin
  cd github-bin
  git status
else
  echo "no means no - I am exiting..."
  exit 1
fi
