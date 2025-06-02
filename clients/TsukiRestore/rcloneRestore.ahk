#SingleInstance Force
#Persistent
;#NoTrayIcon

SetWorkingDir, %A_ScriptDir%

Menu, Tray, Icon, rcloneRestore.ico

Menu, Tray, NoStandard  ; Removes all standard menu options
Menu, Tray, Add, Quitter, ExitRoutine  ; Adds the custom "Exit" option

InputBox, configPassword, Tsuki Restore, Mot de passe:, HIDE

if(configPassword==""){
	MsgBox, Mauvais mot de passe.
	exitapp
}

Gui, mode1: Destroy
Gui, mode1: +AlwaysOnTop -Caption +Border
Gui, mode1: Font, S10
Gui, mode1: Add, Text,, Chargement des sauvegardes...
Gui, mode1: Show, NA

runwait,cmd.exe /c echo %configPassword% | rcloneRestore-Rclone.exe lsf fileserverdatasetrecup: --ask-password > output.txt,,hide

; Check if output.txt exists and if it is empty
FileGetSize, fileSize, output.txt
if (fileSize = 0)
{
    Gui, mode1: Destroy
	MsgBox, Mauvais mot de passe.
	exitapp
}
else
{
    ;MsgBox, The output.txt file has content.
}

folderList := []

Loop, Read, output.txt
{
    ; Remove the trailing slash from the folder name
    folderName := RegExReplace(A_LoopReadLine, "/$")
    
    folderList.Push(folderName)
}

reversedFolderList := []
Loop % folderList.MaxIndex()
{
    reversedFolderList.Push(folderList[folderList.MaxIndex() - A_Index + 1])
}

folderNames := "current||"
for index, folder in reversedFolderList
{
    folderNames .= folder "|"
}

filedelete, output.txt

; Create a simple GUI with a ComboBox
Gui, Add, Text,, Choisir une sauvegarde:

; Set the default folder (initial value)
vSelectedFolder := "current" ; Default folder to be selected
Gui, Add, DropDownList, w330 vSelectedFolder, %folderNames%
;Gui, Add, ComboBox, vSelectedFolder, %folderNames% ; Add folder names directly to ComboBox

; Add OK and Cancel buttons
Gui, Add, Button, gSubmit, OK

; Show the GUI
;Gui, Show
;Gui, Show, , Rclone Restore
Gui, Show, w350, Tsuki Restore

Gui, mode1: Destroy

Return

; When OK is clicked, save the selected folder and close the GUI
Submit:
Gui, Submit , NoHide
;Gui, Submit
;MsgBox, You selected: %SelectedFolder%
;Gui, Destroy

Gui, mode1: Destroy
Gui, mode1: +AlwaysOnTop -Caption +Border
Gui, mode1: Font, S10
Gui, mode1: Add, Text,, Chargement du dossier...
Gui, mode1: Show, NA

runwait,cmd.exe /c taskkill /F /IM rcloneRestore-Rclone.exe,,Hide

cacheFolder=%tmp%\rclonecache
While FileExist(cacheFolder)
{
	; Try to remove the directory and all its contents
	FileRemoveDir, %tmp%\rclonecache, 1
	
	; Optional: Add a short sleep to avoid excessive CPU usage
	Sleep, 500
}

freeDrive := FindFreeDriveLetter()
;msgbox, %freeDrive%
if (freeDrive != "")
{
    ;MsgBox, Free drive letter found: %freeDrive%:, now waiting for it to exist...
	
	if(SelectedFolder = "current"){
		if FileExist("m")
		{
			run,cmd.exe /c echo %configPassword% | rcloneRestore-Rclone.exe mount fileservercrypt: %freeDrive%:\ --vfs-cache-mode off --cache-dir "%tmp%\rclonecache" --crypt-remote fileserverdataset:mycrypt --ask-password,,Hide
			msgbox, loading in write mode
			filedelete,m
		}else{
			run,cmd.exe /c echo %configPassword% | rcloneRestore-Rclone.exe mount fileservercrypt: %freeDrive%:\ --vfs-cache-mode off --cache-dir "%tmp%\rclonecache" --crypt-remote fileserverdataset:mycrypt --read-only --ask-password,,Hide
		}
	}else{
		run,cmd.exe /c echo %configPassword% | rcloneRestore-Rclone.exe mount fileservercrypt: %freeDrive%:\ --vfs-cache-mode off --cache-dir "%tmp%\rclonecache" --crypt-remote fileserverdatasetrecup:%SelectedFolder%/mycrypt --read-only --ask-password,,Hide
	}
    
    ; Wait until the free drive letter exists
    While (true)
    {
        if (FileExist(freeDrive . ":\"))  ; Check if the drive exists
        {
            ; Open the drive in a new File Explorer window
            Run, explorer.exe %freeDrive%:
            break
        }
        Sleep, 1000  ; Check every second (1000 milliseconds)
    }
	
	Gui, mode1: Destroy
}
else
{
    MsgBox, Pas de lettre disque disponible !
	;exitapp
}

return

; Handle the user closing the GUI with the "X" button
;GuiClose:
;exitapp

ExitRoutine:
    ; Add any cleanup code you need to execute before exit here.
    ;MsgBox, Exiting Script...  ; Example message, remove if not needed
	runwait,cmd.exe /c taskkill /F /IM rcloneRestore-Rclone.exe,,Hide
	cacheFolder=%tmp%\rclonecache
	While FileExist(cacheFolder)
	{
		; Try to remove the directory and all its contents
		FileRemoveDir, %tmp%\rclonecache, 1
		
		; Optional: Add a short sleep to avoid excessive CPU usage
		Sleep, 500
	}
    ExitApp  ; Exits the script
Return

; Function to find a free drive letter
FindFreeDriveLetter() {
    Loop, 26  ; Loop through all the drive letters (A to Z)
    {
        driveLetter := Chr(65 + A_Index - 1) . ":\"  ; Convert the loop index to a drive letter (A=65 in ASCII)
        if (!FileExist(driveLetter))  ; If the drive doesn't exist
            return Chr(65 + A_Index - 1)  ; Return the available drive letter
    }
    return ""  ; Return an empty string if no free drive letter is found
}