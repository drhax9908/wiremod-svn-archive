AddCSLuaFile('wirelink.lua')

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
	if(entity and entity.extended and (entity.WriteCell or entity.ReadCell)) then return 1 else return 0 end
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
	if(!entity or !entity.extended) then return end
	if !entity.Inputs[rv2] then return end
	if entity.Inputs[rv2].Type != "NORMAL" then return end
	entity.Inputs[rv2].Value = rv3
	if(entity.TriggerInput == nil)then return end
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


registerFunction("setVector", "xwl:sv", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local entity = checkEntity(rv1)
	if(!entity or !entity.extended) then return end
	if !entity.Inputs[rv2] then return end
	if entity.Inputs[rv2].Type != "VECTOR" then return end
	local vec = Vector(rv3[1], rv3[2], rv3[3])
	entity.Inputs[rv2].Value = vec
	if(entity.TriggerInput == nil)then return end
	entity:TriggerInput(rv2, vec)
end)

registerFunction("vector", "xwl:s", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local entity = checkEntity(rv1)
	if(!entity or !entity.extended) then return {0,0,0} end
	if !entity.Outputs[rv2] then return {0,0,0} end
	if entity.Outputs[rv2].Type != "VECTOR" then return {0,0,0} end
	local vec = entity.Outputs[rv2].Value
	return { vec.x, vec.y, vec.z }
end)


registerFunction("setEntity", "xwl:se", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local entity = checkEntity(rv1)
	if(!entity or !entity.extended) then return end
	if !entity.Inputs[rv2] then return end
	if entity.Inputs[rv2].Type != "ENTITY" then return end
	entity.Inputs[rv2].Value = rv3
	if(entity.TriggerInput == nil)then return end
	entity:TriggerInput(rv2, rv3)
end)

registerFunction("entity", "xwl:s", "e", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local entity = checkEntity(rv1)
	if(!entity or !entity.extended) then return nil end
	if !entity.Outputs[rv2] then return nil end
	if entity.Outputs[rv2].Type != "ENTITY" then return nil end
	return entity.Outputs[rv2].Value
end)


registerFunction("setString", "xwl:ss", "", function(self, args)
    local op1, op2, op3 = args[2], args[3], args[4]
    local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
    local entity = checkEntity(rv1)
    if(!entity or !entity.extended) then return end
    if !entity.Inputs[rv2] then return end
    if entity.Inputs[rv2].Type != "STRING" then return end
	entity.Inputs[rv2].Value = rv3
	if(entity.TriggerInput == nil)then return end
    entity:TriggerInput(rv2, rv3)
end)

registerFunction("string", "xwl:s", "s", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
    local entity = checkEntity(rv1)
    if(!entity or !entity.extended) then return "" end
    if !entity.Outputs[rv2] then return "" end
    if entity.Outputs[rv2].Type != "STRING" then return "" end
    return entity.Outputs[rv2].Value
end)


registerFunction("setXyz", "xwl:v", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local entity = checkEntity(rv1)
	if(!entity or !entity.extended) then return end
	if !entity.Inputs["X"] || !entity.Inputs["Y"] || !entity.Inputs["Z"] then return end
	if entity.Inputs["X"].Type != "NORMAL" || entity.Inputs["Y"].Type != "NORMAL" || entity.Inputs["Z"].Type != "NORMAL" then return end
	entity.Inputs["X"].Value = rv2[1]
	entity.Inputs["Y"].Value = rv2[2]
	entity.Inputs["Z"].Value = rv2[3]
	if(entity.TriggerInput == nil)then return end
	entity:TriggerInput("X", rv2[1])
	entity:TriggerInput("Y", rv2[2])
	entity:TriggerInput("Z", rv2[3])
end)

registerFunction("xyz", "xwl:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity or !entity.extended) then return {0,0,0} end
	if !entity.Outputs["X"] || !entity.Outputs["Y"] || !entity.Outputs["Z"] then return {0,0,0} end
	if entity.Outputs["X"].Type != "NORMAL" || entity.Outputs["Y"].Type != "NORMAL" || entity.Outputs["Z"].Type != "NORMAL" then return {0,0,0} end
	return { entity.Outputs["X"].Value, entity.Outputs["Y"].Value, entity.Outputs["Z"].Value }
end)

/******************************************************************************/

registerFunction("writeCell", "xwl:nn", "n", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local entity = checkEntity(rv1)
	if(!entity or !entity.extended) then return 0 end
	if !entity.WriteCell then return 0 end
	
	if entity:WriteCell(rv2, rv3)
	   then return 1 else return 0 end
end)

registerFunction("readCell", "xwl:n", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local entity = checkEntity(rv1)
	if(!entity or !entity.extended) then return 0 end
	if !entity.ReadCell then return 0 end
	
	local ret = entity:ReadCell(rv2)
	if ret then return ret else return 0 end
end)

/******************************************************************************/

local function WriteString(entity, string, X, Y, Tcolour, Bgcolour, Flash)
    entity=checkEntity(entity)
    if (!entity or !entity.extended or !entity.WriteCell) then return end
    Tcolour = Tcolour - Tcolour % 1
	Bgcolour = Bgcolour - Bgcolour % 1
	Flash = Flash - Flash % 1
	local Params = (Flash%10)*1000000 + (Bgcolour%1000)*1000 + (Tcolour % 1000)
    for N = 1,string:len() do
        local Address = 2*(X+N-1+30*Y)
        if (Address>1080 or Address<0) then return end
        local Byte = string.byte(string,N)
        if (entity:ReadCell(Address)!=Byte) then
            entity:WriteCell(Address,Byte)
		end
		if (entity:ReadCell(Address+1)!=Params) then
            entity:WriteCell(Address+1,Params)
        end
    end
end

registerFunction("writeString","xwl:snnnnn", "", function(self,args)
	local op1, op2, op3, op4, op5, op6, op7 = args[2], args[3], args[4], args[5], args[6], args[7], args[8]
	local rv1, rv2, rv3, rv4, rv5, rv6, rv7 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3), op4[1](self,op4), op5[1](self,op5), op6[1](self,op6), op7[1](self,op7)
	WriteString(rv1,rv2,rv3,rv4,rv5,rv6,rv7)
end)

registerFunction("writeString","xwl:snnnn", "", function(self,args)
	local op1, op2, op3, op4, op5, op6 = args[2], args[3], args[4], args[5], args[6], args[7]
	local rv1, rv2, rv3, rv4, rv5, rv6 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3), op4[1](self,op4), op5[1](self,op5), op6[1](self,op6)
	WriteString(rv1,rv2,rv3,rv4,rv5,rv6,0)
end)

registerFunction("writeString","xwl:snnn", "", function(self,args)
	local op1, op2, op3, op4, op5 = args[2], args[3], args[4], args[5], args[6]
	local rv1, rv2, rv3, rv4, rv5 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3), op4[1](self,op4), op5[1](self,op5)
	WriteString(rv1,rv2,rv3,rv4,rv5,0,0)
end)

registerFunction("writeString","xwl:snn", "", function(self,args)
	local op1, op2, op3, op4, op5 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4, rv5 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3), op4[1](self,op4)
	WriteString(rv1,rv2,rv3,rv4,999,0,0)
end)
