#require '/Library/Ruby/Gems/MacRuby/0.12/gems/ffi-1.2.0/lib/ffi'
require 'ffi'

ENV["R_HOME"]=`R RHOME`.strip.split("\n").select{|l| l=~/^\//}[0] unless `R RHOME`.empty?

module Rffi
	extend FFI::Library
	ffi_lib ENV["R4FFI_LIB"] || "/Users/remy/devel/R4ffi/build/lib/libRffi.dylib"
	attach_function :rffi_init, [:pointer], :int
	attach_function :rffi_eval, [:pointer,:int], :void
	attach_function :rffi_get_ary, [:pointer,:pointer,:pointer], :pointer
	attach_function :rffi_set_ary, [:string,:pointer,:int,:int], :void

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

	def Rffi.get_ary(cmd)
		cmdN=FFI::MemoryPointer.from_string(cmd)
		type=FFI::MemoryPointer.new(:int)
		len=FFI::MemoryPointer.new(:int)
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
		when 3
			res.get_array_of_string(0,len).compact
		end
	end

	def Rffi.set_ary(expr,arr)
		type,tArr=1,:int
		type,tArr=0,:double if arr.map{|e| e.is_a? Float}.any?
		type,tArr=2,:int if arr.map{|e| [TrueClass,FalseClass].include? e.class}.all?
		type,tArr=3,:pointer if arr.map{|e| e.is_a? String}.all?

		len = arr.length

		pArr = FFI::MemoryPointer.new(tArr, len)
		case type
		when 0
			pArr.put_array_of_double(0, arr)
		when 1
			pArr.put_array_of_int32(0, arr)
		when 2
			arr2=arr.map{|e| e ? 1 : 0}
			pArr.put_array_of_int32(0, arr2)
		when 3
			arr2=arr.map{|e| FFI::MemoryPointer.from_string(e)}
			pArr.put_array_of_pointer(0,arr2)
		end
		Rffi::rffi_set_ary(".rubyExport",pArr,type,len)
		Rffi.exec(expr+"<-.rubyExport")
	end



end