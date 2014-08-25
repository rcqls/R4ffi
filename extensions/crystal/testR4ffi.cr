require "./r4ffi"

if true
R.init

R.eval("a=rnorm(10)")

p R.get_ary("a")

R.eval("b=paste(c('toto','tutué'),1:2)")

p R.get_ary("b")

R.set_ary("b",[1,3,2])

R.eval("b")

R.set_ary("b",[1.1,3.2,2.0])

R.eval("b")

R.set_ary("b",[true,false,true])

R.eval("b")

R.set_ary("b",a=["tutu","toto"])

R.eval("b")


end

#p Crystal::Program.new.run("a = 1; a = 1.5_f32; (a + a).to_f")
