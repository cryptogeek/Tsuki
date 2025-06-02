CreateDesktopShortcut(executablePath, iconPath, shortcutName := "")
{
    ; Get the path to the user's desktop
    desktopPath := A_Desktop

    ; Ensure the executable exists
    if !FileExist(executablePath)
    {
        MsgBox, 16, Error, The specified executable does not exist.`n`n%executablePath%
        return false
    }

    ; Ensure the icon file exists
    if !FileExist(iconPath)
    {
        MsgBox, 16, Error, The specified icon file does not exist.`n`n%iconPath%
        return false
    }

    ; If no custom shortcut name is provided, use the executable name without extension
    if (shortcutName = "")
    {
        SplitPath, executablePath, exeName, exeDir, exeExt, exeNameNoExt
        shortcutName := exeNameNoExt
    }

    ; Define the path for the shortcut on the desktop
    shortcutPath := desktopPath . "\" . shortcutName . ".lnk"

    ; Check if a shortcut with the same name already exists
    if FileExist(shortcutPath)
    {
        MsgBox, 48, Warning, A shortcut with this name already exists on the Desktop.`nDo you want to overwrite it?
        IfMsgBox, No
            return false
    }

    ; Create the shortcut
    FileCreateShortcut, %executablePath%, %shortcutPath%, %exeDir%, , , %iconPath%, 0

    ; Check if the shortcut was created successfully
    if FileExist(shortcutPath)
    {
        MsgBox, 64, Success, Shortcut created on Desktop:`n`n%shortcutPath%
        return true
    }
    else
    {
        MsgBox, 16, Error, Failed to create shortcut on Desktop.
        return false
    }
}

; Example usage
executablePath=%A_ScriptDir%\rcloneRestore.exe
iconPath=%A_ScriptDir%\rcloneRestore.ico

CreateDesktopShortcut(executablePath, iconPath, "Tsuki Restore")