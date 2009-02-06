AddCSLuaFile('array.lua')

/******************************************************************************\
  Array support
\******************************************************************************/

E2_MAX_ARRAY_SIZE = 1024*1024	// 1MB

/******************************************************************************/

registerType("array", "r", {},
	function(self, input)
		local ret = {}
		for k,v in ipairs(input) do ret[k] = v end
		return ret
	end,
	function(self, output) return output end
)

/******************************************************************************/

registerFunction("array", "", "r", function(self, args)
	return {}
end)

/******************************************************************************/

registerOperator("ass", "r", "r", function(self, args)
	local op1, op2 = args[2], args[3]
	local      rv2 = op2[1](self, op2)
	self.vars[op1] = rv2
	self.vclk[op1] = true
	return rv2
end)

/******************************************************************************/

registerOperator("is", "r", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return (type(rv1) == "table") and 1 or 0
end)

/******************************************************************************/

registerFunction("count", "r:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return table.getn(rv1)
end)

/******************************************************************************/

registerFunction("clone", "r:", "r", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = {}
	for k,v in ipairs(rv1) do ret[k] = v end
	return ret
end)

/******************************************************************************/

registerFunction("number", "r:n", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1[rv2]
	if ret then return tonumber(ret) end
	return 0
end)

registerFunction("setNumber", "r:nn", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if(rv2 >= E2_MAX_ARRAY_SIZE) then return end
	if rv3 == 0 then rv3 = nil end
	rv1[rv2] = rv3
	self.vclk[op1] = true
end)


registerFunction("vector", "r:n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1[rv2]
	if type(ret) == "table" and table.getn(ret) == 3 then return ret end
	return { 0, 0, 0 }
end)

registerFunction("setVector", "r:nv", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if(rv2 >= E2_MAX_ARRAY_SIZE) then return end
	if rv3[1] == 0 and rv3[2] == 0 and rv3[3] == 0 then rv3 = nil end
	rv1[rv2] = rv3
	self.vclk[op1] = true
end)


registerFunction("angle", "r:n", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1[rv2]
	if type(ret) == "table" and table.getn(ret) == 3 then return ret end
	return { 0, 0, 0 }
end)

registerFunction("setAngle", "r:na", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if(rv2 >= E2_MAX_ARRAY_SIZE) then return end
	if rv3[1] == 0 and rv3[2] == 0 and rv3[3] == 0 then rv3 = nil end
	rv1[rv2] = rv3
	self.vclk[op1] = true
end)


registerFunction("string", "r:n", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1[rv2]
	if ret then return tostring(ret) end
	return ""
end)

registerFunction("setString", "r:ns", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if(rv2 >= E2_MAX_ARRAY_SIZE) then return end
	if rv3 == "" then rv3 = nil end
	rv1[rv2] = rv3
	self.vclk[op1] = true
end)

registerFunction("entity", "r:n", "e", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1[rv2]
	if validEntity(ret) then return ret end
	return nil
end)

registerFunction("setEntity", "r:ne", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if(rv2 >= E2_MAX_ARRAY_SIZE) then return end
	rv1[rv2] = rv3
	self.vclk[op1] = true
end)

/******************************************************************************/

registerFunction("pushNumber", "r:n", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	if (rv2 == 0) then rv2=nil end
	table.insert(rv1,rv2)
	return
end)

registerFunction("popNumber", "r:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1)
	if ret then return tonumber(ret) end
	return 0
end)

registerFunction("pushVector", "r:v", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	if rv2[1] == 0 and rv2[2] == 0 and rv2[3] == 0 then rv2 = nil end
	table.insert(rv1,rv2)
	return
end)

registerFunction("popVector", "r:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1)
	if type(ret) == "table" and table.getn(ret) == 3 then return ret end
	return { 0, 0, 0 }
end)

registerFunction("pushString", "r:s", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	if (rv2 == "") then rv2=nil end
	table.insert(rv1,rv2)
	return
end)

registerFunction("popString", "r:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1)
	if ret then return tostring(ret) end
	return ""	
end)

registerFunction("pushEntity", "r:e", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	table.insert(rv1,rv2)
end)

registerFunction("popEntity", "r:", "e", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = table.remove(rv1)
	if validEntity(ret) then return ret end
	return nil
end)

registerFunction("pop", "r:", "", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	table.remove(rv1)
	return
end)

/******************************************************************************/

registerFunction("insertNumber", "r:nn", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	if (rv3 == 0) then rv3=nil end
	table.insert(rv1,rv2,rv3)
end)

registerFunction("removeNumber", "r:n", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = table.remove(rv1,rv2)
	if ret then return tonumber(ret) end
	return 0
end)

registerFunction("insertVector", "r:nv", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	if rv3[1] == 0 and rv3[2] == 0 and rv3[3] == 0 then rv3 = nil end
	table.insert(rv1,rv2,rv3)
end)

registerFunction("removeVector", "r:n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = table.remove(rv1,rv2)
	if type(ret) == "table" and table.getn(ret) == 3 then return ret end
	return { 0, 0, 0 }
end)

registerFunction("insertString", "r:ns", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	if (rv3 == "") then rv3=nil end
	table.insert(rv1,rv2,rv3)
end)

registerFunction("removeString", "r:n", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = table.remove(rv1,rv2)
	if ret then return tostring(ret) end
	return ""
end)

registerFunction("insertEntity", "r:ne", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	table.insert(rv1,rv2,rv3)
end)

registerFunction("removeEntity", "r:n", "e", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = table.remove(rv1,rv2)
	if validEntity(ret) then return ret end
	return nil
end)

registerFunction("remove", "r:n", "", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	table.remove(rv1,rv2)
	return
end)

/******************************************************************************/

registerFunction("unshiftNumber", "r:n", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	if (rv2 == 0) then rv2=nil end
	table.insert(rv1,1,rv2)
	return
end)

registerFunction("shiftNumber", "r:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1,1)
	if ret then return tonumber(ret) end
	return 0
end)

registerFunction("unshiftVector", "r:v", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	if rv2[1] == 0 and rv2[2] == 0 and rv2[3] == 0 then rv2 = nil end
	table.insert(rv1,1,rv2)
	return
end)

registerFunction("shiftVector", "r:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1,1)
	if type(ret) == "table" and table.getn(ret) == 3 then return ret end
	return { 0, 0, 0 }
end)

registerFunction("unshiftString", "r:s", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	if (rv2 == "") then rv2=nil end
	table.insert(rv1,1,rv2)
	return
end)

registerFunction("shiftString", "r:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1,1)
	if ret then return tostring(ret) end
	return ""
end)

registerFunction("unshiftEntity", "r:e", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	table.insert(rv1,1,rv3)
	return
end)

registerFunction("shiftEntity", "r:", "e", function(self, args)
	local op1 = args[2]
	local rv1= op1[1](self, op1)
	local ret = table.remove(rv1,1)
	if validEntity(ret) then return ret end
	return nil
end)

registerFunction("shift", "r:", "", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	table.remove(rv1,1)
	return
end)

/******************************************************************************/

registerFunction("sum", "r:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local out = 0
	for _,value in ipairs(rv1) do
		out = out + tonumber(value)
	end
	return out
end)

registerFunction("average", "r:", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    local totalValue = 0
    local totalIndex = 0
    local averageValue = 0
    for k,v in ipairs(rv1) do
        if type( v ) == "number" then
            totalValue = totalValue + rv1[k]
            totalIndex = totalIndex + 1
        end
    end
    averageValue = totalValue / totalIndex
    return averageValue
end)


registerFunction("min", "r:", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    local min = nil
    for k,v in ipairs(rv1) do
        if type( v ) == "number" then
            if min == nil || v < min then
                min = rv1[k]
            end
        end
    end
    if min == nil then min = 0 end
    local ret = min
    min = nil
    return ret
end)
 
registerFunction("minIndex", "r:", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    local minIndex = 0
    local min = nil
    for k,v in ipairs(rv1) do
        if type( v ) == "number" then
            if min == nil || v < min then
                min = rv1[k]
                minIndex = k
            end
        end
    end
    if min == nil then min = 0 end
    local ret = minIndex
    min = nil
    return ret
end)
 
registerFunction("max", "r:", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    local ret = 0
    for k,v in ipairs(rv1) do
        if type( v ) == "number" then
            if v > ret then
                ret = rv1[k]
            end
        end
    end
    return ret
end)
 
registerFunction("maxIndex", "r:", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    local retIndex = 0
    local ret = 0
    for k,v in ipairs(rv1) do
        if type( v ) == "number" then
            if v > ret then
                ret = rv1[k]
                retIndex = k
            end
        end
    end
    return retIndex
end)

/******************************************************************************/

registerFunction("concat", "r:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local out = ""
	for _,value in ipairs(rv1) do
		out = out .. tostring(value)
	end
	return out
end)

registerFunction("concat", "r:s", "s", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
    local out = ""
    for _,value in ipairs(rv1) do
        out = out .. tostring(value) .. tostring(rv2)
    end
    return string.Left(out, string.len(out) - string.len(tostring(rv2)))
end)
