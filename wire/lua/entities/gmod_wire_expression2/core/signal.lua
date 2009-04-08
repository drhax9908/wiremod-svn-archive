AddCSLuaFile('signal.lua')

//Author: Gwahir

wire_exp2_signals = {}
wire_exp2_removeSignal = {}
local activeSignal = nil
local signal = ""
local signalGroup = ""

local curGroup = "default"
local delim = "_&_@_"

/***************
FORMAT:

signal data:
{Sender ID, Sender (ent), SenderOwner (ent), Receiver (ent), Signal name, Signal scope, reserved, reserved}
Both sender Id and ent are stored as the ent might be invalid if it's a removal signal
Receiver will be nil in most cases, if it is valid, it's a direct signal to that entity

receiver data:
stored by signal name then entId {receiver (ent), receiver owner, receiver scope, receiver owner steamId}

on remove signal data
stored by entId {signal name, signal scope}
****************/

local isBuddy = nil

if SPropProtection != nil then
	isBuddy = function(ply,receiver)
		if ply == nil || !ply:IsValid() || !ply:IsPlayer() then return false end
		if receiver == nil || !receiver:IsValid() || !receiver:IsPlayer() then return false end
		return ((ply == receiver) || table.HasValue(SPropProtection[ply:SteamID()], receiver:SteamID()))
	end
else
	isBuddy = function(ply,receiver) return true end
end

registerFunction("signalSetGroup", "s", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	curGroup = rv1
end)

registerFunction("signalGetGroup", "", "s", function(self, args)
    return curGroup
end)

registerFunction("runOnSignal", "sn", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    if rv1 == nil || rv1 == "" then return end
	rv1 = curGroup .. delim .. rv1
    local op2 = args[3]
    local rv2 = op2[1](self, op2)
    if rv2 > 3 then rv2 = 3 end
    if rv2 < 0 then rv2 = 0 end
    rv2 = math.Round(rv2)
	if wire_exp2_signals[rv1] == nil then 
		wire_exp2_signals[rv1] = {}
	end
	local owner = getOwner(self,self.entity)
	wire_exp2_signals[rv1][self.entity:EntIndex()] = {self.entity, owner,rv2, owner:SteamID()}
end)

registerFunction("runOnSignal", "snn", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    if rv1 == nil || rv1 == "" then return end
	rv1 = curGroup .. delim .. rv1
    local op2 = args[3]
    local rv2 = op2[1](self, op2)
    local op3 = args[4]
    local rv3 = op3[1](self, op3)
    if rv3 == 0 then
		wire_exp2_signals[rv1][self.entity:EntIndex()] = nil
		if table.Count(wire_exp2_signals[rv1]) == 0 then wire_exp2_signals[rv1] = nil end
    else
		if rv2 > 3 then rv2 = 3 end
		if rv2 < 0 then rv2 = 0 end
		rv2 = math.Round(rv2)
		if wire_exp2_signals[rv1] == nil then 
			wire_exp2_signals[rv1] = {}
		end
		local owner = getOwner(self,self.entity)
		wire_exp2_signals[rv1][self.entity:EntIndex()] = {self.entity, owner,rv2, owner:SteamID()}
	end
end)


registerFunction("runOnSignalStop", "s", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    if rv1 == nil || rv1 == "" then return end
	rv1 = curGroup .. delim .. rv1
    wire_exp2_signals[rv1][self.entity:EntIndex()] = nil
    if table.Count(wire_exp2_signals[rv1]) == 0 then wire_exp2_signals[rv1] = nil end
end)


registerFunction("signalClk", "s", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	if rv1 == nil || rv1 == "" then return end
	if rv1 == signal then return 1 else return 0 end
end)

registerFunction("signalClk", "sn", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	if rv1 == nil || rv1 == "" then return end
    local op2 = args[3]
    local rv2 = op2[1](self, op2)
    if rv2 > 3 then rv2 = 3 end
    if rv2 < 0 then rv2 = 0 end
    rv2 = math.Round(rv2)
	if rv1 == signal && activeSignal != nil && 
		(self.player == activeSignal[3] && rv2 <= 1 || self.player != activeSignal[3] && rv2 >= 1) then
		return 1
	else
		return 0
	end
end)


registerFunction("signalClk", "ss", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	if rv1 == nil || rv1 == "" then return end
    local op2 = args[3]
    local rv2 = op2[1](self, op2)
	if rv2 == nil || rv2 == "" then return end
	if rv1 == signalGroup && rv2 == signal then return 1 else return 0 end
end)

registerFunction("signalClk", "ssn", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	if rv1 == nil || rv1 == "" then return end
    local op2 = args[3]
    local rv2 = op2[1](self, op2)
	if rv2 == nil || rv2 == "" then return end
    local op3 = args[4]
    local rv3 = op3[1](self, op3)
    if rv3 > 3 then rv3 = 3 end
    if rv3 < 0 then rv3 = 0 end
    rv3 = math.Round(rv3)
	if rv1 == signalGroup && rv2 == signal && activeSignal != nil && 
		(self.player == activeSignal[3] && rv3 <= 1 || self.player != activeSignal[3] && rv3 >= 1) then
		return 1
	else
		return 0
	end
end)

registerFunction("signalGroup", "", "s", function(self, args)
	if signal != "" && activeSignal != nil then return signalGroup else return "" end
end)

registerFunction("signalName", "", "s", function(self, args)
	if signal != "" && activeSignal != nil then return signal else return "" end
end)

registerFunction("signalSender", "", "e", function(self, args)
	if signal != "" && activeSignal != nil then return activeSignal[2] else return nil end
end)

registerFunction("signalSenderId", "", "n", function(self, args)
	if signal != "" && activeSignal != nil then return activeSignal[1] else return 0 end
end)

registerFunction("signalSetOnRemove", "sn", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	if rv1 == nil || rv1 == "" then return end
	rv1 = curGroup .. delim .. rv1
    local op2 = args[3]
    local rv2 = op2[1](self, op2)
    if rv2 > 3 then rv2 = 3 end
    if rv2 < 0 then rv2 = 0 end
    rv2 = math.Round(rv2)
    wire_exp2_removeSignal[self.entity:EntIndex()] = {rv1,rv2}
end)

registerFunction("signalClearOnRemove", "", "", function(self, args)
    wire_exp2_removeSignal[self.entity:EntIndex()] = nil
end)

local function sendSignal(data)
	local fullSignal = data[5]:explode(delim)
	signalGroup = fullSignal[1]
	signal = fullSignal[2]
	activeSignal = data
	if activeSignal[4] != nil && !activeSignal[4]:IsPlayer() then //direct signal
		if activeSignal[4]:IsValid() then //ensure the receiving entity wants to receive it
			local id = activeSignal[4]:EntIndex()
			local info = wire_exp2_signals[activeSignal[5]]
			if info != nil then 
				info = info[id]
				if info != nil && (info[2] == activeSignal[3] || info[3] >= 1) then
					activeSignal[4]:Execute()
				end
			end
		end
	elseif wire_exp2_signals[activeSignal[5]] != nil then
		for i,t in pairs(wire_exp2_signals[activeSignal[5]]) do
			local playerInfoGood = false
			//ensure the player info is still good, if not, don't remove the receiver, the player may return
			//and if the chip is cleaned up, the receiver entry will be cleaned then
			if t[2] == nil || !t[2]:IsValid() || !t[2]:IsPlayer() || t[2]:SteamID() != t[4] then
				for _,p in pairs(player.GetAll()) do
					if p:SteamID() == t[4] then
						t[2] = p
						playerInfoGood = true
						break
					end
				end
			else
				playerInfoGood = true
			end
			if  playerInfoGood && i != activeSignal[1] && t[1] != nil && t[1]:IsValid() && 
				(activeSignal[4] == nil || activeSignal[4]:SteamID() == t[4]) then
				if activeSignal[6] == 3 then
					if t[3] == 3 then
						if isBuddy(activeSignal[3],t[2]) && isBuddy(t[2],activeSignal[3]) then 
							t[1]:Execute()
						end
					elseif ((activeSignal[3] == t[2] && t[3] <= 1) ||
						(activeSignal[3] != t[2] && t[3] >= 1)) && 
						isBuddy(activeSignal[3],t[2]) then

						t[1]:Execute()
					end
				elseif t[2] == 3 then
					if isBuddy(t[2],activeSignal[3]) then
						t[1]:Execute()
					end
				elseif ((activeSignal[3] == t[2] && t[3] <= 1 && activeSignal[6] <= 1) ||
					(activeSignal[3] != t[2] && t[3] >= 1 && activeSignal[6] >= 1)) then

					t[1]:Execute()
				end
			end
		end
	end
	signal = ""
	signalGroup = ""
	activeSignal = nil
end

registerFunction("signalSend", "sn", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    if rv1 == nil || rv1 == "" then return end
	rv1 = curGroup .. delim .. rv1
    local op2 = args[3]
    local rv2 = op2[1](self, op2)
    if rv2 > 3 then rv2 = 3 end
    if rv2 < 0 then rv2 = 0 end
    rv2 = math.Round(rv2)
    local id = self.entity:EntIndex()
	local timerName = "wire_exp2_signal_" .. rv1 .. "_" .. id
	timer.Adjust(timerName, 0.01, 1, sendSignal, {id, self.entity, self.player, nil, rv1, rv2})
	timer.Start(timerName)
end)

registerFunction("signalSendDirect", "es", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    if rv1 == nil || !rv1:IsValid() then return end
    local op2 = args[3]
    local rv2 = op2[1](self, op2)
    if rv2 == nil || rv2 == "" then return end
	rv2 = curGroup .. delim .. rv2
    local id = self.entity:EntIndex()
	local timerName = "wire_exp2_signal_" .. rv2 .. "_" .. id .. "_" .. rv1:EntIndex()
	timer.Adjust(timerName, 0.01, 1, sendSignal, {id, self.entity, self.player, rv1, rv2, 1})
	timer.Start(timerName)
end)

registerFunction("signalSendToPlayer", "es", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    if rv1 == nil || !rv1:IsValid() || !rv1:IsPlayer() then return end
    local op2 = args[3]
    local rv2 = op2[1](self, op2)
    if rv2 == nil || rv2 == "" then return end
	rv2 = curGroup .. delim .. rv2
    local id = self.entity:EntIndex()
	local timerName = "wire_exp2_signal_" .. rv2 .. "_" .. id .. "_" .. rv1:SteamID()
	timer.Adjust(timerName, 0.01, 1, sendSignal, {id, self.entity, self.player, rv1, rv2, 1})
	timer.Start(timerName)
end)

registerCallback("destruct",function(self)
	local id = self.entity:EntIndex()
	if wire_exp2_removeSignal[id] != nil then
		local timerName = "wire_exp2_signal_" .. wire_exp2_removeSignal[id][1] .. "_" .. id
		timer.Adjust(timerName, 0.01, 1, sendSignal, {id, self.entity, self.player, nil, wire_exp2_removeSignal[id][1],
			wire_exp2_removeSignal[id][2]})
		timer.Start(timerName)
		wire_exp2_removeSignal[id] = nil
	end

	for s,t in pairs(wire_exp2_signals) do
	    t[id] = nil
		if table.Count(t) == 0 then wire_exp2_signals[s] = nil end
	end
end)


registerCallback("preexecute",function(self)
	curGroup = "default"
end)

