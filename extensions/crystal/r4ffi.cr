
lib LibRffi("Rffi")

	fun init = rffi_init(arg : UInt8*) : Int32
	fun eval = rffi_eval(cmds : UInt8*, print : Int32)
	fun get_ary = rffi_get_ary(cmd : UInt8*, type : Int32*, len : Int32*) : Void*
	fun set_ary = rffi_set_ary(name : UInt8*, arr : Void*, type : Int32, len : Int32)
end

module R
	extend self
	def init
		LibRffi.init("")	
	end

	def eval(cmd : String)
		LibRffi.eval(cmd, 1)
	end

	def get_ary(cmd : String)

		t,l=Pointer(Int32).malloc(1),Pointer(Int32).malloc(1)
		res=LibRffi.get_ary(cmd,t, l)
		#p [t.value,l.value]
		#p [res[0],res[1],res[11]]
		Array.new(l.value) {|i|
			case t.value
			when 0 then (res as Float64*)[i]
			when 1 then (res as Int32*)[i] 
			when 2 then (res as Int32*)[i]==1
			end
		}
	end

	def set_ary(name : String, arr)

		type=1
		type=0 if arr.map{|e| e.is_a? Float64}.all?
		type=2 if arr.map{|e| e.is_a? Bool}.all?
		
		len = arr.length
		#p arr.map{|e| e.class};p [type,len]

		if(type==2) 
			LibRffi.set_ary(".rubyExport",(arr.map{|e| e ? 1 :0}).buffer as Void*,type,len)
		else 
			LibRffi.set_ary(".rubyExport",arr.buffer as Void*,type,len)
		end
		LibRffi.eval(name+" <- .rubyExport",0)
	end

end

R.init

R.eval("a=rnorm(10)")

p R.get_ary("a")

R.set_ary("b",[1.1,3.2,2.0])

R.eval("b")

R.set_ary("b",[true,false,true])

R.eval("b")

#p Crystal::Program.new.run("a = 1; a = 1.5_f32; (a + a).to_f")
