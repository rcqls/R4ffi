require "R4rb"

R4rb.init

if ARGV.length==1
	R4rb_is Rserve
	Rserve.init
	Rserve.client(:toto) 
end

if ARGV.length==2
	R4rb_is R2rb 
end

R4rb.try_eval <<-CodeR
print(rnorm(10))
toto
CodeR

=begin
if R4rb==Rserve
	## copy of code for obtaining the same resut as before
 	puts (R2rb.output "RSeval(toto,\"capture.output({.result_try_code<- try({print(rnorm(10))\ntoto},silent=TRUE)})\")").join("\n")
 	puts R2rb.output("RSeval(toto,\".result_try_code\")")

	#Does not work! No print captured!
	#puts (R2rb.output "RSeval(toto,\".result_try_code<- try({capture.output({print(rnorm(10))\ntoto})},silent=TRUE)\")")
	#p R2rb.output("RSeval(toto,\".result_try_code\")")
end
=end

puts "ici"