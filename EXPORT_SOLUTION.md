# iMessage Export Solution

## The Sandboxing Challenge

The AiMessage app runs in a macOS sandbox, which prevents it from directly accessing the Messages database at `~/Library/Messages/chat.db`. This is by design for security - sandboxed apps can only access files the user explicitly grants permission to.

## Current Solution

Since direct database access isn't possible from a sandboxed app, we've implemented a hybrid approach:

### 1. Export Script Generation
When users click "Export Messages Now", the app:
- Creates an export script (`export_imessages.sh`) on the Desktop
- Opens Terminal automatically with the script
- The script runs outside the sandbox with proper permissions

### 2. User Workflow
1. Click "Export Messages Now" in AiMessage
2. Terminal opens with the export script
3. Run the script (it will check for Full Disk Access)
4. The script exports messages to a CSV file on Desktop
5. Drag the CSV file back into AiMessage to import

## Why This Approach?

### Security Benefits
- App remains sandboxed (safer for users)
- No need to disable app sandboxing
- Users maintain control over their data
- Clear visibility into what's being exported

### Technical Constraints
- macOS prevents sandboxed apps from accessing Messages database
- Full Disk Access must be granted to Terminal, not the app
- Running shell commands from sandboxed apps has limited permissions

## Alternative Approaches Considered

1. **Disable Sandboxing** - Would work but compromises security
2. **AppleScript** - Also blocked by sandbox for Messages access
3. **Shortcuts App** - Requires manual shortcut creation by users
4. **Direct SQLite Access** - Blocked by sandbox permissions

## For Developers

If you're building from source and want direct export:
1. Disable app sandboxing in entitlements (not recommended)
2. Or use the current script-based approach
3. Or implement a non-sandboxed helper tool (complex)

## Future Improvements

- Investigate using XPC services for privileged operations
- Consider Apple's App Groups for shared data access
- Explore Messages framework APIs (if Apple provides them)

## Troubleshooting

### "Operation not permitted" error
- Grant Terminal Full Disk Access in System Settings
- Restart Terminal after granting access

### Script won't run
- Make sure script has execute permissions
- Check that Messages app has been used on this Mac

### No messages in export
- Verify Messages database exists at `~/Library/Messages/chat.db`
- Try closing Messages app before exporting