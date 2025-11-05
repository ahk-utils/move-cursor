;; https://stackoverflow.com/a/70069592

!J::
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
