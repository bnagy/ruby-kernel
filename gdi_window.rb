# Monolithic class to handle windows, in ... uh... Windows. Horribly incomplete
# and quite likely wrong in many areas.
#
# Author: Ben Nagy
# Copyright: Copyright (c) Ben Nagy, 2006-2013.
# License: The MIT License
# (See http://www.opensource.org/licenses/mit-license.php for details.)

require_relative 'gdi'
require_relative 'gdi_font'
require_relative 'winerror'

class GDIWindow

  include GDIFont

  DEFAULTS={
    width: 1024,
    height: 768,
    title: "FFI Window",
    font_size: 36,
    debug: true
  }

  def initialize opts={}
    @opts         = DEFAULTS.merge opts
    @current_y    = 0
    if @opts[:font_file]
      # Do this before creating the window, in case it doesn't load.
      load_font @opts[:font_file]
    end
    register_class
    create_window
    if @opts[:font_file]
      face=GDI.get_facename_for_file @opts[:font_file]
      set_font face, @opts[:font_size]
    end
    GDI.ShowWindow hwnd, GDI::SW_SHOWNORMAL
  end

  def close
    begin
      restore_font
      restore_cursor
    ensure
      #GDI.GdiFlush
      GDI.ReleaseDC @hwnd, dc
      GDI.DestroyWindow @hwnd
      # Because we created a new class, we MUST unregister it here, otherwise
      # the global atom table fills up with class names after ~16k. Good times.
      GDI.UnregisterClass poi(@atom), @hinst
    end
  end

  # ===
  # Cursor handling
  # ===

  def set_cursor cursor_file
    unless File.file? cursor_file
      raise ArgumentError, "Couldn't find cursor file #{cursor_file}"
    end
    hCursor=GDI.LoadCursorFromFile cursor_file
    raise_win32_error if hCursor.zero?
    @old_cursor=GDI.SetCursor hCursor
    debug_info "Set cursor #{cursor_file}, replacing old handle #{@old_cursor}"
    true
  end

  def restore_cursor
    if @old_cursor && @old_cursor.nonzero?
      # MSDN docs say we musn't destroy shared cursors, like those created by
      # LoadCursorFromFile. I do anyway. Leaks. Hate 'em.
      # SetCursor returns the cursor which was just replaced.
      GDI.DestroyCursor( GDI.SetCursor( @old_cursor ))
      debug_info "Restored #{@old_cursor}"
    else
      debug_info "No old cursor to restore, ignoring restore_cursor"
    end
  end

  def clip_cursor
    # This doesn't seem to move the cursor, but it does mean that our cursor
    # icon will display, wherever the physical cursor is onscreen. GDI! HOW THE
    # F*CK DOES IT WORK??
    @old_clip=GDI::RECT.new
    @clip=GDI::RECT.new
    get_focus
    GDI.GetClipCursor @old_clip
    GDI.GetWindowRect @hwnd, @clip
    GDI.ClipCursor @clip
  end

  def unclip_cursor
    GDI.ClipCursor @old_clip
  end

  # ===
  # Utility
  # ===

  def get_focus
    # This can only work when the process that created the window is in the
    # foreground. See MSDN for more details. There are some approaches to steal
    # focus more reliably, but they're awful. I'll leave this here though
    # http://betterlogic.com/roger/2010/07/windows-forceforeground-
    # bringwindowtotop-brings-it-to-top-but-without-being-active/
    GDI.SetForegroundWindow @hwnd
  end

  # ===
  # Drawing
  # ===

  def set_alignment align
    # TODO: add sugar. Right now you need to specify alignment options as INTs
    res=GDI.SetTextAlign dc, align
    raise_win32_error if res==GDI::GDI_ERROR
    true
  end

  def draw_text str, opts={wide: true, raw: false}
    if opts[:wide]
      text_out_method    = :ExtTextOutW
      text_extent_method = :GetTextExtentPoint32W
    else
      text_out_method    = :ExtTextOutA
      text_extent_method = :GetTextExtentPoint32A
    end
    out       = ""
    guess     = nil
    sz        = GDI::SIZE.new
    this_line = GDI::RECT.new
    width     = rect[:right]
    until str.empty?
      if guess
        out << str.slice!(0,guess)
      else
        # for the first line, build the string one glyph at a time until the
        # text extent is greater than our rect width
        until sz[:cx] > width || str.empty?
          out << str.slice!( 0,1 )
          if GDI.send( text_extent_method, dc, out, out.size, sz )
            guess = out.size
          else
            # OK, GetTextExtentPoint failed for some reason. Try to draw the
            # whole thing (may well be massively clipped)
            out=str.clone
            str.clear
            break
          end
        end
      end
      # This next bit was designed to ensure that the line really is going to
      # fit horizontally, but it is stripped, for now, for speed. Some lines
      # will get clipped slightly, but it's not really a huge deal for fuzzing
      # purposes.
      #
      # until sz[:cx] < width
      if false
        # put one back
        before=out.size
        str.prepend out.slice!(-1,1)
        break if out.size==before # slice failed to shorten! jruby bug...
        raise_win32_error unless GDI.send( text_extent_method, dc, out, out.size, sz )
      end
      # Write what we have so far, which may be only part of the input string.
      # Wrap to top if we would pass the bottom of the window
      @current_y=0 if @current_y + sz[:cy] > rect[:bottom]
      this_line[:left]   = 0
      this_line[:right]  = width
      this_line[:top]    = @current_y
      this_line[:bottom] = @current_y + sz[:cy]
      GDI.send(
        text_out_method,
        dc, # device context
        0, # X start
        @current_y, # Y start
        opts[:raw] ? GDI::ETO_GLYPH_INDEX : GDI::ETO_CLIPPED|GDI::ETO_OPAQUE,
        this_line, # RECT
        out, # str to draw
        out.size, # size
        nil # lpDx
      )
      @current_y+=sz[:cy]
      out=""
    end
    GDI.GdiFlush
  end
  alias :write :draw_text

  # ===
  # Images
  # ===

  def play_emf_file emf_fname
    draw_emf_from_handle GDI.GetEnhMetaFile emf_fname
  end

  def play_emf_data emf_data
    p_data = make_pstr emf_data
    draw_emf_from_handle GDI.SetEnhMetaFileBits p_data.size, p_data
  end

  def draw_emf_from_handle emf_handle
    raise_win32_error if emf_handle.zero?
    GDI.PlayEnhMetaFile dc, emf_handle, rect
    GDI.DeleteEnhMetaFile emf_handle
  end

  def play_wmf_data wmf_data
    # So. WMF do not have any position or scaling information. they're just raw
    # GDI commands. They're usually stored on disk in a 'standard' nonstandard
    # way with a 'placeable metafile' header that contains that info. However,
    # the PlayMetaFile API does not allow you to pass that header, and will try
    # and draw stuff retardedly. The options, then are:
    # 1. Shell out to mspaint.exe
    # - internally that calls GDI+, converts WMF to Bitmap and displays that
    #   (which does not sound so awesome for reaching kernel stuff)
    # 2. Convert to EMF, play the EMF
    # - Easy, may lose some opportunities to be evil, not sure
    # 3. Get the scaling information from the APM header and use the Coordinate
    # Spaces and Transforms APIs to modify the target DC to correctly display
    # the WMF by applying global transforms to all the GDI drawing commands
    # contained in the WMF.
    # - This involves large amounts of pels and twips and maths and crap.
    if wmf_data[0..3]=="\xD7\xCD\xC6\x9A"
      # This is an 'Aldus Placeable Metafile', and the first 22 bytes are the
      # APM header, which needs to be stripped.
      # ref: http://msdn.microsoft.com/en-us/library/windows/desktop/ms534075(v=vs.85).aspx
      debug_info "Detected Aldus Metafile, stripping header..."
      pdata=make_pstr wmf_data[22..-1]
    else
      debug_info "Doesn't look like a WMF, playing as EMF..."
      play_emf_data( wmf_data ) and return
    end
    # Convert to EMF. MSDN says:
    # If the lpmfp parameter is NULL, the system uses the MM_ANISOTROPIC mapping
    # mode to scale the picture so that it fits the entire device surface.
    draw_emf_from_handle GDI.SetWinMetaFileBits pdata.size, pdata, dc, nil
  end

  private

  def poi(a); ::FFI::Pointer.new(a); end

  def make_pstr str
    FFI::MemoryPointer.from_string str
  end

  def raise_win32_error
    error=WinError.get_last_error
    debug_info "#{error} from #{caller[1]}"
    raise "[Win32 Exception]  #{WinError.get_last_error}"
  end

  def debug_info str
    warn "[#{self.class} DEBUG] #{str}" if @opts[:debug]
  end

  def hwnd
    # Window handle
    return @hwnd if @hwnd && GDI.IsWindow(@hwnd)
    nil
  end

  def dc
    # Device context
    @dc ||= GDI.GetDC hwnd
    raise_win32_error if @dc.zero?
    @dc
  end

  def rect
    # Area owned by this window
    @r ||= GDI::RECT.new # reuse this struct
    raise_win32_error unless GDI.GetClientRect( hwnd, @r )
    @r
  end

  def hinst
    # Instance handle
    @hinst ||= GDI.GetModuleHandle( nil ) # handle to the .exe we're in
    raise_win32_error if @hinst.zero?
    @hinst
  end

  def create_window
    @hwnd ||= GDI.CreateWindowEx(
      GDI::WS_EX_LEFT, # extended style
      poi(@atom), # class name or atom
      @opts[:title], # window title
      GDI::WS_OVERLAPPEDWINDOW | GDI::WS_VISIBLE, # style
      GDI::CW_USEDEFAULT, # X pos
      GDI::CW_USEDEFAULT, # Y pos
      @opts[:width], # width
      @opts[:height], # height
      0, # parent
      0, # menu
      hinst, # instance
      nil  # lparam
    )
    raise_win32_error if @hwnd.zero?
  end

  def register_class

    window_class = GDI::WNDCLASSEX.new
    window_class[:lpfnWndProc]   = method(:window_proc)
    window_class[:hInstance]     = hinst
    window_class[:hbrBackground] = GDI::COLOR_WINDOW
    window_class[:lpszClassName] = make_pstr("#{rand(2**32)}")
    window_class[:hCursor]       = 0

    @atom = GDI.RegisterClassEx( window_class )
    if @atom.zero?
      debug_info "Failed RegisterClassEx"
      raise_win32_error
    end
    debug_info "Registered class."
  end

  def window_proc(hwnd, umsg, wparam, lparam)
    case umsg
    when GDI::WM_DESTROY
      GDI.PostQuitMessage(0)
      return 0
    else
      # This handles all messages we don't explicitly process
      return GDI.DefWindowProc(hwnd, umsg, wparam, lparam)
    end
    0
  end

end
