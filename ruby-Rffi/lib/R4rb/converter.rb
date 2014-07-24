class String

  def to_aRy(sep=",")
    self.split(sep).map{|str|
      R2rb.multilang_parser(str)
    }.flatten
  end

end

module R2rb

  @@pair=["<<",">>"]

  def R2rb.pair
    @@pair
  end

  def R2rb.pair=(pair)
    if pair.is_a? String
      pairs={"{"=>"}","("=>")","<"=>">","["=>"]"}
      pair2=pair.reverse.gsub(/[#{Regexp.escape(pairs.keys.join)}]/) {|e| Regexp.escape(pairs[e])}
      pair=[pair,pair2]
    end
#p "ICI";p pair
    if (pair.is_a? Array) and pair.length==2
      @@pair=pair
    end
#p @@pair
  end

  def R2rb.multilang_parser(str)
#p @@pair
    lang="r|R|rb|Rb"
    s=str
    if @@pair[0].empty?
      mask = /((?:#{lang}).*)/
    else
      mask = /#{Regexp.escape(@@pair[0])}((?:#{lang})[^#{Regexp.escape(@@pair[0])}]*)#{Regexp.escape(@@pair[1])}/
    end
    str=str.split(mask,-1)
    return s if str.length<=1
    vals=[]
    res=[]
    inds=0..(str.length / 2 - 1)
    ".tmp<-NULL".to_R 
    inds.each {|i|
      res << str[2*i]
      if str[2*i+1] =~ /^(?:r|R):(.*)/
        (".tmp<-cbind(.tmp,"+$1+")").to_R
      end
      if str[2*i+1] =~ /^(?:rb|Rb):(.*)/
        a=eval($1)
        a=[a] unless a.is_a? Array
        a > :tmp
        (".tmp<-cbind(.tmp,tmp)").to_R
     end
    }
    res << str[-1]
#p res
    cmd="apply(.tmp,1,function(e) paste("
    inds.each{|i| cmd += "'"+res[i]+"',e["+i.to_s+"+1]," }
    cmd += "'"+res[-1]+"',sep=''))"
#"print(.tmp)".to_R
#p cmd
    cmd.to_R
  end
end
