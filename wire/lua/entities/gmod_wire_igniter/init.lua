
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Igniter"

local MODEL = Model("models/jaanus/wiretool/wiretool_siren.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self.Entity, { "A", "Length" })
	self.IgniteLength = 10
	self.TargetPlayers = false
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:Setup(trgply)
    self.TargetPlayers = trgply
end

function ENT:TriggerInput(iname, value)
	if (iname == "A") then
		if (value ~= 0) then
			 local vStart = self.Entity:GetPos()
			 local vForward = self.Entity:GetUp()
			 
			 local trace = {}
				 trace.start = vStart
				 trace.endpos = vStart + (vForward * 2048)
				 trace.filter = { self.Entity }
			 local trace = util.TraceLine( trace ) 
			
			local svarTargetPlayers = false
			if(GetConVarNumber('sbox_wire_igniters_allowtrgply') > 0)then
			 svarTargetPlayers = true
			else
			 svarTargetPlayers = false
			end
			
			Msg("TargetPlayersSvar:")
			Msg(svarTargetPlayers)
			Msg("\n")
			
			Msg("TargetPlayersIgniterVar:")
			Msg(self.TargetPlayers)
			Msg("\n")
			
			if (!trace.Entity) then return false end
            if (!trace.Entity:IsValid() ) then return false end
            if (trace.Entity:IsPlayer() && (!self.TargetPlayers || !svarTargetPlayers)) then return false end
            if (trace.Entity:IsWorld()) then return false end
            if ( CLIENT ) then return true end
            trace.Entity:Extinguish()
            trace.Entity:Ignite( self.IgniteLength, 0 )
            Msg("Ignite\n")
		end
	else
	   if(iname == "Length") then
	       self.IgniteLength = math.min(value,GetConVarNumber("sbox_wire_igniters_maxlen"))
	       Msg("IgniteLen"..self.IgniteLength.."\n")
	   end
	end
end

function ENT:ShowOutput(value)
	if (value ~= self.PrevOutput) then
		self:SetOverlayText( "Ingiter" )
		self.PrevOutput = value
	end
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end

