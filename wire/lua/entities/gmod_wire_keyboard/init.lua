
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')
include('remap.lua')

ENT.WireDebugName = "Wired Keyboard"
ENT.OverlayDelay = 0

function ENT:Initialize()
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	
	self.On = {}
	self.Inputs = Wire_CreateInputs(self.Entity, { "Kick the bastard out of keyboard" })
	self.Outputs = WireLib.CreateSpecialOutputs(self.Entity, { "Memory", "User" }, { "NORMAL", "ENTITY" })

	for i = 0,223 do
		self.On[i] = 0
	end
	
	self.Buffer = {}
	for i = 0,31 do
		self.Buffer[i] = 0
	end

	self.InUse = false
	self.IgnoredFirstChar = false
	self:SetOverlayText("Keyboard - not in use")
end


function ENT:ReadCell(Address)
	if (Address >= 0) && (Address < 32) then
		return self.Buffer[Address]
	elseif (Address >= 32) && (Address < 256) then
		if (self.On[Address-32]) then
			return 1
		else
			return 0
		end
	else
		return nil
	end
end

function ENT:WriteCell(Address, value)
	if (Address == 0) then
		self.Buffer[0] = 0
		return true
	elseif (Address > 0) && (Address < 256) then
		self:Switch(false,value)
		return true
	else
		return false
	end
end

function ENT:Use(pl)
	if (!self.InUse) then
		self.InUse = true
		self.IgnoredFirstChar = false
		self.InUseBy = pl
		Wire_TriggerOutput(self.Entity, "User", pl.Entity)

		self:SetOverlayText("Keyboard - In use by " .. pl:GetName())
		pl:ConCommand("wire_keyboard_on "..self:EntIndex())
	end
end

function ENT:TriggerInput(iname, value)
	if (iname == "Kick the bastard out of keyboard") then
		if ((self.InUse == true) && (self.InUseBy:IsValid())) then
			self.InUseBy:ConCommand("wire_keyboard_off")
		end
	end
end

//=============================================================================
// Switch key state to ON/OFF
//=============================================================================

function ENT:Switch(on, key)
	if (!self.Entity:IsValid()) then return false end

	if (key == -1) then
		self.Buffer[0] = 0
		return true
	end

	self.On[ key ] = on

	if ((key != 21) && (key != 16)) then
		if (on == true) then
			if (self.InUse) then
				self.Buffer[0] = self.Buffer[0] + 1
				self.Buffer[self.Buffer[0]] = key
				Wire_TriggerOutput(self.Entity, "Memory", key)
			end
		else
			Wire_TriggerOutput(self.Entity, "Memory", 0)
			for i = 1,self.Buffer[0] do
				if (self.Buffer[i] == key) then
					self.Buffer[0] = self.Buffer[0] - 1
					for j = i,self.Buffer[0] do
						self.Buffer[j] = self.Buffer[j+1]
					end
					return true
				end
			end
		end
	end

	return true
end

//=============================================================================
// Keyboard turning ON/OFF
//=============================================================================

if (!KeyBoardPlayerKeys) then
	KeyBoardPlayerKeys = {}
end

function Wire_KeyOff (pl, cmd, args)
	local ent = ents.GetByIndex(KeyBoardPlayerKeys[pl:EntIndex()])
	if (ent) && (ent:IsValid()) && (ent.InUse) then
		Wire_TriggerOutput(ent.Entity, "User", pl.Entity)
		ent.InUse = false
		ent:SetOverlayText("Keyboard - not in use")
	end
	KeyBoardPlayerKeys[pl:EntIndex()] = nil

	pl:ConCommand("wire_keyboard_releaseinput")
	pl:PrintMessage(HUD_PRINTTALK,"Wired keyboard turned off\n")
end
concommand.Add("wire_keyboard_off", Wire_KeyOff)

function Wire_KeyOn(pl, cmd, args)
	local ent = ents.GetByIndex(KeyBoardPlayerKeys[pl:EntIndex()])
	if (pl) && (pl:IsValid()) && (!ent.InUse) then
		KeyBoardPlayerKeys[pl:EntIndex()] = args[1]

		pl:ConCommand("wire_keyboard_blockinput")
		pl:PrintMessage(HUD_PRINTTALK,"Wired keyboard turned on - press ALT to exit the mode!\n")
	end
end
concommand.Add("wire_keyboard_on", Wire_KeyOn)

//=============================================================================
// Key press/release hook handlers
//=============================================================================

function Wire_KeyPressed(pl, cmd, args)
	local key = tonumber(args[2])

	if (!KeyBoardPlayerKeys[pl:EntIndex()]) then return end
	local ent = ents.GetByIndex(KeyBoardPlayerKeys[pl:EntIndex()])
	if (!ent) || (!ent:IsValid()) || (!ent.InUse) then pl:ConCommand("wire_keyboard_off") return end

	if (key == KEY_RALT) || (key == KEY_LALT) then
		pl:ConCommand("wire_keyboard_off")
		return
	end

	//Get normalized/ASCII key
	local nkey
	if (Keyboard_ReMap[key]) then nkey = Keyboard_ReMap[key]
	else nkey = 0 end

	if (ent.On[21] == true) then
		if (Keyboard_CaseReMap[string.char(nkey)]) then
			nkey = string.byte(Keyboard_CaseReMap[string.char(nkey)])
		end
	end

	if (ent.IgnoredFirstChar == false) then
		ent.IgnoredFirstChar = true
		return
	end

	//Msg("Recieved key press ("..string.char(nkey)..") for player "..pl:EntIndex()..", entity "..ent:EntIndex().."\n")	

	if (args[1] == "p") then
		if (key == KEY_LCONTROL) || (key == KEY_RCONTROL) then ent:Switch(true,16) end
		if (key == KEY_LSHIFT) || (key == KEY_RSHIFT) then ent:Switch(true,21) end

		ent:Switch(true,nkey)
	else
		if (key == KEY_LCONTROL) || (key == KEY_RCONTROL) then ent:Switch(false,16) end
		if (key == KEY_LSHIFT) || (key == KEY_RSHIFT) then ent:Switch(false,21) end

		ent:Switch(false,nkey)
	end
end
concommand.Add("wire_keyboard_press", Wire_KeyPressed)
