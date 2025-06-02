#SingleInstance Ignore
#Persistent

OnExit, ExitSub

OnMessage(0x404, "AHK_NOTIFYICON")

SetTimer, hideMonka, 1000

SetWorkingDir, %A_ScriptDir%

Menu, Tray, Icon, sync.ico
Menu, Tray, NoStandard  ; Removes all standard menu options
Menu, Tray, Add, Quitter, ExitRoutine  ; Adds the custom "Exit" option

runOptions=Hide

loop:

runOptions=Hide

filedelete,%tmp%\mylogfile.txt

;on linux maybe try --exclude='*.tmp'

backupFolders()

sleep 1000*60*60
 
Goto, loop

ExitSub:
WinShow, ahk_exe rcloneSyncBin.exe
WinClose, ahk_exe rcloneSyncBin.exe
ExitApp

AHK_NOTIFYICON(wParam, lParam)
{
    global runOptions
	if (lParam = 0x202) ; WM_LBUTTONUP
	{
		WinShow, ahk_exe rcloneSyncBin.exe
		WinRestore, ahk_exe rcloneSyncBin.exe
		runOptions=
	}
}

hideMonka:
	global runOptions
	WinGet, winState, MinMax, ahk_exe rcloneSyncBin.exe
	if (winState = -1) {
		WinHide, ahk_exe rcloneSyncBin.exe
		runOptions=Hide
	}
return

backupFolders()
{
    storageFile := A_ScriptDir . "\FolderPaths.txt"
    if FileExist(storageFile)
    {
        ; Read the entire file content into a variable and then process each line.
        FileRead, fileContents, %storageFile%
        ; Split the file contents into an array, each element representing a line.
		pathsArray := StrSplit(fileContents, "`r`n") ;

        ; Process each folder path from the file.
        for index, line in pathsArray
        {
            cleanedPath := cleanPath(line)
            folderNameNoSpaces := ExtractFolderNameAndStripSpaces(line)
			runwait, rcloneSyncBin.exe --config=rclone.conf -vv --stats=3s --bwlimit 1000M --progress sync "%cleanedPath%" fileservercrypt:%folderNameNoSpaces% --delete-before --create-empty-src-dirs --log-file="%tmp%\mylogfile.txt",,Hide
        }
    }
    else
    {
        ; If the file doesn't exist, notify the user.
        ;MsgBox, 16, Error, The file "%storageFile%" does not exist.
    }
}

cleanPath(folderPath)
{
    ; Check if the path ends with a backslash (\)
    if (SubStr(folderPath, 0) = "\")
    {
        ; Escape the backslash by adding another one at the end
        folderPath := folderPath . "\"
    }
    
    return folderPath
}

ExtractFolderNameAndStripSpaces(fullPath)
{
    ; Remove trailing backslash if present
    if (SubStr(fullPath, 0) = "\")
        fullPath := SubStr(fullPath, 1, -1)
    
    ; If the path is the root of a drive (e.g., "C:"), return only the drive letter
    if (RegExMatch(fullPath, "^[A-Z]:$", match))
        return SubStr(match, 1, 1)
    
    ; Use SplitPath to extract the folder name
    SplitPath, fullPath, , , , folderName
    
    ; Remove spaces from the folder name
    StringReplace, folderNameNoSpaces, folderName, %A_Space%,, All
    
    return folderNameNoSpaces
}

ExitRoutine:
    WinShow, ahk_exe rcloneSyncBin.exe
	WinClose, ahk_exe rcloneSyncBin.exe
	ExitApp
Return