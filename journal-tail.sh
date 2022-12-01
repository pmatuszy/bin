#!/bin/bash
# 2022.11.25 - v. 0.1 - initial release

figlet -w 120 logs from systemd
sleep 1 

/usr/bin/journalctl -fan500

#  -f --follow                Follow the journal
#  -a --all                   Show all fields, including long and unprintable
#  -n --lines[=INTEGER]       Number of journal entries to show
