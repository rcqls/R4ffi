
module RObj

  def RObj.<(rcode)
    return (R2rb < rcode) 
  end

  def RObj.class(rname)
    RObj < "class(#{rname})"
  end

  def RObj.mode(rcode)
    RObj < "mode(#{rcode})"
  end

  # temporary R object saved in ruby object!
  def RObj.make(rcode,first=true)
    mode=RObj.mode(rcode)
    RObj < ".tmpRObj<-(#{rcode})" if first
    code=(first ? ".tmpRObj" : rcode.dup) 
    if ['numeric','logical','complex','character'].include?(mode)
      #if RObj.class(code)=="matrix"
      return (RObj< rcode)
    elsif mode=="list"
      robj={}
      tmpNames=RObj < "names(#{rcode})"
      tmpNames.each_with_index do |nam,i|
         key=(nam.empty? ? i : nam)
         rkey=(nam.empty? ? i : "\""+nam+"\"")
         robj[key]=RObj.make("#{rcode}[[#{rkey}]]",false)
        end
      return robj
    else
      return nil
    end
  end

  def RObj.<<(rcode) 
    RObj.make(rcode)
  end

  def RObj.exist?(rname)
    RObj < "exists(\"#{rname}\")"
  end

end