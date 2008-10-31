/******************************************************************************\
  Core language support
\******************************************************************************/

registerOperator("dat", "", "", function(self, args)
	return args[2]
end)

registerOperator("var", "", "", function(self, args)
	return self.vars[args[2]]
end)

/******************************************************************************/

registerOperator("seq", "", "", function(self, args)
	local n = #args
	if n == 1 then return end
	
	for i=2,n-1 do
		local op = args[i]
		op[1](self, op)
	end
	
	local op = args[n]
	return op[1](self, op)
end)

/******************************************************************************/

// merge these two?
registerOperator("if", "n", "", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 != 0 then
		local op2 = args[3]
		op2[1](self, op2)
		return
	else
		local op3 = args[4]
		op3[1](self, op3)
		return
	end
end)

registerOperator("cnd", "n", "", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 != 0 then
		local op2 = args[3]
		return op2[1](self, op2)
	else
		local op3 = args[4]
		return op3[1](self, op3)
	end
end)

/******************************************************************************/

registerOperator("trg", "", "n", function(self, args)
	local op1 = args[2]
	if self.triggerinput == op1
	   then return 1 else return 0 end
end)

/******************************************************************************/

registerOperator("is", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 != 0
	   then return 1 else return 0 end
end)

registerOperator("not", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 == 0
	   then return 1 else return 0 end
end)

registerOperator("and", "nn", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 == 0
	   then return 0 end
	
	local op2 = args[3]
	local rv2 = op2[1](self, op2)
	if rv2 == 0
	   then return 0 else return 1 end
end)

registerOperator("or", "nn", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 != 0
	   then return 1 end
	
	local op2 = args[3]
	local rv2 = op2[1](self, op2)
	if rv2 != 0
	   then return 1 else return 0 end
end)

/******************************************************************************/

registerFunction("first", "", "n", function(self, args)
	if runner == "interval"
	   then return 1 else return 0 end
end)
