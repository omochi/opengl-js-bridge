def indent(str, level) 
	str.split("\n", -1).map {|x|
		"    " * level + x
	}.join("\n")
end