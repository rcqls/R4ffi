include("R.jl")

R.start()

R.eval("a=rnorm(10)",1)

println(R.get_ary("a"))

println(R.get_ary("as.integer(a)"))

println(R.get_ary("as.logical(as.integer(a))"))

println(R.get_ary("c('titi','toto')"))

R.set_ary("a",[1.1,3.2,2.3])

R.eval("a",1)

R.set_ary("a",[1,3,2])

R.eval("a",1)

R.set_ary("a",[true,false,true])

R.eval("a",1)

R.set_ary("a",["toto","titi","tata"])

R.eval("a",1)
