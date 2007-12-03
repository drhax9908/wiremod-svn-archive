
TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Igniter"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_igniter_name", "Igniter Tool (Wire)" )
    language.Add( "Tool_wire_igniter_desc", "Spawns a constant igniter prop for use with the wire system." )
    language.Add( "Tool_wire_igniter_0", "Primary: Create/Update Igniter" )
    language.Add( "WireIgniterTool_igniter", "Igniter:" )
    language.Add( "WireIgniterTool_trgply", "Allow Player Igniting:" )
    language.Add( "WireIgniterTool_Range", "Max Range:" )
    language.Add( "WireIgniterTool_Model", "Choose a Model:")
	language.Add( "sboxlimit_wire_igniters", "You've hit igniters limit!" )
	language.Add( "undone_Wire Igniter", "Undone Wire Igniter" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_igniters', 20)
	CreateConVar('sbox_wire_igniters_maxlen', 30)
	CreateConVar('sbox_wire_igniters_allowtrgply',1)
end

TOOL.ClientConVar[ "trgply" ] = "0"
TOOL.ClientConVar[ "Range" ] = 2048
TOOL.ClientConVar[ "Model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"

local ignitermodels = {
    ["models/jaanus/wiretool/wiretool_beamcaster.mdl"] = {},
    ["models/jaanus/wiretool/wiretool_siren.mdl"] = {}};

cleanup.Register( "wire_igniters" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_igniter" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_igniters" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local targetPlayers	= (self:GetClientNumber( "trgply" ) ~= 0)
	local Range = self:GetClientNumber("Range")
	local model = self:GetClientInfo("Model")

	local wire_igniter = MakeWireIgniter( ply, trace.HitPos, targetPlayers, Range, model, Ang )

	local min = wire_igniter:OBBMins()
	wire_igniter:SetPos( trace.HitPos - trace.HitNormal * min.z )

	/*local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_nailer, trace.Entity, 0, trace.PhysicsBone, 0, true, true )
		// Don't disable collision if it's not attached to anything
		wire_nailer:GetPhysicsObject():EnableCollisions( false )
		wire_nailer:GetTable().nocollide = true
	end*/
	local const = WireLib.Weld(wire_igniter, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Igniter")
		undo.AddEntity( wire_igniter )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()


	ply:AddCleanup( "wire_igniters", wire_igniter )

	return true
end

function TOOL:RightClick( trace )
	return false
end

if (SERVER) then

	function MakeWireIgniter( pl, Pos, trgply, Range, Model, Ang )
		if ( !pl:CheckLimit( "wire_igniters" ) ) then return false end
	
		local wire_igniter = ents.Create( "gmod_wire_igniter" )
		if (!wire_igniter:IsValid()) then return false end

		wire_igniter:SetAngles( Ang )
		wire_igniter:SetPos( Pos )
		wire_igniter:SetModel( Model )
		wire_igniter:Spawn()
		wire_igniter:Setup(trgply,Range)

		wire_igniter:GetTable():SetPlayer( pl )

		local ttable = {
		    TargetPlayers = trgply,
		    Range = Range,
			pl = pl
		}

		table.Merge(wire_igniter:GetTable(), ttable )
		
		pl:AddCount( "wire_igniters", wire_igniter )

		return wire_igniter
	end
	
	duplicator.RegisterEntityClass("gmod_wire_igniter", MakeWireIgniter, "Pos", "TargetPlayers", "Range", "Model", "Ang", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireIgniter( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_igniter" ) then
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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo("Model") ) then
		self:MakeGhostEntity( self:GetClientInfo("Model"), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireIgniter( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_igniter_name", Description = "#Tool_wire_igniter_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_igniter",

		Options = {
			Default = {
				wire_igniter_igniter = "0",
			}
		},
		CVars = {
		}
	})
	
	panel:AddControl( "PropSelect", { Label = "#WireIgniterTool_Model",
									 ConVar = "wire_igniter_Model",
									 Category = "Wire Igniter",
									 Models = ignitermodels } )
	
	panel:AddControl("CheckBox", {
		Label = "#WireIgniterTool_trgply",
		Command = "wire_igniter_trgply"
	})
	
		panel:AddControl("Slider", {
		Label = "#WireIgniterTool_Range",
		Type = "Float",
		Min = "1",
		Max = "10000",
		Command = "wire_igniter_Range"
	})
end

