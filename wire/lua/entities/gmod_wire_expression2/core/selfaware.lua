AddCSLuaFile('selfaware.lua')

/******************************************************************************\
  Selfaware support
\******************************************************************************/

registerFunction("entity", "", "e", function(self, args)
	return self.entity
end)

registerFunction("setColor", "nnn", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	self.entity:SetColor(math.Clamp(rv1, 0, 255), math.Clamp(rv2, 0, 255), math.Clamp(rv3, 0, 255), 255)
end)
