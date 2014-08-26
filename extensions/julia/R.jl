

module R

	libR=dlopen("libRffi") 

	export start,stop,eval,alive

	global r_alive=false

	function start()
		code="--save"
		ccall(dlsym(libR,:rffi_init),Uint32,(Ptr{Uint8},),bytestring(code))
		r_alive=true
	end

	function stop()
		#ccall(dlsym(librb,:ruby_finalize),Void,())
		r_alive=false
	end

	function eval(code::String,print::Int64)
		#println(code)
		ccall(dlsym(libR,:rffi_eval),Void,(Ptr{Uint8},Uint32),bytestring(code),print)
	 	return nothing
	end

	function get_ary(code::String)
		l,t=Cint[0],Cint[0]
		res=ccall(dlsym(libR,:rffi_get_ary),Ptr{Any},(Ptr{Uint8},Ptr{Int32},Ptr{Int32}),bytestring(code),t,l)
		l,t=l[1],t[1]
		println((t,l))
		if t==0 
			return pointer_to_array(convert(Ptr{Float64},res),l)
		elseif t==1
			return pointer_to_array(convert(Ptr{Int32},res),l)
		elseif t==2
			return map(pointer_to_array(convert(Ptr{Int32},res),l)) do x
				x == 1 ? true : false
			end
		elseif t==3
			return map(bytestring,pointer_to_array(convert(Ptr{Ptr{Uint8}},res),l))
		end
	end

	function set_ary(name::String,ary)
		
		l=int32(length(ary))

		if  isa(ary[1],Int)
			t,ary=int32(1),convert(Array{Int32},ary)

		elseif isa(ary[1],Float64)
			t=int32(0)
		elseif isa(ary[1],Bool)
			t,ary=int32(2),map(ary) do x; x ? int32(1) : int32(0);end
		elseif isa(ary[1],String)
			t,ary=int32(3),map(ary) do x; convert(Ptr{Uint8},x);end
		end

		ccall(dlsym(libR,:rffi_set_ary),Void,(Ptr{Uint8},Ptr{Void},Int32,Int32),bytestring(name),ary,t,l)
		
	end



	function alive(b::Bool)
		global r_alive=b
	end

	function alive()
		r_alive
	end

end
