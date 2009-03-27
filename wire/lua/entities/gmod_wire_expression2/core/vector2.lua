AddCSLuaFile('vector2.lua')

/******************************************************************************\
  2D Vector support
\******************************************************************************/

/******************************************************************************/

registerType("vector2", "xv2", { 0, 0 },
	function(self, input) return { input.x, input.y } end,
	function(self, output) return Vector( output[1], output[2] ) end
)

/******************************************************************************/

registerFunction("vec2", "", "xv2", function(self, args)
	return { 0, 0 }
end)

registerFunction("vec2", "nn", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1, rv2 }
end)

registerFunction("vec2", "v", "xv2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[2] }
end)

/******************************************************************************/
// TODO: do we want it this way? right now we are never allowed to modify vectors
//       hence, A=B, modifying A will modify B, easy to fix, but "costly"

registerOperator("ass", "xv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local      rv2 = op2[1](self, op2)
	local ret = { rv2[1], rv2[2] }
	self.vars[op1] = ret
	self.vclk[op1] = true
	return ret
end)

/******************************************************************************/

registerOperator("is", "xv2", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1[1] > delta || -rv1[1] > delta ||
	   rv1[2] > delta || -rv1[2] > delta
	   then return 1 else return 0 end
end)

registerOperator("eq", "xv2xv2", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] <= delta && rv2[1] - rv1[1] <= delta &&
	   rv1[2] - rv2[2] <= delta && rv2[2] - rv1[2] <= delta
	   then return 1 else return 0 end
end)

registerOperator("neq", "xv2xv2", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] > delta || rv2[1] - rv1[1] > delta ||
	   rv1[2] - rv2[2] > delta || rv2[2] - rv1[2] > delta
	   then return 1 else return 0 end
end)

/******************************************************************************/

registerOperator("dlt", "xv2", "xv2", function(self, args)
	local op1 = args[2]
	local rv1, rv2 = self.vars[op1], self.vars["$" .. op1]
	return { rv1[1] - rv2[1], rv1[2] - rv2[2] }
end)

registerOperator("neg", "xv2", "xv2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { -rv1[1], -rv1[2] }
end)

registerOperator("add", "xv2xv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] + rv2[1], rv1[2] + rv2[2] }
end)

registerOperator("sub", "xv2xv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] - rv2[1], rv1[2] - rv2[2] }
end)

registerOperator("mul", "nxv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 * rv2[1], rv1 * rv2[2] }
end)

registerOperator("mul", "xv2n", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2, rv1[2] * rv2 }
end)

registerOperator("mul", "xv2xv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2[1], rv1[2] * rv2[2] }
end)

registerOperator("div", "nxv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 / rv2[1], rv1 / rv2[2] }
end)

registerOperator("div", "xv2n", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] / rv2, rv1[2] / rv2 }
end)

registerOperator("div", "xv2xv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] / rv2[1], rv1[2] / rv2[2] }
end)

/******************************************************************************/

registerFunction("length", "xv2:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return (rv1[1] * rv1[1] + rv1[2] * rv1[2] ) ^ 0.5
end)

registerFunction("length2", "xv2:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[1] * rv1[1] + rv1[2] * rv1[2]
end)

registerFunction("distance", "xv2:xv2", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local rvd1, rvd2 = rv1[1] - rv2[1], rv1[2] - rv2[2]
	return (rvd1 * rvd1 + rvd2 * rvd2 ) ^ 0.5
end)

registerFunction("distance2", "xv2:xv2", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local rvd1, rvd2 = rv1[1] - rv2[1], rv1[2] - rv2[2]
	return rvd1 * rvd1 + rvd2 * rvd2
end)

registerFunction("normalized", "xv2:", "xv2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local len = (rv1[1] * rv1[1] + rv1[2] * rv1[2] ) ^ 0.5
	if len > delta then return { rv1[1] / len, rv1[2] / len }
	               else return { 0, 0 } end
end)

registerFunction("dot", "xv2:xv2", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return rv1[1] * rv2[1] + rv1[2] * rv2[2]
end)

registerFunction("cross", "xv2:xv2", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2[2] - rv1[2] * rv2[1] }
end)

registerFunction("rotate", "xv2:n", "xv2", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local a = rv2 * 3.14159265 / 180
    local x = math.cos(a) * rv1[1] - math.sin(a) * rv1[2]
	local y = math.sin(a) * rv1[1] - math.cos(a) * rv1[2]
    return { x, y }
end)
 
/******************************************************************************/

// clamps the length of the vector, remember that the length will always be positive
registerFunction("clamp", "xv2nn", "xv2", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local length = (rv1[1] * rv1[1] + rv1[2] * rv1[2] ) ^ 0.5
	if length < rv2 then
		return { rv1[1]*rv2/length, rv1[2]*rv2/length }
	elseif length > rv3 then
		return { rv1[1]*rv3/length, rv1[2]*rv3/length }
	else return rv1 end
end)
/******************************************************************************/

registerFunction("x", "xv2:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[1]
end)

registerFunction("y", "xv2:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[2]
end)

// SET methods that returns vectors - you shouldn't need these for 2D vectors, but I've added them anyway for consistency
// NOTE: does not change the original vector!
registerFunction("setX", "xv2:n", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv2, rv1[2] }
end)

registerFunction("setY", "xv2:n", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1], rv2 }
end)

/******************************************************************************/

registerFunction("round", "xv2:", "xv2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local x = rv1[1] - (rv1[1] + 0.5) % 1 + 0.5
	local y = rv1[2] - (rv1[2] + 0.5) % 1 + 0.5
	return { x, y }
end)

registerFunction("round", "xv2:n", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local shf = 10 ^ rv2
	local x = rv1[1] - ((rv1[1] * shf + 0.5) % 1 + 0.5) / shf
	local y = rv1[2] - ((rv1[2] * shf + 0.5) % 1 + 0.5) / shf
	return { x, y }
end)

registerFunction("ceil", "xv2", "xv2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local x = rv1[1] - rv1[1] % -1
	local y = rv1[2] - rv1[2] % -1
	return { x, y }
end)

registerFunction("ceil", "xv2n", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local shf = 10 ^ rv2
	local x = rv1[1] - ((rv1[1] * shf) % -1) / shf
	local y = rv1[2] - ((rv1[2] * shf) % -1) / shf
	return { x, y }
end)

registerFunction("floor", "xv2", "xv2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local x = rv1[1] - rv1[1] % 1
	local y = rv1[2] - rv1[2] % 1
	return { x, y }
end)

registerFunction("floor", "xv2n", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local shf = 10 ^ rv2
	local x = rv1[1] - ((rv1[1] * shf) % 1) / shf
	local y = rv1[2] - ((rv1[2] * shf) % 1) / shf
	return { x, y }
end)

// min/max based on vector length - returns shortest/longest vector
registerFunction("min", "xv2xv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local length1 = ( rv1[1] * rv1[1] + rv1[2] * rv1[2] ) ^ 0.5
	local length2 = ( rv2[1] * rv2[1] + rv2[2] * rv2[2] ) ^ 0.5
	if length1 < length2 then return rv1 else return rv2 end
end)

registerFunction("max", "xv2xv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local length1 = ( rv1[1] * rv1[1] + rv1[2] * rv1[2] ) ^ 0.5
	local length2 = ( rv2[1] * rv2[1] + rv2[2] * rv2[2] ) ^ 0.5
	if length1 > length2 then return rv1 else return rv2 end
end)

// Performs modulo on x,y separately
registerFunction("mod", "xv2n", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local x, y
	
	if rv1[1] >= 0 then
		x = rv1[1] % rv2
	else x = rv1[1] % -rv2 end
	
	if rv1[2] >= 0 then
		y = rv1[2] % rv2
	else y = rv1[2] % -rv2 end
	
	return { x, y }
end)

// Modulo where divisors are defined as a vector
registerFunction("mod", "xv2xv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local x, y
	
	if rv1[1] >= 0 then
		x = rv1[1] % rv2[1]
	else x = rv1[1] % -rv2[1] end
	
	if rv1[2] >= 0 then
		y = rv1[2] % rv2[2]
	else y = rv1[2] % -rv2[2] end
	
	return { x, y }
end)

// Clamp according to limits defined by two min/max vectors
registerFunction("clamp", "xv2xv2xv2", "xv2", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local x, y
	
	if rv1[1] < rv2[1] then x = rv2[1]
	elseif rv1[1] > rv3[1] then x = rv3[1]
	else x = rv1[1] end

	if rv1[2] < rv2[2] then y = rv2[2]
	elseif rv1[2] > rv3[2] then y = rv3[2]
	else y = rv1[2] end

	return { x, y }
end)

// Mix two vectors by a given proportion (between 0 and 1)
registerFunction("mix", "xv2xv2n", "xv2", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local n
	
	if rv3 < 0 then n = 0
	elseif rv3 > 1 then n = 1
	else n = rv3 end
	
	local x = rv1[1] * n + rv2[1] * (1-n)
	local y = rv1[2] * n + rv2[2] * (1-n)
	return { x, y }
end)

// swap x/y
registerFunction("shift", "xv2", "xv2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[2], rv1[1] }
end)

/******************************************************************************/

registerFunction("toAngle", "xv2:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local angle = math.atan2( rv1[2], rv1[1] ) * 180 / 3.14159265
	--if (angle < 0) then angle = angle + 180 end
	return angle
end)

registerFunction("toString", "xv2:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return "[" .. tostring(rv1[1]) .. "," .. tostring(rv1[2]) .. "]"
end)
