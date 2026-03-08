#!/bin/sh

STATE_DIR="/mnt/onboard/.add/kobocloud/MoonReaderState"
DB="/mnt/onboard/.kobo/KoboReader.sqlite"
SQLITE="/usr/bin/sqlite3"

log() {
  echo "[MoonSync] $*"
}

extract_percent() {
  echo "$1" | sed -n 's/.*:\([0-9.]*%\).*/\1/p'
}

percent_to_int() {
  p="${1%%%}"
  printf "%.0f\n" "$p"
}

find_book() {
  name="$1"

  "$SQLITE" "$DB" "
  SELECT ContentID
  FROM content
  WHERE ContentType=6
  AND ContentID LIKE '%$name%'
  LIMIT 1;
  "
}

update_progress() {

bookid="$1"
pct="$2"

"$SQLITE" "$DB" "
UPDATE content
SET ___PercentRead=$pct,
    ReadStatus=1,
    DateLastRead=datetime('now')
WHERE ContentID='$bookid';
"

}

for po in "$STATE_DIR"/*.epub.po
do

  file=$(basename "$po")
  book=${file%.po}

  line=$(tail -n 1 "$po")

  pct_raw=$(extract_percent "$line")

  if [ -z "$pct_raw" ]; then
     continue
  fi

  pct=$(percent_to_int "$pct_raw")

  bookid=$(find_book "$book")

  if [ -z "$bookid" ]; then
     log "Book not found $book"
     continue
  fi

  log "Updating $book -> $pct %"

  update_progress "$bookid" "$pct"

done
