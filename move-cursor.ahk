;; https://stackoverflow.com/a/70069592
;; Version: 1.1.1

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
    static pToken := 0
    size := 120
    thickness := 4

    ; Start GDI+
    if (!pToken)
    {
        VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0)
        NumPut(1, si, 0, "UInt")
        DllCall("gdiplus\GdiplusStartup", "Ptr*", pToken, "Ptr", &si, "Ptr", 0)
    }
    if (!pToken)
    {
        DllCall("LoadLibrary", "Str", "gdiplus")
        VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0)
        NumPut(1, si, 0, "UInt")
        DllCall("gdiplus\GdiplusStartup", "Ptr*", pToken, "Ptr", &si, "Ptr", 0)
    }

    ; Create layered window
    Gui, HighlightRing: New
    Gui, HighlightRing: -Caption +E0x80000 +ToolWindow +AlwaysOnTop
    Gui, HighlightRing: Show, w%size% h%size% NA

    Gui, HighlightRing: +LastFound
    hwnd := WinExist()

    ; Create GDI+ graphics on a bitmap
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", size, "Int", size, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", pBitmap)
    DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBitmap, "Ptr*", pGraphics)
    DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", 4) ; AntiAlias

    ; Draw anti-aliased filled circle (red, semi-transparent)
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0xDDFF2020, "Ptr*", pBrush)
    DllCall("gdiplus\GdipFillEllipse", "Ptr", pGraphics, "Ptr", pBrush, "Float", 0.0, "Float", 0.0, "Float", size, "Float", size)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrush)

    ; Update layered window with the bitmap
    hdc := DllCall("GetDC", "Ptr", hwnd)
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", hBitmap, "UInt", 0)
    mdc := DllCall("CreateCompatibleDC", "Ptr", hdc)
    old := DllCall("SelectObject", "Ptr", mdc, "Ptr", hBitmap)

    VarSetCapacity(pt, 8, 0), NumPut(size, pt, 0, "Int"), NumPut(size, pt, 4, "Int")
    VarSetCapacity(ptSrc, 8, 0)
    VarSetCapacity(bf, 4, 0), NumPut(0, bf, 0, "UChar"), NumPut(0, bf, 1, "UChar"), NumPut(255, bf, 2, "UChar"), NumPut(1, bf, 3, "UChar")

    posX := MouseX - size // 2
    posY := MouseY - size // 2
    VarSetCapacity(ptDst, 8, 0), NumPut(posX, ptDst, 0, "Int"), NumPut(posY, ptDst, 4, "Int")

    DllCall("UpdateLayeredWindow", "Ptr", hwnd, "Ptr", hdc, "Ptr", &ptDst, "Ptr", &pt, "Ptr", mdc, "Ptr", &ptSrc, "UInt", 0, "Ptr", &bf, "UInt", 2)

    ; Cleanup GDI objects
    DllCall("SelectObject", "Ptr", mdc, "Ptr", old)
    DllCall("DeleteObject", "Ptr", hBitmap)
    DllCall("DeleteDC", "Ptr", mdc)
    DllCall("ReleaseDC", "Ptr", hwnd, "Ptr", hdc)
    DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGraphics)
    DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)

    Sleep, 300
    Gui, HighlightRing: Destroy
}
