#!/bin/sh

[[ $DEBUG ]] && set -x

BACKUP_DIR=./backup

while getopts "d:a" opt; do
  case $opt in
    d)
      DB_FILE=$OPTARG
      echo "Using $DB_FILE"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

function select_rows () {
  sqlite3 $DB_FILE "$1"
}

for line in $(select_rows "select distinct guid from chat;" ); do
  contact=$line
  arrIN=(${contact//;/ })
  contactNumber=${arrIN[2]}
  #Make a directory specifically for this folder
  mkdir -p $BACKUP_DIR/$contactNumber/Attachments

  #Perform SQL operations
  select_rows "
  select is_from_me,text, datetime(date + strftime('%s', '2001-01-01 00:00:00'), 'unixepoch', 'localtime') as date from message where handle_id=(
  select handle_id from chat_handle_join where chat_id=(
  select ROWID from chat where guid='$line')
  )" | sed 's/1|/Me: /g;s/0|/Friend: /g;s/|$//' > $BACKUP_DIR/$contactNumber/$line.txt
done
