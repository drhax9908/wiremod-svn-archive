
TOOL.Category		= "Wire - Beacon"
TOOL.Name			= "Target Finder"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_target_finder_name", "Target Finder Beacon Tool (Wire)" )
    language.Add( "Tool_wire_target_finder_desc", "Spawns a target finder beacon for use with the wire system." )
    language.Add( "Tool_wire_target_finder_0", "Primary: Create/Update Target Finder Beacon" )
    language.Add( "WireTargetFinderTool_range", "Range:" )
    language.Add( "WireTargetFinderTool_players", "Target players:" )
    language.Add( "WireTargetFinderTool_npcs", "Target NPCs:" )
    language.Add( "WireTargetFinderTool_beacons", "Target Locators:" )
    language.Add( "WireTargetFinderTool_hoverballs", "Target Hoverballs:" )
    language.Add( "WireTargetFinderTool_thrusters", "Target Thrusters:" )
    language.Add( "WireTargetFinderTool_rpgs", "Target RPGs:" )
    language.Add( "WireTargetFinderTool_OutDistance", "Output Distance/Bearing/Elevation:" )
    language.Add( "WireTargetFinderTool_PaintTarget", "Paint Target:" )
	language.Add( "sboxlimit_wire_target_finders", "You've hit target finder beacons limit!" )
	language.Add( "undone_wiretargetfinder", "Undone Wire Target Finder Beacon" )
end

if (SERVER) then
  CreateConVar('sbox_maxwire_target_finders',30)
end

TOOL.ClientConVar[ "range" ] 		= "1000"
TOOL.ClientConVar[ "players" ] 		= "0"
TOOL.ClientConVar[ "npcs" ] 		= "1"
TOOL.ClientConVar[ "beacons" ] 		= "0"
TOOL.ClientConVar[ "hoverballs" ] 	= "0"
TOOL.ClientConVar[ "thrusters" ] 	= "0"
TOOL.ClientConVar[ "rpgs" ] 		= "0"
TOOL.ClientConVar[ "painttarget" ]	= "1"

TOOL.Model = "models/props_lab/powerbox02d.mdl"

cleanup.Register( "wire_target_finders" )


function TOOL:LeftClick(trace)
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	
	// Get client's CVars
	local range			= self:GetClientNumber("range")
	local players		= (self:GetClientNumber("players") ~= 0)
	local npcs			= (self:GetClientNumber("npcs") ~= 0)
	local beacons		= (self:GetClientNumber("beacons") ~= 0)
	local hoverballs	= (self:GetClientNumber("hoverballs") ~= 0)
	local thrusters		= (self:GetClientNumber("thrusters") ~= 0)
	local rpgs 			= (self:GetClientNumber("rpgs") ~= 0)
	local painttarget 	= (self:GetClientNumber("painttarget") ~= 0)

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_target_finder" && trace.Entity.pl == ply ) then
		trace.Entity:Setup(range, players, npcs, beacons, hoverballs, thrusters, rpgs, painttarget)

		trace.Entity:GetTable().range		= range
		trace.Entity:GetTable().players		= players
		trace.Entity:GetTable().npcs		= npcs
		trace.Entity:GetTable().beacons		= beacons
		trace.Entity:GetTable().hoverballs	= hoverballs
		trace.Entity:GetTable().thrusters	= thrusters
		trace.Entity:GetTable().rpgs		= rpgs
		trace.Entity:GetTable().painttarget	= painttarget

		return true
	end	

	if ( !self:GetSWEP():CheckLimit( "wire_target_finders" ) ) then return false end

	local Ang = trace.HitNormal:Angle()

	local wire_target_finder = MakeWireTargetFinder( ply, trace.HitPos, Ang, range, players, npcs, beacons, hoverballs, thrusters, rpgs, painttarget )

	local min = wire_target_finder:OBBMins()
	wire_target_finder:SetPos( trace.HitPos - trace.HitNormal*min.z )
	
	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const, nocollide = constraint.Weld( wire_target_finder, trace.Entity, 0, trace.PhysicsBone, 0, collision == 0 )
		trace.Entity:DeleteOnRemove( wire_target_finder )
	end
	
	undo.Create("WireTargetFinder")
		undo.AddEntity( wire_target_finder )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_target_finders", wire_target_finder )

	return true
	
end


function TOOL:RightClick(trace)
	return self:LeftClick(trace)
end


if SERVER then

	function MakeWireTargetFinder(pl, Pos, Ang, range, players, npcs, beacons, hoverballs, thrusters, rpgs, painttarget, Vel, aVel, frozen )
		if (!pl:CheckLimit("wire_target_finders")) then return end

		local wire_target_finder = ents.Create("gmod_wire_target_finder")
		wire_target_finder:SetPos(Pos)
		wire_target_finder:SetAngles(Ang)
		wire_target_finder:SetModel( Model("models/props_lab/powerbox02d.mdl") )
		wire_target_finder:Spawn()
		wire_target_finder:Activate()
		
		wire_target_finder:Setup(range, players, npcs, beacons, hoverballs, thrusters, rpgs, painttarget)
		wire_target_finder:SetPlayer(pl)

		local ttable = {
			range		= range,
			players		= players,
			npcs		= npcs,
			beacons		= beacons,
			hoverballs	= hoverballs,
			thrusters	= thrusters,
			rpgs		= rpgs,
			painttarget = painttarget,
			pl			= pl,
			nocollide	= nocollide,
			description = description
		}
		
		table.Merge( wire_target_finder:GetTable(), ttable )

		pl:AddCount( "wire_target_finders", wire_target_finder )
		
		return wire_target_finder
	end

	duplicator.RegisterEntityClass("gmod_wire_target_finder", MakeWireTargetFinder, "Pos", "Ang", "range", "players", "npcs", "beacons", "hoverballs", "thrusters", "rpgs", "painttarget", "Vel", "aVel", "frozen")

end


function TOOL:UpdateGhostWireTargetFinder( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	
	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_target_finder" ) then
		ent:SetNoDraw( true )
		return
	end
	
	local Ang = trace.HitNormal:Angle()

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )

	ent:SetNoDraw( false )
end


function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self.Model ) then
		self:MakeGhostEntity( self.Model, Vector(0,0,0), Angle(0,0,0) )
	end
	
	self:UpdateGhostWireTargetFinder( self.GhostEntity, self:GetOwner() )
end


function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_target_finder_name", Description = "#Tool_wire_target_finder_desc" })

	panel:AddControl("Slider", {
		Label = "#WireTargetFinderTool_range",
		Type = "Float",
		Min = "1",
		Max = "1000",
		Command = "wire_target_finder_range"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_players",
		Command = "wire_target_finder_players"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_npcs",
		Command = "wire_target_finder_npcs"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_beacons",
		Command = "wire_target_finder_beacons"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_hoverballs",
		Command = "wire_target_finder_hoverballs"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_thrusters",
		Command = "wire_target_finder_thrusters"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_rpgs",
		Command = "wire_target_finder_rpgs"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_PaintTarget",
		Command = "wire_target_finder_painttarget"
	})
end
	
