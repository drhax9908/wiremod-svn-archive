/******************************************************************************\
  Wire link support
\******************************************************************************/

registerType("wirelink", "xwl", nil)

/******************************************************************************/

registerOperator("ass", "xwl", "xwl", function(self, args)
	local op1, op2 = args[2], args[3]
	rv2 = op2[1](self, op2)
	self.vars[op1] = rv2
	self.vclk[op1] = true
	return rv2
end)

/******************************************************************************/

registerOperator("is", "xwl", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(entity and entity.extended) then return 1 else return 0 end
end)

registerOperator("eq", "xwlxwl", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1 == rv2 then return 1 else return 0 end
end)

registerOperator("neq", "xwlxwl", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1 != rv2 then return 1 else return 0 end
end)

/******************************************************************************/

registerFunction("isHiSpeed", "xwl:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(entity and entity.extended and (entity.writeCell or entity.readCell)) then return 1 else return 0 end
end)

registerFunction("entity", "xwl:", "e", function(self, args)
	local op1 = args[2]
	return op1[1](self, op1)
end)

/******************************************************************************/

registerFunction("hasInput", "xwl:s", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local entity = checkEntity(rv1)
	if(!entity or !entity.extended) then return 0 end
	if !entity.Inputs[rv2] then return 0 end
	return 1
end)

registerFunction("hasOutput", "xwl:s", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local entity = checkEntity(rv1)
	if(!entity or !entity.extended) then return 0 end
	if !entity.Outputs[rv2] then return 0 end
	return 1
end)

/******************************************************************************/
// THESE NEED TO USE THE INPUT/OUTPUT SERIALIZERS! (not numbers)
// THE VALUES SHOULD BE SAVED AND PUSHED ON POST EXECUTION

registerFunction("setNumber", "xwl:sn", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local entity = checkEntity(rv1)
	if(!entity or !entity.extended) then return 0 end
	if !entity.Inputs[rv2] then return 0 end
	if entity.Inputs[rv2].Type != "NORMAL" then return 0 end
	entity:TriggerInput(rv2, rv3)
end)

registerFunction("number", "xwl:s", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local entity = checkEntity(rv1)
	if(!entity or !entity.extended) then return 0 end
	if !entity.Outputs[rv2] then return 0 end
	if entity.Outputs[rv2].Type != "NORMAL" then return 0 end
	return entity.Outputs[rv2].Value
end)

/******************************************************************************/

registerFunction("writeCell", "xwl:nn", "n", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local entity = checkEntity(rv1)
	if(!entity or !entity.extended) then return 0 end
	if !entity.writeCell then return 0 end
	
	if entity:writeCell(rv2, rv3)
	   then return 1 else return 0 end
end)

registerFunction("readCell", "xwl:n", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local entity = checkEntity(rv1)
	if(!entity or !entity.extended) then return 0 end
	if !entity.readCell then return 0 end
	
	local ret = entity:readCell(rv2)
	if ret then return ret else return 0 end
end)
