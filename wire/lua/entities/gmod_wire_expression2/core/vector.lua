AddCSLuaFile('vector.lua')

/******************************************************************************\
  Vector support
\******************************************************************************/

// TODO: add angles!
// TODO: add reflect?
// TODO: add rotate?
// TODO: add absdotproduct?
// TODO: add helper for angle and dotproduct? (just strange?)

/******************************************************************************/

registerType("vector", "v", { 0, 0, 0 },
	function(self, input) return { input.x, input.y, input.z } end,
	function(self, output) return Vector(output[1], output[2], output[3]) end
)

/******************************************************************************/

registerFunction("vec", "", "v", function(self, args)
	return { 0, 0, 0 }
end)

registerFunction("vec", "nnn", "v", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	return { rv1, rv2, rv3 }
end)

registerFunction("vec", "xv2", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[2], 0 }
end)

registerFunction("vec", "xv2n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1], rv1[2], rv2 }
end)

// Convert Angle -> Vector
registerFunction("vec", "a", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[2], rv1[3] }
end)

/******************************************************************************/
// TODO: do we want it this way? right now we are never allowed to modify vectors
//       hence, A=B, modifying A will modify B, easy to fix, but "costly"

registerOperator("ass", "v", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local      rv2 = op2[1](self, op2)
	local ret = { rv2[1], rv2[2], rv2[3] }
	self.vars[op1] = ret
	self.vclk[op1] = true
	return ret
end)

/******************************************************************************/

registerOperator("is", "v", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1[1] > delta || -rv1[1] > delta ||
	   rv1[2] > delta || -rv1[2] > delta ||
	   rv1[3] > delta || -rv1[3] > delta
	   then return 1 else return 0 end
end)

registerOperator("eq", "vv", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] <= delta && rv2[1] - rv1[1] <= delta &&
	   rv1[2] - rv2[2] <= delta && rv2[2] - rv1[2] <= delta &&
	   rv1[3] - rv2[3] <= delta && rv2[3] - rv1[3] <= delta
	   then return 1 else return 0 end
end)

registerOperator("neq", "vv", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] > delta || rv2[1] - rv1[1] > delta ||
	   rv1[2] - rv2[2] > delta || rv2[2] - rv1[2] > delta ||
	   rv1[3] - rv2[3] > delta || rv2[3] - rv1[3] > delta
	   then return 1 else return 0 end
end)

/******************************************************************************/

registerOperator("dlt", "v", "v", function(self, args)
	local op1 = args[2]
	local rv1, rv2 = self.vars[op1], self.vars["$" .. op1]
	return { rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3] }
end)

registerOperator("neg", "v", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { -rv1[1], -rv1[2], -rv1[3] }
end)

registerOperator("add", "nv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 + rv2[1], rv1 + rv2[2], rv1 + rv2[3] }
end)

registerOperator("add", "vn", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] + rv2, rv1[2] + rv2, rv1[3] + rv2 }
end)

registerOperator("add", "vv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] + rv2[1], rv1[2] + rv2[2], rv1[3] + rv2[3] }
end)

registerOperator("sub", "nv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 - rv2[1], rv1 - rv2[2], rv1 - rv2[3] }
end)

registerOperator("sub", "vn", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] - rv2, rv1[2] - rv2, rv1[3] - rv2 }
end)

registerOperator("sub", "vv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3] }
end)

registerOperator("mul", "nv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 * rv2[1], rv1 * rv2[2], rv1 * rv2[3] }
end)

registerOperator("mul", "vn", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2, rv1[2] * rv2, rv1[3] * rv2 }
end)

registerOperator("mul", "vv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2[1], rv1[2] * rv2[2], rv1[3] * rv2[3] }
end)

registerOperator("div", "nv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 / rv2[1], rv1 / rv2[2], rv1 / rv2[3] }
end)

registerOperator("div", "vn", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] / rv2, rv1[2] / rv2, rv1[3] / rv2 }
end)

registerOperator("div", "vv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] / rv2[1], rv1[2] / rv2[2], rv1[3] / rv2[3] }
end)

/******************************************************************************/
// TODO: should these functions round off to zero at DELTA?

registerFunction("length", "v:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return (rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3]) ^ 0.5
end)

registerFunction("length2", "v:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3]
end)

registerFunction("distance", "v:v", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local rvd1, rvd2, rvd3 = rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3]
	return (rvd1 * rvd1 + rvd2 * rvd2 + rvd3 * rvd3) ^ 0.5
end)

registerFunction("distance2", "v:v", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local rvd1, rvd2, rvd3 = rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3]
	return rvd1 * rvd1 + rvd2 * rvd2 + rvd3 * rvd3
end)

registerFunction("normalized", "v:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local len = (rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3]) ^ 0.5
	if len > delta then return { rv1[1] / len, rv1[2] / len, rv1[3] / len }
	               else return { 0, 0, 0 } end
end)

// TODO: map these are EXP (dot) and MOD (cross) or something?
registerFunction("dot", "v:v", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return rv1[1] * rv2[1] + rv1[2] * rv2[2] + rv1[3] * rv2[3]
end)

registerFunction("cross", "v:v", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[2] * rv2[3] - rv1[3] * rv2[2],
	         rv1[3] * rv2[1] - rv1[1] * rv2[3],
		     rv1[1] * rv2[2] - rv1[2] * rv2[1] }
end)

registerFunction("rotate", "v:a", "v", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
    local v = Vector(rv1[1], rv1[2], rv1[3])
    v:Rotate(Angle(rv2[1], rv2[2], rv2[3]))
    return { v.x, v.y, v.z }
end)
 
registerFunction("rotate", "v:nnn", "v", function(self, args)
    local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
    local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op2[1](self, op3), op2[1](self, op4)
    local v = Vector(rv1[1], rv1[2], rv1[3])
    v:Rotate(Angle(rv2, rv3, rv4))
    return { v.x, v.y, v.z }
end)

/******************************************************************************/

// clamps the length of the vector, remember that the length will always be positive
registerFunction("clamp", "vnn", "v", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local length = (rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3]) ^ 0.5
	if length < rv2 then
		return {rv1[1]*rv2/length,rv1[2]*rv2/length,rv1[3]*rv2/length}
	elseif length > rv3 then
		return {rv1[1]*rv3/length,rv1[2]*rv3/length,rv1[3]*rv3/length}
	else return rv1 end
end)
/******************************************************************************/

registerFunction("x", "v:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[1]
end)

registerFunction("y", "v:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[2]
end)

registerFunction("z", "v:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[3]
end)

// SET methods that returns vectors
registerFunction("setX", "v:n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	rv1[1] = rv2
	return rv1
end)

registerFunction("setY", "v:n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	rv1[2] = rv2
	return rv1
end)

registerFunction("setZ", "v:n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	rv1[3] = rv2
	return rv1
end)

/******************************************************************************/

registerFunction("round", "v:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local x = rv1[1] - (rv1[1] + 0.5) % 1 + 0.5
	local y = rv1[2] - (rv1[2] + 0.5) % 1 + 0.5
	local z = rv1[3] - (rv1[3] + 0.5) % 1 + 0.5
	return {x, y, z}
end)

registerFunction("round", "v:n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local shf = 10 ^ rv2
	local x = rv1[1] - ((rv1[1] * shf + 0.5) % 1 + 0.5) / shf
	local y = rv1[2] - ((rv1[2] * shf + 0.5) % 1 + 0.5) / shf
	local z = rv1[3] - ((rv1[3] * shf + 0.5) % 1 + 0.5) / shf
	return {x, y, z}
end)

registerFunction("ceil", "v", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local x = rv1[1] - rv1[1] % -1
	local y = rv1[2] - rv1[2] % -1
	local z = rv1[3] - rv1[3] % -1
	return {x, y, z}
end)

registerFunction("ceil", "vn", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local shf = 10 ^ rv2
	local x = rv1[1] - ((rv1[1] * shf) % -1) / shf
	local y = rv1[2] - ((rv1[2] * shf) % -1) / shf
	local z = rv1[3] - ((rv1[3] * shf) % -1) / shf
	return {x, y, z}
end)

registerFunction("floor", "v", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local x = rv1[1] - rv1[1] % 1
	local y = rv1[2] - rv1[2] % 1
	local z = rv1[3] - rv1[3] % 1
	return {x, y, z}
end)

registerFunction("floor", "vn", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local shf = 10 ^ rv2
	local x = rv1[1] - ((rv1[1] * shf) % 1) / shf
	local y = rv1[2] - ((rv1[2] * shf) % 1) / shf
	local z = rv1[3] - ((rv1[3] * shf) % 1) / shf
	return {x, y, z}
end)

// min/max based on vector length - returns shortest/longest vector
registerFunction("min", "vv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local length1 = ( rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3] ) ^ 0.5
	local length2 = ( rv2[1] * rv2[1] + rv2[2] * rv2[2] + rv2[3] * rv2[3] ) ^ 0.5
	if length1 < length2 then return rv1 else return rv2 end
end)

registerFunction("max", "vv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local length1 = ( rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3] ) ^ 0.5
	local length2 = ( rv2[1] * rv2[1] + rv2[2] * rv2[2] + rv2[3] * rv2[3] ) ^ 0.5
	if length1 > length2 then return rv1 else return rv2 end
end)

// Performs modulo on x,y,z separately
registerFunction("mod", "vn", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local x,y,z
	if rv1[1] >= 0 then
		x = rv1[1] % rv2
	else x = rv1[1] % -rv2 end
	if rv1[2] >= 0 then
		y = rv1[2] % rv2
	else y = rv1[2] % -rv2 end
	if rv1[3] >= 0 then
		z = rv1[3] % rv2
	else z = rv1[3] % -rv2 end
	return {x, y, z}
end)

// Modulo where divisors are defined as a vector
registerFunction("mod", "vv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local x,y,z
	if rv1[1] >= 0 then
		x = rv1[1] % rv2[1]
	else x = rv1[1] % -rv2[1] end
	if rv1[2] >= 0 then
		y = rv1[2] % rv2[2]
	else y = rv1[2] % -rv2[2] end
	if rv1[3] >= 0 then
		z = rv1[3] % rv2[3]
	else z = rv1[3] % -rv2[3] end
	return {x, y, z}
end)

// Clamp according to limits defined by two min/max vectors
registerFunction("clamp", "vvv", "v", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local x,y,z
	
	if rv1[1] < rv2[1] then x = rv2[1]
	elseif rv1[1] > rv3[1] then x = rv3[1]
	else x = rv1[1] end

	if rv1[2] < rv2[2] then y = rv2[2]
	elseif rv1[2] > rv3[2] then y = rv3[2]
	else y = rv1[2] end

	if rv1[3] < rv2[3] then z = rv2[3]
	elseif rv1[3] > rv3[3] then z = rv3[3]
	else z = rv1[3] end

	return {x, y, z}
end)

// Mix two vectors by a given proportion (between 0 and 1)
registerFunction("mix", "vvn", "v", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local n
	if rv3 < 0 then n = 0
	elseif rv3 > 1 then n = 1
	else n = rv3 end
	local x = rv1[1] * n + rv2[1] * (1-n)
	local y = rv1[2] * n + rv2[2] * (1-n)
	local z = rv1[3] * n + rv2[3] * (1-n)
	return {x, y, z}
end)

// Circular shift function: shiftr( x,y,z ) = ( z,x,y )
registerFunction("shiftR", "v", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return {rv1[3], rv1[1], rv1[2]}
end)

registerFunction("shiftL", "v", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return {rv1[2], rv1[3], rv1[1]}
end)

/******************************************************************************/

registerFunction("toAngle", "v:", "a", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local angle = Vector(rv1[1], rv1[2], rv1[3]):Angle()
	return { angle.p, angle.y, angle.r }
end)

registerFunction("toString", "v:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return "[" .. tostring(rv1[1]) .. "," .. tostring(rv1[2]) .. "," .. tostring(rv1[3]) .. "]"
end)
