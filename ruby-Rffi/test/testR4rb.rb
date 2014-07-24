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

##

R4rb_status?

p R2rb.parse  "rnorm(toto"

p R2rb.parse 'RSeval(toto,evalq({{
#Sys.sleep(10)
aaa2 <- "toto"
}},.GlobalEnv$.env4dyn$linuxR))'



$out=[]
p $out.object_id

p R4rb << "rnorm(10)"

p R4rb <<  ".output<<-capture.output({capabilities()\n\n})"

p ($out < '.output' )

#p ".output".to_R