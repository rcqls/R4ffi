

lib LibRffi("Rffi")
	fun init = rffi_init(arg : UInt8*) : Int32
	fun eval = rffi_eval(cmds : UInt8*, print : Int32)
	fun get_ary = rffi_get_ary(cmd : UInt8*, type : Int32*, len : Int32*) : Void*
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

end

R.init

R.eval("a=rnorm(10)")

p R.get_ary("a")

#p Crystal::Program.new.run("a = 1; a = 1.5_f32; (a + a).to_f")
