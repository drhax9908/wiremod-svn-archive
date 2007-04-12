
TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Two-way Radio"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_twoway_radio_name", "Two-Way Radio Tool (Wire)" )
    language.Add( "Tool_wire_twoway_radio_desc", "Spawns a two-way radio for use with the wire system." )
    language.Add( "Tool_wire_twoway_radio_0", "Primary: Create/Update Two-way Radio\nSecondary: Select a two-way radio to pair up with another two-way radio." )
	language.Add( "Tool_wire_twoway_radio_1", "Select the second two-way radio." );
	language.Add( "WireRadioTwoWayTool_model", "Model:" );
	language.Add( "sboxlimit_wire_twoway_radios", "You've hit the two-way radio limit!" )
	language.Add( "undone_wiretwowayradio", "Undone Wire Two-way Radio" )
end

if (SERVER) then
  CreateConVar('sbox_maxwire_twoway_radioes',30)
end

TOOL.ClientConVar[ "model" ] = "models/props_lab/bindergreen.mdl"

if (SERVER) then
	ModelPlug_Register("radio")
end

TOOL.FirstPeer = nil

cleanup.Register( "wire_twoway_radioes" )

function TOOL:LeftClick( trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	
	local model             = self:GetClientInfo( "model" )

	// Get client's CVars
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_twoway_radio" && trace.Entity.pl == ply ) then
		if (self.FirstPeer) and (self.FirstPeer:IsValid()) then
		    local first = self.FirstPeer
			local second = trace.Entity
			
			-- Set the two entities to point to each other.
			local id = Radio_GetTwoWayID()
			first:RadioLink(second, id)
			second:RadioLink(first, id)

			self:GetOwner():SendLua( "GAMEMODE:AddNotify('Radioes paired up. Pair ID is " .. tostring(id) .. ".', NOTIFY_GENERIC, 7);" )
			
			self.FirstPeer = nil
			
			return true
		else
			trace.Entity:Setup( _channel )
			return true
		end
	else
		if self.FirstPeer then
			self.FirstPeer = nil
			return
		end
	end	

	if ( !self:GetSWEP():CheckLimit( "wire_twoway_radioes" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	local wire_twoway_radio = MakeWireTwoWay_Radio( ply, model, trace.HitPos, Ang, nil )
	
	local min = wire_twoway_radio:OBBMins()
	wire_twoway_radio:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	// Don't weld to world
	/*local const
	if ( trace.Entity:IsValid() ) then
		local const = constraint.Weld( wire_twoway_radio, trace.Entity, 0, trace.PhysicsBone, 0, true, true )
		
		// Don't disable collision if it's not attached to anything
		if ( collision == 0 ) then 
			wire_twoway_radio:GetPhysicsObject():EnableCollisions( false )
			wire_twoway_radio:GetTable().nocollide = true
		end
	end*/
	local const = WireLib.Weld(wire_twoway_radio, trace.Entity, trace.PhysicsBone, true)
	
	undo.Create("WireTwoWay_Radio")
		undo.AddEntity( wire_twoway_radio )
		undo.SetPlayer( ply )
		undo.AddEntity( const )
	undo.Finish()
		
	ply:AddCleanup( "wire_twoway_radioes", wire_twoway_radio )
	
	return true
	
end

function TOOL:RightClick( trace )
	if (self.FirstPeer) then return self:LeftClick( trace ) end
	
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_twoway_radio" && trace.Entity.pl == ply ) then
		self.FirstPeer = trace.Entity
		
		return true
	end
end

if SERVER then

	// Having PeerID and Other in the duplicator was making it error out
	// by trying to reference a two-way radio that didn't exist yet
	// Build/ApplyDupeInfo now handle this (TheApathetic)
	function MakeWireTwoWay_Radio(pl, Model, Pos, Ang, Vel, aVel, frozen) //PeerID, Other, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_twoway_radioes" ) ) then return nil end

		local wire_twoway_radio = ents.Create( "gmod_wire_twoway_radio" )
		wire_twoway_radio:SetPos( Pos )
		wire_twoway_radio:SetAngles( Ang )
		wire_twoway_radio:SetModel(Model)
		wire_twoway_radio:Spawn()
		wire_twoway_radio:Activate()
		
		wire_twoway_radio:Setup( channel )
		wire_twoway_radio:SetPlayer( pl )

		local ttable = 
		{
			//PeerID      = PeerID,
			//Other		= Other,
			pl			= pl,
			nocollide	= nocollide,
			description = description
		}
		
		table.Merge( wire_twoway_radio:GetTable(), ttable )

		pl:AddCount( "wire_twoway_radioes", wire_twoway_radio )
		
		return wire_twoway_radio
	end

	duplicator.RegisterEntityClass("gmod_wire_twoway_radio", MakeWireTwoWay_Radio, "Model", "Pos", "Ang", "Vel", "aVel", "frozen") //"PeerID", "Other", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireTwoWay_Radio( ent, player )

	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	
	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_twoway_radio" ) then
		ent:SetNoDraw( true )
		return
	end
	
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	ent:SetAngles( Ang )	

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	ent:SetNoDraw( false )

end

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" )) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end
	
	self:UpdateGhostWireTwoWay_Radio( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_twoway_radio_name", Description = "#Tool_wire_twoway_radio_desc" })

	ModelPlug_AddToCPanel(panel, "radio2", "wire_twoway_radio", "#WireRadioTwoWayTool_model", nil, "#WireRadioTwoWayTool_model")
end
