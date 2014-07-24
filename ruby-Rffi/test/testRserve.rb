require File.join(File.dirname(__FILE__),'../lib/R4rb')

## The R server needs to be initialized first outside this test!
Rserve.client(:toto)

Rserve < "aaa<-1"

Rserve < "aaa"

"aaa".Rserve

Rserve.client(:titi)

Rserve < "b<-10"

"ls()".Rserve(:toto)

"ls()".Rserve(:titi)

p "ls()".R2rb

Rserve.output <<-CodeR
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

rvect=Rserve::RVector.new "a"
p rvect
"a".Rserve
## the 3 are aliases!
p rvect.get 
p rvect.value
p rvect.to_a
## extract the first element
p rvect[0]
## connection between a ruby Array and an R vector! In fact the ruby Array is a cache!
## No more creation of ruby Array is necessary! 
a=[]
rvect > a
puts "content of a (after 'rvect > a')";p a;p a.object_id
rvect << "e[[1]]" > a
puts "content of a (after 'rvect << \"e[[1]]\" > a')";p a;p a.object_id

rvect << "a"
rvect < [true,false,true]

p ".rubyExport".R2rb

Rserve.output <<-CodeR
print(a)
print(length(a))
CodeR

rvect.value =  rvect.value + [true,false,true]
p ".rubyExport".to_R

Rserve.output <<-CodeR
print(a)
print(length(a))
CodeR

p "ls(all=T)".Rserve

rvect.arg="[2]"
print rvect.get_with_arg,"\n"

rvect << :e
rvect.arg="$a"
p rvect.get_with_arg
rvect.arg="$a[2]"
p rvect.get_with_arg


rvect.value_with_arg="toto"
"print(.rubyExport)".R2rb
rvect.arg="$a"
Rserve.output <<-CodeR
print(e)
print(e$a)
CodeR
p rvect.value_with_arg
