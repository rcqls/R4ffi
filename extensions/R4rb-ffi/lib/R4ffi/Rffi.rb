#require '/Library/Ruby/Gems/MacRuby/0.12/gems/ffi-1.2.0/lib/ffi'
require 'ffi'

ENV["R_HOME"]=`R RHOME`.strip.split("\n").select{|l| l=~/^\//}[0] unless `R RHOME`.empty?

module Rffi
	extend FFI::Library
	ffi_lib ENV["R4FFI_LIB"] || "/Users/remy/devel/ruby/R4rb-ffi/Rffi/build/lib/libRffi"]
	attach_function :rffi_init, [:pointer], :int
	attach_function :rffi_eval, [:pointer,:int], :void
	attach_function :rffi_get_ary, [:pointer,:pointer,:pointer], :pointer

	CMD = FFI::MemoryPointer.from_string("--save")
	def Rffi.init
		Rffi::rffi_init(CMD)
	end

	def Rffi.eval(cmd)
		cmdN=FFI::MemoryPointer.from_string(cmd)
		Rffi::rffi_eval(cmdN,1)
	end

	def Rffi.exec(cmd)
		cmdN=FFI::MemoryPointer.from_string(cmd)
		Rffi::rffi_eval(cmdN,0)
	end

	def Rffi.eval_get_ary(cmd)
		cmdN=FFI::MemoryPointer.from_string(cmd)
		type = FFI::MemoryPointer.new(:int)
		len = FFI::MemoryPointer.new(:int)
		res=Rffi::rffi_get_ary(cmdN,type,len)
		type=type.null? ? nil : type.read_int
		len=len.null? ? nil : len.read_int
		case type
		when 0
			res.read_array_of_double(len)
		when 1
			res.read_array_of_int(len)
		when 2
			res.read_array_of_int(len).map{|e| e==0 ? false : true}
		end
	end

end