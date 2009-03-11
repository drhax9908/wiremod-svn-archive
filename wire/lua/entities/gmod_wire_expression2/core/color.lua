AddCSLuaFile('color.lua')

/******************************************************************************\
  Colour support
\******************************************************************************/

function ColorClamp(col)
	return { math.Clamp(col[1], 0, 255), math.Clamp(col[2], 0, 255), math.Clamp(col[3], 0, 255), math.Clamp(col[4], 0, 255) }
end

/******************************************************************************/

registerFunction("getColor", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	local color = {rv1:GetColor()}
	return {color[1], color[2], color[3]}
end)

registerFunction("getAlpha", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	local color = {rv1:GetColor()}
	return color[4]
end)

registerFunction("setColor", "e:nnn", "", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	if(!validEntity(rv1)) then return end
	if(!isOwner(self, rv1)) then return end
	local color1 = {rv1:GetColor()}
	local color2 = ColorClamp{ rv2, rv3, rv4, 0 }
	rv1:SetColor(color2[1], color2[2], color2[3], color1[4])
end)

registerFunction("setColor", "e:nnnn", "", function(self, args)
	local op1, op2, op3, op4, op5 = args[2], args[3], args[4], args[5], args[6]
	local rv1, rv2, rv3, rv4, rv5 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4), op5[1](self, op5)
	if(!validEntity(rv1)) then return end
	if(rv1:IsPlayer() or rv1:IsWeapon()) then rv5 = 255 end
	if(!isOwner(self, rv1)) then return end
	local color = ColorClamp{ rv2, rv3, rv4, rv5 }
	rv1:SetColor(color[1], color[2], color[3], color[4])
end)

registerFunction("setColor", "e:v", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if(!validEntity(rv1)) then return end
	if(!isOwner(self, rv1)) then return end
	local color1 = {rv1:GetColor()}
	local color2 = ColorClamp{ rv2[1], rv2[2], rv2[3], 0 }
	rv1:SetColor(color2[1], color2[2], color2[3], color1[4])
end)

registerFunction("setColor", "e:vn", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if(!validEntity(rv1)) then return end
	if(rv1:IsPlayer() or rv1:IsWeapon()) then rv3 = 255 end
	if(!isOwner(self, rv1)) then return end
	local color = ColorClamp{ rv2[1], rv2[2], rv2[3], rv3 }
	rv1:SetColor(color[1], color[2], color[3], color[4])
end)

registerFunction("setAlpha", "e:n", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if(!validEntity(rv1)) then return end
	if(rv1:IsPlayer() or rv1:IsWeapon()) then return end
	if(!isOwner(self, rv1)) then return end
	local color = {rv1:GetColor()}
	rv1:SetColor(color[1], color[2], color[3], math.Clamp(rv2, 0, 255))
end)