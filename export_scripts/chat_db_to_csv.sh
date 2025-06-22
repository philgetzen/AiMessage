#!/bin/bash

# chat_db_to_csv.sh - Convert Messages chat.db to CSV format
# Usage: ./chat_db_to_csv.sh [path_to_chat.db] [output_file.csv]

set -e

# Default paths
CHAT_DB="${1:-$HOME/Library/Messages/chat.db}"
OUTPUT_CSV="${2:-$HOME/Downloads/messages_export.csv}"

# Check if chat.db exists
if [ ! -f "$CHAT_DB" ]; then
    echo "Error: chat.db not found at $CHAT_DB"
    echo "Usage: $0 [path_to_chat.db] [output_file.csv]"
    exit 1
fi

echo "Converting $CHAT_DB to $OUTPUT_CSV..."

# Create CSV header
echo "timestamp,text,sender,isFromMe,chatIdentifier" > "$OUTPUT_CSV"

# Extract messages using SQLite3
sqlite3 "$CHAT_DB" <<EOF | sed 's/|/","/g' | sed 's/^/"/' | sed 's/$/"/' >> "$OUTPUT_CSV"
SELECT 
    datetime(message.date/1000000000 + strftime("%s", "2001-01-01"), "unixepoch", "localtime") as timestamp,
    CASE 
        WHEN message.text IS NULL OR message.text = '' THEN '[Media/Attachment]'
        ELSE REPLACE(REPLACE(message.text, '"', '""'), char(10), ' ')
    END as text,
    CASE 
        WHEN message.is_from_me = 1 THEN 'Me'
        WHEN handle.id IS NOT NULL THEN handle.id
        ELSE 'Unknown'
    END as sender,
    CASE 
        WHEN message.is_from_me = 1 THEN 'true'
        ELSE 'false'
    END as isFromMe,
    CASE 
        WHEN chat.chat_identifier IS NOT NULL THEN chat.chat_identifier
        ELSE 'direct'
    END as chatIdentifier
FROM message
LEFT JOIN handle ON message.handle_id = handle.ROWID
LEFT JOIN chat_message_join ON message.ROWID = chat_message_join.message_id
LEFT JOIN chat ON chat_message_join.chat_id = chat.ROWID
WHERE message.text IS NOT NULL AND message.text != ''
ORDER BY message.date;
EOF

echo "Export complete! Messages saved to: $OUTPUT_CSV"
echo "Total messages exported: $(tail -n +2 "$OUTPUT_CSV" | wc -l)"