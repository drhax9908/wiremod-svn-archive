AddCSLuaFile('chat.lua')

//Original author: ZeikJT
//Modified by Gwahir

wire_exp2_TextList = {}
wire_exp2_ChatAlert = {}
local runByChat = false

registerFunction("lastSaid", "e:", "s", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    local entity = checkEntity(rv1)
	if(!entity || !rv1:IsValid()) then return "" end
	if(!entity:IsPlayer()) then return "" end
	if !wire_exp2_TextList[entity] then return "" end
    return wire_exp2_TextList[entity][1]
end)

registerFunction("lastSaidWhen", "e:", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if(!rv1:IsPlayer()) then return 0 end
	if !wire_exp2_TextList[rv1] then return 0 end
    return wire_exp2_TextList[rv1][3]
end)

registerFunction("lastSaid", "", "s", function(self, args)
	if !wire_exp2_TextList['last'] then return "" end
    return wire_exp2_TextList['last'][2]
end)

registerFunction("lastSaidWhen", "", "n", function(self, args)
	if !wire_exp2_TextList['last'] then return 0 end
    return wire_exp2_TextList['last'][4]
end)

registerFunction("lastSpoke", "", "e", function(self, args)
	if (!wire_exp2_TextList['last'] || !wire_exp2_TextList['last'][1]) then return nil end
	local ply = wire_exp2_TextList['last'][1]
	if (!ply:IsValid() || !ply:IsPlayer()) then return nil end
    return wire_exp2_TextList['last'][1]
end)

local function HasEnt(table, ent)
	if ent == nil || !ent:IsValid() then return false end
	local id = ent:EntIndex()
	for i,e in ipairs(wire_exp2_ChatAlert) do
		if e != nil && e:IsValid() && e:EntIndex() == id then return true end
	end
	return false
end

registerFunction("runOnChat", "n", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    if rv1 != 0 then
        if !HasEnt(wire_exp2_ChatAlert, self.entity) then
            table.insert(wire_exp2_ChatAlert,self.entity)
        end
    else
		for i,e in ipairs(wire_exp2_ChatAlert) do
			if e == self.entity then
				table.remove(wire_exp2_ChatAlert,i)
				break
			end
		end
    end
end)

registerFunction("chatClk", "", "n", function(self, args)
    if runByChat then return 1 else return 0 end
end)

registerFunction("chatClk", "e", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	if rv1 == nil || !rv1:IsValid() then return 0 end
    if runByChat && rv1 == wire_exp2_TextList['last'][1] then return 1 else return 0 end
end)

registerCallback("destruct",function(self)
	if self.entity == nil || !self.entity:IsValid() then return end
	for i,e in ipairs(wire_exp2_ChatAlert) do
		if e == self.entity then
			table.remove(wire_exp2_ChatAlert,i)
			break
		end
	end
end)

function Exp2TextReceiving( ply, text, toall )
    wire_exp2_TextList[ply] = {text,toall,CurTime()}
    wire_exp2_TextList['last'] = {ply, text, toall, CurTime()}
    runByChat = true
    local clean = false
    for i,e in ipairs(wire_exp2_ChatAlert) do
        if e != nil && e:IsValid() && e.Execute != nil then
            e:Execute()
        else
            clean = true
        end
    end
    runByChat = false
    if clean then
		local indexOffset = 0
		for i,e in ipairs(wire_exp2_ChatAlert) do
			if e == nil || !e:IsValid() || e.Execute == nil then 
				table.remove(wire_exp2_ChatAlert, i - indexOffset)
				indexOffset = indexOffset + 1
				break 
			end
		end
    end
end

local function Exp2ChatPlayerDisconnect(ply)
	wire_exp2_TextList[ply] = nil
end

hook.Add("PlayerSay","Exp2TextReceiving",Exp2TextReceiving)
hook.Add("PlayerDisconnected","Exp2ChatPlayerDisconnect",Exp2ChatPlayerDisconnect)