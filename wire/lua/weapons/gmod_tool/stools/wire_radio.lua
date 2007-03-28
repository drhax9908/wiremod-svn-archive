
TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Radio"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_radio_name", "Radio Tool (Wire)" )
    language.Add( "Tool_wire_radio_desc", "Spawns a radio for use with the wire system." )
    language.Add( "Tool_wire_radio_0", "Primary: Create/Update Radio" )
    language.Add( "WireRadioTool_channel", "Channel:" )
	language.Add( "WireRadioTool_model", "Model:" );
	language.Add( "sboxlimit_wire_radios", "You've hit the radio limit!" )
	language.Add( "undone_wireradio", "Undone Wire Radio" )
end

if (SERVER) then
  CreateConVar('sbox_maxwire_radioes',30)
end

TOOL.ClientConVar[ "channel" ] = 1
TOOL.ClientConVar[ "model" ] = "models/props_lab/binderblue.mdl"

if (SERVER) then
	ModelPlug_Register("radio")
end

TOOL.Model = "models/props_lab/binderblue.mdl"

cleanup.Register( "wire_radioes" )

function TOOL:LeftClick( trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	

	// Get client's CVars
	local _channel			= self:GetClientInfo( "channel" )
	local model             = self:GetClientInfo( "model" )

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_radio" && trace.Entity.pl == ply ) then
		trace.Entity:Setup( _channel )
		trace.Entity:GetTable().channel = _channel
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_radioes" ) ) then return false end

	local wire_radio = MakeWireRadio( ply, model, trace.HitPos, Angle( 90, 0, 0 ), _channel )
	
	local min = wire_radio:OBBMins()
	wire_radio:SetPos( trace.HitPos - trace.HitNormal * (min.z-5) )
	
	// Don't weld to world
	/*local const
	if ( trace.Entity:IsValid() ) then
		local const = constraint.Weld( wire_radio, trace.Entity, 0, trace.PhysicsBone, 0, true, true )
		
		// Don't disable collision if it's not attached to anything
		if ( collision == 0 ) then 
			wire_radio:GetPhysicsObject():EnableCollisions( false )
			wire_radio:GetTable().nocollide = true
		end
	end*/
	local const = WireLib.Weld(wire_radio, trace.Entity, trace.PhysicsBone, true)
	
	undo.Create("WireRadio")
		undo.AddEntity( wire_radio )
		undo.SetPlayer( ply )
		undo.AddEntity(const)
	undo.Finish()
	
	
	ply:AddCleanup( "wire_radioes", wire_radio )
	
	return true
	
end

function TOOL:RightClick( trace )
	return self:LeftClick( trace )
end

if SERVER then

	function MakeWireRadio(pl, Model, Pos, Ang, channel, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_radioes" ) ) then return nil end

		local wire_radio = ents.Create( "gmod_wire_radio" )
		wire_radio:SetPos( Pos )
		wire_radio:SetAngles( Ang )
		wire_radio:SetModel(Model)
		wire_radio:Spawn()
		wire_radio:Activate()
		
		wire_radio:Setup( channel )
		wire_radio:SetPlayer( pl )

		local ttable = 
		{
			channel      = channel,
			pl			= pl,
			nocollide	= nocollide,
			description = description
		}
		
		table.Merge( wire_radio:GetTable(), ttable )

		pl:AddCount( "wire_radioes", wire_radio )
		
		return wire_radio
	end

	duplicator.RegisterEntityClass("gmod_wire_radio", MakeWireRadio, "Model", "Pos", "Ang", "channel", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireRadio( ent, player )

	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	
	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_radio" ) then
		ent:SetNoDraw( true )
		return
	end
	
	local Ang = Angle( 90, 0, 0 )
	ent:SetAngles( Ang )	

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * (min.z-5) )
	
	ent:SetNoDraw( false )

end

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" )) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end
	
	self:UpdateGhostWireRadio( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_radio_name", Description = "#Tool_wire_radio_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_radio",

		Options = {
			Default = {
				wire_radio_channel = "1",
			}
		},

		CVars = {
			[0] = "wire_radio_channel",
		}
	})

	panel:AddControl("Slider", {
		Label = "#WireRadioTool_channel",
		Type = "Integer",
		Min = "1",
		Max = "30",
		Command = "wire_radio_channel"
	})

	ModelPlug_AddToCPanel(panel, "radio", "wire_radio", "#WireRadioTool_model", nil, "#WireRadioTool_model")
end
