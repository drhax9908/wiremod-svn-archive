
TOOL.Category		= "Wire"
TOOL.Name			= "Value"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_value_name", "Value Tool (Wire)" )
    language.Add( "Tool_wire_value_desc", "Spawns a constant value prop for use with the wire system." )
    language.Add( "Tool_wire_value_0", "Primary: Create/Update Value   Secondary: Copy Settings" )
    language.Add( "WireValueTool_value", "Value:" )
	language.Add( "sboxlimit_wire_values", "You've hit values limit!" )
	language.Add( "undone_wirevalue", "Undone Wire Value" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_values', 20)
end

TOOL.ClientConVar[ "value" ] = "0"

TOOL.Model = "models/props_lab/reciever01d.mdl"

cleanup.Register( "wire_values" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()


	// Get client's CVars
	local value = self:GetClientNumber( "value" )

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_value" && trace.Entity.pl == ply ) then
		trace.Entity:Setup(value)
		trace.Entity.value = value
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_values" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_value = MakeWireValue( ply, trace.HitPos, Ang, value )

	local min = wire_value:OBBMins()
	wire_value:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_value, trace.Entity, 0, trace.PhysicsBone, 0, true )
		trace.Entity:DeleteOnRemove( wire_value )
		// Don't disable collision if it's not attached to anything
		wire_value:GetPhysicsObject():EnableCollisions( false )
		wire_value.nocollide = true
	end

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
	    self:GetOwner():ConCommand("wire_value_value " .. trace.Entity.Value)
		return true
	end
end

if (SERVER) then

	function MakeWireValue( pl, Pos, Ang, value, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_values" ) ) then return false end
	
		local wire_value = ents.Create( "gmod_wire_value" )
		if (!wire_value:IsValid()) then return false end

		wire_value:SetAngles( Ang )
		wire_value:SetPos( Pos )
		wire_value:SetModel( Model("models/props_lab/reciever01d.mdl") )
		wire_value:Spawn()

		wire_value:Setup(value)
		wire_value:SetPlayer( pl )

		local ttable = {
			value			= value,
			pl              = pl
			}

		table.Merge(wire_value:GetTable(), ttable )
		
		pl:AddCount( "wire_values", wire_value )

		return wire_value
	end

	duplicator.RegisterEntityClass("gmod_wire_value", MakeWireValue, "Pos", "Ang", "value", "Vel", "aVel", "frozen")

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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self.Model ) then
		self:MakeGhostEntity( self.Model, Vector(0,0,0), Angle(0,0,0) )
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

	panel:AddControl("Slider", {
		Label = "#WireValueTool_value",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_value_value"
	})
end
