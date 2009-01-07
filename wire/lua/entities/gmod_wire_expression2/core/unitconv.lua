AddCSLuaFile('unitconv.lua')

/******************************************************************************\
  Unit conversion
\******************************************************************************/

/*
	mm  - millimeter
	cm  - centimeter
	dm  - decimeter
	m   - meter
	km  - kilometer
	in  - inch
	ft  - foot
	yd  - yard
	mi  - mile
	nmi - nautical mile
	
	g   - gram
	kg  - kilogram
	t   - tonne
	oz  - ounce
	lb  - pound
*/

local speed = {
	["mm/s"]  = 25.4,
	["cm/s"]  = 2.54,
	["dm/s"]  = 0.254,
	["m/s"]   = 0.0254,
	["km/s"]  = 0.0000254,
	["in/s"]  = 1,
	["ft/s"]  = 1 / 12,
	["yd/s"]  = 1 / 36,
	["mi/s"]  = 1 / 63360,
	["nmi/s"] = 1143 / 23150,
	
	["mm/m"]  = 25.4 / 60,
	["cm/m"]  = 2.54 / 60,
	["dm/m"]  = 0.254 / 60,
	["m/m"]   = 0.0254 / 60,
	["km/m"]  = 0.0000254 / 60,
	["in/m"]  = 1 / 60,
	["ft/m"]  = 1 / 720,
	["yd/m"]  = 1 / 2160,
	["mi/m"]  = 1 / 3801600,
	["nmi/m"] = 381 / 463000,
	
	["mm/h"]  = 25.4 / 3600,
	["cm/h"]  = 2.54 / 3600,
	["dm/h"]  = 0.254 / 3600,
	["m/h"]   = 0.0254 / 3600,
	["km/h"]  = 0.0000254 / 3600,
	["in/h"]  = 1 / 3600,
	["ft/h"]  = 1 / 43200,
	["yd/h"]  = 1 / 129600,
	["mi/h"]  = 1 / 228096000,
	["nmi/h"] = 127 / 9260000,
	
	["knots"] = 127 / 9260000,
	["mach"]  = 1 / 1127,
}

local length = {
	["mm"]  = 25.4,
	["cm"]  = 2.54,
	["dm"]  = 0.254,
	["m"]   = 0.0254,
	["km"]  = 0.0000254,
	["in"]  = 1,
	["ft"]  = 1 / 12,
	["yd"]  = 1 / 36,
	["mi"]  = 1 / 63360,
	["nmi"] = 127 / 9260000,
}

local weight = {
	["g"]  = 0.001,
	["kg"] = 1,
	["t"]  = 1000,
	["oz"] = 1 / 0.028349523125,
	["lb"] = 1 / 0.45359237,
}

registerFunction("toUnit", "sn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	
	if speed[rv1] then
		return rv2 * speed[rv1]
	elseif length[rv1] then
		return rv2 * length[rv1]
	elseif weight[rv1] then
		return rv2 * weight[rv1]
	end
	
	return -1
end)

registerFunction("fromUnit", "sn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	
	if speed[rv1] then
		return rv2 / speed[rv1]
	elseif length[rv1] then
		return rv2  / length[rv1]
	elseif weight[rv1] then
		return rv2 / weight[rv1]
	end
	
	return -1
end)

registerFunction("convertUnit", "ssn", "n", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	
	if speed[rv1] and speed[rv2] then
		return rv3 * speed[rv2] / speed[rv1]
	elseif length[rv1] and length[rv2] then
		return rv3 * length[rv2] / length[rv1]
	elseif weight[rv1] and weight[rv2] then
		return rv3 * weight[rv2] / weight[rv1]
	end
	
	return -1
end)
