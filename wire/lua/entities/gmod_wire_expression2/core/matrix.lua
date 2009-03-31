AddCSLuaFile('matrix.lua')

/******************************************************************************\
  Matrix support
\******************************************************************************/

local function clone(a)
	local b = {}
	for k,v in ipairs(a) do
		b[k] = v
	end
	return b
end
		

/******************************************************************************\
  2x2 Matrices
\******************************************************************************/

registerType("matrix2", "xm2", { 0, 0,
								 0, 0 },
	function(self, input)
		local ret = {}
		for k,v in pairs(input) do ret[k] = v end
		return ret
	end,
	function(self, output) return output end
)

/******************************************************************************/
// Common functions - explicit matrix solvers

local function det2(a)
	return ( a[1] * a[4] - a[3] * a[2] )
end

local function inverse2(a)
	local det = det2(a)
	if det == 0 then return { 0, 0,
							  0, 0 }
	end
	return { a[4]/det,	-a[2]/det,
			-a[3]/det,	 a[1]/det }
end

/******************************************************************************/

registerFunction("matrix2", "", "xm2", function(self, args)
	return { 0, 0,
			 0, 0 }
end)

registerFunction("matrix2", "xv2xv2", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1], rv2[1],
			 rv1[2], rv2[2] }
end)

registerFunction("matrix2", "nnnn", "xm2", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	return { rv1, rv2,
			 rv3, rv4 }
end)

registerFunction("matrix2", "m", "xm2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv2[2],
			 rv1[4], rv2[5] }
end)

registerFunction("identity2", "", "xm2", function(self, args)
	return { 1, 0,
			 0, 1 }
end)

/******************************************************************************/

registerOperator("ass", "xm2", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local      rv2 = op2[1](self, op2)
	self.vars[op1] = rv2
	self.vclk[op1] = true
	return rv2
end)

/******************************************************************************/
// Comparison

registerOperator("is", "xm2", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1[1] > delta || -rv1[1] > delta ||
	   rv1[2] > delta || -rv1[2] > delta ||
	   rv1[3] > delta || -rv1[3] > delta ||
	   rv1[4] > delta || -rv1[4] > delta
	   then return 1 else return 0 end
end)

registerOperator("eq", "xm2xm2", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] <= delta && rv2[1] - rv1[1] <= delta &&
	   rv1[2] - rv2[2] <= delta && rv2[2] - rv1[2] <= delta &&
	   rv1[3] - rv2[3] <= delta && rv2[3] - rv1[3] <= delta &&
	   rv1[4] - rv2[4] <= delta && rv2[4] - rv1[4] <= delta
	   then return 1 else return 0 end
end)

registerOperator("neq", "xm2xm2", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] > delta && rv2[1] - rv1[1] > delta &&
	   rv1[2] - rv2[2] > delta && rv2[2] - rv1[2] > delta &&
	   rv1[3] - rv2[3] > delta && rv2[3] - rv1[3] > delta &&
	   rv1[4] - rv2[4] > delta && rv2[4] - rv1[4] > delta
	   then return 1 else return 0 end
end)

/******************************************************************************/
// Basic operations

registerOperator("dlt", "xm2", "xm2", function(self, args)
	local op1 = args[2]
	local rv1, rv2 = self.vars[op1], self.vars["$" .. op1]
	return { rv1[1] - rv2[1], rv1[2] - rv2[2],
			 rv1[3] - rv2[3], rv1[4] - rv2[4] }
end)

registerOperator("neg", "xm2", "xm2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { -rv1[1], -rv1[2],
			 -rv1[3], -rv1[4] }
end)

registerOperator("add", "xm2xm2", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] + rv2[1], rv1[2] + rv2[2],
			 rv1[3] + rv2[3], rv1[4] + rv2[4] }
end)

registerOperator("sub", "xm2xm2", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] - rv2[1], rv1[2] - rv2[2],
			 rv1[3] - rv2[3], rv1[4] - rv2[4] }
end)

registerOperator("mul", "nxm2", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 * rv2[1], rv1 * rv2[2],
			 rv1 * rv2[3], rv1 * rv2[4] }
end)

registerOperator("mul", "xm2n", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2, rv1[2] * rv2,
			 rv1[3] * rv2, rv1[4] * rv2 }
end)

registerOperator("mul", "xm2xv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2[1] + rv1[2] * rv2[2],
			 rv1[3] * rv2[1] + rv1[4] * rv2[2] }
end)

registerOperator("mul", "xm2xm2", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2[1] + rv1[2] * rv2[3],
			 rv1[1] * rv2[2] + rv1[2] * rv2[4],
			 rv1[3] * rv2[1] + rv1[4] * rv2[3],
			 rv1[3] * rv2[2] + rv1[4] * rv2[4] }
end)

registerOperator("div", "xm2n", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] / rv2, rv1[2] / rv2,
			 rv1[3] / rv2, rv1[4] / rv2 }
end)

registerOperator("exp", "xm2n", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)

	if rv2 == -1 then return ( inverse2(rv1) )
	
	elseif rv2 == 0 then return { 1, 0,
								  0, 1 }
								  
	elseif rv2 == 1 then return rv1
	
	elseif rv2 == 2 then
		return { rv1[1] * rv1[1] + rv1[2] * rv1[3],
				 rv1[1] * rv1[2] + rv1[2] * rv1[4],
				 rv1[3] * rv1[1] + rv1[4] * rv1[3],
				 rv1[3] * rv1[2] + rv1[4] * rv1[4] }

	else return { 0, 0,
				  0, 0 }
	end
end)

/******************************************************************************/
// Row/column/element manipulation

registerFunction("row", "xm2:n", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local k
	
	if rv2 < 1 then k = 1
	elseif rv2 > 2 then k = 2
	else k = rv2 - rv2 % 1 end
	
	x = rv1[k * 2 - 1]
	y = rv1[k * 2]
	return { x, y }
end)

registerFunction("column", "xm2:n", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 2 then k = 2
	else k = rv2 - rv2 % 1 end
	
	x = rv1[k]
	y = rv1[k + 2]
	return { x, y }
end)

registerFunction("setRow", "xm2:nnn", "xm2", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	local k
	
	if rv2 < 1 then k = 1
	elseif rv2 > 2 then k = 2
	else k = rv2 - rv2 % 1 end
	
	local a = clone(rv1)
	a[k * 2 - 1] = rv3
	a[k * 2] = rv4
	return a
end)

registerFunction("setRow", "m:nxv2", "xm2", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	local k
	
	if rv2 < 1 then k = 1
	elseif rv2 > 2 then k = 2
	else k = rv2 - rv2 % 1 end
	
	local a = clone(rv1)
	a[k * 2 - 1] = rv3[1]
	a[k * 2] = rv3[2]
	return a
end)


registerFunction("setColum", "xm2:nnn", "xm2", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	local k
	
	if rv2 < 1 then k = 1
	elseif rv2 > 2 then k = 2
	else k = rv2 - rv2 % 1 end
	
	local a = clone(rv1)
	a[k] = rv3
	a[k + 2] = rv4
	return a
end)

registerFunction("setColumn", "m:nxv2", "xm2", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	local k
	
	if rv2 < 1 then k = 1
	elseif rv2 > 2 then k = 2
	else k = rv2 - rv2 % 1 end
	
	local a = clone(rv1)
	a[k] = rv3[1]
	a[k + 2] = rv3[2]
	return a
end)

registerFunction("swapRows", "xm2:", "xm2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	
	rv1 = { rv1[3], rv1[4],
			rv1[1], rv1[2] }
	return rv1
end)

registerFunction("swapColumns", "xm2:", "xm2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	
	rv1 = { rv1[2], rv1[1],
			rv1[4], rv1[3] }
	return rv1
end)

registerFunction("element", "xm2:nn", "n", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local i, j
	
	if rv2 < 1 then i = 1
	elseif rv2 > 2 then i = 2
	else i = rv2 - rv2 % 1 end
	if rv3 < 1 then j = 1
	elseif rv3 > 2 then j = 2
	else j = rv3 - rv3 % 1 end
	
	local k = i + (j - 1) * 2
	return rv1[k]
end)

registerFunction("setElement", "xm2:nnn", "xm2", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	local i, j

	if rv2 < 1 then i = 1
	elseif rv2 > 2 then i = 2
	else i = rv2 - rv2 % 1 end
	if rv3 < 1 then j = 1
	elseif rv3 > 2 then j = 2
	else j = rv3 - rv3 % 1 end

	local a = clone(rv1)
	a[i + (j - 1) * 2] = rv4
	return a
end)

registerFunction("swapElements", "xm2:nnnn", "xm2", function(self, args)
	local op1, op2, op3, op4, op5 = args[2], args[3], args[4], args[5], args[6]
	local rv1, rv2, rv3, rv4, rv5 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4), op5[1](self, op5)
	local i1, j1, i2, j2

	if rv2 < 1 then i1 = 1
	elseif rv2 > 3 then i1 = 3
	else i1 = rv2 - rv2 % 1 end
	
	if rv3 < 1 then j1 = 1
	elseif rv3 > 3 then j1 = 3
	else j1 = rv3 - rv3 % 1 end
	
	if rv4 < 1 then i2 = 1
	elseif rv4 > 3 then i2 = 3
	else i2 = rv4 - rv4 % 1 end
	
	if rv5 < 1 then j2 = 1
	elseif rv5 > 3 then j2 = 3
	else j2 = rv5 - rv5 % 1 end
	
	local k1 = i1 + (j1 - 1) * 2
	local k2 = i2 + (j2 - 1) * 2
	local a = clone(rv1)
	a[k1], a[k2] = rv1[k2], rv1[k1]
	return a
end)

/******************************************************************************/
// Useful matrix maths functions

registerFunction("diagonal", "xm2", "xv2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[4] }
end)

registerFunction("trace", "xm2", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return ( rv1[1] + rv[4] )
end)

registerFunction("det", "xm2", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return ( det2(rv1) )
end)

registerFunction("transpose", "xm2", "xm2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[3],
			 rv1[2], rv1[4] }
end)

registerFunction("adj", "xm2", "xm2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return {  rv1[4], -rv1[2],
			 -rv1[3],  rv1[1] }
end)


/******************************************************************************\
  3x3 Matrices
\******************************************************************************/

registerType("matrix", "m", { 0, 0, 0,
							  0, 0, 0,
							  0, 0, 0 },
	function(self, input)
		local ret = {}
		for k,v in pairs(input) do ret[k] = v end
		return ret
	end,
	function(self, output) return output end
)

/******************************************************************************/
// Common functions - matrix solvers

/*
-- Useful functions - may be used in the future? These have been written explicitly in the relevant commands for now.

local function transpose3(a)
	return { a[1], a[4], a[7],
			 a[2], a[5], a[8],
			 a[3], a[6], a[9] }
end

local function adj3(a)
	return { a[5] * a[9] - a[8] * a[6],	a[8] * a[3] - a[2] * a[9],	a[2] * a[6] - a[5] * a[3],
			a[7] * a[6] - a[4] * a[9],	a[1] * a[9] - a[7] * a[3],	a[4] * a[3] - a[1] * a[6],
			a[4] * a[8] - a[7] * a[5],	a[7] * a[2] - a[1] * a[8],	a[1] * a[5] - a[4] * a[2] }
end
*/

local function det3(a)
	return ( a[1] * (a[5] * a[9] - a[8] * a[6]) -
			 a[2] * (a[4] * a[9] - a[7] * a[6]) +
			 a[3] * (a[4] * a[8] - a[7] * a[5]) )
end

local function inverse3(a)
	local det = det3(a)
	if det == 0 then return { 0, 0, 0,
							  0, 0, 0,
							  0, 0, 0 }
	end
	return { (a[5] * a[9] - a[8] * a[6])/det,	(a[8] * a[3] - a[2] * a[9])/det,	(a[2] * a[6] - a[5] * a[3])/det,
			 (a[7] * a[6] - a[4] * a[9])/det,	(a[1] * a[9] - a[7] * a[3])/det,	(a[4] * a[3] - a[1] * a[6])/det,
			 (a[4] * a[8] - a[7] * a[5])/det,	(a[7] * a[2] - a[1] * a[8])/det,	(a[1] * a[5] - a[4] * a[2])/det }
end


/******************************************************************************/

registerFunction("matrix", "", "m", function(self, args)
	return { 0, 0, 0,
			 0, 0, 0,
			 0, 0, 0 }
end)

registerFunction("matrix", "vvv", "m", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	return { rv1[1], rv2[1], rv3[1],
			 rv1[2], rv2[2], rv3[2],
			 rv1[3], rv2[3], rv3[3] }
end)

registerFunction("matrix", "nnnnnnnnn", "m", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local op4, op5, op6 = args[5], args[6], args[7]
	local op7, op8, op9 = args[8], args[9], args[10]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local rv4, rv5, rv6 = op4[1](self, op4), op5[1](self, op5), op6[1](self, op6)
	local rv7, rv8, rv9 = op7[1](self, op7), op8[1](self, op8), op9[1](self, op9)
	return { rv1, rv2, rv3,
			 rv4, rv5, rv6,
			 rv7, rv8, rv9 }
end)

registerFunction("matrix", "xm2", "m", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[2], 0,
			 rv1[3], rv1[4], 0,
			 0,		 0,		 0 }
end)

registerFunction("identity", "", "m", function(self, args)
	return { 1, 0, 0,
			 0, 1, 0,
			 0, 0, 1 }
end)

/******************************************************************************/

registerOperator("ass", "m", "m", function(self, args)
	local op1, op2 = args[2], args[3]
	local      rv2 = op2[1](self, op2)
	self.vars[op1] = rv2
	self.vclk[op1] = true
	return rv2
end)

/******************************************************************************/
// Comparison

registerOperator("is", "m", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1[1] > delta || -rv1[1] > delta ||
	   rv1[2] > delta || -rv1[2] > delta ||
	   rv1[3] > delta || -rv1[3] > delta ||
	   rv1[4] > delta || -rv1[4] > delta ||
	   rv1[5] > delta || -rv1[5] > delta ||
	   rv1[6] > delta || -rv1[6] > delta ||
	   rv1[7] > delta || -rv1[7] > delta ||
	   rv1[8] > delta || -rv1[8] > delta ||
	   rv1[9] > delta || -rv1[9] > delta
	   then return 1 else return 0 end
end)

registerOperator("eq", "mm", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] <= delta && rv2[1] - rv1[1] <= delta &&
	   rv1[2] - rv2[2] <= delta && rv2[2] - rv1[2] <= delta &&
	   rv1[3] - rv2[3] <= delta && rv2[3] - rv1[3] <= delta &&
	   rv1[4] - rv2[4] <= delta && rv2[4] - rv1[4] <= delta &&
	   rv1[5] - rv2[5] <= delta && rv2[5] - rv1[5] <= delta &&
	   rv1[6] - rv2[6] <= delta && rv2[6] - rv1[6] <= delta &&
	   rv1[7] - rv2[7] <= delta && rv2[7] - rv1[7] <= delta &&
	   rv1[8] - rv2[8] <= delta && rv2[8] - rv1[8] <= delta &&
	   rv1[9] - rv2[9] <= delta && rv2[9] - rv1[9] <= delta
	   then return 1 else return 0 end
end)

registerOperator("neq", "mm", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] > delta && rv2[1] - rv1[1] > delta &&
	   rv1[2] - rv2[2] > delta && rv2[2] - rv1[2] > delta &&
	   rv1[3] - rv2[3] > delta && rv2[3] - rv1[3] > delta &&
	   rv1[4] - rv2[4] > delta && rv2[4] - rv1[4] > delta &&
	   rv1[5] - rv2[5] > delta && rv2[5] - rv1[5] > delta &&
	   rv1[6] - rv2[6] > delta && rv2[6] - rv1[6] > delta &&
	   rv1[7] - rv2[7] > delta && rv2[7] - rv1[7] > delta &&
	   rv1[8] - rv2[8] > delta && rv2[8] - rv1[8] > delta &&
	   rv1[9] - rv2[9] > delta && rv2[9] - rv1[9] > delta
	   then return 1 else return 0 end
end)

/******************************************************************************/
// Basic operations

registerOperator("dlt", "m", "m", function(self, args)
	local op1 = args[2]
	local rv1, rv2 = self.vars[op1], self.vars["$" .. op1]
	return { rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3],
			 rv1[4] - rv2[4], rv1[5] - rv2[5], rv1[6] - rv2[6],
			 rv1[7] - rv2[7], rv1[8] - rv2[8], rv1[9] - rv2[9]	}
end)

registerOperator("neg", "m", "m", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { -rv1[1], -rv1[2], -rv1[3],
			 -rv1[4], -rv1[5], -rv1[6],
			 -rv1[7], -rv1[8], -rv1[9] }
end)

registerOperator("add", "mm", "m", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] + rv2[1], rv1[2] + rv2[2], rv1[3] + rv2[3],
			 rv1[4] + rv2[4], rv1[5] + rv2[5], rv1[6] + rv2[6],
			 rv1[7] + rv2[7], rv1[8] + rv2[8], rv1[9] + rv2[9] }
end)

registerOperator("sub", "mm", "m", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3],
			 rv1[4] - rv2[4], rv1[5] - rv2[5], rv1[6] - rv2[6],
			 rv1[7] - rv2[7], rv1[8] - rv2[8], rv1[9] - rv2[9] }
end)

registerOperator("mul", "nm", "m", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 * rv2[1], rv1 * rv2[2], rv1 * rv2[3],
			 rv1 * rv2[4], rv1 * rv2[5], rv1 * rv2[6],
			 rv1 * rv2[7], rv1 * rv2[8], rv1 * rv2[9] }
end)

registerOperator("mul", "mn", "m", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2, rv1[2] * rv2, rv1[3] * rv2,
			 rv1[4] * rv2, rv1[5] * rv2, rv1[6] * rv2,
			 rv1[7] * rv2, rv1[8] * rv2, rv1[9] * rv2 }
end)

registerOperator("mul", "mv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2[1] + rv1[2] * rv2[2] + rv1[3] * rv2[3],
			 rv1[4] * rv2[1] + rv1[5] * rv2[2] + rv1[6] * rv2[3],
			 rv1[7] * rv2[1] + rv1[8] * rv2[2] + rv1[9] * rv2[3] }
end)

registerOperator("mul", "mm", "m", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2[1] + rv1[2] * rv2[4] + rv1[3] * rv2[7],
			 rv1[1] * rv2[2] + rv1[2] * rv2[5] + rv1[3] * rv2[8],
			 rv1[1] * rv2[3] + rv1[2] * rv2[6] + rv1[3] * rv2[9],
			 rv1[4] * rv2[1] + rv1[5] * rv2[4] + rv1[6] * rv2[7],
			 rv1[4] * rv2[2] + rv1[5] * rv2[5] + rv1[6] * rv2[8],
			 rv1[4] * rv2[3] + rv1[5] * rv2[6] + rv1[6] * rv2[9],
			 rv1[7] * rv2[1] + rv1[8] * rv2[4] + rv1[9] * rv2[7],
			 rv1[7] * rv2[2] + rv1[8] * rv2[5] + rv1[9] * rv2[8],
			 rv1[7] * rv2[3] + rv1[8] * rv2[6] + rv1[9] * rv2[9] }
end)

registerOperator("div", "mn", "m", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] / rv2, rv1[2] / rv2, rv1[3] / rv2,
			 rv1[4] / rv2, rv1[5] / rv2, rv1[6] / rv2,
			 rv1[7] / rv2, rv1[8] / rv2, rv1[9] / rv2 }
end)

registerOperator("exp", "mn", "m", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)

	if rv2 == -1 then return ( inverse3(rv1) )
	
	elseif rv2 == 0 then return { 1, 0, 0,
								  0, 1, 0,
								  0, 0, 1 }
								  
	elseif rv2 == 1 then return rv1
	
	elseif rv2 == 2 then
		return { rv1[1] * rv1[1] + rv1[2] * rv1[4] + rv1[3] * rv1[7],
				 rv1[1] * rv1[2] + rv1[2] * rv1[5] + rv1[3] * rv1[8],
				 rv1[1] * rv1[3] + rv1[2] * rv1[6] + rv1[3] * rv1[9],
				 rv1[4] * rv1[1] + rv1[5] * rv1[4] + rv1[6] * rv1[7],
				 rv1[4] * rv1[2] + rv1[5] * rv1[5] + rv1[6] * rv1[8],
				 rv1[4] * rv1[3] + rv1[5] * rv1[6] + rv1[6] * rv1[9],
				 rv1[7] * rv1[1] + rv1[8] * rv1[4] + rv1[9] * rv1[7],
				 rv1[7] * rv1[2] + rv1[8] * rv1[5] + rv1[9] * rv1[8],
				 rv1[7] * rv1[3] + rv1[8] * rv1[6] + rv1[9] * rv1[9] }

	else return { 0, 0, 0,
				  0, 0, 0,
				  0, 0, 0 }
	end
end)

/******************************************************************************/
// Row/column/element manipulation

registerFunction("row", "m:n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local k
	
	if rv2 < 1 then k = 1
	elseif rv2 > 3 then k = 3
	else k = rv2 - rv2 % 1 end
	
	x = rv1[k * 3 - 2]
	y = rv1[k * 3 - 1]
	z = rv1[k * 3]
	return { x, y, z }
end)

registerFunction("column", "m:n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 3 then k = 3
	else k = rv2 - rv2 % 1 end
	
	x = rv1[k]
	y = rv1[k + 3]
	z = rv1[k + 6]
	return { x, y, z }
end)

registerFunction("setRow", "m:nnnn", "m", function(self, args)
	local op1, op2, op3, op4, op5 = args[2], args[3], args[4], args[5], args[6]
	local rv1, rv2, rv3, rv4, rv5 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4), op5[1](self, op5)
	local k
	
	if rv2 < 1 then k = 1
	elseif rv2 > 3 then k = 3
	else k = rv2 - rv2 % 1 end
	
	local a = clone(rv1)
	a[k * 3 - 2] = rv3
	a[k * 3 - 1] = rv4
	a[k * 3] = rv5
	return a
end)

registerFunction("setRow", "m:nv", "m", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local k
	
	if rv2 < 1 then k = 1
	elseif rv2 > 3 then k = 3
	else k = rv2 - rv2 % 1 end
	
	local a = clone(rv1)
	a[k * 3 - 2] = rv3[1]
	a[k * 3 - 1] = rv3[2]
	a[k * 3] = rv3[3]
	return a
end)

registerFunction("setColumn", "m:nnnn", "m", function(self, args)
	local op1, op2, op3, op4, op5 = args[2], args[3], args[4], args[5], args[6]
	local rv1, rv2, rv3, rv4, rv5 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4), op5[1](self, op5)
	local k
	
	if rv2 < 1 then k = 1
	elseif rv2 > 3 then k = 3
	else k = rv2 - rv2 % 1 end
	
	local a = clone(rv1)
	a[k] = rv3
	a[k + 3] = rv4
	a[k + 6] = rv5
	return a
end)

registerFunction("setColumn", "m:nv", "m", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local k
	
	if rv2 < 1 then k = 1
	elseif rv2 > 3 then k = 3
	else k = rv2 - rv2 % 1 end
	
	local a = clone(rv1)
	a[k] = rv3[1]
	a[k + 3] = rv3[2]
	a[k + 6] = rv3[3]
	return a
end)

registerFunction("swapRows", "m:nn", "m", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local r1, r2
	
	if rv2 < 1 then r1 = 1
	elseif rv2 > 3 then r1 = 3
	else r1 = rv2 - rv2 % 1 end
	if rv3 < 1 then r2 = 1
	elseif rv3 > 3 then r2 = 3
	else r2 = rv3 - rv3 % 1 end
	
	if r1 == r2 then return rv1
	elseif (r1 == 1 && r2 == 2) || (r1 == 2 && r2 == 1) then
		rv1 = { rv1[4], rv1[5], rv1[6],
				rv1[1], rv1[2], rv1[3],
				rv1[7], rv1[8], rv1[9] }
	elseif (r1 == 2 && r2 == 3) || (r1 == 3 && r2 == 2) then
		rv1 = { rv1[1], rv1[2], rv1[3],
				rv1[7], rv1[8], rv1[9],
				rv1[4], rv1[5], rv1[6] }	
	elseif (r1 == 1 && r2 == 3) || (r1 == 3 && r2 == 1) then
		rv1 = { rv1[7], rv1[8], rv1[9],
				rv1[4], rv1[5], rv1[6],
				rv1[1], rv1[2], rv1[3] }	
	end
	return rv1
end)

registerFunction("swapColumns", "m:nn", "m", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local r1, r2
	
	if rv2 < 1 then r1 = 1
	elseif rv2 > 3 then r1 = 3
	else r1 = rv2 - rv2 % 1 end
	if rv3 < 1 then r2 = 1
	elseif rv3 > 3 then r2 = 3
	else r2 = rv3 - rv3 % 1 end
	
	if r1 == r2 then return rv1
	elseif (r1 == 1 && r2 == 2) || (r1 == 2 && r2 == 1) then
		rv1 = { rv1[2], rv1[1], rv1[3],
				rv1[5], rv1[4], rv1[6],
				rv1[8], rv1[7], rv1[9] }
	elseif (r1 == 2 && r2 == 3) || (r1 == 3 && r2 == 2) then
		rv1 = { rv1[1], rv1[3], rv1[2],
				rv1[4], rv1[6], rv1[5],
				rv1[7], rv1[9], rv1[8] }
	elseif (r1 == 1 && r2 == 3) || (r1 == 3 && r2 == 1) then
		rv1 = { rv1[3], rv1[2], rv1[1],
				rv1[6], rv1[5], rv1[4],
				rv1[9], rv1[8], rv1[7] }
	end
	return rv1
end)

registerFunction("element", "m:nn", "n", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local i, j	
	
	if rv2 < 1 then i = 1
	elseif rv2 > 3 then i = 3
	else i = rv2 - rv2 % 1 end
	if rv3 < 1 then j = 1
	elseif rv3 > 3 then j = 3
	else j = rv3 - rv3 % 1 end
	
	local k = i + (j - 1) * 3
	return rv1[k]
end)

registerFunction("setElement", "m:nnn", "m", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	local i, j

	if rv2 < 1 then i = 1
	elseif rv2 > 3 then i = 3
	else i = rv2 - rv2 % 1 end
	if rv3 < 1 then j = 1
	elseif rv3 > 3 then j = 3
	else j = rv3 - rv3 % 1 end
	
	local a = clone(rv1)
	a[i + (j - 1) * 3] = rv4
	return a
end)

registerFunction("swapElements", "m:nnnn", "m", function(self, args)
	local op1, op2, op3, op4, op5 = args[2], args[3], args[4], args[5], args[6]
	local rv1, rv2, rv3, rv4, rv5 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4), op5[1](self, op5)
	local i1, j1, i2, j2

	if rv2 < 1 then i1 = 1
	elseif rv2 > 3 then i1 = 3
	else i1 = rv2 - rv2 % 1 end
	
	if rv3 < 1 then j1 = 1
	elseif rv3 > 3 then j1 = 3
	else j1 = rv3 - rv3 % 1 end
	
	if rv4 < 1 then i2 = 1
	elseif rv4 > 3 then i2 = 3
	else i2 = rv4 - rv4 % 1 end
	
	if rv5 < 1 then j2 = 1
	elseif rv5 > 3 then j2 = 3
	else j2 = rv5 - rv5 % 1 end
	
	local k1 = i1 + (j1 - 1) * 3
	local k2 = i2 + (j2 - 1) * 3
	local a = clone(rv1)
	a[k1], a[k2] = rv1[k2], rv1[k1]
	return a
end)

/******************************************************************************/
// Useful matrix maths functions

registerFunction("diagonal", "m", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[5], rv1[9] }
end)

registerFunction("trace", "m", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return ( rv1[1] + rv1[5] + rv1[9] )
end)

registerFunction("det", "m", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return ( det3(rv1) )
end)

registerFunction("transpose", "m", "m", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[4], rv1[7],
			 rv1[2], rv1[5], rv1[8],
			 rv1[3], rv1[6], rv1[9] }
end)

registerFunction("adj", "m", "m", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[5] * rv1[9] - rv1[8] * rv1[6],	rv1[8] * rv1[3] - rv1[2] * rv1[9],	rv1[2] * rv1[6] - rv1[5] * rv1[3],
			 rv1[7] * rv1[6] - rv1[4] * rv1[9],	rv1[1] * rv1[9] - rv1[7] * rv1[3],	rv1[4] * rv1[3] - rv1[1] * rv1[6],
			 rv1[4] * rv1[8] - rv1[7] * rv1[5],	rv1[7] * rv1[2] - rv1[1] * rv1[8],	rv1[1] * rv1[5] - rv1[4] * rv1[2] }
end)

/******************************************************************************/
// Extra functions

registerFunction("matrix", "e", "m", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then
		return { 0, 0, 0,
				 0, 0, 0,
				 0, 0, 0 }
	end
	local x = rv1:GetForward()
	local y = rv1:GetRight()
	local z = rv1:GetUp()
	return { x.x, x.y, x.z,
			 y.x, y.y, y.z,
			 z.x, z.y, z.z }
end)

registerFunction("forward", "m:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[2], rv1[3] }
end)

registerFunction("right", "m:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[4], rv1[5], rv1[6] }
end)

registerFunction("up", "m:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[7], rv1[8], rv1[9] }
end)
