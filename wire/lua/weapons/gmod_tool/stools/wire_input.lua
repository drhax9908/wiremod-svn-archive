TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Numpad Input"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_input_name", "Input Tool (Wire)" )
    language.Add( "Tool_wire_input_desc", "Spawns a input for use with the wire system." )
    language.Add( "Tool_wire_input_0", "Primary: Create/Update Input" )
    language.Add( "WireInputTool_keygroup", "Key:" )
    language.Add( "WireInputTool_toggle", "Toggle:" )
    language.Add( "WireInputTool_value_on", "Value On:" )
    language.Add( "WireInputTool_value_off", "Value Off:" )
	language.Add( "sboxlimit_wire_inputs", "You've hit inputs limit!" )
	language.Add( "undone_wireinput", "Undone Wire Input" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_inputs', 20)
end

TOOL.ClientConVar[ "keygroup" ] = "7"
TOOL.ClientConVar[ "toggle" ] = "0"
TOOL.ClientConVar[ "value_off" ] = "0"
TOOL.ClientConVar[ "value_on" ] = "1"

TOOL.Model = "models/jaanus/wiretool/wiretool_input.mdl"

cleanup.Register( "wire_inputs" )

function TOOL:LeftClick( trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	local _keygroup			= self:GetClientNumber( "keygroup" )
	local _toggle			= self:GetClientNumber( "toggle" )
	local _value_off		= self:GetClientNumber( "value_off" )
	local _value_on			= self:GetClientNumber( "value_on" )

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_input" && trace.Entity.pl == ply ) then
		trace.Entity:Setup( _keygroup, _toggle, _value_off, _value_on )
		trace.Entity.keygroup	= _keygroup
		trace.Entity.toggle		= _toggle
		trace.Entity.value_off	= _value_off
		trace.Entity.value_on	= _value_on
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_inputs" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_input = MakeWireInput( ply, trace.HitPos, Ang, _keygroup, _toggle, _value_off, _value_on )

	local min = wire_input:OBBMins()
	wire_input:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_input, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireInput")
		undo.AddEntity( wire_input )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_inputs", wire_input )

	return true

end

if (SERVER) then

	function MakeWireInput( pl, Pos, Ang, keygroup, toggle, value_off, value_on, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_inputs" ) ) then return false end
	
		local wire_input = ents.Create( "gmod_wire_input" )
		if (!wire_input:IsValid()) then return false end

		wire_input:SetAngles( Ang )
		wire_input:SetPos( Pos )
		wire_input:SetModel( Model("models/jaanus/wiretool/wiretool_input.mdl") )
		wire_input:Spawn()

		wire_input:SetPlayer( pl )
		wire_input:Setup( keygroup, toggle, value_off, value_on )

		local ttable = {
			keygroup		= keygroup,
			toggle			= toggle,
			value_off		= value_off,
			value_on		= value_on,
			pl              = pl
		}
		table.Merge(wire_input, ttable )
		
		pl:AddCount( "wire_inputs", wire_input )

		return wire_input
	end

	duplicator.RegisterEntityClass("gmod_wire_input", MakeWireInput, "Pos", "Ang", "keygroup", "toggle", "value_off", "value_on", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireInput( ent, player )

	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_input" ) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )

	ent:SetNoDraw( false )

end

function TOOL:Think()

	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self.Model ) then
		self:MakeGhostEntity( self.Model, Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireInput( self.GhostEntity, self:GetOwner() )

end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_input_name", Description = "#Tool_wire_input_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_input",

		Options = {
			Default = {
				wire_input_keygroup = "1",
				wire_input_toggle = "0",
				wire_input_value_on = "1",
				wire_input_value_off = "0"
			}
		},

		CVars = {
			[0] = "wire_input_keygroup",
			[1] = "wire_input_toggle",
			[2] = "wire_input_value_on",
			[3] = "wire_input_value_off"
		}
	})

	panel:AddControl("Numpad", {
		Label = "#WireInputTool_keygroup",
		Command = "wire_input_keygroup",
		ButtonSize = "22"
	})
	panel:AddControl("CheckBox", {
		Label = "#WireInputTool_toggle",
		Command = "wire_input_toggle"
	})

	panel:AddControl("Slider", {
		Label = "#WireInputTool_value_on",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_input_value_on"
	})
	panel:AddControl("Slider", {
		Label = "#WireInputTool_value_off",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_input_value_off"
	})
end
