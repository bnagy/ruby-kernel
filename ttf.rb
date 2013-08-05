#! /usr/bin/env ruby

# This class fixes up basic checksums in TTF / OTF fonts - no sense having
# fuzz tests dropped because of an easily fixed checksum error.
#
# Author: Ben Nagy
# Copyright: Copyright (c) Ben Nagy, 2006-2013.
# License: The MIT License
# (See http://www.opensource.org/licenses/mit-license.php for details.)

require 'bm3-core'
require 'bindata'
require 'stringio'

module BM3

  class TTFTableHeader < BinData::Record

    endian :big

    string :tag, read_length: 4
    uint32 :checksum
    uint32 :table_offset
    uint32 :len

  end

  class TTFHeader < BinData::Record

    endian :big

    uint32 :scaler_type
    uint16 :num_tables
    uint16 :search_range
    uint16 :entry_selector
    uint16 :range_shift

  end

  class TTF

    include BM3::Logger

    attr_reader :header, :tables, :table_data
    attr_accessor :debug

    def initialize data, opts={debug: false}
      @debug  = opts[:debug]
      input   = StringIO.new data.clone
      @raw_data = data
      headers = []
      @header = TTFHeader.read input
      if header.scaler_type == 65536 # magic
        debug_info "Valid windows TTF / OTF. Yay"
      else
        debug_info "Invalid TTF, trying anyway..."
      end
      @tables = {}
      @header.num_tables.times do
        headers << TTFTableHeader.read( input )
      end
      @table_data = input.read
      build_tables headers
    end

    def update_table tag, data, opts={fix_checksums: true}
      debug_info "updating #{tag} table..."
      target_table        = tables[tag]
      target_header       = target_table[:header]
      debug_info "New data #{data.bytesize}, existing data #{target_table[:data].bytesize}, should be #{target_header.len}"

      raise "Can't find table #{tag}" unless target_table
      adjustment          = data.bytesize - target_table[:data].bytesize
      # Make the update in our OO version of the TTF
      target_table[:data] = data
      # Apply the adjustment to all tables with a start offset after that of the
      # one we just modified ( the table data is not packed in the same order as
      # the headers)
      to_fix = tables.values.select {|table|
        ( table[:header].table_offset >= target_header.table_offset ) &&
        table != target_table
      }
      to_fix.each {|table|
        table[:header].table_offset += adjustment
      }
      # Make the adjustment in the packed table data
      table_data[target_header.table_offset, target_header.len] = data
      debug_info "Offset #{target_header.table_offset}, really #{table_data.index(data)}"
      target_header.len = data.bytesize
      fix_checksums! if opts[:fix_checksums]
    end

    def insert_table tag, data, idx = -1, opts = {fix_checksums: true}
      headers           = tables.values.map {|t| t[:header]}
      new_header        = TTFTableHeader.new
      new_header.tag    = tag[0,4]
      # Inserting anywhere past the last real index just gets appended
      headers.insert( idx, new_header ).compact!
      if headers.first == new_header
        new_header.offset = 0
      else
        previous_header   = headers[headers.index( new_header ) - 1]
        new_header.offset = previous_header.table_offset + previous_header.len
      end
      build_tables headers
      header.num_tables += 1
      # So now we have inserted a new header, but the len field is still 0 and
      # there is no data in it. So, finally, we update the data for the new table.
      update_table new_header.tag, data, fix_checksums: opts[:fix_checksums]
    end

    def fix_checksums!
      fix_table_sums
      fix_global_checksum
    end

    def to_s
      header.to_binary_s <<
        tables.map {|_,table| table[:header].to_binary_s}.join <<
        table_data
    end

    private

      def build_tables headers
        @tables.clear
        headers.each_with_index {|th, idx|
          @tables[th.tag.value] = {
            header: th,
            data: table_data[th.table_offset, th.len],
            idx: idx
          }
        }
      end

      def fix_table_sums
        raw = self.to_s
        tables.each_key {|tag|
          begin
            unless tag =~ /\w+/
              debug_info "Skipping invalid table tagged #{tag}"
              return
            end
            th = tables[tag][:header]
            # add 3 to the length to ensure dword alignment. We have to do this on
            # the "packed" table data for this reason, can't use table[:data]
            table_contents = raw[ th.table_offset, th.len+3 ]
            check = table_contents.unpack('N*').inject(:+) % 2**32
            if check == th.checksum || tag == 'head'
              # The checksum for the head table is special, and can't be fixed here
              # debug_info "#{tag} - checksum OK (#{check.to_s(16)})"
            else
              debug_info(
                "#{tag} - checksum error (#{"%x" % th.checksum}) " <<
                "should be #{check.to_s(16)}. Fixing..."
              )
              th.checksum = check
            end
          rescue
            debug_info "Error processing #{tag} - #{$!}"
            $@.first(5).each {|frame| debug_info frame}
            next
          end
        }
      end

      def fix_global_checksum
        head = tables['head'][:header]
        debug_info "No head table, can't examine checksum adjustment" unless head
        # Store the checksum adjust that's there now
        current_check_adjust = head.checksum.to_i # cast to Integer from BinData class
        # Set it to 0
        head.checksum = 0
        # Calculate the sum of the entire file
        sum = self.to_s.unpack('N*').inject(:+) % 2**32
        # calculate the adjustment required to make the sum 0xb1b0afba (magic).
        # ( the pack+unpack converts to unsigned )
        check_adjust = [(0xb1b0afba - sum)].pack('N').unpack('N').first
        if current_check_adjust == check_adjust
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
        head.checksum = check_adjust
      end

  end
end
