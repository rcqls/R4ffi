## Module R2rb

module R2rb
  def R2rb.eval(s,aff=nil)
    s=["{\n"+s+"}\n"]
    evalLines s,aff
  end

  def R2rb.parse(s,aff=nil)
    s=["{\n"+s+"}\n"]
    parseLines s,aff
  end

  def R2rb.try_eval(code)
    try_code=".result_try_code<-try({\n"+code+"\n},silent=TRUE)\n.result_try_code"
    R2rb << try_code
    puts ".result_try_code".to_R if "inherits(.result_try_code,'try-error')".to_R
  end


  def R2rb.<<(s)
    R2rb.eval(s)
  end

  class RVector

    def <<(name)
      if name.is_a? Symbol
        @name=name.to_s
        @type="var"
      else
        @name=name
        @type="expr"
      end
      return self
    end

    def arg=(arg)
      @arg=arg
    end

    #this method is the same as the previous one but return self! Let us notice that even by adding return self in the previous one
    # I could not manage to execute (rvect.arg="[2]").value_with_arg but fortunately rvect.set_arg("[2]").value_with_arg is working!
    def set_arg(arg)
      @arg=arg
      return self
    end
   
    def >(arr)
      res=self.get
#puts "res";p @name;p res
      if res
#puts "arr.class:";p arr.class
#puts "res.class";p res.class
        res=[res] unless res.is_a? Array
        arr.replace(res)
      else
        arr.clear
      end
      return self
    end

=begin #Done directly inside R4rb.c
    def value_with_arg(arg)
      old_name,old_type=@name.dup,@type.dup
      @name,@type=@name+arg,"expr"
      value
      @name,@type=old_name,old_type
    end
=end

  end

  @@out=[]
  ##@@out.rb2R=R2rb

  def R2rb.<(rcode)
    @@out.replace [] ##@@out=[] #important! it could otherwise remove
    @@out.rb2R=self
    @@out < rcode.to_s ##@@out.inR2rb rcode.to_s
    return (@@out.length<=1 ? @@out[0] : @@out) 
  end

  class << self
    alias output <
  end

  class Server
    @@in,@@out=nil,[]

    def Server.in
      return @@in
    end

    def Server.in=(block)
      @@in=block
    end

    def Server.<<(block)
      @@in << block
    end

    def Server.out
      return @@out.join("\n")
    end
    
    def Server.echo(block=nil)
      @@in=block if block
      R2rb << ".output<<-capture.output({"+@@in+"})"
      return (@@out < '.output').join("\n")
    end
  end

end
 