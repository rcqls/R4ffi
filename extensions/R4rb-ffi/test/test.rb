require "R4rb"

R4rb.init

### without argument the default mode is R2rb
### with 1 arguments, it is updated to Rserve 
### with 2 arguments, it is then updated to R2rb 

if ARGV.length==1
	R4rb_is Rserve
	Rserve.init
	Rserve.client(:toto) 
end

if ARGV.length==2
	R4rb_is R2rb 
end

R4rb.eval <<-CodeR
require(ctest)
a<-c(1.1+2i,2)
print('titi')
print('tata')
b<-rnorm(10)
a=as.integer(c(1,2,1,4))
print(mode(a))
e<-list(a=c(1,3,2))
# bug!!!
for(i in 1:10) {
print(i)
  }
CodeR

rvect=R4rb::RVector.new "a"
p rvect
## the 3 are aliases!
p rvect.get 
p rvect.value
p rvect.value.to_a
## extract the first element
p rvect[0]
## connection between a ruby Array and an R vector! In fact the ruby Array is a cache!
## No more creation of ruby Array is necessary! 
a=[]
rvect > a
puts "content of a (after 'rvect > a')";p a;p a.object_id
#print (rvect << "a").class,"\n"
rvect << "as.integer(e[[1]])" > a
puts "content of a (after 'rvect << \"e[[1]]\" > a')";p a;p a.object_id
print rvect.name,"=",a.inspect,"\n"
print "length(",rvect.name,")=",rvect.length,"\n"
print rvect.name,"[0] is of class ",a[0].class,"\n"
rvect << :b
print rvect.name,"=",rvect.get.inspect,"\n"
print "length(",rvect.name,")=",rvect.length,"\n"
rvect << :a #> a
print rvect.name,"=",rvect.to_a.inspect,"\n"
print "length(",rvect.name,")=",rvect.length,"\n"
print rvect.name,"[2]=",rvect[2],"\n"
#rvect.set [true,false,false]
rvect << "x<-seq(-3,3,l=10)" > a
p a
rvect << "dnorm(x)" > a
p a
rvect << "e$a"
rvect < [true,false,false]
# could be used with affectation symbol
p rvect.value
rvect.value =  rvect.value + [true,false,true]
R4rb.eval <<-CodeR
print(e$a)
print(length(e$a))
CodeR
print rvect.name,"=",rvect.to_a.inspect,"\n"
print "length(",rvect.name,")=",rvect.length,"\n"
print rvect.name,"=",rvect.to_a.inspect,"\n"
print rvect.name,"[2]=",rvect[2],"\n"

#with argument (used in dyndoc and notably in parser)
rvect.arg="[2]"
print rvect.get_with_arg,"\n"
rvect << :e
rvect.arg="$a"
p rvect.get_with_arg
rvect.arg="$a[2]"
p rvect.get_with_arg
rvect.value_with_arg="toto"
rvect.arg="$a"
p rvect.value_with_arg
