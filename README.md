# FileSplitter.ps1
Split large files using PowerShell

## Overview
This script is intended to split and restore files without the need to download additional software.

### Parameters
#### LoadFile
The full path and name of the file to load. If restoring a file, please select the first segment. "The one ending in '.0'.
#### SaveFile
The full path and name of the file to save. If not restoring, then the base file name. The sequential numbers will be added automatically.
#### SegmentSize
The size that each of the file segments should be in megabytes. (Default 1024 or 1Gb)
#### ReadBuffer
The buffer that data is temporarily stored in while the file is being read in bytes. You do not need to change this usually. (Default 4096 or 4Kb) 

## Split
Assuming you have a file named OriginalFile.zip that you wanted to split into 4GB segments, you would run the follwing command. If it was an 8GB file, the script would output "C:\OriginalFile.zip.0" and "C:\OriginalFile.zip.1"
PowerShell
```
&"<Path to script>" -LoadFile "C:\OriginalFile.zip" -SaveFile "C:\OriginalFile.zip" -SegmentSize 4096 
```
## Restore
If you followed the previous split example, and wanted to restore the file, you would run the following command which would output a single "C:\OriginalFileRestored.zip" file.
```
&"<Path to script>" -LoadFile "C:\SomeSplitFile.zip.0" -SaveFile "C:\OriginalFileRestored.zip" -Restore
```
## Additional notes
This script does not verify the file pieces that it stiches together, as such, you could use this to join plain text document together just by naming them the same thing with a sequential number at the end. (Ex, ShoppingList.txt.0, ShoppingList.txt.1) This also means that this script does not validate the file pieces either, so if you transfer the files accross the network, be sure to check the hashes yourself to ensure no corruption was introduced during transfer.
