
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
	if (sound) then
		local parsedsound = sound
		while (string.find(parsedsound,"%s") && (string.find(parsedsound,"%s") == 1)) do
			parsedsound = string.sub(parsedsound,2,string.len(parsedsound))
		end
		util.PrecacheSound(parsedsound)

		self.sound = (parsedsound or ""):gsub("[/\\]+","/")
		self:SetOverlayText( "Sound: " .. self.sound .. "\nOff" )
	end
end

function ENT:StartSounds()
	self:StopSounds(); -- Stop old sounds before
	self.SND = CreateSound(self.Entity,Sound(self.sound)); -- Create new CSoundPatch (Must be created everytime again, or some people do not hear it)
	self.SND:Play();
end

function ENT:StopSounds()
	if (self.SND) then
		self.SND:Stop()
		self.SND = nil;
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

	if wire_emitter:GetPhysicsObject():IsValid() then
		local Phys = wire_emitter:GetPhysicsObject()
		Phys:EnableMotion(!frozen)
	end

	wire_emitter:SetSound( Sound(sound) )
	wire_emitter:SetPlayer( pl )

	local etable = {
		pl	= pl,
		sound = sound,
		nocollide = nocollide
	}
	table.Merge(wire_emitter:GetTable(), etable )

	pl:AddCount( "wire_emitters", wire_emitter )

	return wire_emitter
	
end
duplicator.RegisterEntityClass("gmod_wire_soundemitter", MakeWireEmitter, "Model", "Ang", "Pos", "sound", "nocollide", "frozen")
