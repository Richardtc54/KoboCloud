#!/bin/sh
WHERE ContentID = '$bookid'
  AND ContentType = 6;

UPDATE content
SET ___PercentRead = $pct
WHERE ContentID = '$chapterid'
  AND ContentType = 9;
COMMIT;
SQL
}

if [ ! -d "$STATE_DIR" ]; then
  log "State dir not found: $STATE_DIR"
  exit 0
fi

if [ ! -f "$DB" ]; then
  log "Database not found: $DB"
  exit 1
fi

if [ ! -x "$SQLITE" ]; then
  log "sqlite3 not found at $SQLITE"
  exit 1
fi

find "$STATE_DIR" -type f -name '*.epub.po' | while read po; do
  po_name="$(basename "$po")"
  book_file="${po_name%.po}"
  book_norm="$(normalize_name "$book_file")"

  raw_line="$(tail -n 1 "$po" | tr -d '\r\n')"
  pct_raw="$(extract_percent "$raw_line")"

  if [ -z "$pct_raw" ]; then
    log "No percentage found in $po_name"
    continue
  fi

  pct_int="$(percent_to_int "$pct_raw")"
  bookid="$(find_book_contentid "$book_norm")"

  if [ -z "$bookid" ]; then
    log "No Kobo match for $book_file"
    continue
  fi

  chapterid="$(find_best_chapter "$bookid" "$pct_int")"
  if [ -z "$chapterid" ]; then
    chapterid="$(fallback_last_chapter "$bookid")"
  fi

  if [ -z "$chapterid" ]; then
    log "No chapter found for $bookid"
    continue
  fi

  log "Updating $book_file => $pct_int% ($bookid / $chapterid)"
  update_progress "$bookid" "$chapterid" "$pct_int"
done

exit 0
