<#
.SYNOPSIS
    Splits any single file into multiple parts, or, restores a file from multiple parts.
 
.DESCRIPTION
    When used with the "restore" switch, restores the specified file. Otherwise, it splits the specified file. This is a dumb fire script with little validation. If you select a file to restore, it will stitch it and any file named similiarly with seguential file names. For example, if you restore a file named "a.0", it will search for all a.# files and stitch them together, whether they were exported by this script or not.
 
.PARAMETER LoadFile
    The full path and name of the file to load. If restoring a file, please select the first segment. "The one ending in '.0'.
 
.PARAMETER SaveFile
    The full path and name of the file to save. If not restoring, then the base file name. The sequential numbers will be added automatically.
 
.PARAMETER SegmentSize
    The size that each of the file segments should be in megabytes. (Default 1024 or 1Gb)
 
.PARAMETER ReadBuffer
    The buffer that data is temporarily stored in while the file is being read in bytes. You do not need to change this usually. (Default 4096 or 4Kb)
 
.INPUTS
    LoadFile, and if restore, LoadFile+".#" where "#" represents a segment of the completed file.
 
.OUTPUTS
    If restore, the SaveFile path supplied. Otherwise, multiple files with SaveFile+".#" where "#" is the sequential number of that file segment.
 
.NOTES
    Version:        1.0
    Author:         Matthew Thompson
    Creation Date:  2016-08-09
    Purpose/Change: Cleanup and commenting
 
.EXAMPLE
    &"FileSplitter.ps1" -LoadFile "C:\OriginalFile.zip" -SaveFile "C:\OriginalFile.zip" -SegmentSize 4096
 
.EXAMPLE
    &"FileSplitter.ps1" -LoadFile "C:\SomeSplitFile.zip.0" -SaveFile "C:\OriginalFile.zip" -Restore
#>
Param($LoadFile,$SaveFile=$LoadFile,[switch]$Restore, $SegmentSize=1024, $ReadBuffer = 4096)
#Convert from MB to KB to B
$SegmentSize = $SegmentSize * 1024 * 1024 
#Initialize read buffer
$Buffer = New-Object Byte[] $ReadBuffer
#Amount read in a pass.
$AmtRead=$null
#Current file segment
$I = 0;
#DateTime for update
$LastUpdate = [DateTime]::Now

#SPLITTING
if (!$Restore)
{
    Write-Progress -Activity "Splitting" -Status "Starting" -PercentComplete 0
    $StreamReader = New-Object System.IO.FileStream -ArgumentList @($LoadFile, [System.IO.FileMode]::Open)
    $StreamWriter = New-Object System.IO.FileStream -ArgumentList @(($SaveFile+"."+$I.ToString()), [System.IO.FileMode]::Create)
 
    #CurrentSize of the file segment we are working on.
    $TotalSize = $StreamReader.Length
    $CurrentTotal = 0
    $CurrentSize=0
    while($AmtRead -ne 0 -or $AmtRead -eq $null)
    {
        #Read the file to memory
        $AmtRead=$StreamReader.Read($Buffer,0,$ReadBuffer)
        if ($AmtRead-gt 0)
        {
            #Write the file to the file segment
            $StreamWriter.Write($Buffer,0,$AmtRead);
            $CurrentSize +=$AmtRead;
            $CurrentTotal += $AmtRead;
            if ([DateTime]::Now - $LastUpdate -gt [TimeSpan]::FromSeconds(5))
            {
                Write-Progress -Activity "Splitting" -Status "Writing" -PercentComplete (($CurrentTotal*100)/$TotalSize)
                $LastUpdate = [DateTime]::Now
            }
        }
        if ($CurrentSize -ge $SegmentSize)
        {
            #Once the current segment is larger or equal to the specified size, finish the file and start a new segment.
            $CurrentSize =0;
            $StreamWriter.Close();
            $I++;
            $StreamWriter = New-Object System.IO.FileStream -ArgumentList @(($SaveFile+"."+$I.ToString()), [System.IO.FileMode]::Create)
            Write-Progress -Activity "Splitting" -Status "New-File" -PercentComplete (($CurrentTotal*100)/$TotalSize)
        }
    }
    #CleanUp
    $StreamWriter.Close();
    $StreamReader.Close();
    Write-Progress -Activity "Splitting" -Status "Completed" -PercentComplete 100 -Completed
}
else # RESTORING
{
    #Cleanup LoadFile
    if (!$LoadFile.EndsWith(".0"))
    {
        #A poor attempt at ensuring that we are about to restore the right files.
        throw "The specified file to load does not end with a '.0'."
        return 1
    }
    $LoadFile = $LoadFile.Substring(0,$LoadFile.Length-2)

    $TotalSize =0;
    $CurrentTotal =0;
    Write-Progress -Activity "Restoring" -Status "Starting" -PercentComplete 0

    while($true)
    {
        $FI = New-Object System.IO.FileInfo -ArgumentList @($LoadFile+"."+$I.ToString())
        $TotalSize += $FI.Length
        $I++;
        if (-not [System.IO.File]::Exists($LoadFile+"."+$I.ToString()))
        {
            break;
        }
    }

    $I=0;
    $StreamWriter = New-Object System.IO.FileStream -ArgumentList @($SaveFile, [System.IO.FileMode]::Create)
    $StreamReader = New-Object System.IO.FileStream -ArgumentList @(($LoadFile+"."+$I.ToString()), [System.IO.FileMode]::Open)
    while($StreamReader -ne $null)
    {
        #Initialize
        $AmtRead=$null
        #While we have received data from a read attempt, keep looping
        while($AmtRead -ne 0 -or $AmtRead -eq $null)
        {
            #Read data from a file segment
            $AmtRead=$StreamReader.Read($Buffer,0,$ReadBuffer)
            if ($AmtRead-gt 0)
            {
                #Write it to the restored file
                $StreamWriter.Write($Buffer,0,$AmtRead);
                $CurrentTotal+=$AmtRead;
                if ([DateTime]::Now - $LastUpdate -gt [TimeSpan]::FromSeconds(5))
                {
                    Write-Progress -Activity "Restoring" -Status "Writing" -PercentComplete (($CurrentTotal*100)/$TotalSize)
                    $LastUpdate = [DateTime]::Now
                }
            }
        }
        #Close the current segment we are reading.
        $StreamReader.Close()
        $I++;
        if ([System.IO.File]::Exists($LoadFile+"."+$I.ToString()))
        {
            #If another segment exists, read it too.
            $StreamReader = New-Object System.IO.FileStream -ArgumentList @(($LoadFile+"."+$I.ToString()), [System.IO.FileMode]::Open)
            Write-Progress -Activity "Restoring" -Status "Open-File" -PercentComplete (($CurrentTotal*100)/$TotalSize)
        }
        else
        {
            #Otherwise, remove the StreamReader. This triggers the loop to end.
            $StreamReader = $null
        }
    }
    #CleanUp
    $StreamWriter.Close();
    Write-Progress -Activity "Restoring" -Status "Complete" -PercentComplete 100 -Completed
}