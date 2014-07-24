### IMPORTANT, no use of R4rb tools! R2rb or Rserve mode only!

module Rserve

	## server side
	def Rserve.pid
		`ps -C Rserve -o pid=`.strip
	end

	def Rserve.running?
  		!Rserve.pid.empty?
  	end

  	def Rserve.start(rserve=File.expand_path("~/bin/Rserve"))
  		`R CMD #{rserve}` unless Rserve.running?
  	end


	def Rserve.stop
		pid=Rserve.pid
  		`kill #{pid}` unless pid.empty?
  		sleep(2)
  		if Rserve.running?
  			puts "Sorry! but the Rserver is still running!"
  		end
  	end

  	## client side
  	@@clients,@@cli=nil,nil

	def Rserve.init
		#puts "Rserve.init"
		Array.initR
		#puts "Rserve.init2"
		"require(Rserve)".R2rb
		#puts "Rserve.init3"
		@@clients,@@cli=[],nil
		@@out=[]
		@@out.rb2R=R2rb
		#puts "Rserve.init4"
	end

	#####################################################
	# the two following methods to be possibly redefined
	# in particular inside Dyndoc to automatically 
	# allocate the R session related to the user!
	def Rserve.cli
		@@cli
	end
	#
	def Rserve.cli=(cli)
		@@cli=cli
	end
	#####################################################


	def Rserve.client(cli=nil)
		## automate the init process!
		#Rserve.init unless @@clients

		##return current client!
		unless cli 	
			return Rserve.cli
		## create a new client
		else 		
			Rserve.open(cli)
		end
	end

	## change the current client!
	def Rserve.client=(cli=nil)
		return nil unless @@clients.include? cli
		Rserve.cli=cli
	end

	def Rserve.open(cli)
		"#{cli.to_s} <- RSconnect()".R2rb
		@@clients << cli
		Rserve.cli=cli
	end

	def Rserve.close(cli=nil) 
		cli=Rserve.cli unless cli
		return unless @@clients.include? cli
		"RSclose(#{cli.to_s})".R2rb
		@@clients.delete(cli)
	end

	def Rserve.ls
		@@clients
	end

	#####################################################
	## interface
	def Rserve.complete_code!(code)
		code.gsub!("\\","\\\\")
		code.gsub!("\"","\\\"")
		code.replace("RSeval(#{cli},\"capture.output({"+code+"})\")")
	end


	def Rserve.completed_code(code,capture=true)
		open,close= (capture ? ["capture.output({","})"] : ["",""])
		"RSeval(#{cli},\""+open+code.gsub("\\","\\\\").gsub("\"","\\\"")+close+"\")"
	end

	def Rserve.eval(code,cli=nil)
		cli=Rserve.cli unless cli
		return nil unless cli
		## check parsing locally (without RSeval)
		status=R2rb.parse code
		if status!=1
			R2rb.parse code,true
			return false
		end
		## RSeval completed in code!
		Rserve.complete_code!(code)
		#puts "Rserve.eval:";p code
		R2rb.eval code
		#@@out < code ##@@out.inR2rb code # since @@out < code but for R2rb
	end

	def Rserve.try_eval(code,cli=nil)
		cli=Rserve.cli unless cli
    	try_code=".result_try_code<-try({\n"+code+"\n},silent=TRUE)\n"
    	puts Rserve.output(try_code,cli).join("\n")
    	puts R2rb.output(Rserve.completed_code(".result_try_code",false)) if "inherits(.result_try_code,'try-error')".to_R
  	end

	def Rserve.<<(code)
		Rserve.eval(code)
	end

	def Rserve.output(code,cli=nil)
		#puts "Rserve.output:";p code
		cli=Rserve.cli unless cli
		return nil unless cli
		## RSeval completed in code!
		Rserve.complete_code!(code)
		@@out < code ##@@out.inR2rb rcode.to_s
    	return (@@out.length<=1 ? @@out[0] : @@out)
	end

	def Rserve.<(code)
		Rserve.output(code)
	end

	def Rserve.assign(code,var=nil,cli=nil)
		code+=",quote(#{var})" if var
		cli=Rserve.cli unless cli
		code="RSassign(#{cli},#{code})"
		#p code
		R2rb << code
	end

	class RVector < R2rb::RVector

		def RVector.assign(var,ary,cli=nil)
			super(var,ary)
			Rserve.assign(var,var,cli)
		end

		attr_accessor :cli

		## The goal is to connect a ruby Array to a Rserve Vector  
		def initialize(name,cli=nil)
			@cli=(cli ? cli : Rserve.cli)
			puts "WARNING: Rserve::RVector.initialize: @cli is null!" unless @cli
			@name_orig=name
			super(name!)
			@type="expr"
		end

		def name! #name from cli and name_orig
			##puts "name!";p @name_orig
			##deb,fin="quote(",")" #(@name_orig=~/^evalq\(/ ? ["quote(",")"] : ["\"","\""])
			"RSeval(#{@cli},quote(#{@name_orig}))"
		end

		def <<(name)
			## no "var" in this context! transform it in String if necessary
	        @name_orig=name.to_s
	        super(name!)
	      	return self
	    end

	    ## no need to make aby change for ">"

		def <(ary)
			ary.R2rb(".rubyExport") #transition
			Rserve.assign(".rubyExport",@name_orig,@cli)
		end

		alias value= <

		def set_with_arg(ary)
			ary=[ary] unless ary.is_a? Array
			ary.R2rb(".rubyExport") #transition
			#p @name_orig+@arg
			Rserve.assign(".rubyExport",@name_orig+@arg,@cli)
		end

		alias value_with_arg= set_with_arg

	end
end
