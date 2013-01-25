# Monolithic class to handle printers. Horribly incomplete and quite likely
# wrong in many areas.
#
# Author: Ben Nagy
# Copyright: Copyright (c) Ben Nagy, 2006-2013.
# License: The MIT License
# (See http://www.opensource.org/licenses/mit-license.php for details.)

require_relative 'gdi'
require_relative 'gdi_font'
require_relative 'winerror'

module GDI

  # Add extra constants for printers

  # Not going to put ALL the DEVMODE constants in.
  # http://source.winehq.org/source/include/wingdi.h has them, if you need.

  DM_SPECVERSION  = 0x401
  DM_UPDATE       = 1
  DM_COPY         = 2
  DM_PROMPT       = 4
  DM_MODIFY       = 8

  DM_IN_BUFFER      = DM_MODIFY
  DM_IN_PROMPT      = DM_PROMPT
  DM_OUT_BUFFER     = DM_COPY
  DM_OUT_DEFAULT    = DM_UPDATE

  DM_ORIENTATION         = 0x00000001
  DM_PAPERSIZE           = 0x00000002
  DM_PAPERLENGTH         = 0x00000004
  DM_PAPERWIDTH          = 0x00000008
  DM_SCALE               = 0x00000010
  DM_POSITION            = 0x00000020
  DM_NUP                 = 0x00000040
  DM_DISPLAYORIENTATION  = 0x00000080
  DM_COPIES              = 0x00000100
  DM_DEFAULTSOURCE       = 0x00000200
  DM_PRINTQUALITY        = 0x00000400
  DM_COLOR               = 0x00000800
  DM_DUPLEX              = 0x00001000
  DM_YRESOLUTION         = 0x00002000
  DM_TTOPTION            = 0x00004000
  DM_COLLATE             = 0x00008000
  DM_FORMNAME            = 0x00010000
  DM_LOGPIXELS           = 0x00020000
  DM_BITSPERPEL          = 0x00040000
  DM_PELSWIDTH           = 0x00080000
  DM_PELSHEIGHT          = 0x00100000
  DM_DISPLAYFLAGS        = 0x00200000
  DM_DISPLAYFREQUENCY    = 0x00400000
  DM_ICMMETHOD           = 0x00800000
  DM_ICMINTENT           = 0x01000000
  DM_MEDIATYPE           = 0x02000000
  DM_DITHERTYPE          = 0x04000000
  DM_PANNINGWIDTH        = 0x08000000
  DM_PANNINGHEIGHT       = 0x10000000

  # Constants for GetDeviceCaps

  DRIVERVERSION     = 0
  TECHNOLOGY        = 2
  HORZSIZE          = 4
  VERTSIZE          = 6
  HORZRES           = 8
  VERTRES           = 10
  BITSPIXEL         = 12
  PLANES            = 14
  NUMBRUSHES        = 16
  NUMPENS           = 18
  NUMMARKERS        = 20
  NUMFONTS          = 22
  NUMCOLORS         = 24
  PDEVICESIZE       = 26
  CURVECAPS         = 28
  LINECAPS          = 30
  POLYGONALCAPS     = 32
  TEXTCAPS          = 34
  CLIPCAPS          = 36
  RASTERCAPS        = 38
  ASPECTX           = 40
  ASPECTY           = 42
  ASPECTXY          = 44
  LOGPIXELSX        = 88
  LOGPIXELSY        = 90
  CAPS1             = 94
  SIZEPALETTE       = 104
  NUMRESERVED       = 106
  COLORRES          = 108
  PHYSICALWIDTH     = 110
  PHYSICALHEIGHT    = 111
  PHYSICALOFFSETX   = 112
  PHYSICALOFFSETY   = 113
  SCALINGFACTORX    = 114
  SCALINGFACTORY    = 115
  VREFRESH          = 116
  DESKTOPVERTRES    = 117
  DESKTOPHORZRES    = 118
  BLTALIGNMENT      = 119
  SHADEBLENDCAPS    = 120
  COLORMGMTCAPS     = 121

  # Constants for GDI Escapes
  # These are from the WINE wingdi.h here:
  # http://source.winehq.org/source/include/wingdi.h#L275
  # They do not completely match MSDN, here:
  # http://msdn.microsoft.com/en-us/library/windows/desktop/dd162843(v=vs.85).aspx
  # I love my job. :(

  NEWFRAME                = 1
  ABORTDOC                = 2
  NEXTBAND                = 3
  SETCOLORTABLE           = 4
  GETCOLORTABLE           = 5
  FLUSHOUTPUT             = 6
  DRAFTMODE               = 7
  QUERYESCSUPPORT         = 8
  SETABORTPROC            = 9
  STARTDOC                = 10
  ENDDOC                  = 11
  GETPHYSPAGESIZE         = 12
  GETPRINTINGOFFSET       = 13
  GETSCALINGFACTOR        = 14
  MFCOMMENT               = 15
  GETPENWIDTH             = 16
  SETCOPYCOUNT            = 17
  SELECTPAPERSOURCE       = 18
  DEVICEDATA              = 19
  PASSTHROUGH             = 19
  GETTECHNOLGY            = 20
  GETTECHNOLOGY           = 20
  SETLINECAP              = 21
  SETLINEJOIN             = 22
  SETMITERLIMIT           = 23
  BANDINFO                = 24
  DRAWPATTERNRECT         = 25
  GETVECTORPENSIZE        = 26
  GETVECTORBRUSHSIZE      = 27
  ENABLEDUPLEX            = 28
  GETSETPAPERBINS         = 29
  GETSETPRINTORIENT       = 30
  ENUMPAPERBINS           = 31
  SETDIBSCALING           = 32
  EPSPRINTING             = 33
  ENUMPAPERMETRICS        = 34
  GETSETPAPERMETRICS      = 35
  POSTSCRIPT_DATA         = 37
  POSTSCRIPT_IGNORE       = 38
  MOUSETRAILS             = 39
  GETDEVICEUNITS          = 42
  GETEXTENDEDTEXTMETRICS  = 256
  GETEXTENTTABLE          = 257
  GETPAIRKERNTABLE        = 258
  GETTRACKKERNTABLE       = 259
  EXTTEXTOUT              = 512
  GETFACENAME             = 513
  DOWNLOADFACE            = 514
  ENABLERELATIVEWIDTHS    = 768
  ENABLEPAIRKERNING       = 769
  SETKERNTRACK            = 770
  SETALLJUSTVALUES        = 771
  SETCHARSET              = 772
  STRETCHBLT              = 2048
  GETSETSCREENPARAMS      = 3072
  QUERYDIBSUPPORT         = 3073
  BEGIN_PATH              = 4096
  CLIP_TO_PATH            = 4097
  END_PATH                = 4098
  EXT_DEVICE_CAPS         = 4099
  RESTORE_CTM             = 4100
  SAVE_CTM                = 4101
  SET_ARC_DIRECTION       = 4102
  SET_BACKGROUND_COLOR    = 4103
  SET_POLY_MODE           = 4104
  SET_SCREEN_ANGLE        = 4105
  SET_SPREAD              = 4106
  TRANSFORM_CTM           = 4107
  SET_CLIP_BOX            = 4108
  SET_BOUNDS              = 4109
  SET_MIRROR_MODE         = 4110
  OPENCHANNEL             = 4110
  DOWNLOADHEADER          = 4111
  CLOSECHANNEL            = 4112
  POSTSCRIPT_PASSTHROUGH  = 4115
  ENCAPSULATED_POSTSCRIPT = 4116
  POSTSCRIPT_IDENTIFY     = 4117
  POSTSCRIPT_INJECTION    = 4118
  CHECKJPEGFORMAT         = 4119
  CHECKPNGFORMAT          = 4120
  GET_PS_FEATURESETTING   = 4121
  GDIPLUS_TS_QUERYVER     = 4122
  GDIPLUS_TS_RECORD       = 4123
  PSIDENT_GDICENTRIC      = 0
  PSIDENT_PSCENTRIC       = 1
  QDI_SETDIBITS           = 1
  QDI_GETDIBITS           = 2
  QDI_DIBTOSCREEN         = 4
  QDI_STRETCHDIB          = 8

end

class GDIPrinter

  include GDIFont

  DEFAULTS={
    font_size: 36,
    debug: true
  }

  attr_reader :dc

  def initialize opts={}
    @opts         = DEFAULTS.merge opts
    @current_y    = 0
    if @opts[:font_file]
      # Do this before creating the DC, in case it doesn't load.
      load_font @opts[:font_file]
    end
    lpszDevice=make_pstr( opts[:printer] || default_printer )
    @dc=GDI.CreateDC nil, lpszDevice, nil, nil
    raise "Unable to connect to #{lpszDevice.read_string}" if @dc.zero?
    @printer_name=lpszDevice.read_string
    debug_info "OK, connected to #{@printer_name}"
    if @opts[:font_file]
      face=GDI.get_facename_for_file @opts[:font_file]
      ydpi=GDI.GetDeviceCaps dc, GDI::LOGPIXELSY
      # Screen res for fonts is 72dpi, so scale the font up to try and WYSIWYG.
      set_font( face, (@opts[:font_size] * ( ydpi / 72.0 )).round )
    end
  end

  def close
    begin
      restore_font
    ensure
      GDI.DeleteDC dc
      debug_info "DC destroyed."
    end
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
    rect      = get_printable_rect
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
      if @current_y + sz[:cy] > rect[:bottom]
        @current_y=0
        end_page
        start_page
      end
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

  def set_di_bits img_data, img_width, img_height, img_type
    unless [:jpeg].include? img_type
      # TODO expand types that we handle
      raise ArgumentError, "Unknown image type #{img_type}"
    end

    bmi_header=GDI::BITMAPINFOHEADER.new
    bmi_header[:biSize]        = GDI::BITMAPINFOHEADER.size
    bmi_header[:biWidth]       = img_width
    bmi_header[:biHeight]      = -img_height # top down image
    bmi_header[:biPlanes]      = 1
    bmi_header[:biBitCount]    = 0
    bmi_header[:biCompression] = GDI::BI_JPEG
    bmi_header[:biSizeImage]   = img_data.bytesize

    retval=GDI.SetDIBitsToDevice(
      dc,
      0, # dest X
      0, # dest Y
      img_width, # width
      img_height, # height
      0, # src X
      img_height, # src Y, (bottom left corner of image)
      0, # Starting scanline
      img_height, # total scanlines
      make_pstr( img_data ),
      bmi_header,
      GDI::DIB_RGB_COLORS
    )
    raise_win32_error if retval==GDI::GDI_ERROR || retval.zero?
    retval # scan lines copied
  end

  def stretch_di_bits img_data, img_width, img_height, img_type, stretch_X=1, stretch_Y=1
    # This is NOT a general purpose implementation of this function, it is for
    # fuzzing purposes only. Basically, all I want to do is be able to force
    # win32k.sys to rasterize PNG / JPEG images.
    unless [:jpeg].include? img_type
      # TODO expand types that we handle
      raise ArgumentError, "Unknown image type #{img_type}"
    end

    bmi_header=GDI::BITMAPINFOHEADER.new
    bmi_header[:biSize]        = GDI::BITMAPINFOHEADER.size
    bmi_header[:biWidth]       = img_width
    bmi_header[:biHeight]      = -img_height # top down image
    bmi_header[:biPlanes]      = 1
    bmi_header[:biBitCount]    = 0
    bmi_header[:biCompression] = GDI::BI_JPEG
    bmi_header[:biSizeImage]   = img_data.bytesize

    debug_info "Original: #{img_width} x #{img_height} - Stretching X by #{stretch_X} Y by #{stretch_Y}"
    retval=GDI.StretchDIBits(
      dc,
      0, # dest X
      0, # dest Y
      img_width * stretch_X, # width
      img_height * stretch_Y, # height
      0, # src X
      0, # src Y
      img_width,
      img_height,
      make_pstr( img_data ),
      bmi_header,
      GDI::DIB_RGB_COLORS,
      GDI::SRCCOPY
    )
    raise_win32_error if retval==GDI::GDI_ERROR || retval.zero?
    retval # scan lines copied
  end

  def start_doc opts={output: "C:\\bm3\\blah.xps"}
    docinfo=GDI::DOCINFO.new
    docname=opts[:docname] || "PRINT"
    docinfo[:lpszDocName] = make_pstr docname
    docinfo[:lpszOutput] = make_pstr opts[:output]
    GDI.StartDoc dc, docinfo
  end

  def start_page
    GDI.StartPage dc
  end

  def end_page
    GDI.EndPage dc
  end

  def end_doc
    GDI.EndDoc dc
  end

  def get_printable_rect
    xres=GDI.GetDeviceCaps dc, GDI::HORZRES
    yres=GDI.GetDeviceCaps dc, GDI::VERTRES
    r=GDI::RECT.new
    r[:left]   = 0
    r[:right]  = xres - 1
    r[:top]    = 0
    r[:bottom] = yres - 1
    r
  end

  def stretch_img img_data, opts={}
    debug_info "Got a JPG, size #{(img_data.bytesize / 1024).round 2}KB"
    # Stretch the image onto the printer DC
    stretch_di_bits(
      img_data,
      opts[:width],
      opts[:height],
      :jpeg,
      opts[:stretch_X],
      opts[:stretch_Y]
    )
  end

  def get_document_properties
    # http://msdn.microsoft.com/en-us/library/windows/desktop/dd183576(v=vs.85).aspx
    hPrinter=FFI::MemoryPointer.new( WinTypes::HANDLE )
    if GDI.OpenPrinter( make_pstr( @printer_name), hPrinter, nil )
      devmode_sz=GDI.DocumentProperties(
        0,    # hWND, but seems to work anyway
        hPrinter.send( "read_array_of_" + WinTypes::HANDLE.to_sym.to_s, 1 ).first, # BARF!
        make_pstr( @printer_name ),
        nil,  # output buffer
        nil,  # input buffer
        0     # mode - 0 to get the full size of the DEVMODE inc special driver options
      )
      devmode=make_pstr "\x00" * devmode_sz
      res=GDI.DocumentProperties(
        0,
        hPrinter.send( "read_array_of_" + WinTypes::HANDLE.to_sym.to_s, 1 ).first, # BARF!
        make_pstr( @printer_name ),
        devmode,
        nil,
        GDI::DM_OUT_BUFFER
      )
      raise_win32_error if res.zero?
      GDI::DEVMODE.new devmode
    else
      raise_win32_error
    end
  end

  def ext_escape escape_code, p_input, p_output=nil
    sz_input = p_input.size rescue 0
    sz_output = p_output.size rescue 0
    res = GDI.ExtEscape(
      dc,
      escape_code,
      sz_input,
      p_input,
      sz_output,
      p_output
    )
    raise_win32_error if res < 0
    res
  end

  def enumerate_escapes
    (0..5000).each {|escape|
      escape_code=FFI::MemoryPointer.new :ulong
      escape_code.write_ulong escape
      res=GDI.ExtEscape(
        dc,
        GDI::QUERYESCSUPPORT,
        escape_code.size,
        escape_code,
        0,
        nil
      )
      puts "Supports #{escape}" if res > 0
    }
  end

  private

  def default_printer
    buf=make_pstr( "\x00" * 260 )
    buf_sz=FFI::MemoryPointer.new( :ulong )
    buf_sz.write_ulong buf.size
    if GDI.GetDefaultPrinter buf, buf_sz
      buf.read_string
    else
      raise_win32_error
    end
  end

  def check_jpeg_support p_jpeg_data
    escape_code=FFI::MemoryPointer.new :ulong
    escape_code.write_ulong GDI::CHECKJPEGFORMAT
    # Check if CHECKJPEGFORMAT exists
    res=GDI.ExtEscape(
      dc,
      GDI::QUERYESCSUPPORT,
      escape_code.size,
      escape_code,
      0,
      nil
    )
    if res > 0
      status=FFI::MemoryPointer.new :ulong
      res=GDI.ExtEscape(
        dc,
        GDI::CHECKJPEGFORMAT,
        p_jpeg_data.size,
        p_jpeg_data,
        status.size,
        status
      )
      return true if status.read_ulong==1 && res > 0
    end
    false
  end

  def poi(a); ::FFI::Pointer.new(a); end

  def make_pstr str
    return nil unless str
    FFI::MemoryPointer.from_string str
  end

  def raise_win32_error
    error=WinError.get_last_error
    debug_info "#{error} from #{caller[1]}"
    raise "[#{Time.now} #{self.class} WIN32 ERR]  #{WinError.get_last_error}"
  end

  def debug_info str
    warn "[#{Time.now} #{self.class} DEBUG] #{str}" if @opts[:debug]
  end

end
