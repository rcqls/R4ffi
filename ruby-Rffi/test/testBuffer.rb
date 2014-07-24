require "R4rb"

rbuf=R4rb::RBuffer.new
rbuf.init
rbuf+<<RCode
print("toto")
RCode
print "suite\n"
rbuf+<<RCode
print("titi")
RCode
rbuf.exec
