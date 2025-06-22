# How to Export iMessages with AiMessage

## Quick Start

1. **Click "Export Messages Now"** in AiMessage
2. The export script will be saved to your Downloads folder (or copied to clipboard)
3. **Open Terminal** and run the script
4. **Import the CSV file** back into AiMessage

## Why Does It Work This Way?

AiMessage is a **sandboxed app** for your security. This means:
- ✅ The app can't access your private data without permission
- ✅ Your messages stay private and secure
- ❌ The app can't directly read the Messages database

## The Solution: Export Scripts

Since the app can't access Messages directly, it creates a script that you run in Terminal. This approach:
- Keeps the app sandboxed (safer)
- Gives you full control over the export
- Shows exactly what data is being accessed

## Step-by-Step Instructions

### 1. Generate Export Script
- Open AiMessage
- Go to Import tab
- Click "How to Export" 
- Click "Export Messages Now"

### 2. Run the Script
The app will try to:
1. Save script to Downloads folder (usually works)
2. If that fails, copy script to clipboard

**If saved to Downloads:**
```bash
~/Downloads/export_imessages_[timestamp].sh
```

**If copied to clipboard:**
```bash
# In Terminal, paste and save:
pbpaste > ~/Desktop/export.sh && chmod +x ~/Desktop/export.sh
~/Desktop/export.sh
```

### 3. Grant Terminal Access (First Time Only)
If you see "Operation not permitted":
1. Open System Settings
2. Go to Privacy & Security → Full Disk Access
3. Add Terminal (click + and select from Applications/Utilities)
4. Restart Terminal

### 4. Import Results
After the script runs successfully:
1. Find the CSV file on your Desktop
2. Drag it into AiMessage
3. Start analyzing!

## Common Questions

**Q: Why can't the app export directly?**
A: macOS sandboxing prevents apps from accessing your Messages database. This is a security feature.

**Q: Is this safe?**
A: Yes! The script only reads data, never modifies it. You can review the script before running.

**Q: Why Terminal and not the app?**
A: Terminal runs outside the sandbox and can access Messages with your permission.

## Troubleshooting

### "Permission denied" saving script
- The app will copy to clipboard instead
- Follow the clipboard instructions above

### "Operation not permitted" in Terminal
- Grant Terminal Full Disk Access (see step 3)
- Make sure Messages app is closed

### No messages in export
- Verify Messages has been set up on this Mac
- Check that you have message history

## Alternative: Manual Export

If you prefer, you can manually run this SQL query in Terminal:

```bash
sqlite3 ~/Library/Messages/chat.db <<EOF
.mode csv
.headers on
.output ~/Desktop/messages_export.csv
SELECT 
    datetime(date/1000000000 + 978307200, 'unixepoch', 'localtime') as timestamp,
    text,
    CASE is_from_me WHEN 1 THEN 'Me' ELSE handle.id END as sender,
    is_from_me as isFromMe,
    'chat' as chatIdentifier
FROM message
LEFT JOIN handle ON message.handle_id = handle.ROWID
WHERE text IS NOT NULL
ORDER BY date DESC;
.quit
EOF
```

## Privacy Note

- All processing happens locally on your Mac
- No data is sent to any servers
- The export script is generated locally
- You have full control over your data