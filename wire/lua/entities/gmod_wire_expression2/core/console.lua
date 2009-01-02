/******************************************************************************\
  Console support
\******************************************************************************/

/*registerFunction("trace", "s", "", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	self.player:Msg(rv1 .. "\n")
end)*/

registerFunction("concmd", "s", "", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	self.player:ConCommand(rv1)
end)

registerFunction("convar", "s", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	self.player:GetInfo(rv1) 
end)

registerFunction("convarnum", "s", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	self.player:GetInfoNum(rv1) 
end)