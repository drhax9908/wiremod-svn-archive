AddCSLuaFile('constraint.lua')

/******************************************************************************\
  Constraint support V1.5
\******************************************************************************/

//---------------------------//
//--Helper Functions--//
//---------------------------//

local function formatString(text)
    local constxt = string.upper(string.Left(text,1))..string.lower(string.Right(text,string.len(text)-1))
	if(constxt=="Nocollide")then return "NoCollide" end
	if(constxt=="Advballsocket")then return "AdvBallsocket" end
	return constxt
end

local function ent1or2(ent,con,num)
	if(!con)then return nil end
	if(type(num)=="number")then
		con = con[num]
		if(!con)then return nil end
	end
	if(con["Ent1"]==ent) then return con["Ent2"] end
	return con["Ent1"]
end

/******************************************************************************/

registerFunction("getConstraints", "e:", "r", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    local entity = checkEntity(rv1)
	if(!entity) then return 0 end
    if(constraint.HasConstraints(rv1))then
	local keytable = table.ClearKeys(constraint.GetAllConstrainedEntities(rv1),false)
	local array = {}
	local count = 0
		for k,v in pairs(keytable) do
			if v!=rv1 && validEntity(v) then
				count = count + 1
				array[count] = v
			end
		end
	return array
    end
    return {}
end)

registerFunction("hasConstraints", "e:", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    local entity = checkEntity(rv1)
	if(!entity) then return 0 end
    	if ( !entity.Constraints ) then return 0 end
	local count = 0
	for k, v in pairs( entity.Constraints ) do
		if ( !v || !v:IsValid() ) then
			entity.Constraints[ k ] = nil
		else
			count = count + 1
		end
	end
    return count
end)

registerFunction("hasConstraints", "e:s", "n", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
    local entity = checkEntity(rv1)
	if(!entity) then return 0 end
    local constype = formatString(rv2)
		local ConTable = constraint.GetTable(entity)
		local count = 0
    	for k, con in ipairs( ConTable ) do
		if ( con.Type == constype ) then
			count = count + 1
		end
	end
    return count
end)

registerFunction("isConstrained", "e:", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    local entity = checkEntity(rv1)
	if(!entity) then return 0 end
    if(constraint.HasConstraints(rv1))then return 1 end
    return 0
end)

registerFunction("isWeldedTo", "e:", "e", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    local entity = checkEntity(rv1)
	if(!entity) then return nil end
    if(constraint.HasConstraints(rv1))then
	return ent1or2(rv1,constraint.FindConstraint( rv1, "Weld" ),true)
    end
    return nil
end)

registerFunction("isWeldedTo", "e:n", "e", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	rv2 = rv2 - rv2 % 1
    local entity = checkEntity(rv1)
	if(!entity) then return nil end
    if(constraint.HasConstraints(rv1))then
	return ent1or2(rv1,constraint.FindConstraints( rv1, "Weld" ),rv2)
    end
    return nil
end)

registerFunction("isConstrainedTo", "e:", "e", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    local entity = checkEntity(rv1)
	if(!entity) then return nil end
    if(constraint.HasConstraints(rv1))then
	for _,v in pairs(rv1.Constraints)do
	    if(v && v:IsValid())then
		return ent1or2(rv1,v,true)
	    else
		rv1.Constraints[k] = nil
	    end
	end
    end
    return nil
end)

registerFunction("isConstrainedTo", "e:n", "e", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	rv2 = rv2 - rv2 % 1
    local entity = checkEntity(rv1)
	if(!entity) then return 0 end
    if(constraint.HasConstraints(rv1))then
	return ent1or2(rv1,rv1.Constraints,rv2)
    end
    return nil
end)

registerFunction("isConstrainedTo", "e:s", "e", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
    local entity = checkEntity(rv1)
	if(!entity) then return nil end
    local constype = formatString(rv2)
    if(constraint.HasConstraints(rv1))then
	local con = constraint.FindConstraintEntity(rv1, constype)
	return ent1or2(rv1,con,true)
    end
    return nil
end)

registerFunction("isConstrainedTo", "e:sn", "e", function(self, args)
    local op1, op2, op3 = args[2], args[3], args[4]
    local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	rv3 = rv3 - rv3 % 1
    local entity = checkEntity(rv1)
	if(!entity) then return nil end
    local constype = formatString(rv2)
    if(constraint.HasConstraints(rv1))then
	return ent1or2(rv1,constraint.FindConstraints( rv1, constype ),rv3)
    end
    return nil
end)