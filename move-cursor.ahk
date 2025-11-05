;; https://stackoverflow.com/a/70069592
;; Version: 1.1.0

; Variable to track the toggle state
toggle := true

; Ctrl-Win-j to toggle the Win-j functionality
^#j::
    toggle := !toggle  ; Toggle the state (true/false)

    if (toggle)
    {
        ShowCustomTooltip("Cursor Jumping is ENABLED", "Green") ; Show green background
    }
    else
    {
        ShowCustomTooltip("Cursor Jumping is PAUSED", "Red") ; Show red background
    }
return

ShowCustomTooltip(text, color)
{
    ; Declare TooltipText as a global variable
    global TooltipText

    ; Create a custom tooltip GUI with a background color
    Gui, TooltipGui: New
    Gui, TooltipGui: +ToolWindow +AlwaysOnTop +Border +Resize -SysMenu -Caption  ; Remove title bar and system menu (close icon)
    Gui, TooltipGui: Color, %color% ; Set background color

    ; Set the font to bold and center the text
    Gui, TooltipGui: Font, s10 cWhite Bold  ; Set font size to 10, color to white, and make it bold
    Gui, TooltipGui: Add, Text, vTooltipText w200 h50 Center, %text% ; Center the text within the tooltip

    ; Get the current monitor the mouse is on
    SysGet, MonitorCount, MonitorCount
    CoordMode, Mouse, Screen
    MouseGetPos, MouseX, MouseY

    ; Loop through monitors to find the one where the mouse is located
    Loop, %MonitorCount%
    {
        SysGet, Monitor, Monitor, %A_Index%
        if (MouseX >= MonitorLeft && MouseX < MonitorRight && MouseY >= MonitorTop && MouseY < MonitorBottom)
        {
            ; Calculate the center of the current monitor
            MonitorWidth := MonitorRight - MonitorLeft
            MonitorHeight := MonitorBottom - MonitorTop
            TooltipX := MonitorLeft + (MonitorWidth // 2) - 120  ; Center the tooltip horizontally on the monitor
            TooltipY := MonitorTop + (MonitorHeight // 2) - 25   ; Center the tooltip vertically on the monitor
            break
        }
    }

    ; Show the tooltip at the center of the monitor
    Gui, TooltipGui: Show, x%TooltipX% y%TooltipY% w240 h50, Tooltip

    ; Hide the tooltip after 1 second
    SetTimer, RemoveToolTip, -1000
}

RemoveToolTip:
    Gui, TooltipGui: Destroy
return

; Win-J keybinding behavior
#j::
    if (!toggle)
        return  ; If the script is paused, do nothing

    ; Get the monitor count and primary monitor
    SysGet, MonitorCount, MonitorCount
    SysGet, MonitorPrimary, MonitorPrimary

    current := 0

    ; Loop through the monitors to find which one the mouse is on
    Loop, %MonitorCount%
    {
        SysGet, Monitor, Monitor, %A_Index%
        CoordMode, Mouse, Screen
        MouseGetPos, MouseX, MouseY

        if (MouseX >= MonitorLeft && MouseX < MonitorRight && MouseY >= MonitorTop && MouseY < MonitorBottom)
        {
            current := A_Index
            break
        }
    }

    next := current + 1
    if (next > MonitorCount)
        next := 1

    ; Get the coordinates of the next monitor
    SysGet, Monitor, Monitor, %next%
    newX := MonitorLeft + 0.5 * (MonitorRight - MonitorLeft)
    newY := MonitorTop + 0.5 * (MonitorBottom - MonitorTop)

    ; Display a red circle at the cursor's arrival position
    highlight_pos(newX, newY)

    ; Move the cursor to the new position
    DllCall("SetCursorPos", "int", newX, "int", newY)

return

highlight_pos(MouseX, MouseY)
{
    ; Create a red circle around the cursor position
    Gui, Destroy
    Gui, -Caption +ToolWindow +AlwaysOnTop
    Gui, Color, Red
    Gui, +LastFound
    GuiHwnd := WinExist()

    ; Make the window transparent
    DetectHiddenWindows, On
    WinSet, Transparent, 100, ahk_id %GuiHwnd%

    ; Set the region to be a circle (ellipse)
    WinSet, Region, 0-0 W100 H100 E, ahk_id %GuiHwnd%  ; 100x100 circle

    ; Position the circle around the cursor
    posX := MouseX - 50  ; Adjust to center the circle around the cursor
    posY := MouseY - 50

    ; Show the circle at the cursor position
    Gui, Show, w100 h100 x%posX% y%posY%

    ; Sleep for a short time to keep the circle visible
    Sleep, 200

    ; Destroy the circle after showing it
    Gui, Destroy
}
