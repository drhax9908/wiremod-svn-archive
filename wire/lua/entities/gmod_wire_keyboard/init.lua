
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Numpad"
ENT.OverlayDelay = 0

local MODEL = Model("models/jaanus/wiretool/wiretool_input.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.On = {}
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Memory" })

	for i = 1,127 do
		self.On[i] = 0
	end
	
	self.Buffer = {}
	for i = 0,31 do
		self.Buffer[i] = 0
	end

	self.InUse = false
	self:SetOverlayText( "Keyboard - not in use" )
end


function ENT:ReadCell( Address )
	if (Address >= 0) && (Address < 32) then
		return self.Buffer[Address]
	else
		return nil
	end
end

function ENT:WriteCell( Address, value )
	if (Address >= 0) && (Address < 32) then
		self:Switch(false,value)
		return true
	else
		return false
	end
end

function Wire_KeyOn(pl,ent)
	pl:ConCommand("exec vkeyboard.cfg")
	KeyBoardPlayerKeys[pl:EntIndex()] = ent:EntIndex()
	pl:PrintMessage(HUD_PRINTTALK,"Virtual keyboard turned on\n")
end

function ENT:Use(pl)
	if (!self.InUse) then
		self.InUse = true
		self:SetOverlayText( "Keyboard - In use" )

		timer.Create("Wire_Keyboard_ShitTimer",0.1,1,Wire_KeyOn,pl,self)

//		pl:ConCommand("exec vkeyboard.cfg")
//		KeyBoardPlayerKeys[pl:EntIndex()] = self:EntIndex()
//		pl:PrintMessage(HUD_PRINTTALK,"Virtual keyboard turned on\n")
	end
end

//16 - CTRL (THE JESUS)
//17,18,19,20 - UP,DOWN,LEFT,RIGHT,MOVE IT,THATS ALL ABOUT
//21 - SHIFT?? NO I MEAN FUCK
//127 - BACKSPACE, NEEDS MORE FORWARDSPACE

function ENT:Switch( on, key )
	if (!self.Entity:IsValid()) then return false end

	if (key == -1) then
		self.Buffer[0] = 0
		return true
	end

	self.On[ key ] = on

	if ( on ) then
		self.Buffer[0] = self.Buffer[0] + 1
		self.Buffer[self.Buffer[0]] = key
	else
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

	//self.Buffer[0] = 0
	//for i = 1,127 do
	//	if (self.On[ i ] == true) then
	//		self.Buffer[0] = self.Buffer[0] + 1
	//		self.Buffer[self.Buffer[0]] = i
	//	end
	//end

	return true
end

KeyBoardPlayerKeys = {}

function Wire_KeyPress ( pl, cmd, args )
	local key = args[1]

	if (KeyBoardPlayerKeys[pl:EntIndex()]) then
		local ent = ents.GetByIndex( KeyBoardPlayerKeys[pl:EntIndex()] )
		if (ent) && (ent:IsValid()) && (ent.InUse) then
			if (pl:KeyDown(IN_SPEED)) then
				key = string.upper(key)
			end
			//Msg("Key press: "..key.."\n")

			local tkey = "?"
			if (key == "SPACE") then tkey = string.byte(" ")
			elseif (key == "CTRL") then tkey = 16
			elseif (key == "BACKSPACE") then tkey = 127
			elseif (key == "UPARROW") then tkey = 17
			elseif (key == "DOWNARROW") then tkey = 18
			elseif (key == "LEFTARROW") then tkey = 19
			elseif (key == "RIGHTARROW") then tkey = 20
			elseif (key == "ENTER") then tkey = 13
			else tkey = string.byte(key) end
	
			ent:Switch(true,tkey)
			//surface.PlaySound("common/talk.wav")
		end
	end
end
concommand.Add("wire_keyboard_key", Wire_KeyPress)

function Wire_KeyOff ( pl, cmd, args )
	local ent = ents.GetByIndex( KeyBoardPlayerKeys[pl:EntIndex()] )
	if (ent) && (ent:IsValid()) && (ent.InUse) then
		ent.InUse = false
		ent:SetOverlayText( "Keyboard - not in use" )
	end
	KeyBoardPlayerKeys[pl:EntIndex()] = -1

	pl:ConCommand("exec config.cfg")
	pl:PrintMessage(HUD_PRINTTALK,"Virtual keyboard turned off\n")
	//surface.PlaySound("common/talk.wav")
end
concommand.Add("wire_keyboard_off", Wire_KeyOff)