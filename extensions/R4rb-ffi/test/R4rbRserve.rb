module Test
	def test
		"test1: #{self}"
	end
end

module Test2
	def test
		"test2: #{self}"
	end
end

#Test2=Test unless Module.constants.include? "Test2" 

#def update_class(test)

class String

	include Test

	def String.modeR=(rmode)
		load_module(Test) if rmode==1
		load_module(Test2) if rmode==2
	end

	def to_R
		self.test
	end

end