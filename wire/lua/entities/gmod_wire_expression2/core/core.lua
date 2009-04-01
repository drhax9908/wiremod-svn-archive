AddCSLuaFile('core.lua')

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

registerCallback("preexecute", function(self)
	if self.data['first'] == nil then
		self.data['first'] = true
	elseif self.data['first'] == true then
		self.data['first'] = false
	end
end)

registerFunction("first", "", "n", function(self, args)
	if self.data['first'] == true
	   then return 1 else return 0 end
end)

/******************************************************************************/

registerFunction("exit", "", "", function(self, args)
	error("exit", 0)
end)

/******************************************************************************/

registerCallback("postexecute", function(self) 
    if self.data["reset"] then
		if self.data['first'] then
			self.data["reset"] = nil
		else
			self.entity:Reset()
		end
	end
end)
 
registerFunction("reset", "", "", function(self,args)
    self.data["reset"] = true
	error("exit", 0)
end)
