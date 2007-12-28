
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Sound"

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "A" })
end

function ENT:OnRemove()
	self.BaseClass.OnRemove(self)
	self:StopSounds()
end

function ENT:TriggerInput(iname, value)
	if (iname == "A") then
		local on = value > 0
		if (self.on == on) then return end
		self.on = on
		if ( on ) then
			self:SetOverlayText( "Sound: " .. self.sound .. "\nOn" )
			self:StartSounds()
		else
			self:SetOverlayText( "Sound: " .. self.sound .. "\nOff" )
			self:StopSounds()
		end
	end
end

function ENT:SetSound(sound)
	self:StopSounds()
	if ( sound ) then
		util.PrecacheSound( sound )
		self.sound = (sound or ""):gsub("[/\\]+","/")
		self.SND = CreateSound( self.Entity, Sound(self.sound) )
		self:SetOverlayText( "Sound: " .. self.sound .. "\nOff" )
	end
end

function ENT:StartSounds()
	if (self.SND) then
		self.SND:Play()
	end
end

function ENT:StopSounds()
	if (self.SND) then
		self.SND:Stop()
	end
end


function MakeWireEmitter( pl, Model, Ang, Pos, sound, nocollide, frozen )

	if ( !pl:CheckLimit( "wire_emitters" ) ) then return false end

	local wire_emitter = ents.Create( "gmod_wire_soundemitter" )
	if (!wire_emitter:IsValid()) then return false end
	wire_emitter:SetModel( Model )

	wire_emitter:SetAngles( Ang )
	wire_emitter:SetPos( Pos )
	wire_emitter:Spawn()
	
	wire_emitter:SetSound( Sound(sound) )
	wire_emitter:SetPlayer( pl )

	local etable = {
		pl	= pl,
		nocollide = nocollide
	}
	table.Merge(wire_emitter:GetTable(), etable )

	pl:AddCount( "wire_emitters", wire_emitter )

	return wire_emitter
	
end

duplicator.RegisterEntityClass("gmod_wire_soundemitter", MakeWireEmitter, "Model", "Ang", "Pos", "sound", "nocollide", "frozen")
