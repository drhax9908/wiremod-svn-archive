
TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Forcer"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_forcer_name", "Forcer Tool (Wire)" )
    language.Add( "Tool_wire_forcer_desc", "Spawns a forcer prop for use with the wire system." )
    language.Add( "Tool_wire_forcer_0", "Primary: Create/Update Forcer" )
    language.Add( "WireForcerTool_forcer", "Forcer:" )
    language.Add( "WireForcerTool_Model", "Choose a Model:")
	language.Add( "sboxlimit_wire_forcers", "You've hit forcers limit!" )
	language.Add( "undone_wireforcer", "Undone Wire Forcer" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_forcers', 20)
end

TOOL.ClientConVar[ "multiplier" ] = "1"
TOOL.ClientConVar[ "length" ] = "100"
TOOL.ClientConVar[ "beam" ] = "1"
TOOL.ClientConVar[ "Model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"

local forcermodels = {
    ["models/jaanus/wiretool/wiretool_grabber_forcer.mdl"] = {},
    ["models/jaanus/wiretool/wiretool_siren.mdl"] = {}};

cleanup.Register( "wire_forcers" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_forcer" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_forcers" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local showbeam = self:GetClientNumber( "beam" ) == 1
	local model = self:GetClientInfo("Model")
	
	local wire_forcer = MakeWireForcer( ply, trace.HitPos, Ang, self:GetClientNumber( "multiplier" ), self:GetClientNumber( "length" ), showbeam, model )

	local min = wire_forcer:OBBMins()
	if(model == "models/jaanus/wiretool/wiretool_grabber_forcer.mdl")then
	   wire_forcer:SetPos( trace.HitPos - trace.HitNormal * (min.z + 20) )
	else
	   wire_forcer:SetPos( trace.HitPos - trace.HitNormal * min.z )
	end

	/*local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_forcer, trace.Entity, 0, trace.PhysicsBone, 0, true, true )
		// Don't disable collision if it's not attached to anything
		wire_forcer:GetPhysicsObject():EnableCollisions( false )
		wire_forcer:GetTable().nocollide = true
	end*/
	local const = WireLib.Weld(wire_forcer, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireForcer")
		undo.AddEntity( wire_forcer )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()


	ply:AddCleanup( "wire_forcers", wire_forcer )

	return true
end

function TOOL:RightClick( trace )
	return false
end

if (SERVER) then

	function MakeWireForcer( pl, Pos, Ang, Force, Length, showbeam,Model )
		if ( !pl:CheckLimit( "wire_forcers" ) ) then return false end
	
		local wire_forcer = ents.Create( "gmod_wire_forcer" )
		if (!wire_forcer:IsValid()) then return false end

		wire_forcer:SetAngles( Ang )
		wire_forcer:SetPos( Pos )
		wire_forcer:SetModel( Model )
		wire_forcer:Spawn()

		wire_forcer:GetTable():Setup(Force, Length, showbeam)
		wire_forcer:GetTable():SetPlayer( pl )
		
		local ttable = {
			pl		= pl,
			Force	= Force,
			Length	= Length,
			showbeam = showbeam,
		}

		table.Merge(wire_forcer:GetTable(), ttable )
		
		pl:AddCount( "wire_forcers", wire_forcer )

		return wire_forcer
	end
	
	duplicator.RegisterEntityClass("gmod_wire_forcer", MakeWireForcer, "Pos", "Ang", "Force", "Length", "showbeam", "Model", "Vel", "aVel", "frozen")
	
end

function TOOL:UpdateGhostWireForcer( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_forcer" ) then
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

	self:UpdateGhostWireForcer( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_forcer_name", Description = "#Tool_wire_forcer_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_forcer",

		Options = {
			Default = {
				wire_forcer_forcer = "0",
			}
		},
		CVars = {
		}
	})
	
	panel:AddControl( "PropSelect", { Label = "#WireForcerTool_Model",
									 ConVar = "wire_forcer_Model",
									 Category = "Wire Forcer",
									 Models = forcermodels } )
	
	panel:AddControl("Slider", {
		Label = "Force multiplier",
		Type = "Float",
		Min = "1",
		Max = "10000",
		Command = "wire_forcer_multiplier"
  }) 
  	panel:AddControl("Slider", {
		Label = "Force distance (How long away the force gets applied)",
		Type = "Float",
		Min = "1",
		Max = "10000",
		Command = "wire_forcer_length"
  })
  panel:AddControl( "Checkbox", { Label = "Show Beam", Command = "wire_forcer_beam" } )
end
