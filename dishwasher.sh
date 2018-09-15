#!/bin/sh

readonly LINENOTIFY_TOKEN="<please change yours>"

readonly INTERVAL=60
readonly GOOGLEHOME_URL="http://127.0.0.1:8091/google-home-notifier"
readonly LINENOTIFY_URL="https://notify-api.line.me/api/notify"
readonly LATEST_FILE=/home/pi/bluebutton/dishwasher_latest_start_datetime.txt

notify_start() {
  notify_to_googlehome "食洗機を開始しました"
  notify_to_line "食洗機スタート！"
  echo "$(date +'%Y-%m-%d %H:%M:%S')" > $LATEST_FILE
}

notify_nostart() {
  curl -X POST -d "text=食洗機の開始時刻からまだ ${INTERVAL} 分以内です。まだ完了していないと思われます。" $GOOGLEHOME_URL
}

notify_to_googlehome() {
  MESSAGE="$1"
  curl -X POST -d "text=${MESSAGE}" $GOOGLEHOME_URL
}

notify_to_line() {
  MESSAGE="$1"
  curl -X POST -H "Authorization: Bearer ${LINENOTIFY_TOKEN}" -F "message=${MESSAGE}" $LINENOTIFY_URL
}

start() {
  LATEST_DATE=$(cat $LATEST_FILE)
  # echo "LATEST_DATE: ${LATEST_DATE}"
  if [ "${LATEST_DATE}" = "" ]; then
    notify_start
    exit
  fi
  LATEST_IN_SECOND=$(date -d "${LATEST_DATE}" '+%s')
  # echo "LATEST_IN_SECOND: $LATEST_IN_SECOND"
  HOURAGO_IN_SECOND="$(date -d "${INTERVAL} minutes ago" '+%s')"
  # echo "HOURAGO_IN_SECOND: $HOURAGO_IN_SECOND"

  DIFF=$(expr $LATEST_IN_SECOND - $HOURAGO_IN_SECOND)
  # echo "DIFF: $DIFF sec"

  if [ ${DIFF} -gt 0 ]; then
    notify_nostart
  else
    notify_start
  fi
}

read() {
  LATEST_DATE=$(cat $LATEST_FILE)
  notify_to_googlehome "$(date -d "${LATEST_DATE}")"
}

reset() {
  curl -X POST -d "text=食洗機の開始時刻をリセットしました" $GOOGLEHOME_URL
  echo "" > $LATEST_FILE
}

case "$1" in
  start ) start ;;
  read )  read ;;
  reset ) reset ;;
esac
