# Secure iMessage Export Guide

This guide shows how to export your iMessage data using **only native macOS tools** for maximum security and privacy. No third-party applications required.

## Overview

- ✅ **100% Local Processing** - Your data never leaves your Mac
- ✅ **Native Tools Only** - Uses Apple's built-in SQLite3 and shell commands
- ✅ **Complete Privacy** - No external dependencies or network access
- ✅ **Full Control** - You see and control every step of the process

## Prerequisites

- macOS with Terminal access
- Administrator privileges (for Full Disk Access)
- Basic comfort with command line (copy/paste commands provided)

## Step 1: Grant Terminal Access

1. Open **System Settings** (or System Preferences)
2. Go to **Privacy & Security** → **Full Disk Access**
3. Click the **+** button and add **Terminal**
4. Restart Terminal for changes to take effect

> **Security Note**: You can revoke this access after completing the export.

## Step 2: Safely Copy the Database

First, create a secure working directory and copy the iMessage database:

```bash
# Create a secure working directory
mkdir ~/Documents/imessage_export
cd ~/Documents/imessage_export

# Copy the iMessage database (this may take a moment)
cp ~/Library/Messages/chat.db ./messages_backup.db

# Verify the copy was successful
ls -la messages_backup.db
```

> **Important**: Always work with a copy to avoid any risk to your original message database.

## Step 3: Explore the Database Structure

Let's examine what's in the database using native SQLite3:

```bash
# Open the database
sqlite3 messages_backup.db

# View all tables
.tables

# See the structure of the main message table
.schema message

# Exit SQLite3
.quit
```

Key tables you'll see:
- `message` - Contains all message text and metadata
- `handle` - Phone numbers and email addresses
- `chat` - Conversation groupings
- `chat_message_join` - Links messages to conversations

## Step 4: Export Your Messages

### Option A: Export All Messages to CSV

```bash
sqlite3 messages_backup.db << 'EOF'
.mode csv
.headers on
.output all_messages.csv
SELECT 
    datetime(date/1000000000 + strftime("%s", "2001-01-01"), "unixepoch", "localtime") as timestamp,
    text,
    CASE WHEN is_from_me = 1 THEN 'Me' ELSE handle.id END as sender,
    is_from_me,
    chat.chat_identifier
FROM message
LEFT JOIN handle ON message.handle_id = handle.ROWID
LEFT JOIN chat_message_join ON message.ROWID = chat_message_join.message_id
LEFT JOIN chat ON chat_message_join.chat_id = chat.ROWID
WHERE text IS NOT NULL
ORDER BY date;
.quit
EOF
```

### Option B: Export Messages with Specific Contact

Replace `+1234567890` with the phone number or email you want:

```bash
sqlite3 messages_backup.db << 'EOF'
.mode csv
.headers on
.output contact_messages.csv
SELECT 
    datetime(date/1000000000 + strftime("%s", "2001-01-01"), "unixepoch", "localtime") as timestamp,
    text,
    CASE WHEN is_from_me = 1 THEN 'Me' ELSE handle.id END as sender,
    is_from_me,
    chat.chat_identifier
FROM message
LEFT JOIN handle ON message.handle_id = handle.ROWID
LEFT JOIN chat_message_join ON message.ROWID = chat_message_join.message_id
LEFT JOIN chat ON chat_message_join.chat_id = chat.ROWID
WHERE text IS NOT NULL 
AND (handle.id = '+1234567890' OR is_from_me = 1)
ORDER BY date;
.quit
EOF
```

### Option C: Export as JSON-Compatible CSV

For better compatibility with AiMessage:

```bash
sqlite3 messages_backup.db << 'EOF'
.mode csv
.headers on
.output json_compatible_messages.csv
SELECT 
    '"' || replace(text, '"', '""') || '"' as text,
    '"' || datetime(date/1000000000 + strftime("%s", "2001-01-01"), "unixepoch", "localtime") || '"' as timestamp,
    '"' || CASE WHEN is_from_me = 1 THEN 'Me' ELSE COALESCE(handle.id, 'Unknown') END || '"' as sender,
    CASE WHEN is_from_me = 1 THEN 'true' ELSE 'false' END as isFromMe,
    '"' || COALESCE(chat.chat_identifier, 'direct') || '"' as chatIdentifier
FROM message
LEFT JOIN handle ON message.handle_id = handle.ROWID
LEFT JOIN chat_message_join ON message.ROWID = chat_message_join.message_id
LEFT JOIN chat ON chat_message_join.chat_id = chat.ROWID
WHERE text IS NOT NULL
AND text != ''
ORDER BY date;
.quit
EOF
```

## Step 5: Verify Your Export

Check that your export files were created successfully:

```bash
# List exported files
ls -la *.csv

# Preview the first few lines
head -10 all_messages.csv
```

## Step 6: Secure Cleanup

After successfully exporting your data:

```bash
# Securely delete the database copy
rm messages_backup.db

# Optionally revoke Terminal's Full Disk Access
echo "Don't forget to remove Terminal from Full Disk Access in System Settings"
```

## Export Format Details

### CSV Structure
The exported CSV files will have these columns:
- `timestamp` - When the message was sent (human-readable format)
- `text` - The message content
- `sender` - Who sent the message (phone/email or "Me")
- `isFromMe` - true/false indicating if you sent it
- `chatIdentifier` - Group chat ID or "direct" for individual chats

### Date Format Notes
- Original iMessage dates are in Apple's Core Data format (nanoseconds since 2001-01-01)
- Exports convert these to standard datetime format: `YYYY-MM-DD HH:MM:SS`
- Times are in your local timezone

## Troubleshooting

### "Permission denied" error
- Ensure Terminal has Full Disk Access (Step 1)
- Restart Terminal after granting access
- Try copying to a different location (Desktop, Downloads)

### "Database is locked" error
- Close the Messages app completely
- Wait a moment and try again
- Restart your Mac if the issue persists

### Empty or missing messages
- Some messages may have NULL text (typically system messages)
- Group messages might require joining multiple tables
- Deleted messages won't appear in exports

### Large database performance
- The chat.db file can be several GB for heavy users
- Export operations may take several minutes
- Consider exporting specific date ranges for better performance

## Security Best Practices

1. **Always work with copies** - Never modify the original chat.db
2. **Clean up afterward** - Delete copies and exports when done
3. **Revoke access** - Remove Full Disk Access from Terminal when finished
4. **Local processing only** - These commands never send data anywhere
5. **Secure storage** - Store exports in encrypted locations if needed

## Advanced Usage

### Export Specific Date Range
```bash
# Messages from the last 30 days
sqlite3 messages_backup.db << 'EOF'
.mode csv
.headers on
.output recent_messages.csv
SELECT * FROM (your_query_here)
WHERE date > (strftime('%s', 'now', '-30 days') - strftime('%s', '2001-01-01')) * 1000000000;
.quit
EOF
```

### Count Messages by Contact
```bash
sqlite3 messages_backup.db << 'EOF'
SELECT handle.id, COUNT(*) as message_count
FROM message
LEFT JOIN handle ON message.handle_id = handle.ROWID
WHERE text IS NOT NULL
GROUP BY handle.id
ORDER BY message_count DESC;
.quit
EOF
```

## Support for AiMessage App

The exported CSV files from this guide are designed to work directly with the AiMessage application. The app supports:

- ✅ CSV files with the structure shown above
- ✅ Multiple chat participants
- ✅ Timestamp parsing in various formats
- ✅ Privacy-focused local analysis only

Simply drag and drop your exported CSV file into AiMessage to begin analysis.