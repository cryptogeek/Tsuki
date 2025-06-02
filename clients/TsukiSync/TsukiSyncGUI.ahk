; AutoHotkey v1 script to create a GUI for managing folder paths using ListView

#SingleInstance, Force
#Persistent
#NoTrayIcon

SetWorkingDir, %A_ScriptDir%

run, rcloneSync.exe

Menu, Tray, Icon, sync.ico

; Global array to hold folder paths
folderPaths := []

; Define the storage file path
storageFile=%A_ScriptDir%\FolderPaths.txt
storageFileTmp=%A_ScriptDir%\FolderPaths.txt.tmp

; Load folder paths from the storage file
if FileExist(storageFile)
{
    Loop, Read, %storageFile%
    {
        folderPaths.Push(A_LoopReadLine)
    }
}

; Create the GUI
Gui, Add, Button, x10 y10 w100 h25 gAddFolder, Ajouter un dossier
Gui, Add, Button, x120 y10 w150 h25 gRemoveSelected, Retirer dossier selectionné
Gui, Add, Button, x280 y10 w100 h25 gSaveAll, Sauvegarder

; Add ListView to display folder paths
Gui, Add, ListView, x10 y50 w370 h200 vFolderListView, Dossiers sauvegardés

; Populate the ListView
For index, path in folderPaths
{
    LV_Add("", path)
}

Gui, Show, AutoSize, Tsuki Sync
Return

; Handler for AddFolder button
AddFolder:
    FileSelectFolder, selectedFolder,,, Séléctionner un dossier
    if (selectedFolder <> "")
    {
        ; Extract the folder name from the selected folder
        SplitPath, selectedFolder, , , , folderName
        
        ; Initialize a flag to check for duplicates
        duplicateFound := false
        
        ; Iterate over existing folder paths
        for index, path in folderPaths
        {
            ; Extract the folder name from the existing path
            SplitPath, path, , , , existingFolderName
            
            ; Compare folder names
            if (folderName = existingFolderName)
            {
                duplicateFound := true
                break
            }
        }
        
        if duplicateFound
        {
            MsgBox, Chaque dossier doit avoir un nom unique.
        }
        else
        {
            folderPaths.Push(selectedFolder)
            LV_Add("", selectedFolder)
        }
    }
Return

; Handler for RemoveSelected button
RemoveSelected:
    SelectedRow := LV_GetNext(0, "F") ; Get the index of the selected row
    if (SelectedRow = 0)
    {
        MsgBox, Selectionner un dossier à retirer.
    }
    else
    {
        ; Get the path from the selected row
        LV_GetText(pathToRemove, SelectedRow, 1)
        ; Remove from folderPaths array
        For index, path in folderPaths
        {
            if (path = pathToRemove)
            {
                folderPaths.RemoveAt(index)
                Break
            }
        }
        ; Remove from ListView
        LV_Delete(SelectedRow)
    }
Return

; Handler for SaveAll button
SaveAll:
    Gui, mypopup: +AlwaysOnTop -Caption +Border
	Gui, mypopup: Font, S10
	Gui, mypopup: Add, Text,, Sauvegarde en cours...
	Gui, mypopup: Show, NA
	
	while FileExist(storageFileTmp)
	{
		FileDelete, %storageFileTmp%
		sleep 1000
	}

    For index, path in folderPaths
    {
        ;msgbox, %path%
		FileAppend, %path%`n, %storageFileTmp%
    }
	
	; Save folderPaths to the storage file
	while FileExist(storageFileTmp)
	{
		FileMove, %storageFileTmp%, %storageFile% , 1
		sleep 1000
	}
	
	Gui, mypopup: Destroy
	
	MsgBox, Sauvegardé
Return

GuiClose:
    ExitApp

