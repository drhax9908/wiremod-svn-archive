AddCSLuaFile( "helpers.lua" )

WireToolHelpers = {}

local function NoGhostOn(self, trace)
	return self.NoGhostOn and table.HasValue( self.NoGhostOn, trace.Entity:GetClass())
end

function WireToolHelpers.LeftClick( self, trace )
	if ( not trace.HitPos or trace.Entity:IsPlayer() or trace.Entity:IsNPC() ) then return false end
	if ( not self.AllowLeftOnClass and trace.HitNonWorld and (trace.Entity:GetClass() == self.WireClass or NoGhostOn(self, trace)) ) then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	local ent = self:ToolMakeEnt( trace, ply )
	if ( ent == true ) then return true end
	if ( ent == nil or ent == false or not ent:IsValid() ) then return false end

	local const = WireLib.Weld( ent, trace.Entity, trace.PhysicsBone, true )

	undo.Create( self.WireClass )
		undo.AddEntity( ent )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( self.WireClass, ent )

	return true
end

function WireToolHelpers.UpdateGhost( self, ent )

	if ( !ent or !ent:IsValid() ) then return end

	local tr 		= utilx.GetPlayerTrace( self:GetOwner(), self:GetOwner():GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:IsNPC() || trace.Entity:GetClass() == self.WireClass ) or ( NoGhostOn(self, trace) ) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()
	if (self.GetGhostAngle) then
		Ang = self:GetGhostAngle( Ang )
	elseif (self.GhostAngle) then
		Ang = Ang + self.GhostAngle
	end
	Ang.pitch = Ang.pitch + 90

	local min = ent:OBBMins()
	if (self.GetGhostMin) then
		ent:SetPos( trace.HitPos - trace.HitNormal * self:GetGhostMin( min ) )
	elseif (self.GhostMin) then
		ent:SetPos( trace.HitPos - trace.HitNormal * min[self.GhostMin] )
	else
		ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	end
	ent:SetAngles( Ang )

	ent:SetNoDraw( false )

end

function WireToolHelpers.Think( self )
	local model = self.Model or self:GetClientInfo( "model" )
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != model) then
		if (self.GetGhostAngle) then
			self:MakeGhostEntity( model, Vector(0,0,0), self:GetGhostAngle(Angle(0,0,0)) )
		else
			self:MakeGhostEntity( model, Vector(0,0,0), self.GhostAngle or Angle(0,0,0) )
		end
	end
	self:UpdateGhost( self.GhostEntity )
end


WireToolSetup = {}

function WireToolSetup.open( s_mode, s_cat, s_name, s_class, f_toolmakeent )
	if (TOOL) then WireToolSetup.close() end
	--Msg( "WireToolSetup.open ",s_mode,"\n")
	
	TOOL				= ToolObj:Create()
	TOOL.Command		= nil
	TOOL.ConfigName		= ""
	TOOL.LeftClick		= WireToolHelpers.LeftClick
	TOOL.UpdateGhost	= WireToolHelpers.UpdateGhost
	TOOL.Think			= WireToolHelpers.Think
	
	TOOL.Mode			= "wire_"..s_mode
	TOOL.Category		= "Wire - "..s_cat
	TOOL.Name			= s_name
	TOOL.WireClass		= s_class --should begin with gmod_wire_
	TOOL.ToolMakeEnt	= f_toolmakeent
end

function WireToolSetup.close()
	--Msg( "WireToolSetup.close ",TOOL.Mode,"\n")
	TOOL:CreateConVars()
	SWEP.Tool[ TOOL.Mode ] = TOOL
	TOOL = nil
end

base_tool = nil

--WireToolSetup.open( s_mode, s_cat, s_name, s_class, f_toolmakeent )
--WireToolSetup.close()