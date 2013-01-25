# Wrapper to make Windows system calls from Ruby.
#
# Author: Ben Nagy
# Copyright: Copyright (c) Ben Nagy, 2006-2013.
# License: The MIT License
# (See http://www.opensource.org/licenses/mit-license.php for details.)

require 'ffi'
require_relative 'wintypes'
require_relative 'winerror'
require_relative '../metasm/metasm'

module Syscall

  extend FFI::Library
  include WinTypes

  ffi_lib 'kernel32'
  ffi_convention :stdcall

  def self.add_func *args
    attach_function( *args )
    case args.size
    when 3
      module_function args[0]
    when 4
      module_function args[0]
      alias_method args[1], args[0]
      module_function args[1]
    end
  end

  CREATE_SUSPENDED       = 0x04
  PAGE_EXECUTE_READWRITE = 0x40

  add_func :CreateThread, [
    LPSTRUCT, # Security Attributes struct, NULL for default
    SIZE_T,   # Stack size - 0 for default
    LPVOID,   # Start address
    LPVOID,   # Parameter
    DWORD,    # Create Flags
    LPDWORD   # Receives TID
  ], HANDLE   # hThread returned
  add_func :ResumeThread, [ HANDLE ], LONG
  add_func :VirtualProtect, [ LPVOID, SIZE_T, DWORD, LPDWORD ], BOOL
  add_func :CloseHandle,  [ HANDLE ], BOOL

  def self.call32 syscall, *args

    # Useful: http://j00ru.vexillium.org/ntapi/
    # And:    http://j00ru.vexillium.org/win32k_syscalls/

    # This will only work on XP and later, prior to that there's an int 2e
    # technique that I can't be bothered implementing, but the same approach
    # should work fine.
    unless args.all? {|arg| arg.kind_of? Numeric}
      raise ArgumentError, "Args must all be numbers"
    end
    # This technique ripped off from jduck's MS010-073 keyboard layout sploit
    # https://metasploit.com/svn/framework3/trunk/modules/post/windows/escalate/ms10_073_kbdlayout.rb
    asm=[
      "pop esi",                              # magic
      args.reverse.map {|arg| "push #{arg}"}, # push args in reverse order
      "push esi",                             # magic
      "mov eax, #{syscall}",                  # load eax with syscall id
      "mov edx, 0x7ffe0300",                  # hardcoded - pointer to syscall site
      "call [edx]",                           # syscall happens here
      "ret #{args.size * 4}"                  # clean up stack
    ].join("\n")
    opcodes = Metasm::Shellcode.assemble( Metasm::Ia32.new, asm ).encode_string
    p_opcodes = FFI::MemoryPointer.from_string opcodes
    begin
      hThread = Syscall.CreateThread( nil, 0, p_opcodes, nil, CREATE_SUSPENDED, nil )
      self.raise_win32_error if hThread.zero?
      retval = Syscall.ResumeThread hThread
      self.raise_win32_error if retval == -1
    ensure
      Syscall.CloseHandle hThread
    end
    true
  end

  def self.call64 syscall, *args

    # Useful: http://j00ru.vexillium.org/ntapi_64/
    # And:    http://j00ru.vexillium.org/win32k_x64/

    unless args.all? {|arg| arg.kind_of? Numeric}
      raise ArgumentError, "Args must all be numbers"
    end
    # first 4 args are passed in registers. This does not support floats, which
    # are passed in XMM0..3 - cry me a river.
    register_args=args.shift( 4 ).zip %w( rcx rdx r8 r9 )
    register_args.map! {|arg,reg|
      "mov #{reg}, #{arg}"
    }
    # the rest are passed on the stack
    stack_args=args.reverse.map {|arg| "push #{arg}"}
    stub_x64=[
      "mov r10, rcx",                     # don't know why, but this is how all the stubs are
      "mov eax, #{syscall}",              # syscall in eax
      "syscall",                          # make the call
      "add rsp, #{stack_args.size * 8}",  # clean up the stack
      "ret"
    ]
    asm = (register_args + stack_args + stub_x64).join "\n"
    opcodes = Metasm::Shellcode.assemble( Metasm::X86_64.new, asm ).encode_string
    p_opcodes = FFI::MemoryPointer.from_string opcodes
    # Windows 7 x64 has NX heap. We need RWX not RX because otherwise it crashes
    # when something tries to zero the shellcode memory when the thread ends.
    Syscall.VirtualProtect(
      p_opcodes,
      p_opcodes.size,
      PAGE_EXECUTE_READWRITE,
      FFI::MemoryPointer.new( DWORD ) # receives previous protection value
    )
    # Don't need to create suspended, it's just nice for debugging purposes.
    begin
      hThread = Syscall.CreateThread( nil, 0, p_opcodes, nil, CREATE_SUSPENDED, nil )
      self.raise_win32_error if hThread.zero?
      retval = Syscall.ResumeThread hThread
      self.raise_win32_error if retval == -1
    ensure
      Syscall.CloseHandle hThread
    end
    true
  end

  private

  def self.raise_win32_error
    error=WinError.get_last_error
    debug_info "#{error} from #{caller[1]}"
    raise "[Win32 Exception]  #{WinError.get_last_error}"
  end

  def self.debug_info str
    warn "[#{self.class} DEBUG] #{str}" if @opts[:debug]
  end

end
