require File.join(File.dirname(__FILE__),'../lib/R4rb')

Array.initR


## Assignment from ruby to R
R4rb::RVector.assign("a",[1,2,3])

"print(a)".to_R

[1,4,3].to_R(:b) #R4rb::RVector.assign("b",[1,4,3])

"print(b)".R4rb #instead of to_R

## Assignment from R to ruby
a="3:1".evalR #instead of to_R

p a
