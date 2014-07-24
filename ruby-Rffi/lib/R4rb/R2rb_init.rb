##  Attention "...\n..." have to be replaced by "...\\n..."
## example : 'cat("toto\n")' fails but not 'cat("toto\\n")'
## more surprisingly, this fails even in comment '# cat("toto\n")'

module R2rb

  def R2rb.init(args=["--save","--slave","--quiet"])
    @@initR=R2rb.initR(args) unless R2rb.alive?
  end

  def R2rb.alive?
    defined? @@initR
  end

  class RBuffer
    def initialize
      @s=String.new
    end
    
    def init
      R2rb.init
    end
    
    def clear
      @s=""
    end
    
    def +(s=nil)
      if s
      	s=s.to_s unless s.is_a? String
      	@s += "\n"+s
      else
        clear
      end
      return self
    end
    
    def exec(aff=nil)
      R2rb.eval @s,aff
    end
  end

 class RConsole
   def initialize
     require "readline"
   end

   def init args
     R2rb.init args
   end

   def exec
     #todo : continuation
     toggle=true
     fin=false
     words=[]
     rvect=R2rb::RVector.new("")
     Readline.completion_proc=Proc.new {|e|
       cpt=0
       begin
      	 begin
      	   cpt += 1
      	   toggle = !toggle
      	   rvect << (toggle ? "apropos(" : "ls(pat=")+"'^"+e+"')" > words
      	   res=words.map{|w| w[Regexp.new("^"+e+".*")]}-[nil]
      	 end while res.empty? and cpt<3
      	 res
       rescue
      	 warn("\r"+e+" not suitable for completion!!!")
      	 []
       end
     }
     Readline.completion_append_character=""
     begin
       line = Readline.readline("R> ", true)
       if !(fin = line=="quit")
      	 R2rb.eval line,true
      	 toggle=true
       end
     end until fin
   end
 end
end

def find_installed_R

  if RUBY_PLATFORM=~/mingw32/
     ENV["R_HOME"]=`R RHOME`
  elsif RUBY_PLATFORM=~/darwin/
    ENV["R_HOME"]=`R RHOME`.strip
  else
    dirs=["/usr/lib/R","/usr/local/lib/R","/usr/lib64/R"]
   
    dirs.each do |dir|
      if FileTest.exists?(dir)
        return dir
      end
    end

    raise RuntimeError, "couldn't find R Home : R seems to be uninstalled!!"
  end

end

ENV["R_HOME"]=`R RHOME`.strip.split("\n").select{|l| l=~/^\//}[0] unless `R RHOME`.empty?

ENV["R_HOME"]=find_installed_R unless ENV["R_HOME"]
