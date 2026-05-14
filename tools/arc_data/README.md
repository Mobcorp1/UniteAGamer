# ARC Data Import Tooling

This folder is optional. It is not required for the app to compile.

Use this when you want to pull MIT-licensed structured data from RaidTheory/ARCTracker and convert it into your own UAG local item database.

The current drop-in app upgrade already works against your existing `UnifiedItemIndex`.

Recommended use:

```powershell
cd tools/arc_data
.\update_arc_raiders_data.ps1
```

This script downloads source JSON into `tools/arc_data/source/raidtheory_items/` for review. Do not commit images. Review JSON before converting it into production Dart data.
