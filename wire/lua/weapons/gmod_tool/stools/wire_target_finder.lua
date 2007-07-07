
TOOL.Category		= "Wire - Beacon"
TOOL.Name			= "Target Finder"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
	language.Add( "Tool_wire_target_finder_name", "Target Finder Beacon Tool (Wire)" )
	language.Add( "Tool_wire_target_finder_desc", "Spawns a target finder beacon for use with the wire system." )
	language.Add( "Tool_wire_target_finder_0", "Primary: Create/Update Target Finder Beacon" )
	
	//language.Add( "WireTargetFinderTool_range", "Range:" )
	language.Add( "WireTargetFinderTool_players", "Target players:" )
	language.Add( "WireTargetFinderTool_npcs", "Target NPCs:" )
	language.Add( "WireTargetFinderTool_npcname", "NPC Filter:" )
	language.Add( "WireTargetFinderTool_beacons", "Target Locators:" )
	language.Add( "WireTargetFinderTool_hoverballs", "Target Hoverballs:" )
	language.Add( "WireTargetFinderTool_thrusters", "Target Thrusters:" )
	language.Add( "WireTargetFinderTool_props", "Target Props:" )
	language.Add( "WireTargetFinderTool_propmodel", "Prop Model Filter:" )
	language.Add( "WireTargetFinderTool_vehicles", "Target Vehicles:" )
	language.Add( "WireTargetFinderTool_rpgs", "Target RPGs:" )
	language.Add( "WireTargetFinderTool_OutDistance", "Output Distance/Bearing/Elevation:" )
	language.Add( "WireTargetFinderTool_PaintTarget", "Paint Target:" )
	language.Add( "WireTargetFinderTool_casesen", "Case Sensitive:" )
	language.Add( "WireTargetFinderTool_playername", "Name Filter:" )
	language.Add( "WireTargetFinderTool_entity", "Entity Name:" )
	language.Add( "WireTargetFinderTool_minrange", "Minimum Range:" )
	language.Add( "WireTargetFinderTool_maxrange", "Maximum Range:" )
	language.Add( "WireTargetFinderTool_PaintTarget", "Paint Current Target:" )
	language.Add( "WireTargetFinderTool_PaintTarget_desc", "Paints currently selected target(s)." )
	language.Add( "WireTargetFinderTool_maxtargets", "Maximum number of targets to track:" )
	language.Add( "WireTargetFinderTool_notowner", "Do not target owner:" )
	language.Add( "WireTargetFinderTool_MaxBogeys", "Max number of bogeys (closest):" )
	language.Add( "WireTargetFinderTool_MaxBogeys_desc", "Set to 0 for all within range, this needs to be atleast as many as Max Targets." )
	
	language.Add( "sboxlimit_wire_target_finders", "You've hit target finder beacons limit!" )
	language.Add( "undone_wiretargetfinder", "Undone Wire Target Finder Beacon" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_target_finders',30)
	// The Multi-Target finder uses the same sbox CVar for regular Target Finders

	// Server CVar to control maximum targets that players
	// can find per Multi-Target Finder (to control lag, etc.)
	CreateConVar("wire_target_finders_maxtargets",10)
	CreateConVar("wire_target_finders_maxbogeys",30)
end

TOOL.ClientConVar[ "minrange" ]		= "1"
TOOL.ClientConVar[ "maxrange" ]		= "1000"
TOOL.ClientConVar[ "players" ] 		= "0"
TOOL.ClientConVar[ "npcs" ] 		= "1"
TOOL.ClientConVar[ "npcname" ] 		= ""
TOOL.ClientConVar[ "beacons" ] 		= "0"
TOOL.ClientConVar[ "hoverballs" ] 	= "0"
TOOL.ClientConVar[ "thrusters" ] 	= "0"
TOOL.ClientConVar[ "props" ] 		= "0"
TOOL.ClientConVar[ "propmodel" ] 	= ""
TOOL.ClientConVar[ "vehicles" ] 	= "0"
TOOL.ClientConVar[ "playername" ] 	= ""
TOOL.ClientConVar[ "casesen" ] 		= "0"
TOOL.ClientConVar[ "rpgs" ] 		= "0"
TOOL.ClientConVar[ "painttarget" ]	= "1"
TOOL.ClientConVar[ "maxtargets" ]	= "1"
TOOL.ClientConVar[ "maxbogeys" ]	= "1"
TOOL.ClientConVar[ "notargetowner" ]	= "0"
TOOL.ClientConVar[ "entityfil" ] 		= ""

TOOL.Model = "models/props_lab/powerbox02d.mdl"

cleanup.Register( "wire_target_finders" )


function TOOL:LeftClick(trace)
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	
	// Get client's CVars
	local minrange		= self:GetClientNumber("minrange")
	local range			= self:GetClientNumber("maxrange")
	local players		= (self:GetClientNumber("players") ~= 0)
	local npcs			= (self:GetClientNumber("npcs") ~= 0)
	local npcname		= self:GetClientInfo("npcname")
	local beacons		= (self:GetClientNumber("beacons") ~= 0)
	local hoverballs	= (self:GetClientNumber("hoverballs") ~= 0)
	local thrusters		= (self:GetClientNumber("thrusters") ~= 0)
	local props			= (self:GetClientNumber("props") ~= 0)
	local propmodel		= self:GetClientInfo("propmodel")
	local vehicles		= (self:GetClientNumber("vehicles") ~= 0)
	local playername	= self:GetClientInfo("playername")
	local casesen		= (self:GetClientNumber("casesen") ~= 0)
	local rpgs 			= (self:GetClientNumber("rpgs") ~= 0)
	local painttarget 	= (self:GetClientNumber("painttarget") ~= 0)
	local maxtargets	= self:GetClientNumber("maxtargets")
	local maxbogeys		= self:GetClientNumber("maxbogeys")
	local notargetowner	= (self:GetClientNumber("notargetowner") != 0)
	local entity		= self:GetClientInfo("entityfil")

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_target_finder" && trace.Entity.pl == ply ) then
		trace.Entity:Setup(range, players, npcs, npcname, beacons, hoverballs, thrusters, props, propmodel,  vehicles, playername, casesen, rpgs, painttarget, minrange, maxtargets, maxbogeys, notargetowner, entity)
		
		trace.Entity:GetTable().range		= range
		trace.Entity:GetTable().players		= players
		trace.Entity:GetTable().npcs		= npcs
		trace.Entity:GetTable().npcname		= npcname
		trace.Entity:GetTable().beacons		= beacons
		trace.Entity:GetTable().hoverballs	= hoverballs
		trace.Entity:GetTable().thrusters	= thrusters
		trace.Entity:GetTable().props		= props
		trace.Entity:GetTable().propmodel	= propmodel
		trace.Entity:GetTable().vehicles	= vehicles
		trace.Entity:GetTable().playername	= playername
		trace.Entity:GetTable().casesen		= casesen
		trace.Entity:GetTable().rpgs		= rpgs
		trace.Entity:GetTable().painttarget	= painttarget
		trace.Entity:GetTable().minrange	= minrange
		trace.Entity:GetTable().maxtargets	= maxtargets
		trace.Entity:GetTable().maxbogeys	= maxbogeys
		trace.Entity:GetTable().notargetowner	= notargetowner
		trace.Entity:GetTable().entity		= entity
		
		return true
	end	
	
	if ( !self:GetSWEP():CheckLimit( "wire_target_finders" ) ) then return false end
	
	local Ang = trace.HitNormal:Angle()
	
	local wire_target_finder = MakeWireTargetFinder( ply, trace.HitPos, Ang, range, players, npcs, npcname, beacons, hoverballs, thrusters, props, propmodel,  vehicles, playername, casesen, rpgs, painttarget, minrange, maxtargets, maxbogeys, notargetowner, entity )
	
	local min = wire_target_finder:OBBMins()
	wire_target_finder:SetPos( trace.HitPos - trace.HitNormal*min.z )
	
	// Don't weld to world
	local const = WireLib.Weld(wire_target_finder, trace.Entity, trace.PhysicsBone, true)
	
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
	
	function MakeWireTargetFinder(pl, Pos, Ang, range, players, npcs, npcname, beacons, hoverballs, thrusters, props, propmodel,  vehicles, playername, casesen, rpgs, painttarget, minrange, maxtargets, maxbogeys, notargetowner, entity, Vel, aVel, frozen )
		if (!pl:CheckLimit("wire_target_finders")) then return end
		
		local wire_target_finder = ents.Create("gmod_wire_target_finder")
		wire_target_finder:SetPos(Pos)
		wire_target_finder:SetAngles(Ang)
		wire_target_finder:SetModel( Model("models/props_lab/powerbox02d.mdl") )
		wire_target_finder:Spawn()
		wire_target_finder:Activate()
		
		wire_target_finder:Setup(range, players, npcs, npcname, beacons, hoverballs, thrusters, props, propmodel,  vehicles, playername, casesen, rpgs, painttarget, minrange, maxtargets, maxbogeys, notargetowner, entity)
		wire_target_finder:SetPlayer(pl)
		
		local ttable = {
			pl			= pl,
			range		= range,
			players		= players,
			npcs		= npcs,
			npcname		= npcname,
			beacons		= beacons,
			hoverballs	= hoverballs,
			thrusters	= thrusters,
			props		= props,
			propmodel	= propmodel,
			vehicles	= vehicles,
			playername	= playername,
			casesen		= casesen,
			rpgs		= rpgs,
			painttarget = painttarget,
			nocollide	= nocollide,
			description	= description,
			minrange	= minrange,
			maxtargets	= maxtargets,
			maxbogeys	= maxbogeys,
			entity 		= entity,
			notargetowner 	= notargetowner
		}
		
		table.Merge( wire_target_finder:GetTable(), ttable )

		pl:AddCount( "wire_target_finders", wire_target_finder )
		
		return wire_target_finder
	end

	duplicator.RegisterEntityClass("gmod_wire_target_finder", MakeWireTargetFinder, "Pos", "Ang", "range", "players", "npcs", "npcname", "beacons", "hoverballs", "thrusters", "props", "propmodel", "vehicles", "playername", "casesen", "rpgs", "painttarget", "minrange", "maxtargets", "maxbogeys", "notargetowner", "entity","Vel", "aVel", "frozen")

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
		Label = "#WireTargetFinderTool_minrange",
		Type = "Float",
		Min = "1",
		Max = "1000",
		Command = "wire_target_finder_minrange"
	})
	
	panel:AddControl("Slider", {
		Label = "#WireTargetFinderTool_maxrange",
		Type = "Float",
		Min = "1",
		Max = "1000",
		Command = "wire_target_finder_maxrange"
	})
	
	panel:AddControl("Slider", {
		Label = "#WireTargetFinderTool_maxtargets",
		Type = "Integer",
		Min = "1",
		Max = "10",
		Command = "wire_target_finder_maxtargets"
	})
	
	panel:AddControl("Slider", {
		Label = "#WireTargetFinderTool_MaxBogeys",
		Description = "#WireTargetFinderTool_MaxBogeys_desc",
		Type = "Integer",
		Min = "0",
		Max = "30",
		Command = "wire_target_finder_maxbogeys"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_players",
		Command = "wire_target_finder_players"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_notowner",
		Command = "wire_target_finder_notargetowner"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_npcs",
		Command = "wire_target_finder_npcs"
	})
	
	panel:AddControl("TextBox", {
		Label = "#WireTargetFinderTool_npcname",
		Command = "wire_target_finder_npcname",
		MaxLength = "20"
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
		Label = "#WireTargetFinderTool_props",
		Command = "wire_target_finder_props"
	})
	
	panel:AddControl("TextBox", {
		Label = "#WireTargetFinderTool_propmodel",
		Command = "wire_target_finder_propmodel",
		MaxLength = "100"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_vehicles",
		Command = "wire_target_finder_vehicles"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_rpgs",
		Command = "wire_target_finder_rpgs"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_PaintTarget",
		Description = "#WireTargetFinderTool_PaintTarget_desc",
		Command = "wire_target_finder_painttarget"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_casesen",
		Command = "wire_target_finder_casesen"
	})
	
	panel:AddControl("TextBox", {
		Label = "#WireTargetFinderTool_playername",
		Command = "wire_target_finder_playername",
		MaxLength = "50"
	})
	
	panel:AddControl("TextBox", {
		Label = "#WireTargetFinderTool_entity",
		Command = "wire_target_finder_entityfil",
		MaxLength = "50"
	})
end
	
