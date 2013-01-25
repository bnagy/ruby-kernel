#! /usr/bin/env ruby

# This class fixes up basic checksums in TTF / OTF fonts - no sense having
# fuzz tests dropped because of an easily fixed checksum error.
#
# Author: Ben Nagy
# Copyright: Copyright (c) Ben Nagy, 2006-2013.
# License: The MIT License
# (See http://www.opensource.org/licenses/mit-license.php for details.)

require_relative '../../fuzz/lib/binstruct'

# These aren't used any more, because Binstruct is slow, but they're left here
# as structure reference
class TTFTable < Binstruct
  parse {|buf|
    endian :big
    string buf, :tag, 32, "Table tag"
    hexstring buf, :checksum, 32, "Checksum"
    unsigned buf, :offset, 32, "Offset"
    unsigned buf, :len, 32, "Length"
  }
end

class TTFHeader < Binstruct
  parse {|buf|
    endian :big
    unsigned buf, :scaler_type, 32, "Scaler type"
    unsigned buf, :num_tables, 16, "Number of tables"
    unsigned buf, :search_range, 16, "Search range"
    unsigned buf, :entry_selector, 16, "Entry selector"
    unsigned buf, :range_shift, 16, "Range shift"
  }
end

class TTFFixer

  def debug_info( str )
    warn "[#{self.class} DEBUG] #{str}" if @debug
  end

  attr_reader :repaired

  def initialize data, opts={}
    @debug=opts[:debug]
    @data=data
    @table_dir={}
    @repaired=data.clone
  end

  def fix_table_sums

    if @data[0..3]=="\x00\x01\x00\x00"
      debug_info "Valid windows TTF / OTF. Yay"
    else
      debug_info "Invalid TTF"
      return
    end
    header=@data.slice!(0,12)
    num_tables=header[4..5].unpack('n').first
    num_tables.times do |i|
      begin
        tag=@data.slice!(0,4)
        next unless tag=~/\w+/
        checksum,offset,len=@data.slice!(0,12).unpack('NNN')
        @table_dir[tag]={tag: tag, checksum: checksum, offset: offset, len: len}
        # add 3 to the length to ensure dword alignment
        table_contents=@repaired.slice( offset, len+3 )
        check=(table_contents.unpack('N*').inject(:+) % 2**32)
        if check==checksum || tag=='head'
          debug_info "#{tag} - checksum OK (#{check.to_s(16)})"
        else
          debug_info(
            "#{tag} - checksum error (#{checksum.to_s(16)}) " <<
            "should be #{check.to_s(16)}. Fixing..."
          )
          file_offset=12+((i-1) * 16)
          @repaired[ file_offset+4..file_offset+7 ] = [check].pack('N')
        end
      rescue
        debug_info "Error processing #{tag} - #{$!}"
        break
      end
    end
  end

  def fix_global_checksum
    head=@table_dir['head']
    unless head
      debug_info "No head table, can't examine checksum adjustment"
    else
      # Store the checksum adjust that's there now
      current_check_adjust=@repaired[ head[:offset]+8 .. head[:offset]+11 ].unpack('N').first
      # Set it to 0
      @repaired[ head[:offset]+8 .. head[:offset]+11 ]=[0].pack('N')
      # Calculate the sum
      sum=@repaired.unpack('N*').inject(:+) % 2**32
      # calculate the adjustment required to make the sum 0xb1b0afba (magic).
      # ( the pack+unpack converts to unsigned )
      check_adjust=[(0xb1b0afba - sum)].pack('N').unpack('N').first
      if current_check_adjust==check_adjust
        debug_info(
          "Check adjust: #{check_adjust.to_s(16)} matches " <<
          "stored #{current_check_adjust.to_s(16)}"
        )
      else
        debug_info(
          "Check adjust error - stored #{current_check_adjust.to_s(16)} " <<
          "should be #{check_adjust.to_s(16)}. Fixing..."
        )
      end
      @repaired[ head[:offset]+8 .. head[:offset]+11 ]=[check_adjust].pack('N')
    end
  end
end
