# AiMessage Quick Start Guide

## What Changed?

Your import system is now much simpler and actually works! Here's what's new:

### ✅ New Import Flow
1. **Step 1**: Copy Terminal command with one click
2. **Step 2**: Drop the exported CSV file  
3. **Done!** Auto-navigates to Analysis tab

### 🗑️ Removed Complexity
- No more failing database imports
- No more confusing multiple paths
- 500+ lines of dead code removed

### 📁 File Changes
- **New**: `ImportView.swift` - Clean two-step flow
- **Updated**: `FileImporter.swift` - CSV only, no database code
- **Updated**: `ContentView.swift` - Auto-navigation after import
- **Backup**: `DropZoneView.swift.old` - Old file kept just in case

## How to Use

1. Open Xcode and follow `XCODE_UPDATE.md` instructions
2. Build and run the app
3. The new import flow guides users through:
   - Exporting messages via Terminal (one-click copy)
   - Importing the CSV file (drag & drop)
4. After import, app automatically shows Analysis tab

## Terminal Export Command

The app provides this command (users just click to copy):
```bash
sqlite3 -header -csv ~/Library/Messages/chat.db "SELECT datetime(message.date/1000000000 + strftime('%s', '2001-01-01'), 'unixepoch', 'localtime') as timestamp, message.text, CASE WHEN message.is_from_me = 1 THEN 'Me' ELSE COALESCE(handle.id, 'Unknown') END as sender, CASE WHEN message.is_from_me = 1 THEN 'true' ELSE 'false' END as isFromMe, 'direct' as chatIdentifier FROM message LEFT JOIN handle ON message.handle_id = handle.ROWID WHERE message.text IS NOT NULL AND message.text != '' ORDER BY message.date LIMIT 50000;" > ~/Downloads/messages.csv
```

## Next Steps

Now that import is solved, focus on:
1. Apple Foundation Models integration
2. Building the analysis pipeline
3. Creating meaningful visualizations

The simplified import system removes barriers so you can focus on the AI features!
