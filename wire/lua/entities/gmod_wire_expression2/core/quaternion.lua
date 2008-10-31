/******************************************************************************\
  Quaternion support
\******************************************************************************/

// TODO: implement more!

/******************************************************************************/

registerFunction("quat", "nnnn", "q", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	return { rv1, rv2, rv3, rv4 }
end)

/******************************************************************************/

registerOperator("ass", "q", "q", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv2 = op2[1](self, op2)
	self.vars[op1] = rv2
	return rv2
end)

/******************************************************************************/
// TODO: define division as multiplication with (1/x), or is it not useful?

registerOperator("neg", "q", "q", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { -rv1[1], -rv1[2], -rv1[3], -rv1[4] }
end)

registerOperator("add", "qq", "q", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] + rv2[1], rv1[2] + rv2[2], rv1[3] + rv2[3], rv1[4] + rv2[4] }
end)

registerOperator("sub", "qq", "q", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3], rv1[4] - rv2[4] }
end)

registerOperator("mul", "nq", "q", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 * rv2[1], rv1 * rv2[2], rv1 * rv2[3], rv1 * rv2[4] }
end)

registerOperator("mul", "qn", "q", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2, rv1[2] * rv2, rv1[3] * rv2, rv1[4] * rv2 }
end)

registerOperator("mul", "qq", "q", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local rv11, rv12, rv13, rv14 = rv1[1], rv1[2], rv1[3], rv1[4]
	local rv21, rv22, rv23, rv24 = rv2[1], rv2[2], rv2[3], rv2[4]
	return { rv11 * rv21 - rv12 * rv22 - rv13 * rv23 - rv14 * rv24,
	         rv11 * rv22 + rv12 * rv21 + rv13 * rv24 - rv14 * rv23,
	         rv11 * rv23 + rv13 * rv21 + rv14 * rv22 - rv12 * rv24,
	         rv11 * rv24 + rv14 * rv21 + rv12 * rv23 - rv13 * rv22 }
end)

/******************************************************************************/

registerOperator("eq", "qq", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local rvd1, rvd2, rvd3, rvd4 = rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3], rv1[4] - rv2[4]
	if rvd1 <= delta && rvd1 >= -delta &&
	   rvd2 <= delta && rvd2 >= -delta &&
	   rvd3 <= delta && rvd3 >= -delta &&
	   rvd4 <= delta && rvd4 >= -delta
	   then return 1 else return 0 end
end)

registerOperator("neq", "qq", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local rvd1, rvd2, rvd3, rvd4 = rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3], rv1[4] - rv2[4]
	if rvd1 > delta || rvd1 < -delta ||
	   rvd2 > delta || rvd2 < -delta ||
	   rvd3 > delta || rvd3 < -delta ||
	   rvd4 > delta || rvd4 < -delta
	   then return 1 else return 0 end
end)

/******************************************************************************/

registerFunction("xaxis", "q:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local rv11, rv12, rv13, rv14 = rv1[1], rv1[2], rv1[3], rv1[4]
	local t2, t3, t4 = rv12 * 2, rv13 * 2, rv14 * 2
	return { 1.0 - t3 * rv13 - t4 * rv14,
	               t3 * tv12 + t4 * rv11,
				   t4 * rv12 + t3 * rv11 }
end)

// TODO: yaxis, zaxis!
