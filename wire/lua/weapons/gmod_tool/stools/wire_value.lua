TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Constant Value"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_value_name", "Value Tool (Wire)" )
    language.Add( "Tool_wire_value_desc", "Spawns a constant value prop for use with the wire system." )
    language.Add( "Tool_wire_value_0", "Primary: Create/Update Value   Secondary: Copy Settings" )
	language.Add( "WireValueTool_value", "Value:" )
    language.Add( "WireValueTool_model", "Model:" )
	language.Add( "sboxlimit_wire_values", "You've hit values limit!" )
	language.Add( "undone_wirevalue", "Undone Wire Value" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_values', 20)
	ModelPlug_Register("value")
end

TOOL.ClientConVar[ "model" ] = "models/kobilica/value.mdl"
TOOL.ClientConVar[ "numvalues" ] = "1"
TOOL.ClientConVar[ "value1" ] = "0"
TOOL.ClientConVar[ "value2" ] = "0"
TOOL.ClientConVar[ "value3" ] = "0"
TOOL.ClientConVar[ "value4" ] = "0"
TOOL.ClientConVar[ "value5" ] = "0"
TOOL.ClientConVar[ "value6" ] = "0"
TOOL.ClientConVar[ "value7" ] = "0"
TOOL.ClientConVar[ "value8" ] = "0"
TOOL.ClientConVar[ "value9" ] = "0"
TOOL.ClientConVar[ "value10" ] = "0"
TOOL.ClientConVar[ "value11" ] = "0"
TOOL.ClientConVar[ "value12" ] = "0"

cleanup.Register( "wire_values" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	
	local model		= self:GetClientInfo( "model" )
	local numvalues	= self:GetClientNumber( "numvalues" )
	
	//value is a table of strings so we can save a step later in adjusting the outputs
	local value = {}
	for i = 1, numvalues do
		value[i] = tostring( self:GetClientNumber( "value"..i ) )
	end
	
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_value" && trace.Entity.pl == ply ) then
		trace.Entity:Setup(value)
		trace.Entity.value = value
		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_values" ) ) then return false end
	
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local wire_value = MakeWireValue( ply, model, trace.HitPos, Ang, value )
	
	local min = wire_value:OBBMins()
	wire_value:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local const = WireLib.Weld(wire_value, trace.Entity, trace.PhysicsBone, true)
	
	undo.Create("WireValue")
		undo.AddEntity( wire_value )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
	
	ply:AddCleanup( "wire_values", wire_value )
	
	return true
end

function TOOL:RightClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_value" ) then
	    local i = 0
		for k,v in pairs(trace.Entity.value) do
			ply:ConCommand("wire_value_value"..k.." "..v)
			i = i + 1
		end
		ply:ConCommand("wire_value_numvalues "..i)
		return true
	end
end

if (SERVER) then

	function MakeWireValue( pl, Model, Pos, Ang, value, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_values" ) ) then return false end
	
		local wire_value = ents.Create( "gmod_wire_value" )
		if (!wire_value:IsValid()) then return false end

		wire_value:SetAngles( Ang )
		wire_value:SetPos( Pos )
		wire_value:SetModel( Model )
		wire_value:Spawn()
		
		//for old saves
		if type(value) != "table" then 
			local v = value
			value = {}
			value[v] = tostring(v)
		end
		
		wire_value:Setup(value)
		wire_value:SetPlayer( pl )

		local ttable = {
			value	= value,
			pl		= pl
		}
		table.Merge(wire_value:GetTable(), ttable )
		
		pl:AddCount( "wire_values", wire_value )

		return wire_value
	end

	duplicator.RegisterEntityClass("gmod_wire_value", MakeWireValue, "Model", "Pos", "Ang", "value", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireValue( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_value" ) then
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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" )) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireValue( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_value_name", Description = "#Tool_wire_value_desc" })
	
	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_value",
		
		Options = {
			Default = {
				wire_value_value = "0",
			}
		},
		
		CVars = {
			[0] = "wire_value_value",
		}
	})
	
	panel:AddControl("Button", {
		Text = "Reset values to zero",
		Name = "Reset",
		Command = "wire_value_value1 0;wire_value_value2 0;wire_value_value3 0;wire_value_value4 0;wire_value_value5 0;wire_value_value6 0;wire_value_value7 0;wire_value_value8 0;wire_value_value9 0;wire_value_value10 0;wire_value_value11 0;wire_value_value12 0;"
	})
	
	panel:AddControl("Slider", {
		Label = "Num of Values",
		Type = "Integer",
		Min = "1",
		Max = "12",
		Command = "wire_value_numvalues"
	})
	
	for i = 1,12 do
		panel:AddControl("Slider", {
			Label = "Value"..i..":",
			Type = "Float",
			Min = "-10",
			Max = "10",
			Command = "wire_value_value"..i
		})
	end
	
	ModelPlug_AddToCPanel(panel, "value", "wire_value", "#WireValueTool_model", nil, "#WireValueTool_model")
end
