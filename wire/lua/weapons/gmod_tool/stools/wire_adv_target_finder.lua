
TOOL.Category		= "Wire - Beacon"
TOOL.Name			= "Target Finder (Advanced)"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_adv_target_finder_name", "Target Finder Beacon Tool (Wire)" )
    language.Add( "Tool_wire_adv_target_finder_desc", "Spawns an enhanced target finder beacon for use with the wire system." )
    language.Add( "Tool_wire_adv_target_finder_0", "Primary: Create/Update Target Finder Beacon" )
    language.Add( "WireAdvTargetFinderTool_range", "Maximum Range:" )
    language.Add( "WireAdvTargetFinderTool_min_range", "Minimum Range:" )
    language.Add( "WireAdvTargetFinderTool_players", "Target Players:" )
    language.Add( "WireAdvTargetFinderTool_npcs", "Target NPCs:" )
    language.Add( "WireAdvTargetFinderTool_beacons", "Target Locators:" )
    language.Add( "WireAdvTargetFinderTool_hoverballs", "Target Hoverballs:" )
    language.Add( "WireAdvTargetFinderTool_thrusters", "Target Thrusters:" )
    language.Add( "WireAdvTargetFinderTool_rpgs", "Target RPGs:" )
	language.Add( "sboxlimit_wire_adv_target_finders", "You've hit advanced target finder limit!" )
	language.Add( "undone_wire_adv_target_finder", "Undone Wire Target Finder Beacon" )
	language.Add( "undo_wire_adv_target_find", "Wire Advanced Target Finder" )
end

if (SERVER) then
  CreateConVar('sbox_maxwire_adv_target_finders',30)
end

TOOL.ClientConVar[ "range" ] = "1000"
TOOL.ClientConVar[ "min_range" ] = "0"
TOOL.ClientConVar[ "players" ] = "0"
TOOL.ClientConVar[ "npcs" ] = "1"
TOOL.ClientConVar[ "beacons" ] = "0"
TOOL.ClientConVar[ "hoverballs" ] = "0"
TOOL.ClientConVar[ "thrusters" ] = "0"
TOOL.ClientConVar[ "rpgs" ] = "0"

TOOL.Model = "models/props_lab/powerbox02d.mdl"

cleanup.Register( "wire_adv_target_finders" )


function TOOL:LeftClick(trace)
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	
	// Get client's CVars
	local range		= self:GetClientNumber("range")
	local min_range = self:GetClientNumber("min_range")
	local players	= (self:GetClientNumber("players") ~= 0)
	local npcs		= (self:GetClientNumber("npcs") ~= 0)
	local beacons	= (self:GetClientNumber("beacons") ~= 0)
	local hoverballs = (self:GetClientNumber("hoverballs") ~= 0)
	local thrusters	= (self:GetClientNumber("thrusters") ~= 0)
	local rpgs 		= (self:GetClientNumber("rpgs") ~= 0)

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_adv_target_finder" && trace.Entity:GetTable().pl == ply ) then
		trace.Entity:GetTable():Setup(range, min_range, players, npcs, beacons, hoverballs, thrusters, rpgs)
		
		return true
	end	

	if ( !self:GetSWEP():CheckLimit( "wire_adv_target_finders" ) ) then return false end

	local Ang = trace.HitNormal:Angle()

	local wire_target_finder = MakeWireAdvTargetFinder( ply, trace.HitPos, Ang, range, min_range, players, npcs, beacons, hoverballs, thrusters, rpgs )

	local min = wire_target_finder:OBBMins()
	wire_target_finder:SetPos( trace.HitPos - trace.HitNormal*min.z )

	undo.Create("WireAdvTargetFinder")
		undo.AddEntity( wire_target_finder )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_adv_target_finders", wire_target_finder )

	return true
	
end


function TOOL:RightClick(trace)
	self:LeftClick(trace)
end


if SERVER then

	function MakeWireAdvTargetFinder(pl, Pos, Ang, range, min_range, players, npcs, beacons, hoverballs, thrusters, rpgs, Vel, aVel, frozen )
		if (!pl:CheckLimit("wire_adv_target_finders")) then return end

		local wire_adv_target_finder = ents.Create("gmod_wire_adv_target_finder")
		wire_adv_target_finder:SetPos(Pos)
		wire_adv_target_finder:SetAngles(Ang)
		wire_adv_target_finder:Spawn()
		wire_adv_target_finder:Activate()

		wire_adv_target_finder:GetTable():Setup(range, min_range, players, npcs, beacons, hoverballs, thrusters, rpgs)
		wire_adv_target_finder:GetTable():SetPlayer(pl)

		local ttable = {
			pl			= pl,
			nocollide	= nocollide,
			description = description
		}
		
		table.Merge( wire_adv_target_finder:GetTable(), ttable )

		pl:AddCount( "wire_adv_target_finders", wire_adv_target_finder )
		
		return wire_adv_target_finder
	end
	
end


function TOOL:UpdateGhostWireAdvTargetFinder( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	
	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_adv_target_finder" ) then
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
	
	self:UpdateGhostWireAdvTargetFinder( self.GhostEntity, self:GetOwner() )
end


function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_adv_target_finder_name", Description = "#Tool_wire_adv_target_finder_desc" })

	panel:AddControl("Slider", {
		Label = "#WireAdvTargetFinderTool_range",
		Type = "Float",
		Min = "1",
		Max = "1000",
		Command = "wire_adv_target_finder_range"
	})
	
    panel:AddControl("Slider", {
		Label = "#WireAdvTargetFinderTool_min_range",
		Type = "Float",
		Min = "0",
		Max = "1000",
		Command = "wire_adv_target_finder_min_range"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireAdvTargetFinderTool_players",
		Command = "wire_adv_target_finder_players"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireAdvTargetFinderTool_npcs",
		Command = "wire_adv_target_finder_npcs"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireAdvTargetFinderTool_beacons",
		Command = "wire_adv_target_finder_beacons"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireAdvTargetFinderTool_hoverballs",
		Command = "wire_adv_target_finder_hoverballs"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireAdvTargetFinderTool_thrusters",
		Command = "wire_adv_target_finder_thrusters"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireAdvTargetFinderTool_rpgs",
		Command = "wire_adv_target_finder_rpgs"
	})
end
	
