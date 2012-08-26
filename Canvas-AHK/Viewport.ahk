#NoEnv

/*
Copyright 2012 Anthony Zhang <azhang9@gmail.com>

This file is part of Canvas-AHK. Source code is available at <https://github.com/Uberi/Canvas-AHK>.

Canvas-AHK is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

class Viewport
{
    __New(hWindow)
    {
        this.hWindow := hWindow
    }

    Attach(Surface)
    {
        this.Width := Surface.Width
        this.Height := Surface.Height
        this.pGraphics := Surface.pGraphics
        this.pBitmap := Surface.pBitmap
        Return, this
    }

    Refresh()
    {
        ;flush the GDI+ drawing batch
        this.CheckStatus(DllCall("gdiplus\GdipFlush","UPtr",this.pGraphics,"UInt",1) ;FlushIntention.FlushIntentionSync
            ,"GdipFlush","Could not flush GDI+ pending rendering operations")

        ;obtain handle to the bitmap
        hBitmap := 0
        this.CheckStatus(DllCall("gdiplus\GdipCreateHBITMAPFromBitmap","UPtr",this.pBitmap,"UPtr*",hBitmap,"UInt",0xFF0000)
            ,"GdipCreateHBITMAPFromBitmap","Could not obtain bitmap handle")

        ;set control bitmap to bitmap handle
        SendMessage, 0x172, 0x0, hBitmap,, % "ahk_id " . this.hWindow ;STM_SETIMAGE, IMAGE_BITMAP
        If (ErrorLevel = "FAIL") ;failed to send message
        {
            DllCall("DeleteObject","UPtr",hBitmap)
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not set control bitmap (error sending message STM_SETIMAGE)")
        }
        If ErrorLevel != 0 ;bitmap available
        {
            ;delete old bitmap
            If !DllCall("DeleteObject","UPtr",ErrorLevel)
            {
                DllCall("DeleteObject","UPtr",hBitmap)
                throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not delete old bitmap (error in DeleteObject)")
            }
        }

        ;delete bitmap handle
        If !DllCall("DeleteObject","UPtr",hBitmap)
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not delete bitmap (error in DeleteObject)")

        Return, this
    }

    CheckStatus(Result,Name,Message)
    {
        static StatusValues := ["Status.GenericError"
                               ,"Status.InvalidParameter"
                               ,"Status.OutOfMemory"
                               ,"Status.ObjectBusy"
                               ,"Status.InsufficientBuffer"
                               ,"Status.NotImplemented"
                               ,"Status.Win32Error"
                               ,"Status.WrongState"
                               ,"Status.Aborted"
                               ,"Status.FileNotFound"
                               ,"Status.ValueOverflow"
                               ,"Status.AccessDenied"
                               ,"Status.UnknownImageFormat"
                               ,"Status.FontFamilyNotFound"
                               ,"Status.FontStyleNotFound"
                               ,"Status.NotTrueTypeFont"
                               ,"Status.UnsupportedGdiplusVersion"
                               ,"Status.GdiplusNotInitialized"
                               ,"Status.PropertyNotFound"
                               ,"Status.PropertyNotSupported"
                               ,"Status.ProfileNotFound"]
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",-1,Message . " (GDI+ error " . StatusValues[Result] . " in " . Name . ")")
        Return, this
    }
}