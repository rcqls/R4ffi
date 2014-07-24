class Object

  def R4rb_is(mode)
    unless [R2rb,Rserve,"R2rb","Rserve",:R2rb,:Rserve].include? mode
      puts "Improper value for R4rb_is function!"
      return 
    end
    unless mode.is_a? Module
      mode=mode.to_s.to_sym
      ##puts "R4rb_is: mode=#{mode}"
      mode= case mode
          when :R2rb
            R2rb
          when :Rserve
            Rserve
          end
    end
    if mode==Rserve and !Rserve.running?
      puts "Rserve is not running and R4rb_is method cannot be set to :Rserve!"
      mode=R2rb
    end
    ##p mode
    ## trick to avoid warning when modifying constant!
    con=Object #( self.is_a?(Module) ? self : self.class )
    con.send(:remove_const, :R4rb) if con.const_defined?(:R4rb)
    con.const_set(:R4rb, mode)
  end

  def R2rb_running?
    Object.const_get(:R4rb)==R2rb
  end

  def Rserve_running?
    Object.const_get(:R4rb)==Rserve
  end

  def R4rb_status?
    puts "R is now in "+ ( R2rb_running? ? "local" : "server" )+" use!"
  end

end



## first init
unless Object.const_defined?(:R4rb)
  ##puts "First, R4rb initialized to R2rb!"
  R4rb_is R2rb 
end

=begin
module R4rb

  def R4rb.mode=(mode) #mode=:R4rb or :Rserve
    return unless [:R2rb,:Rserve].include? mode
    puts mode
    puts Rserve
    $R4rb=(mode==:R2rb ? R2rb : Rserve)
    puts "R4rb mode changed: #{$R2rb.inspect}"
  end

  def R4rb.init(args=["--save","--slave","--quiet"])
    R2rb.init(args)
  end

  def R4rb.<<(code)
    $R4rb << code
  end

  def R4rb.<(code)
    $R4rb < code
  end

  def R4rb.output(code)
    $R4rb.output(code)
  end


  class << self
    alias eval <<
  end

  RVector=$R4rb::RVector
  
end
=end

## reload 
class String

  def R2rb
    R2rb < self
  end

  def Rserve(cli=nil)
    Rserve < self
  end

  def R4rb
    R4rb < self
  end

  alias to_R R4rb
  alias evalR R4rb
  alias Reval R4rb
  alias R R4rb

end

class Array

  def R2rb(var)
    R2rb::RVector.assign(var.to_s,self)
  end

  def RServe(var,cli=nil)
    Rserve::RVector.assign(var.to_s,self,cli)
  end

  def R4rb(var)
    R4rb::RVector.assign(var.to_s,self)
  end

  alias to_R R4rb
  alias evalR R4rb
  alias Reval R4rb
  alias R R4rb


  #@@rb2R=nil

  ## connect Array class to some RVector!!!
  def Array.initR(init=true)
    R2rb.init if init
    #p @@rb2R
  end

  def rb2R=(mode=nil)
    ##puts "rb2R mode #{object_id}";p mode
    mode=R4rb unless mode
    return if @rb2R_mode and @rb2R_mode==mode
    @rb2R_mode=mode unless @rb2R_mode
    @rb2R=(@rb2R_mode==Rserve ? Rserve::RVector.new("") :  R2rb::RVector.new("") )
    ##puts "rb2R=";p @rb2R
  end

  def >(outR) #outR represents here an R object
    self.rb2R=nil unless @rb2R
    @rb2R << outR
    @rb2R < self
    return self
  end

  def <(outR) #outR represents here an R expression to execute and put inside the Array
    #p @rb2R
    self.rb2R=nil unless @rb2R
    @rb2R << outR
    @rb2R > self
    return self
  end

=begin
  def outR2rb(outR)
    rvect=rb2R(R2rb)
    rvect << outR
    rvect < self
    return self
  end

  def inR2rb(outR)
    rvect=rb2R(R2rb)
    rvect << outR
    rvect > self
    return self
  end
=end

end
