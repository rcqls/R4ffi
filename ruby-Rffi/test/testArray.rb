require 'R4rb'

Array.initR

### without argument the default mode is R2rb
### with 1 arguments, it is updated to Rserve 
### with 2 arguments, it is then updated to R2rb 

if ARGV.length==1
	R4rb_is Rserve
	Rserve.init
	Rserve.client(:toto) 
	puts "init cli";p Rserve.cli
end

if ARGV.length==2
	R4rb_is R2rb 
end

puts "calcul de runif(10)"
a=[] < 'runif(10)'
p a
