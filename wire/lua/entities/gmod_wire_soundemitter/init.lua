
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Sound"

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "A", "Toggle", "Volume", "Play", "Stop", 
		/*"PitchNote",*/ "PitchRelative", "PitchStart", 
		"SpinUpTime", "SpinDownTime", "FadeInStartVolume", "FadeInTime", "FadeOutTime",
		"LFOType", "LFORate", "LFOModPitch", "LFOModVolume", "Sample" })

	self.BaseFreq = 440
	self.Active = 0
	self.Volume = 5
	self.Pitch = 100

	self.SoundOutput = ents.Create("ambient_generic") //magic begins
	self.SoundOutput:SetName("Wire_SoundOutput_"..self:EntIndex())
	self.SoundOutput:SetPos(self.Entity:GetPos())
	self.SoundOutput:SetOwner(self.Entity:GetOwner())
	self.SoundOutput:SetKeyValue("message", "synth/square.wav")
	self.SoundOutput:SetKeyValue("health", "5")
	self.SoundOutput:SetKeyValue("spawnflags","16") //looped, and silent
	self.SoundOutput:SetKeyValue("radius", "1024")

	self.SoundOutput:Spawn()
	self.SoundOutput:Activate()

	self.SampleTable = {}
	self.SampleTable[0] = "synth/square.wav"
	self.SampleTable[1] = "synth/square.wav"
	self.SampleTable[2] = "synth/saw.wav"
	self.SampleTable[3] = "synth/tri.wav"
	self.SampleTable[4] = "synth/sine.wav"

	//LFO:
	// 0 - none
	// 1 - square
	// 2 - tri
	// 3 - saw
	// 4 - sine
	// 5 - random noise
	
	self.LFOType = 0
	self.LFORate = 0
	self.LFOModPitch = 0
	self.LFOModVolume = 0
	self.Sample = 0

	self.LFOValue = 0
	self.LFONoiseTime = 0
	

//	expl:Fire("explode", "", 0)
//	expl:Fire("kill","",0)

//	note = 69+12 * log2(f/440)
//	f = (2^((note - 69) / 12))*440
end

function ENT:OnRemove()
	self.BaseClass.OnRemove(self)
	self:StopSounds()
	self.SoundOutput:Fire("Kill", "", 0)
end

function ENT:TriggerInput(iname, value)
	if (iname == "A") then
		local active = value >= 1
		if (self.Active == active) then return end
		self.Active = active
		if (active) then
			self:StartSounds()
		else
			self:StopSounds()
		end
	elseif (iname == "Toggle") then
		local active = value >= 1
		if (active) then
			self.SoundOutput:Fire("ToggleSound", "", 0)
			self.Active = !self.Active
		end
	elseif (iname == "Volume") then
		local volume = math.Clamp(math.floor(value*10),0,10)
		self.Volume = volume

		self.SoundOutput:SetKeyValue("health",volume)
		if (self.Active) then
			self.SoundOutput:Fire("Volume", volume, 0)
		end
	elseif (iname == "Play") then
		local active = value >= 1
		if (active) then
			self.Active = true
			self:StartSounds()
		end
	elseif (iname == "Stop") then
		local active = value >= 1
		if (active) then
			self.Active = false
			self:StopSounds()
		end
	elseif (iname == "PitchNote") then
	elseif (iname == "PitchRelative") then
		local relpitch = math.Clamp(math.floor(value*100),0,255)
		self.SoundOutput:SetKeyValue("pitch",relpitch)
		if (self.Active) then
			self.SoundOutput:Fire("Pitch", relpitch, 0)
		end
		self.Pitch = relpitch
	elseif (iname == "PitchStart") then
		local relpitch = math.Clamp(math.floor(value*100),0,255)
		self.SoundOutput:SetKeyValue("pitchstart",relpitch)
	elseif (iname == "SpinUpTime") then
		local val = math.Clamp(math.floor(value*100),0,100)
		self.SoundOutput:SetKeyValue("spinup",val)
	elseif (iname == "SpinDownTime") then
		local val = math.Clamp(math.floor(value*100),0,100)
		self.SoundOutput:SetKeyValue("spindown",val)
	elseif (iname == "FadeInStartvolume") then
	elseif (iname == "FadeInTime") then
		local val = math.Clamp(math.floor(value*100),0,100)
		self.SoundOutput:SetKeyValue("fadeinsecs",val)
	elseif (iname == "FadeOutTime") then
		local val = math.Clamp(math.floor(value*100),0,100)
		self.SoundOutput:SetKeyValue("fadeoutsecs",val)
	elseif (iname == "LFOType") then
		local val = math.Clamp(math.floor(value),0,5)
		self.LFOType = val
	elseif (iname == "LFORate") then
		self.LFORate = value
	elseif (iname == "LFOModPitch") then
		self.LFOModPitch = value
	elseif (iname == "LFOModVolume") then
		self.LFOModVolume = value
	elseif (iname == "Sample") then
		self:SetSample(value)
	end

//		"Toggle", "Volume", "Play", "Stop", 
//		"PitchFreq", "PitchNote", "PitchRelative", "PitchStart", 
//		"SpinUpTime", "SpinDownTime", "FadeInStartVolume", "FadeInTime", "FadeOutTime",
//		"LFOType", "LFORate", "LFOModPitch", "LFOModVolume", 
end

function ENT:SetSound(sound)
	self:StopSounds()

	local parsedsound = sound
	while (string.find(parsedsound,"%s") && (string.find(parsedsound,"%s") == 1)) do
		parsedsound = string.sub(parsedsound,2,string.len(parsedsound))
	end
	util.PrecacheSound(parsedsound)
	local tsound = (parsedsound or ""):gsub("[/\\]+","/")

	self.SampleTable[0] = sound
	self.SoundOutput:SetKeyValue("message", tsound)
	self:SetOverlayText( "Sound: " .. tsound )
end

function ENT:SetSample(sample)
	if (self.SampleTable[sample]) then
		self:StopSounds()
		self.SoundOutput:SetKeyValue("message", self.SampleTable[sample])
	end
end

function ENT:StartSounds()
	self:StopSounds()
	self.SoundOutput:Fire("Volume", self.Volume, 0) //FIXME
	self.SoundOutput:Fire("Pitch", self.Pitch, 0)
	self.SoundOutput:Fire("PlaySound", "", 0)
end

function ENT:StopSounds()
	self.SoundOutput:Fire("Volume", "0", 0)
	self.SoundOutput:Fire("StopSound", "", 0)
end

function ENT:Think()
	self.SoundOutput:SetPos(self.Entity:GetPos())

	if (self.LFOType == 5) then //Random noise
		if ((self.LFORate ~= 0) && (CurTime() - self.LFONoiseTime > 1 / self.LFORate)) then
			self.LFONoiseTime = CurTime()

			self.LFOValue = math.random()*2-1

			if (self.Active) then
				self.SoundOutput:Fire("Pitch", self.Pitch + 100*self.LFOValue*self.LFOModPitch, 0)
				self.SoundOutput:Fire("Volume", self.Volume + 5*self.LFOValue*self.LFOModVolume, 0)
			end
		end
	end
	
	self.Entity:NextThink(CurTime()+0.01)
	return true
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
