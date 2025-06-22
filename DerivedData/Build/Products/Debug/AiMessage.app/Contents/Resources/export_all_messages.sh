#!/bin/bash

# AiMessage - Secure iMessage Export Script
# Exports all messages using native macOS tools only
# Usage: ./export_all_messages.sh

set -e  # Exit on any error

echo "🔒 AiMessage Secure Export - All Messages"
echo "========================================"

# Create working directory
WORK_DIR="$HOME/Documents/imessage_export"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
EXPORT_FILE="all_messages_${TIMESTAMP}.csv"

echo "📁 Creating working directory..."
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Check if Messages database exists
if [ ! -f "$HOME/Library/Messages/chat.db" ]; then
    echo "❌ Error: iMessage database not found at ~/Library/Messages/chat.db"
    echo "   Make sure you have iMessage set up on this Mac."
    exit 1
fi

echo "💾 Copying iMessage database (this may take a moment)..."
cp "$HOME/Library/Messages/chat.db" "./messages_backup.db"

if [ ! -f "./messages_backup.db" ]; then
    echo "❌ Error: Failed to copy database. Check Terminal has Full Disk Access."
    echo "   Go to System Settings > Privacy & Security > Full Disk Access"
    echo "   Add Terminal to the list and restart Terminal."
    exit 1
fi

echo "📊 Exporting messages to CSV..."

# Export all messages with proper formatting for AiMessage
sqlite3 messages_backup.db << EOF
.mode csv
.headers on
.output $EXPORT_FILE
SELECT 
    datetime(date/1000000000 + strftime("%s", "2001-01-01"), "unixepoch", "localtime") as timestamp,
    replace(replace(text, char(10), ' '), char(13), ' ') as text,
    CASE WHEN is_from_me = 1 THEN 'Me' ELSE COALESCE(handle.id, 'Unknown') END as sender,
    CASE WHEN is_from_me = 1 THEN 'true' ELSE 'false' END as isFromMe,
    COALESCE(chat.chat_identifier, 'direct') as chatIdentifier
FROM message
LEFT JOIN handle ON message.handle_id = handle.ROWID
LEFT JOIN chat_message_join ON message.ROWID = chat_message_join.message_id
LEFT JOIN chat ON chat_message_join.chat_id = chat.ROWID
WHERE text IS NOT NULL 
AND text != ''
AND length(trim(text)) > 0
ORDER BY date;
.quit
EOF

# Check if export was successful
if [ ! -f "$EXPORT_FILE" ]; then
    echo "❌ Error: Export failed - no output file created"
    rm -f messages_backup.db
    exit 1
fi

# Get export statistics
MESSAGE_COUNT=$(tail -n +2 "$EXPORT_FILE" | wc -l | xargs)
FILE_SIZE=$(du -h "$EXPORT_FILE" | cut -f1)

echo "✅ Export completed successfully!"
echo "   📄 File: $WORK_DIR/$EXPORT_FILE"
echo "   📊 Messages: $MESSAGE_COUNT"
echo "   💾 Size: $FILE_SIZE"

# Secure cleanup
echo "🧹 Cleaning up temporary files..."
rm -f messages_backup.db

echo ""
echo "🎯 Next Steps:"
echo "   1. Open AiMessage app"
echo "   2. Drag and drop $EXPORT_FILE into the Import tab"
echo "   3. Begin your privacy-focused message analysis!"
echo ""
echo "🔒 Security: Your data was processed entirely on this Mac using native tools only."
echo "   No data was sent to external services."

# Optional: Open the export directory
read -p "📂 Open export folder? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "$WORK_DIR"
fi