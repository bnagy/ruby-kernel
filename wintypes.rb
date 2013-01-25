# This is mainly so that the rest of the code will appear consistent with
# Windows documentation, and allows me to quickly prototype new APIs by copying
# directly from MSDN.
#
# Author: Ben Nagy
# Copyright: Copyright (c) Ben Nagy, 2006-2013.
# License: The MIT License
# (See http://www.opensource.org/licenses/mit-license.php for details.)

require 'ffi'

module WinTypes

  # This is a roundabout way of doing things, but I am trying to keep
  # definitions consistent with the types found here:
  # http://msdn.microsoft.com/en-us/library/windows/desktop/aa383751(v=vs.85).aspx
  WIN64=FFI::Platform::ADDRESS_SIZE==64
  if WIN64
    ULONG_PTR = FFI::TypeDefs[:uint64]
    LONG_PTR  = FFI::TypeDefs[:uint64]
  else
    ULONG_PTR = FFI::TypeDefs[:ulong]
    LONG_PTR  = FFI::TypeDefs[:long]
  end
  ULONG     = FFI::TypeDefs[:ulong]
  LONG      = FFI::TypeDefs[:long]
  INT       = FFI::TypeDefs[:int]
  WORD      = FFI::TypeDefs[:uint16]
  BYTE      = FFI::TypeDefs[:uchar]
  DWORD     = FFI::TypeDefs[:ulong]
  BOOL      = FFI::TypeDefs[:bool]
  UINT      = FFI::TypeDefs[:uint]
  POINTER   = FFI::TypeDefs[:pointer]
  SHORT     = FFI::TypeDefs[:short]
  VOID      = FFI::TypeDefs[:void]
  SIZE_T    = ULONG_PTR
  TCHAR     = WORD # let's assume unicode is always defined
  CHAR      = BYTE
  PVOID     = LPVOID = POINTER
  HANDLE    = ULONG_PTR
  NTSTATUS  = ULONG
  HWND      = HICON = HCURSOR = HBRUSH = HDC = HINSTANCE = HGDIOBJ =
              HMENU = HMODULE = HFONT = HMETAFILE = HANDLE
  LPARAM    = LONG_PTR
  WPARAM    = ULONG_PTR
  LPSTRUCT  = LPVOID # Use for when too lazy to add below
  LPCTSTR   = LPMSG = LPRECT = LPBOOL = LPPAINTSTRUCT = LPDX = LPSIZE =
              LPLF = LPCWSTR = LPLOGFONT = LPTEXTMETRIC = LPBITMAPINFO =
              LPDWORD = LPINITDATA = LPDOCINFO = LPVOID
  LRESULT   = LONG_PTR
  ATOM      = WORD

end
