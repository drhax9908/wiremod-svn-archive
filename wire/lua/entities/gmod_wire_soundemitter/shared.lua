

ENT.Type 			= "anim"
ENT.Base 			= "base_wire_entity"

ENT.PrintName		= ""
ENT.Author			= ""
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false




function ENT:SetOn( boolon )
	self.Entity:SetNetworkedBool( "On", boolon, true )
end

function ENT:IsOn( name )
	return self.Entity:GetNetworkedBool( "On" )
end

function ENT:StartSounds( filename, volume )
	util.PrecacheSound( filename )
	-- This new method fixes bugs with soundloops!
	self.SND = CreateSound(self.Entity,Sound(filename)); -- Sorry, volume must suffer - Anyway, volume NEVER worked for me
	self.SND:Play();
	--self.Entity:EmitSound( filename, volume or 100, 100)
end

function ENT:StopSounds( filename )
	if(self.SND) then
		self.SND:Stop()
	end
	--self.Entity:StopSound( filename )
end

