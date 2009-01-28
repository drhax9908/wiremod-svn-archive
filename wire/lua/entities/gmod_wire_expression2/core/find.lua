AddCSLuaFile('find.lua')


exp2Discoveries = {}

exp2LastPlayerFind = {}

exp2FindComparePoint = Vector(0,0,0)

exp2FindLastListCheck = 0

function exp2FindCleanup()
	local time = CurTime()
	if time - exp2FindLastListCheck < 900 then return end
	for entId,entry in pairs(exp2Discoveries) do
		if time - entry.lastAccess > 900 then //900 = 15 minutes
			exp2Discoveries[entId] = nil
		end
	end
end

function exp2FindOnRemove(entity)
	if not entity:IsValid() then return false end
	exp2Discoveries[entity:EntIndex()] = nil
end

if not ConVarExists("wire_exp2_entFindRate") then CreateConVar("wire_exp2_entFindRate", ".05") end
if not ConVarExists("wire_exp2_playerFindRate") then CreateConVar("wire_exp2_playerFindRate", ".01") end

local function initTable(entity)
	if not entity:IsValid() then return false end
	local id = entity:EntIndex()
	if exp2Discoveries[id] == nil then
		exp2Discoveries[id] = {}
		exp2Discoveries[id].entities = {}
		exp2Discoveries[id].whitePlayerList = {}
		exp2Discoveries[id].blackPlayerList = {}
		exp2Discoveries[id].whitePropList = {}
		exp2Discoveries[id].blackPropList = {}
		exp2Discoveries[id].whiteClassList = {}
		exp2Discoveries[id].blackClassList = {}
		exp2Discoveries[id].whiteModelList = {}
		exp2Discoveries[id].blackModelList = {}
		exp2Discoveries[id].whiteListInUse = false
		exp2Discoveries[id].lastFind = 0
		exp2Discoveries[id].lastAccess = 0
		local player = entity:GetOwner()
		if player == nil or (not player:IsValid()) then
			exp2Discoveries[id].playerId = 1
		else
			exp2Discoveries[id].playerId = player:SteamID()
		end
		exp2LastPlayerFind[exp2Discoveries[id].playerId] = 0
	end

	return true
end

local function canFindByTime(id)
	if exp2Discoveries[id] == nil then return end
	local time = CurTime()
	local entFindRate = GetConVarNumber("wire_exp2_entFindRate")
	//local playerFindRate = GetConVarNumber("wire_exp2_playerFindRate")
	return time - exp2Discoveries[id].lastFind >= entFindRate// and
	//	time - exp2LastPlayerFind[exp2Discoveries[id].playerId] >= playerFindRate
end

local function clipEntities(entity)
	if not entity:IsValid() then return end
	local id = entity:EntIndex()
	if exp2Discoveries[id] == nil then return end
	if exp2Discoveries[id].entities == nil then exp2Discoveries[id].entities = {} return end
	local indexOffset = 0
	for i = 1, table.Count(exp2Discoveries[id].entities), 1 do
		local ent = exp2Discoveries[id].entities[i - indexOffset]
		local entSteamId = nil
		if ent:IsPlayer() then entSteamId = ent:SteamID() end
		local entOwner = ent:GetOwner()
		if entOwner != nil && entOwner:IsValid() && entOwner:IsPlayer() then entOwner = entOwner:SteamID() end
		local entModel = ent:GetModel()
		if entModel != nil then
			entModel = string.lower(entModel)
		end
		local entClass = string.lower(ent:GetClass())
		local cont = true
		local found = false
		//ignore: the chip, info entities, predicted entities, physgun_beam, prop_dynamic
		if ent:EntIndex() == id || string.find(entClass,"info_") != nil 
				|| string.find(entClass,"predicted") != nil || entClass == "physgun_beam" || entClass == "prop_dynamic" 
				|| entClass == "player_manager" then 
			table.remove(exp2Discoveries[id].entities, i - indexOffset)
			indexOffset = indexOffset + 1
		else
			//black list
			for _,id  in pairs(exp2Discoveries[id].blackPlayerList) do
				if id == entSteamId then table.remove(exp2Discoveries[id].entities, i - indexOffset) cont = false indexOffset = indexOffset + 1 break end
			end
			if cont then for _,id  in pairs(exp2Discoveries[id].blackPropList) do
				if id == entOwner then table.remove(exp2Discoveries[id].entities, i - indexOffset) cont = false indexOffset = indexOffset + 1 break end
			end
			if cont then for _,model  in pairs(exp2Discoveries[id].blackModelList) do
				if string.find(entModel, model) != nil then table.remove(exp2Discoveries[id].entities, i - indexOffset) cont = false indexOffset = indexOffset + 1 break end
			end
			if cont then for _,class  in pairs(exp2Discoveries[id].blackClassList) do
				if string.find(entClass,class) then table.remove(exp2Discoveries[id].entities, i - indexOffset) cont = false indexOffset = indexOffset + 1 break end
			end end end end

			//white list
			if cont and exp2Discoveries[id].whiteListInUse then
				for _,id  in pairs(exp2Discoveries[id].whitePlayerList) do
					if id == entSteamId then found = true passKind = "player" break end
				end
				if not found then
					for _,id  in pairs(exp2Discoveries[id].whitePropList) do
						if id == entOwner then found = true passKind = "prop" break end
					end
				if not found then
					for _,model  in pairs(exp2Discoveries[id].whiteModelList) do
						if string.find(entModel,model) != nil then found = true passKind = "model" break end
					end
				if not found then

					for _,class in pairs(exp2Discoveries[id].whiteClassList) do
						if string.find(entClass,class) != nil then found = true passKind = "class" break end
					end
				if not found then
					table.remove(exp2Discoveries[id].entities, i - indexOffset)
					indexOffset = indexOffset + 1 

				end end end end
			end

		end
	end
end

registerFunction("findUpdateRate", "", "n", function(self,args)
	return GetConVarNumber("wire_exp2_entFindRate")
end)

registerFunction("findPlayerUpdateRate", "", "n", function(self,args)
	return GetConVarNumber("wire_exp2_playerFindRate")
end)

registerFunction("findInSphere", "vn", "n", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1),op2[1](self,op2)
	local id = self.entity:EntIndex()
	local canFind = initTable(self.entity)
	canFind = canFindByTime(id) and canFind
	if canFind then
		local time = CurTime()
		exp2Discoveries[id].entities = ents.FindInSphere(Vector(rv1[1],rv1[2],rv1[3]),rv2)
		clipEntities(self.entity)
		exp2Discoveries[id].lastFind = time
		exp2LastPlayerFind[exp2Discoveries[id].playerId] = time
		exp2Discoveries[id].lastAccess = time
		return table.Count(exp2Discoveries[id].entities)
	end
	return table.Count(exp2Discoveries[id].entities)
end)

registerFunction("findInCone", "vvnn", "n", function(self,args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self,op1),op2[1](self,op2),op3[1](self,op3),op4[1](self,op4)
	local id = self.entity:EntIndex()
	if initTable(self.entity) and canFindByTime(id) then
		local time = CurTime()
		exp2Discoveries[id].entities = ents.FindInCone(Vector(rv1[1],rv1[2],rv1[3]),Vector(rv2[1],rv2[2],rv2[3]),rv3,rv4)
		clipEntities(self.entity)
		exp2Discoveries[id].lastFind = time
		exp2LastPlayerFind[exp2Discoveries[id].playerId] = time
		exp2Discoveries[id].lastAccess = time
		return table.Count(exp2Discoveries[id].entities)
	end
	return table.Count(exp2Discoveries[id].entities)
end)

registerFunction("findInBox", "vv", "n", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1),op2[1](self,op2)
	local id = self.entity:EntIndex()
	if initTable(self.entity) and canFindByTime(id) then
		local time = CurTime()
		exp2Discoveries[id].lastFind = time
		exp2LastPlayerFind[exp2Discoveries[id].playerId] = time
		exp2Discoveries[id].entities = ents.FindInBox(Vector(rv1[1],rv1[2],rv1[3]),Vector(rv2[1],rv2[2],rv2[3]))
		clipEntities(self.entity)
		exp2Discoveries[id].lastAccess = time
		return table.Count(exp2Discoveries[id].entities)
	end
	return table.Count(exp2Discoveries[id].entities)
end)

registerFunction("findByName", "s", "n", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	local id = self.entity:EntIndex()
	if initTable(self.entity) and canFindByTime(id) then
		local time = CurTime()
		exp2Discoveries[id].lastFind = time
		exp2LastPlayerFind[exp2Discoveries[id].playerId] = time
		exp2Discoveries[id].entities = ents.FindByName(rv1)
		clipEntities(self.entity)
		exp2Discoveries[id].lastAccess = time
		return table.Count(exp2Discoveries[id].entities)
	end
	return table.Count(exp2Discoveries[id].entities)
end)

registerFunction("findByClass", "s", "n", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	local id = self.entity:EntIndex()
	if initTable(self.entity) and canFindByTime(id) then
		local time = CurTime()
		exp2Discoveries[id].lastFind = time
		exp2LastPlayerFind[exp2Discoveries[id].playerId] = time
		exp2Discoveries[id].entities = ents.FindByClass(rv1)
		clipEntities(self.entity)
		exp2Discoveries[id].lastAccess = time
		return table.Count(exp2Discoveries[id].entities)
	end
	return table.Count(exp2Discoveries[id].entities)
end)


registerFunction("findByModel", "s", "n", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	local id = self.entity:EntIndex()
	if initTable(self.entity) and canFindByTime(id) then
		local time = CurTime()
		exp2Discoveries[id].lastFind = time
		exp2LastPlayerFind[exp2Discoveries[id].playerId] = time
		exp2Discoveries[id].entities = ents.FindByModel(rv1)
		clipEntities(self.entity)
		exp2Discoveries[id].lastAccess = time
		return table.Count(exp2Discoveries[id].entities)
	end
	return table.Count(exp2Discoveries[id].entities)
end)

registerFunction("findPlayerByName", "s", "e", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	local id = self.entity:EntIndex()
	if initTable(self.entity) and canFindByTime(id) then
		local time = CurTime()
		exp2Discoveries[id].lastFind = time
		exp2LastPlayerFind[exp2Discoveries[id].playerId] = time
		local ents = ents.FindByClass("player")
		exp2Discoveries[id].lastAccess = time
		for _,ent in pairs(ents) do
			if string.find(ent:GetName(),rv1) != nil then return ent end
		end
	end
	return nil
end)

registerFunction("findExcludePlayer","e","", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	if not rv1:IsValid() then return end
	initTable(self.entity)
	local id = self.entity:EntIndex()
	if not table.HasValue(exp2Discoveries[id].blackPlayerList, rv1:SteamID()) then
		table.insert(exp2Discoveries[id].blackPlayerList, rv1:SteamID())
	end
end)

registerFunction("findExcludePlayer","s","", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	local plyr = ents.FindByName(rv1)
	if plyr != nil then rv1 = plyr[1] else 
		for _,player  in pairs(ents.FindByClass("player")) do
			if string.find(player:GetName(),rv1) != nil then rv1 = player break end
		end
	end
	if !rv1:IsValid() then return end
	initTable(self.entity)
	local id = self.entity:EntIndex()
	if not table.HasValue(exp2Discoveries[id].blackPlayerList, rv1:SteamID()) then
		table.insert(exp2Discoveries[id].blackPlayerList, rv1:SteamID())
	end
end)

registerFunction("findExcludePlayerProps","e","", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	if not rv1:IsValid() then return end
	initTable(self.entity)
	local id = self.entity:EntIndex()
	if not table.HasValue(exp2Discoveries[id].blackPropList, rv1:SteamID()) then
		table.insert(exp2Discoveries[id].blackPropList, rv1:SteamID())
	end
end)

registerFunction("findExcludePlayerProps","s","", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	local plyr = ents.FindByName(rv1)
	if plyr != nil then rv1 = plyr[1] else 
		for _,player  in pairs(ents.FindByClass("player")) do
			if string.find(player:GetName(),rv1) != nil then rv1 = player break end
		end
	end
	if !rv1:IsValid() || !rv1:IsPlayer() then return end
	initTable(self.entity)
	local id = self.entity:EntIndex()
	if not table.HasValue(exp2Discoveries[id].blackPropList, rv1:SteamID()) then
		table.insert(exp2Discoveries[id].blackPropList, rv1:SteamID())
	end
end)

registerFunction("findExcludeModel","s","", function(self,args)
	local op1 = args[2]
	local rv1 = string.lower(op1[1](self,op1))
	initTable(self.entity)
	local id = self.entity:EntIndex()
	if not table.HasValue(exp2Discoveries[id].blackModelList, rv1) then
		table.insert(exp2Discoveries[id].blackModelList, rv1)
	end
end)

registerFunction("findExcludeClass","s","", function(self,args)
	local op1 = args[2]
	local rv1 = string.lower(op1[1](self,op1))
	initTable(self.entity)
	local id = self.entity:EntIndex()
	if not table.HasValue(exp2Discoveries[id].blackClassList, rv1) then
		table.insert(exp2Discoveries[id].blackClassList, rv1)
	end
end)

registerFunction("findAllowPlayer","e","", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	if !rv1:IsValid() then return end
	initTable(self.entity)
	local id = self.entity:EntIndex()
	rv1 = rv1:SteamID()
	for i,pId in ipairs(exp2Discoveries[id].blackPlayerList) do
		if PId == rv1 then table.remove(exp2Discoveries[id].blackPlayerList, i) break end
	end
end)

registerFunction("findAllowPlayer","s","", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	rv1 = ents.FindByName(rv1)
	if rv1 != nil then rv1 = rv1[1] else return end
	if !rv1:IsValid() || !rv1:IsPlayer() then return end
	initTable(self.entity)
	local id = self.entity:EntIndex()
	rv1 = rv1:SteamID()
	for i,pId in ipairs(exp2Discoveries[id].blackPlayerList) do
		if PId == rv1 then table.remove(exp2Discoveries[id].blackPlayerList, i) break end
	end
end)

registerFunction("findAllowPlayerProps","e","", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	if !rv1:IsValid() then return end
	initTable(self.entity)
	local id = self.entity:EntIndex()
	rv1 = rv1:SteamID()
	for i,pId in ipairs(exp2Discoveries[id].blackPropList) do
		if pId == rv1 then table.remove(exp2Discoveries[id].blackPropList, i) break end
	end
end)

registerFunction("findAllowPlayerProps","s","", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	rv1 = ents.FindByName(rv1)
	if rv1 != nil then rv1 = rv1[1] else return end
	if !rv1:IsValid() || !rv1:IsPlayer() then return end
	initTable(self.entity)
	local id = self.entity:EntIndex()
	rv1 = rv1:SteamID()
	for i,pId in ipairs(exp2Discoveries[id].blackPropList) do
		if pId == rv1 then table.remove(exp2Discoveries[id].blackPropList, i) break end
	end
end)

registerFunction("findAllowModel","s","", function(self,args)
	local op1 = args[2]
	local rv1 = string.lower(op1[1](self,op1))
	initTable(self.entity)
	local id = self.entity:EntIndex()
	for i,model in ipairs(exp2Discoveries[id].blackModelList) do
		if model  == rv1 then table.remove(exp2Discoveries[id].blackModelList, i) break end
	end
end)

registerFunction("findAllowClass","s","", function(self,args)
	local op1 = args[2]
	local rv1 = string.lower(op1[1](self,op1))
	initTable(self.entity)
	local id = self.entity:EntIndex()
	for i,class in ipairs(exp2Discoveries[id].blackClassList) do
		if class == rv1 then table.remove(exp2Discoveries[id].blackClassList, i) break end
	end
end)

registerFunction("findIncludePlayer","e","", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	if not rv1:IsValid() then return end
	initTable(self.entity)
	local id = self.entity:EntIndex()
	if not table.HasValue(exp2Discoveries[id].whitePlayerList, rv1:SteamID()) then
		table.insert(exp2Discoveries[id].whitePlayerList, rv1:SteamID())
	end
	exp2Discoveries[id].whiteListInUse = true
end)

registerFunction("findIncludePlayer","s","", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	local plyr = ents.FindByName(rv1)
	if plyr != nil then rv1 = plyr[1] else 
		for _,player  in pairs(ents.FindByClass("player")) do
			if string.find(player:GetName(),rv1) != nil then rv1 = player break end
		end
	end
	if !rv1:IsValid() || !rv1:IsPlayer() then return end
	initTable(self.entity)
	local id = self.entity:EntIndex()
	if not table.HasValue(exp2Discoveries[id].whitePlayerList, rv1:SteamID()) then
		table.insert(exp2Discoveries[id].whitePlayerList, rv1:SteamID())
	end
	exp2Discoveries[id].whiteListInUse = true
end)

registerFunction("findIncludePlayerProps","e","", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	if not rv1:IsValid() then return end
	initTable(self.entity)
	local id = self.entity:EntIndex()
	if not table.HasValue(exp2Discoveries[id].whitePropList, rv1:SteamID()) then
		table.insert(exp2Discoveries[id].whitePropList, rv1:SteamID())
	end
	exp2Discoveries[id].whiteListInUse = true
end)

registerFunction("findIncludePlayerProps","s","", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	local plyr = ents.FindByName(rv1)
	if plyr != nil then rv1 = plyr[1] else 
		for _,player  in pairs(ents.FindByClass("player")) do
			if string.find(player:GetName(),rv1) != nil then rv1 = player break end
		end
	end
	if !rv1:IsValid() || !rv1:IsPlayer() then return end
	initTable(self.entity)
	local id = self.entity:EntIndex()
	if not table.HasValue(exp2Discoveries[id].whitePropList, rv1:SteamID()) then
		table.insert(exp2Discoveries[id].whitePropList, rv1:SteamID())
	end
	exp2Discoveries[id].whiteListInUse = true
end)

registerFunction("findIncludeModel","s","", function(self,args)
	local op1 = args[2]
	local rv1 = string.lower(op1[1](self,op1))
	initTable(self.entity)
	local id = self.entity:EntIndex()
	if not table.HasValue(exp2Discoveries[id].whiteModelList, rv1) then
		table.insert(exp2Discoveries[id].whiteModelList, rv1)
	end
	exp2Discoveries[id].whiteListInUse = true
end)

registerFunction("findIncludeClass","s","", function(self,args)
	local op1 = args[2]
	local rv1 = string.lower(op1[1](self,op1))
	initTable(self.entity)
	local id = self.entity:EntIndex()
	if not table.HasValue(exp2Discoveries[id].whiteClassList, rv1) then
		table.insert(exp2Discoveries[id].whiteClassList, rv1)
	end
	exp2Discoveries[id].whiteListInUse = true
end)

local function somethingInWhiteList(id)
	return #exp2Discoveries[id].whitePlayerList > 0 or
		#exp2Discoveries[id].whitePropList > 0 or
		#exp2Discoveries[id].whiteModelList > 0 or
		#exp2Discoveries[id].whiteClassList > 0
end

registerFunction("findDisallowPlayer","e","", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	if !rv1:IsValid() then return end
	initTable(self.entity)
	local id = self.entity:EntIndex()
	rv1 = rv1:SteamID()
	for i,pId in ipairs(exp2Discoveries[id].whitePlayerList) do
		if PId == rv1 then table.remove(exp2Discoveries[id].whitePlayerList, i) break end
	end
	exp2Discoveries[id].whiteListInUse = somethingInWhiteList(id)
end)

registerFunction("findDisallowPlayer","s","", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	rv1 = ents.FindByName(rv1)
	if rv1 != nil then rv1 = rv1[1] else return end
	if !rv1:IsValid() || !rv1:IsPlayer() then return end
	initTable(self.entity)
	local id = self.entity:EntIndex()
	rv1 = rv1:SteamID()
	for i,pId in ipairs(exp2Discoveries[id].whitePlayerList) do
		if PId == rv1 then table.remove(exp2Discoveries[id].whitePlayerList, i) break end
	end
	exp2Discoveries[id].whiteListInUse = somethingInWhiteList(id)
end)

registerFunction("findDisallowPlayerProps","e","", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	if !rv1:IsValid() then return end
	initTable(self.entity)
	local id = self.entity:EntIndex()
	rv1 = rv1:SteamID()
	for i,pId in ipairs(exp2Discoveries[id].whitePropList) do
		if pId == rv1 then table.remove(exp2Discoveries[id].whitePropList, i) break end
	end
	exp2Discoveries[id].whiteListInUse = somethingInWhiteList(id)
end)

registerFunction("findDisallowPlayerProps","s","", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	rv1 = ents.FindByName(rv1)
	if rv1 != nil then rv1 = rv1[1] else return end
	if !rv1:IsValid() || !rv1:IsPlayer() then return end
	initTable(self.entity)
	local id = self.entity:EntIndex()
	rv1 = rv1:SteamID()
	for i,pId in ipairs(exp2Discoveries[id].whitePropList) do
		if pId == rv1 then table.remove(exp2Discoveries[id].whitePropList, i) break end
	end
	exp2Discoveries[id].whiteListInUse = somethingInWhiteList(id)
end)

registerFunction("findDisallowModel","s","", function(self,args)
	local op1 = args[2]
	local rv1 = string.lower(op1[1](self,op1))
	initTable(self.entity)
	local id = self.entity:EntIndex()
	for i,model in ipairs(exp2Discoveries[id].whiteModelList) do
		if model == rv1 then table.remove(exp2Discoveries[id].whiteModelList, i) break end
	end
	exp2Discoveries[id].whiteListInUse = somethingInWhiteList(id)
end)

registerFunction("findDisallowClass","s","", function(self,args)
	local op1 = args[2]
	local rv1 = string.lower(op1[1](self,op1))
	initTable(self.entity)
	local id = self.entity:EntIndex()
	for i,class in ipairs(exp2Discoveries[id].whiteClassList) do
		if class == rv1 then table.remove(exp2Discoveries[id].whiteClassList, i) break end
	end
	exp2Discoveries[id].whiteListInUse = somethingInWhiteList(id)
end)

registerFunction("findClearBlackList","","", function(self,args)
	local id = self.entity:EntIndex()
	initTable(self.entity)
	exp2Discoveries[id].blackPlayerList = {}
	exp2Discoveries[id].blackPropList = {}
	exp2Discoveries[id].blackModelList = {}
	exp2Discoveries[id].blackClassList = {}
end)

registerFunction("findClearBlackPlayerList","","", function(self,args)
	local id = self.entity:EntIndex()
	initTable(self.entity)
	exp2Discoveries[id].blackPlayerList = {}
end)

registerFunction("findClearBlackPlayerPropList","","", function(self,args)
	local id = self.entity:EntIndex()
	initTable(self.entity)
	exp2Discoveries[id].blackPropList = {}
end)

registerFunction("findClearBlackModelList","","", function(self,args)
	local id = self.entity:EntIndex()
	initTable(self.entity)
	exp2Discoveries[id].blackModelList = {}
end)

registerFunction("findClearBlackClassList","","", function(self,args)
	local id = self.entity:EntIndex()
	initTable(self.entity)
	exp2Discoveries[id].blackClassList = {}
end)

registerFunction("findClearWhiteList","","", function(self,args)
	local id = self.entity:EntIndex()
	initTable(self.entity)
	exp2Discoveries[id].whitePlayerList = {}
	exp2Discoveries[id].whitePropList = {}
	exp2Discoveries[id].whiteModelList = {}
	exp2Discoveries[id].whiteClassList = {}
	exp2Discoveries[id].whiteListInUse = false
end)

registerFunction("findClearWhitePlayerList","","", function(self,args)
	local id = self.entity:EntIndex()
	initTable(self.entity)
	exp2Discoveries[id].whitePlayerList = {}
	exp2Discoveries[id].whiteListInUse = somethingInWhiteList(id)
end)

registerFunction("findClearWhitePlayerPropList","","", function(self,args)
	local id = self.entity:EntIndex()
	initTable(self.entity)
	exp2Discoveries[id].whitePropList = {}
	exp2Discoveries[id].whiteListInUse = somethingInWhiteList(id)
end)

registerFunction("findClearWhiteModelList","","", function(self,args)
	local id = self.entity:EntIndex()
	initTable(self.entity)
	exp2Discoveries[id].whiteModelList = {}
	exp2Discoveries[id].whiteListInUse = somethingInWhiteList(id)
end)

registerFunction("findClearWhiteClassList","","", function(self,args)
	local id = self.entity:EntIndex()
	initTable(self.entity)
	exp2Discoveries[id].whiteClassList = {}
	exp2Discoveries[id].whiteListInUse = somethingInWhiteList(id)
end)

registerFunction("findResult","n","e", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	local id = self.entity:EntIndex()
	initTable(self.entity)
	exp2Discoveries[id].lastAccess = CurTime()
	if rv1 < 1 or rv1 > #exp2Discoveries[id].entities then return nil end
	return exp2Discoveries[id].entities[rv1]
end)

registerFunction("findClosest","v","e", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	local id = self.entity:EntIndex()
	initTable(self.entity)
	local closest = 99999999
	local closestEnt = nil
	rv1 = Vector(rv1[1],rv1[2],rv1[3])
	exp2Discoveries[id].lastAccess = CurTime()
	for entId,ent in pairs(exp2Discoveries[id].entities) do
		local dist = (ent:GetPos() - rv1):Length()
		if dist < closest then
			closestEnt = ent
			closest = dist
		end
	end
	return closestEnt
end)

registerFunction("find","","e", function(self,args)
	local id = self.entity:EntIndex()
	initTable(self.entity)
	exp2Discoveries[id].lastAccess = CurTime()
	return exp2Discoveries[id].entities[1]
end)

registerFunction("findSortByDistance","v","n", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	local id = self.entity:EntIndex()
	initTable(self.entity)
	exp2FindComparePoint = Vector(rv1[1],rv1[2],rv1[3])
	exp2Discoveries[id].lastAccess = CurTime()
	table.sort(exp2Discoveries[id].entities, function(a, b)
		if a == nil || !a:IsValid() then return false end
		if b == nil  || !b:IsValid() then return true end
		return (a:GetPos() - exp2FindComparePoint):Length() < (b:GetPos() - exp2FindComparePoint):Length() end)
	return table.Count(exp2Discoveries[id].entities)
end)

registerFunction("findClipToClass","s","n", function(self,args)
	local op1= args[2]
	local rv1 = string.lower(op1[1](self,op1))
	local id = self.entity:EntIndex()
	local indexOffset = 0
	local i,count=1
	initTable(self.entity)
	//for i,ent in ipairs(exp2Discoveries[id].entities) do
	for i = 1, table.Count(exp2Discoveries[id].entities), 1 do
		local ent = exp2Discoveries[id].entities[i - indexOffset]
		if ent != nil && string.find(string.lower(ent:GetClass()), rv1) == nil then
			table.remove(exp2Discoveries[id].entities, i - indexOffset)
			indexOffset = indexOffset + 1
		end
	end
	return table.Count(exp2Discoveries[id].entities)
end)

registerFunction("findClipFromClass","s","n", function(self,args)
	local op1= args[2]
	local rv1 = string.lower(op1[1](self,op1))
	local id = self.entity:EntIndex()
	local indexOffset = 0
	local i,count=1,1
	initTable(self.entity)
	//for i,ent in ipairs(exp2Discoveries[id].entities) do
	for i = 1, table.Count(exp2Discoveries[id].entities), 1 do
		local ent = exp2Discoveries[id].entities[i - indexOffset]
		if ent != nil && string.find(string.lower(ent:GetClass()), rv1) != nil then
			table.remove(exp2Discoveries[id].entities, i - indexOffset)
			indexOffset = indexOffset + 1
		end
	end
	return table.Count(exp2Discoveries[id].entities)
end)

registerFunction("findClipToModel","s","n", function(self,args)
	local op1= args[2]
	local rv1 = string.lower(op1[1](self,op1))
	local id = self.entity:EntIndex()
	local indexOffset = 0
	local i,count=1,1
	initTable(self.entity)
	//for i,ent in ipairs(exp2Discoveries[id].entities) do
	for i = 1, table.Count(exp2Discoveries[id].entities), 1 do
		local ent = exp2Discoveries[id].entities[i - indexOffset]
		if ent != nil && string.find(string.lower(ent:GetModel()), rv1) == nil then
			table.remove(exp2Discoveries[id].entities, i - indexOffset)
			indexOffset = indexOffset + 1
		end
	end
	return table.Count(exp2Discoveries[id].entities)
end)

registerFunction("findClipFromModel","s","n", function(self,args)
	local op1= args[2]
	local rv1 = string.lower(op1[1](self,op1))
	local id = self.entity:EntIndex()
	local indexOffset = 0
	local i,count=1,1
	initTable(self.entity)
	//for i,ent in ipairs(exp2Discoveries[id].entities) do
	for i = 1, table.Count(exp2Discoveries[id].entities), 1 do
		local ent = exp2Discoveries[id].entities[i - indexOffset]
		if ent != nil && string.find(string.lower(ent:GetModel()), rv1) != nil then
			table.remove(exp2Discoveries[id].entities, i - indexOffset)
			indexOffset = indexOffset + 1
		end
	end
	return table.Count(exp2Discoveries[id].entities)
end)

registerFunction("findClipToName","s","n", function(self,args)
	local op1= args[2]
	local rv1 = string.lower(op1[1](self,op1))
	local id = self.entity:EntIndex()
	local indexOffset = 0
	local i,count=1,1
	initTable(self.entity)
	//for i,ent in ipairs(exp2Discoveries[id].entities) do
	for i = 1, table.Count(exp2Discoveries[id].entities), 1 do
		local ent = exp2Discoveries[id].entities[i - indexOffset]
		if ent != nil && string.find(string.lower(ent:GetName()), rv1) == nil then
			table.remove(exp2Discoveries[id].entities, i - indexOffset)
			indexOffset = indexOffset + 1
		end
	end
	return table.Count(exp2Discoveries[id].entities)
end)

registerFunction("findClipFromName","s","n", function(self,args)
	local op1= args[2]
	local rv1 = string.lower(op1[1](self,op1))
	local id = self.entity:EntIndex()
	local indexOffset = 0
	local i,count=1,1
	initTable(self.entity)
	//for i,ent in ipairs(exp2Discoveries[id].entities) do
	for i = 1, table.Count(exp2Discoveries[id].entities), 1 do
		local ent = exp2Discoveries[id].entities[i - indexOffset]
		if ent != nil && string.find(string.lower(ent:GetName()), rv1) != nil then
			table.remove(exp2Discoveries[id].entities, i - indexOffset)
			indexOffset = indexOffset + 1
		end
	end
	return table.Count(exp2Discoveries[id].entities)
end)

registerFunction("findClipFromSphere","vn","n", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1),op2[1](self,op2)
	local id = self.entity:EntIndex()
	local refPoint = Vector(rv1[1],rv1[2],rv1[3])
	initTable(self.entity)
	local indexOffset = 0
	local i,count=1,1
	for i = 1, table.Count(exp2Discoveries[id].entities), 1 do
		local ent = exp2Discoveries[id].entities[i - indexOffset]
		if ent != nil && (ent:GetPos() - refPoint):Length() + ent:BoundingRadius() <= rv2 then
			table.remove(exp2Discoveries[id].entities, i - indexOffset)
			indexOffset = indexOffset + 1
		end
	end
	return table.Count(exp2Discoveries[id].entities)
end)

registerFunction("findClipToRegion","vv","n", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1),op2[1](self,op2)
	local id = self.entity:EntIndex()
	
	local planeVec = Vector(rv2[1],rv2[2],rv2[3])
	local relPos = Vector(rv1[1],rv1[2],rv1[3]):Dot(planeVec)
	initTable(self.entity)
	local indexOffset = 0
	local i,count=1,1
	for i = 1, table.Count(exp2Discoveries[id].entities), 1 do
		local ent = exp2Discoveries[id].entities[i - indexOffset]
		if ent != nil && (ent:GetPos():Dot(planeVec) - relPos) < 0 then
			table.remove(exp2Discoveries[id].entities, i - indexOffset)
			indexOffset = indexOffset + 1
		end
	end
	return table.Count(exp2Discoveries[id].entities)
end)

registerFunction("findToArray","","r", function(self,args)
	initTable(self.entity)
	local id = self.entity:EntIndex()
	local ret = {}
	for i,e in ipairs(exp2Discoveries[id].entities) do ret[i] = e end
	return ret
end)

