# APIs and structs for playing with GDI / USER stuff.
#
# Author: Ben Nagy
# Copyright: Copyright (c) Ben Nagy, 2006-2013.
# License: The MIT License
# (See http://www.opensource.org/licenses/mit-license.php for details.)

require 'ffi'
require_relative 'wintypes'
require_relative 'winerror'

module GDI
  extend FFI::Library
  include WinTypes

  ffi_lib('user32', 'gdi32', 'kernel32')
  # This is gross, but the ffi_lib method doesn't know about .drv libraries, so
  # we have to grub about modifying ivars manually
  @ffi_libs << FFI::DynamicLibrary.open(
    'winspool.drv',
    FFI::DynamicLibrary::RTLD_LAZY | FFI::DynamicLibrary::RTLD_LOCAL
  )

  ffi_convention(:stdcall)

  def self.add_func(*args)
    attach_function( *args )
    case args.size
    when 3
      module_function args[0]
    when 4
      module_function args[0]
      alias_method(args[1], args[0])
      module_function args[1]
    end
  end

  # ===
  # Constants
  # ===

  BLACK_BRUSH         = 4
  BI_JPEG             = 4
  BI_PNG              = 5
  CHECKJPEGFORMAT     = 4120
  CLIP_DEFAULT_PRECIS = 0
  COLOR_WINDOW        = 5
  CW_USEDEFAULT       = -2147483648
  DEFAULT_CHARSET     = 1
  DEFAULT_PITCH       = 0
  DIB_RGB_COLORS      = 0
  DT_CENTER           = 0x01
  DT_SINGLELINE       = 0x20
  DT_VCENTER          = 0x04
  ETO_CLIPPED         = 0x04
  ETO_GLYPH_INDEX     = 0x0010
  ETO_OPAQUE          = 0x02
  FF_DONTCARE         = 0
  FR_PRIVATE          = 0x10
  FW_NORMAL           = 400
  GCL_HBRBACKGROUND   = -10
  GDI_ERROR           = -1 # (~0u) according to the header :/
  GWL_HINSTANCE       = -6
  IDC_ARROW           = 32512
  IDI_APPLICATION     = 32512
  IMAGE_CURSOR        = 2
  IMAGE_ICON          = 1
  LR_SHARED           = 32768
  MB_PRECOMPOSED      = 0x01
  NULL                = 0
  OUT_DEFAULT_PRECIS  = 0
  QUERYESCSUPPORT     = 8
  SRCCOPY             = 0xCC0020
  SW_SHOWNORMAL       = 1
  TA_RTLREADING       = 0x100
  WC_COMPOSITECHECK   = 0x200
  WHITE_BRUSH         = 0
  WM_DESTROY          = 2
  WM_LBUTTONDOWN      = 513
  WM_PAINT            = 0x000F
  WM_RBUTTONUP        = 517
  WNDPROC             = callback( :WindowProc, [ HWND, UINT, WPARAM, LPARAM ], LRESULT )
  WS_EX_LEFT          = 0
  WS_OVERLAPPEDWINDOW = 13565952
  WS_VISIBLE          = 268435456

  # Not going to put ALL the DEVMODE constants in.
  # http://source.winehq.org/source/include/wingdi.h has them, if you need.

  CCHDEVICENAME = 32
  CCHFORMNAME   = 32

  # ===
  # Classes - all caps is horrible, but matches the MSDN docs
  # ===

  class BITMAPINFOHEADER < FFI::Struct
    include WinTypes

    layout(
      :biSize, DWORD,
      :biWidth, LONG,
      :biHeight, LONG,
      :biPlanes, WORD,
      :biBitCount, WORD,
      :biCompression, DWORD,
      :biSizeImage, DWORD,
      :biXPelsPerMeter, LONG,
      :biYPelsPerMeter, LONG,
      :biClrUsed, DWORD,
      :biClrImportant, DWORD
    )
  end

  class BITMAPINFO < FFI::Struct

    include WinTypes

    layout(
      :biHeader, BITMAPINFOHEADER,
      :biColors, DWORD
    )
  end

  class DOCINFO < FFI::Struct
    include WinTypes

    layout(
      :cbSize, INT,
      :lpszDocName, LPCTSTR,
      :lpszOutput, LPCTSTR,
      :lpszDatatype, LPCTSTR,
      :fwType, DWORD
    )

    def initialize
      super
      self[:cbSize] = self.size
    end

  end

  class LOGFONTW < FFI::Struct
    include WinTypes

    layout(
      :lfHeight, LONG,
      :lfWidth, LONG,
      :lfEscapement, LONG, # is that even a real word??
      :lfOrientation, LONG,
      :lfWeight, LONG,
      :lfItalic,  BYTE,
      :lfUnderline, BYTE,
      :lfStrikeOut, BYTE,
      :lfCharSet, BYTE,
      :lfOutPrecision, BYTE,
      :lfClipPrecision, BYTE,
      :lfQuality, BYTE,
      :lfPitchAndFamily, BYTE,
      :lfFaceName, [WORD, 32]
    )
  end

  class POINT < FFI::Struct
    include WinTypes

    layout(
      :x, LONG,
      :y, LONG
    )
  end

  class RECT < FFI::Struct
    include WinTypes

    layout(
      :left, LONG,
      :top, LONG,
      :right, LONG,
      :bottom, LONG
    )
  end

  class METAHEADER < FFI::Struct
    include WinTypes
    pack 2 # 18 bytes is not dword aligned
    layout(
      :mtType, WORD,
      :mtHeaderSize, WORD,
      :mtVersion, WORD,
      :mtSize, DWORD,
      :mtNoObjects, WORD,
      :mtMaxRecord,  DWORD,
      :mtNoParameters, WORD,
    )
  end

  class MSG < FFI::Struct
    include WinTypes

    layout(
      :hwnd, HWND,
      :message, UINT,
      :wParam, WPARAM,
      :lParam, LPARAM,
      :time, DWORD,
      :pt, POINT
    )
  end

  class POINTL < FFI::Struct
    include WinTypes
    layout(
      :x, LONG,
      :y, LONG
    )
  end

  class PAINTSTRUCT < FFI::Struct
    include WinTypes

    layout(
      :hdc, HDC,
      :fErase, BOOL,
      :rcPaint, RECT,
      :fRestore, BOOL,
      :fIncUpdate, BOOL,
      :rgbReserved, [BYTE, 32]
    )
  end

  class SIZE < FFI::Struct
    include WinTypes
    layout(
      :cx, LONG,
      :cy, LONG
    )
  end

  class WNDCLASSEX < FFI::Struct
    include WinTypes

    layout(
      :cbSize, UINT,
      :style, UINT,
      :lpfnWndProc, WNDPROC,
      :cbClsExtra, INT,
      :cbWndExtra, INT,
      :hInstance, HANDLE,
      :hIcon, HICON,
      :hCursor, HCURSOR,
      :hbrBackground, HBRUSH,
      :lpszMenuName, LPCTSTR,
      :lpszClassName, LPCTSTR,
      :hIconSm, HICON
    )

    def initialize
      super
      self[:cbSize] = self.size
    end

  end

  # DEVMODE struct components (for Printers)
  # http://msdn.microsoft.com/en-us/library/windows/desktop/dd183565(v=vs.85).aspx
  # Don't know how to manage the unnamed unions / structs :(
  # Turns out WINE doesn't know either:
  # http://source.winehq.org/source/include/wingdi.h#L2936

  class DMUnion1Struct1 < FFI::Struct
    include WinTypes
    layout(
      :dmOrientation, SHORT,
      :dmPaperSize, SHORT,
      :dmPaperLength, SHORT,
      :dmPaperWidth, SHORT,
      :dmScale, SHORT,
      :dmCopies, SHORT,
      :dmDefaultSource, SHORT,
      :dmPrintQuality, SHORT
    )
  end

  class DMUnion1Struct2 < FFI::Struct
    include WinTypes
    layout(
      :dmPosition, POINTL,
      :dmDisplayOrientation, DWORD,
      :dmDisplayFixedOutput, DWORD
    )
  end

  class DMUnion1 < FFI::Union
    layout(
      :s1, DMUnion1Struct1,
      :s2, DMUnion1Struct2
    )
  end

  class DMUnion2 < FFI::Union
    include WinTypes
    layout(
      :dmDisplayFlags, DWORD,
      :dmNup, DWORD
    )
  end

  class DEVMODE < FFI::Struct
    include WinTypes
    layout(
      :dmDeviceName, [CHAR, CCHDEVICENAME],
      :dmSpecVersion, WORD,
      :dmDriverVersion, WORD,
      :dmSize, WORD,
      :dmDriverExtra, WORD,
      :dmFields, DWORD,
      :u1, DMUnion1,
      :dmColor, SHORT,
      :dmDuplex, SHORT,
      :dmYResolution, SHORT,
      :dmTTOption, SHORT,
      :dmCollate, SHORT,
      :dmFormName, [CHAR, CCHFORMNAME],
      :dmLogPixels, WORD,
      :dmBitsPerPel, DWORD,
      :dmPelsWidth, DWORD,
      :dmPelsHeight, DWORD,
      :u2, DMUnion2,
      :dmDisplayFrequency, DWORD,
      :dmICMMethod, DWORD,
      :dmICMIntent, DWORD,
      :dmMediaType, DWORD,
      :dmDitherType, DWORD,
      :dmReserved1, DWORD,
      :dmReserved2, DWORD,
      :dmPanningWidth, DWORD,
      :dmPanningHeight, DWORD
    )

    def initialize *args
      super
      self[:dmSize] = self.size
    end

  end

  # Special - utility class to run a message pump. Run this in a Thread. Or not.
  # Things seem to work either way. I have no idea what I'm doing.
  class MessagePump
    def run
      msg=MSG.new
      while GDI.GetMessage(msg, 0, 0, 0)
        GDI.TranslateMessage(msg)
        GDI.DispatchMessage(msg)
      end
    end
  end

  # ===
  # Methods. GDI / User32 / Kenel32 all lumped together for ease of use.
  # ===

  add_func :AddFontResourceEx, :AddFontResourceExA, [ LPCTSTR, DWORD, PVOID ], INT
  add_func :AddFontMemResourceEx, [ PVOID, DWORD, PVOID, POINTER ], HFONT
  add_func :BeginPaint, [ HWND, PAINTSTRUCT ], HDC
  add_func :ClipCursor, [ LPRECT ], BOOL
  add_func :CopyImage, [ HANDLE, UINT, INT, INT, UINT ], HANDLE
  add_func :CreateDC, :CreateDCA, [ LPCTSTR, LPCTSTR, LPCTSTR, LPINITDATA ], HDC
  add_func :CreateFontIndirect, :CreateFontIndirectA, [ LPLF ], HFONT
  add_func(
    :CreateWindowEx,
    :CreateWindowExA,
    [ DWORD, LPCTSTR, LPCTSTR, DWORD, INT, INT, INT, INT, HWND, HMENU, HINSTANCE, LPVOID ],
    HWND
  )
  add_func :DefWindowProc, :DefWindowProcA, [ HWND, UINT, WPARAM, LPARAM ], LRESULT
  add_func :DeleteDC, [ HDC ], BOOL
  add_func :DeleteMetaFile, [ HMETAFILE ], BOOL
  add_func :DeleteEnhMetaFile, [ HMETAFILE ], BOOL
  add_func :DeleteObject, [ HGDIOBJ ], BOOL
  add_func :DestroyCursor, [ HCURSOR ], BOOL
  add_func :DestroyWindow, [ HWND ], BOOL
  add_func :DispatchMessage, :DispatchMessageA, [ LPVOID ], BOOL
  add_func(
    :DocumentProperties,
    :DocumentPropertiesA,
    [ HWND, HANDLE, LPCTSTR, LPSTRUCT, LPSTRUCT, DWORD ],
    LONG
  )
  add_func :DrawText, :DrawTextA, [ HDC, LPCTSTR, INT, LPRECT, UINT ], INT
  add_func :EndDoc, [ HDC ], BOOL
  add_func :EndPage, [ HDC ], BOOL
  add_func :EndPaint, [ HWND, PAINTSTRUCT ], BOOL
  callback :EnumFontFamExProc, [ LPLOGFONT, LPTEXTMETRIC, DWORD, LPARAM ], BOOL
  add_func(
    :EnumFontFamiliesEx,
    :EnumFontFamiliesExA,
    [ HDC, LPLOGFONT, :EnumFontFamExProc, LPARAM, DWORD ],
    INT
  )
  add_func :ExtEscape, [ HDC, INT, INT, LPCTSTR, INT, LPCTSTR ], INT
  add_func :ExtTextOutA, [ HDC, INT, INT, UINT, LPRECT, LPCTSTR, UINT, LPDX ], BOOL
  add_func :ExtTextOutW, [ HDC, INT, INT, UINT, LPRECT, LPCTSTR, UINT, LPDX ], BOOL
  add_func :GdiFlush, [], BOOL
  add_func :GetClientRect, [ HWND, RECT ], BOOL
  add_func :GetClipCursor, [ LPRECT ], BOOL
  add_func :GetDC, [ HWND ], HDC
  add_func :GetDefaultPrinter, :GetDefaultPrinterA, [ LPCTSTR, LPDWORD ], BOOL
  add_func :GetDeviceCaps, [ HDC, INT ], INT
  add_func :GetFocus, [ HWND ], HWND
  # This guy is undocumented on MSDN.
  add_func(
    :GetFontResourceInfo,
    :GetFontResourceInfoW,
    [
      LPCWSTR, # filename [IN]
      POINTER, # Buffer size [IN], Result size [OUT]
      POINTER, # Buffer
      DWORD    # Info requested 1 - face name, 2 - LOGFONTW struct 4 - Full filename
    ],
    BOOL
  )
  add_func :GetMessage, :GetMessageA, [ LPMSG, HWND, UINT, UINT ], BOOL
  add_func :GetMetaFile, :GetMetaFileA, [ LPCTSTR ], HMETAFILE
  add_func :GetEnhMetaFile, :GetEnhMetaFileA, [ LPCTSTR ], HMETAFILE
  add_func :GetModuleHandle, :GetModuleHandleA, [ LPCTSTR ], HMODULE
  add_func :GetStockObject, [ INT ], HGDIOBJ
  add_func :GetTextExtentPoint32A, [ HDC, LPCTSTR, INT, LPSIZE ], BOOL
  add_func :GetTextExtentPoint32W, [ HDC, LPCTSTR, INT, LPSIZE ], BOOL
  add_func :GetWindowRect, [ HWND, LPRECT ], BOOL
  add_func :InvalidateRect, [ HWND, LPVOID, BOOL ], BOOL
  add_func :IsWindow, [ HWND ], BOOL
  add_func :LoadCursorFromFile, :LoadCursorFromFileA, [ LPCTSTR ], HCURSOR
  add_func :LoadImage,:LoadImageA, [ HINSTANCE, LPCTSTR, UINT, INT, INT, UINT ], HANDLE
  add_func :MultiByteToWideChar, [ UINT, DWORD, LPCTSTR, INT, LPCWSTR, INT ], INT
  add_func :OpenPrinter, :OpenPrinterA, [ LPCTSTR, POINTER, POINTER ], BOOL
  add_func :PlayMetaFile, [ HDC, HMETAFILE ], INT
  add_func :PlayEnhMetaFile, [ HDC, HMETAFILE, LPRECT ], BOOL
  add_func :PostQuitMessage, [ INT ], VOID
  add_func :PrintWindow, [ HWND, HDC, UINT ], BOOL
  add_func :RegisterClassEx, :RegisterClassExA, [ LPVOID ], ATOM
  add_func :ReleaseDC, [ HWND, HDC ], INT
  add_func :RemoveFontResourceEx, :RemoveFontResourceExA, [ LPCTSTR, DWORD, PVOID ], INT
  add_func :SelectObject, [ HDC, HGDIOBJ ], HGDIOBJ
  add_func :SetActiveWindow, [ HWND ], HWND
  if WIN64
    # Normally the compiler would do this automatically
    add_func :SetClassLongPtr, :SetClassLongPtrA, [ HWND, INT, LONG_PTR ], DWORD
  else
    add_func :SetClassLong, :SetClassLongA, [ HWND, INT, LONG ], DWORD
  end
  add_func :SetCursor, [ HCURSOR ], HCURSOR
  add_func :SetCursorPos, [ INT, INT ], BOOL
  add_func(
    :SetDIBitsToDevice,
    [ HDC, INT, INT, DWORD, DWORD, INT, INT, UINT, UINT, POINTER, LPBITMAPINFO, UINT],
    INT
  )
  add_func :SetEnhMetaFileBits, [ UINT, POINTER ], HANDLE
  add_func :SetForegroundWindow, [ HWND ], BOOL
  add_func :SetMetaFileBitsEx, [ UINT, POINTER ], HMETAFILE
  add_func :SetSystemCursor, [ HCURSOR, DWORD ], BOOL
  add_func :SetTextAlign, [ HDC, UINT ], INT
  add_func :SetWinMetaFileBits, [ UINT, POINTER, HDC, POINTER ], HMETAFILE
  add_func :ShowWindow, [ HWND, INT ], BOOL
  add_func :ShowWindow, [ HWND, INT ], BOOL
  add_func :StartDoc, :StartDocA, [ HDC, LPDOCINFO ], INT
  add_func :StartPage, [ HDC ], BOOL
  add_func(
    :StretchDIBits,
    [ HDC, INT, INT, INT, INT, INT, INT, INT, INT, POINTER, LPBITMAPINFO, UINT, DWORD ],
    INT
  )
  add_func :SwitchToThisWindow, [ HWND, BOOL ], VOID
  add_func :TextOut, :TextOutA, [ HDC, INT, INT, LPCTSTR, INT ], BOOL
  add_func :TranslateMessage, [ LPVOID ], BOOL
  add_func :UnregisterClass, :UnregisterClassA, [ LPCTSTR, HINSTANCE ], BOOL
  add_func :UpdateWindow, [ HWND ], BOOL
  add_func :WideCharToMultiByte, [ UINT, DWORD, LPCWSTR, INT, LPCTSTR, INT, LPCTSTR, LPBOOL ], INT

  # ===
  # Utility functions
  # ===

  def raise_win32_error
    raise "[Win32 Exception]  #{WinError.get_last_error}"
  end

  def get_facename_for_file fname
    buf=FFI::MemoryPointer.new :char, 260 # MAX_PATH - doubt I need this much.
    sz=FFI::MemoryPointer.new :int
    w_fname=FFI::MemoryPointer.new :char, 260*2
    sz.write_int 260
    # Convert the filename to MS style wide string
    w_sz=GDI.MultiByteToWideChar( 0, MB_PRECOMPOSED, fname, fname.size, w_fname, 260)
    raise_win32_error if w_sz.zero?
    # Undocumented GDI function. 2 asks for a LOGFONT struct, apparently more
    # reliable, according to the Internet. w_fname has had a null terminated
    # wide string written into it, so we don't need to process it further.
    3.times do
      # Very occasionally this fails, and I don't know why. Kernel stuff is trippy.
      success=GDI.GetFontResourceInfo( w_fname, sz, buf, 2 )
      break if success
      sleep 0.5
    end
    lf=LOGFONTW.new buf # cast the buffer to a LOGFONT struct
    # Convert the null terminated WCSTR back to UTF-8
    GDI.WideCharToMultiByte( 0, WC_COMPOSITECHECK, lf[:lfFaceName].to_ptr, -1, buf, 260, nil, nil )
    buf.read_string
  end
  module_function :get_facename_for_file, :raise_win32_error

end #GDI
