# Sparkle-Auto-Update-Tool
Release mac app updates quicker with sparkle



Process:
- updates version number of app
- zips and renames w/ version number appended
- signs zip using sparkle code signing
- uploads zip to ftp directory
- edits appcast file to contain new item for update w/ update notes and all other necessary metadata
