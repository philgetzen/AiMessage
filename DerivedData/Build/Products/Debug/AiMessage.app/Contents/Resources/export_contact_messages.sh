#!/bin/bash

# AiMessage - Secure iMessage Export Script for Specific Contact
# Exports messages with a specific contact using native macOS tools only
# Usage: ./export_contact_messages.sh

set -e  # Exit on any error

echo "🔒 AiMessage Secure Export - Contact Messages"
echo "============================================="

# Get contact information from user
echo "📱 Enter the phone number or email address of the contact:"
echo "   Examples: +1234567890, john@example.com"
read -p "Contact: " CONTACT

if [ -z "$CONTACT" ]; then
    echo "❌ Error: No contact provided"
    exit 1
fi

# Create working directory
WORK_DIR="$HOME/Documents/imessage_export"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SAFE_CONTACT=$(echo "$CONTACT" | sed 's/[^a-zA-Z0-9]/_/g')
EXPORT_FILE="messages_${SAFE_CONTACT}_${TIMESTAMP}.csv"

echo "📁 Creating working directory..."
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Check if Messages database exists
if [ ! -f "$HOME/Library/Messages/chat.db" ]; then
    echo "❌ Error: iMessage database not found at ~/Library/Messages/chat.db"
    echo "   Make sure you have iMessage set up on this Mac."
    exit 1
fi

echo "💾 Copying iMessage database..."
cp "$HOME/Library/Messages/chat.db" "./messages_backup.db"

if [ ! -f "./messages_backup.db" ]; then
    echo "❌ Error: Failed to copy database. Check Terminal has Full Disk Access."
    echo "   Go to System Settings > Privacy & Security > Full Disk Access"
    echo "   Add Terminal to the list and restart Terminal."
    exit 1
fi

echo "🔍 Searching for messages with: $CONTACT"

# First, let's check if the contact exists
CONTACT_CHECK=$(sqlite3 messages_backup.db "SELECT COUNT(*) FROM handle WHERE id = '$CONTACT';")

if [ "$CONTACT_CHECK" -eq 0 ]; then
    echo "⚠️  Warning: No exact match found for '$CONTACT'"
    echo "📋 Here are similar contacts in your database:"
    
    sqlite3 messages_backup.db << EOF
SELECT DISTINCT id FROM handle 
WHERE id LIKE '%$CONTACT%' 
ORDER BY id 
LIMIT 10;
EOF
    
    echo ""
    read -p "Continue with exact match '$CONTACT'? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        rm -f messages_backup.db
        echo "Export cancelled."
        exit 0
    fi
fi

echo "📊 Exporting messages to CSV..."

# Export messages with specific contact
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
AND (handle.id = '$CONTACT' OR (is_from_me = 1 AND EXISTS (
    SELECT 1 FROM message m2 
    LEFT JOIN handle h2 ON m2.handle_id = h2.ROWID 
    LEFT JOIN chat_message_join cmj2 ON m2.ROWID = cmj2.message_id 
    WHERE h2.id = '$CONTACT' 
    AND cmj2.chat_id IN (
        SELECT cmj.chat_id FROM chat_message_join cmj 
        WHERE cmj.message_id = message.ROWID
    )
)))
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

if [ "$MESSAGE_COUNT" -eq 0 ]; then
    echo "⚠️  No messages found with contact: $CONTACT"
    echo "   This could mean:"
    echo "   - The contact identifier doesn't match exactly"
    echo "   - You haven't exchanged messages with this contact"
    echo "   - The messages are in group chats only"
    rm -f messages_backup.db "$EXPORT_FILE"
    exit 1
fi

echo "✅ Export completed successfully!"
echo "   📄 File: $WORK_DIR/$EXPORT_FILE"
echo "   📊 Messages: $MESSAGE_COUNT"
echo "   💾 Size: $FILE_SIZE"
echo "   👤 Contact: $CONTACT"

# Secure cleanup
echo "🧹 Cleaning up temporary files..."
rm -f messages_backup.db

echo ""
echo "🎯 Next Steps:"
echo "   1. Open AiMessage app"
echo "   2. Drag and drop $EXPORT_FILE into the Import tab"
echo "   3. Analyze your conversation with $CONTACT!"
echo ""
echo "🔒 Security: Your data was processed entirely on this Mac using native tools only."

# Optional: Open the export directory
read -p "📂 Open export folder? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "$WORK_DIR"
fi