# Abstracted out font stuff for anything that uses a DC, so it can be mixed in.
#
# Author: Ben Nagy
# Copyright: Copyright (c) Ben Nagy, 2006-2013.
# License: The MIT License
# (See http://www.opensource.org/licenses/mit-license.php for details.)

module BM3
  module Win32
    module GDIFont

      def load_font font_file
        @last_font=font_file
        unless File.file? font_file # Needs an absolute, Windows style path
          if File.file?( ENV['SYSTEMROOT'] + "\\Fonts\\" << font_file )
            font_file=ENV['SYSTEMROOT'] + "\\Fonts\\" << font_file
            debug_info "Warning: Using system font #{font_file}"
          else
            raise ArgumentError, "#{self.class}-#{__method__}: Unable to find #{font_file}"
          end
        end
        debug_info "Removing any old copies of #{font_file}"
        GDI.RemoveFontResourceEx(font_file, 0, 0) # just in case
        added=GDI.AddFontResourceEx(font_file, 0, 0)
        if added.zero?
          debug_info "Failed to load #{font_file}."
          raise ArgumentError, "#{self.class}-#{__method__}: Failed to load font."
        else
          debug_info "Loaded #{added} font(s) from #{font_file}"
          true
        end
      end

      def font_families
        font_families=[]
        enum_proc=Proc.new {|lpelfme, lpntme, font_type, lparam|
          logical_font=GDI::LOGFONTW.new lpelfme
          font_families << logical_font[:lfFaceName].to_ptr.read_string
          true
        }
        desired_info=GDI::LOGFONTW.new # empty struct matches all fonts, basically
        GDI.EnumFontFamiliesEx( self.dc, desired_info, enum_proc, 0, 0 )
        font_families
      end

      def set_font font_face, font_size

        logical_font=GDI::LOGFONTW.new
        logical_font[:lfHeight]         = font_size
        logical_font[:lfFaceName].to_ptr.put_string(0,font_face)
        logical_font[:lfWidth]          = 0
        logical_font[:lfEscapement]     = 0
        logical_font[:lfOrientation]    = 0
        logical_font[:lfWeight]         = GDI::FW_NORMAL
        logical_font[:lfItalic]         = 0
        logical_font[:lfUnderline]      = 0
        logical_font[:lfStrikeOut]      = 0
        logical_font[:lfCharSet]        = GDI::DEFAULT_CHARSET
        logical_font[:lfOutPrecision]   = GDI::OUT_DEFAULT_PRECIS
        logical_font[:lfClipPrecision]  = GDI::CLIP_DEFAULT_PRECIS
        logical_font[:lfPitchAndFamily] = GDI::DEFAULT_PITCH|GDI::FF_DONTCARE

        @current_font=GDI.CreateFontIndirect logical_font
        raise_win32_error if @current_font.zero?
        @old_font=GDI.SelectObject self.dc, @current_font
        raise_win32_error if @old_font.zero?
        debug_info(
          "Set #{logical_font[:lfFaceName].to_ptr.read_string} size " <<
          "#{font_size} handle:#{@current_font} replacing:#{@old_font}"
        )
        true
      end

      def restore_font
        return unless @old_font
        # SelectObject returns the new font (being swapped out), which we delete
        raise_win32_error unless GDI.DeleteObject(GDI.SelectObject(self.dc, @old_font))
        raise_win32_error if GDI.RemoveFontResourceEx(@last_font, 0, 0).zero?
        debug_info "Removed #{@last_font}, restored handle #{@old_font}"
        true
      end

    end
  end
end
