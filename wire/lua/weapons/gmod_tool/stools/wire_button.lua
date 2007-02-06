
TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Button"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_button_name", "Button Tool (Wire)" )
    language.Add( "Tool_wire_button_desc", "Spawns a button for use with the wire system." )
    language.Add( "Tool_wire_button_0", "Primary: Create/Update Button" )
    language.Add( "WireButtonTool_toggle", "Toggle:" )
    language.Add( "WireButtonTool_value_on", "Value On:" )
    language.Add( "WireButtonTool_value_off", "Value Off:" )
	language.Add( "sboxlimit_wire_buttons", "You've hit buttons limit!" )
	language.Add( "undone_wirebutton", "Undone Wire Button" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_buttons', 20)
end

TOOL.ClientConVar[ "model" ] = "models/props_c17/clock01.mdl"
TOOL.ClientConVar[ "toggle" ] = "0"
TOOL.ClientConVar[ "value_off" ] = "0"
TOOL.ClientConVar[ "value_on" ] = "1"
TOOL.ClientConVar[ "description" ] = ""

if (SERVER) then
	ModelPlug_Register("button")
end

cleanup.Register( "wire_buttons" )

function TOOL:LeftClick( trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()


	// Get client's CVars
	local _model			= self:GetClientInfo( "model" )
	local _toggle			= (self:GetClientNumber( "toggle" ) ~= 0)
	local _value_off		= self:GetClientNumber( "value_off" )
	local _value_on			= self:GetClientNumber( "value_on" )
	local _description		= self:GetClientInfo( "description" )

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_button" && trace.Entity.pl == ply ) then
		trace.Entity:Setup(_toggle, _value_off, _value_on)
		trace.Entity.toggle = _toggle
		trace.Entity.value_off = _value_off
		trace.Entity.value_on = _value_on
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_buttons" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_button = MakeWireButton( ply, _model, trace.HitPos, Ang, _toggle, _value_off, _value_on, _description )

	local min = wire_button:OBBMins()
	wire_button:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_button, trace.Entity, 0, trace.PhysicsBone, 0, true )
		trace.Entity:DeleteOnRemove( wire_button )
		// Don't disable collision if it's not attached to anything
		wire_button:GetPhysicsObject():EnableCollisions( false )
		wire_button.nocollide = true
	end

	undo.Create("WireButton")
		undo.AddEntity( wire_button )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()


	ply:AddCleanup( "wire_buttons", wire_button )

	return true

end

if (SERVER) then

	function MakeWireButton( pl, Model, Pos, Ang, toggle, value_off, value_on, description, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_buttons" ) ) then return false end
	
		local wire_button = ents.Create( "gmod_wire_button" )
		if (!wire_button:IsValid()) then return false end

		wire_button:SetModel( Model )
		wire_button:SetAngles( Ang )
		wire_button:SetPos( Pos )
		wire_button:Spawn()

		wire_button:Setup(toggle, value_off, value_on )
		wire_button:SetPlayer( pl )

		local ttable = {
			toggle			= toggle,
			value_off		= value_off,
			value_on		= value_on,
			pl              = pl
			}

		table.Merge(wire_button:GetTable(), ttable )
		
		pl:AddCount( "wire_buttons", wire_button )

		return wire_button
	end

	duplicator.RegisterEntityClass("gmod_wire_button", MakeWireButton, "Model", "Pos", "Ang", "toggle", "value_off", "value_on", "description", "Vel", "aVel", "frozen" )

end

function TOOL:UpdateGhostWireButton( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_button" ) then
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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" ) ) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireButton( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_button_name", Description = "#Tool_wire_button_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_button",

		Options = {
			Default = {
				wire_button_toggle = "0",
				wire_button_value_on = "1",
				wire_button_value_off = "0"
			}
		},

		CVars = {
			[0] = "wire_button_toggle",
			[1] = "wire_button_value_on",
			[2] = "wire_button_value_off"
		}
	})

	ModelPlug_AddToCPanel(panel, "button", "wire_button", "#Button_Model", nil, "#Button_Model")

//  ToDo: Move these to Wire Model Pack 1
//			["Start"] = { wire_button_model = "models/cheeze/buttons/chz_button_start.mdl" },
//			["Reset"] = { wire_button_model = "models/cheeze/buttons/chz_button_reset.mdl" },
//			["Enter"] = { wire_button_model = "models/cheeze/buttons/chz_button_enter.mdl" },
//			["Stop"] = { wire_button_model = "models/cheeze/buttons/chz_button_stop.mdl" },
//			["Key 1"] = { wire_button_model = "models/cheeze/buttons/chz_button1.mdl" },
//			["Key 2"] = { wire_button_model = "models/cheeze/buttons/chz_button2.mdl" },
//			["Key 3"] = { wire_button_model = "models/cheeze/buttons/chz_button3.mdl" },
//			["Key 4"] = { wire_button_model = "models/cheeze/buttons/chz_button4.mdl" },
//			["Key 5"] = { wire_button_model = "models/cheeze/buttons/chz_button5.mdl" },
//			["Key 6"] = { wire_button_model = "models/cheeze/buttons/chz_button6.mdl" },
//			["Key 7"] = { wire_button_model = "models/cheeze/buttons/chz_button7.mdl" },
//			["Key 8"] = { wire_button_model = "models/cheeze/buttons/chz_button8.mdl" },
//			["Key 9"] = { wire_button_model = "models/cheeze/buttons/chz_button9.mdl" },
//			["Key 0"] = { wire_button_model = "models/cheeze/buttons/chz_button0.mdl" },
//			["Set"] = { wire_button_model = "models/cheeze/buttons/chz_button_set.mdl" },
//			["Plus"] = { wire_button_model = "models/cheeze/buttons/chz_button_plus.mdl" },
//			["Minus"] = { wire_button_model = "models/cheeze/buttons/chz_button_minus.mdl" },
//			["Clear"] = { wire_button_model = "models/cheeze/buttons/chz_button_clear.mdl" },
//			["Arm"] = { wire_button_model = "models/cheeze/buttons/chz_button_arm.mdl" },
//			["Muffin!"] = { wire_button_model = "models/cheeze/buttons/muffin.mdl" },

	panel:AddControl("CheckBox", {
		Label = "#WireButtonTool_toggle",
		Command = "wire_button_toggle"
	})

	panel:AddControl("Slider", {
		Label = "#WireButtonTool_value_on",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_button_value_on"
	})
	panel:AddControl("Slider", {
		Label = "#WireButtonTool_value_off",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_button_value_off"
	})
end
