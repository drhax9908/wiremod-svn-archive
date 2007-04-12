
TOOL.Category		= "Wire - Advanced"
TOOL.Name			= "Data Plug"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_dataplug_name", "Data Plug Tool (Wire)" )
    language.Add( "Tool_wire_dataplug_desc", "Spawns plugs and sockets for use with the hi-speed wire system." )
    language.Add( "Tool_wire_dataplug_0", "Primary: Create/Update Socket    Secondary: Create/Update Plug" )
    language.Add( "WirePlugTool_colour", "Colour:" )
	language.Add( "sboxlimit_wire_dataplugs", "You've hit plugs limit!" )
	language.Add( "sboxlimit_wire_datasockets", "You've hit sockets limit!" )
	language.Add( "undone_wiredataplug", "Undone Wire Data Plug" )
	language.Add( "undone_wiredatasocket", "Undone Wire Data Socket" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_dataplugs', 20)
	CreateConVar('sbox_maxwire_datasockets', 20)
end

TOOL.ClientConVar[ "a" ] = "0"
TOOL.ClientConVar[ "ar" ] = "255"
TOOL.ClientConVar[ "ag" ] = "255"
TOOL.ClientConVar[ "ab" ] = "255"
TOOL.ClientConVar[ "aa" ] = "255"

TOOL.PlugModel = "models/props_lab/tpplug.mdl"
TOOL.SocketModel = "models/props_lab/tpplugholder_single.mdl"

cleanup.Register( "wire_dataplugs" )

// Create socket
function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_dataplug") then
		return false
	end
	
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()


	// Get client's CVars
	local a				= self:GetClientNumber("a")
	local ar			= math.min(self:GetClientNumber("ar"), 255)
	local ag			= math.min(self:GetClientNumber("ag"), 255)
	local ab			= math.min(self:GetClientNumber("ab"), 255)
	local aa			= math.min(self:GetClientNumber("aa"), 255)

	local ply = self:GetOwner()
	
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_datasocket" && trace.Entity.pl == ply ) then
		trace.Entity:Setup(a,ar,ag,ab,aa)
		
		trace.Entity.a = a
		trace.Entity.ar = ar
		trace.Entity.ag = ag
		trace.Entity.ab = ab
		trace.Entity.aa = aa
		trace.Entity.ReceivedValue = 0
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_datasockets" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	
	local Pos = trace.HitPos
	
	Pos = Pos + self:Offset( trace.HitNormal:Angle(), Vector(-12, 13, 0) )
	
	local wire_datasocket = MakeWireSocket( ply, Pos, Ang, a, ar, ag, ab, aa )

	//local min = wire_datasocket:OBBMins()
	//wire_datasocket:SetPos( trace.HitPos - trace.HitNormal * min.z )

	/*local const, nocollide

	const = constraint.Weld( wire_datasocket, trace.Entity, 0, trace.PhysicsBone, 0, true )

	if (trace.HitWorld) then
		 local socket_phys = wire_datasocket:GetPhysicsObject()
	else
		trace.Entity:DeleteOnRemove( wire_datasocket )
		
		// Don't disable collision if it's not attached to anything
		if ( collision == 0 ) then 
			wire_dataplug:GetPhysicsObject():EnableCollisions( false )
			wire_dataplug.nocollide = true
		end
	end*/
	
	local const = WireLib.Weld(wire_datasocket, trace.Entity, trace.PhysicsBone, true, false, true)

	undo.Create("WireSocket")
		undo.AddEntity( wire_datasocket )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()


	ply:AddCleanup( "wire_datasockets", wire_datasocket )
	ply:AddCleanup( "wire_datasockets", nocollide )

	return true
end

// Create plug
function TOOL:RightClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()


	// Get client's CVars
	local a				= self:GetClientNumber("a")
	local ar			= math.min(self:GetClientNumber("ar"), 255)
	local ag			= math.min(self:GetClientNumber("ag"), 255)
	local ab			= math.min(self:GetClientNumber("ab"), 255)
	local aa			= math.min(self:GetClientNumber("aa"), 255)

	local ply = self:GetOwner()
	
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_dataplug" && trace.Entity.pl == ply ) then
		trace.Entity:Setup(a,ar,ag,ab,aa)
		
		trace.Entity.a = a
		trace.Entity.ar = ar
		trace.Entity.ag = ag
		trace.Entity.ab = ab
		trace.Entity.aa = aa
		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_dataplugs" ) ) then return false end

	local Ang = trace.HitNormal:Angle()

	local wire_dataplug = MakeWirePlug( ply, trace.HitPos, Ang, a, ar, ag, ab, aa )
	
	local min = wire_dataplug:OBBMins()
	wire_dataplug:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const, nocollide

	undo.Create("WirePlug")
		undo.AddEntity( wire_dataplug )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_dataplugs", wire_dataplug )
	ply:AddCleanup( "wire_dataplugs", nocollide )

	return true
end

if (SERVER) then

	function MakeWirePlug( pl, Pos, Ang, a, ar, ag, ab, aa )
		if ( !pl:CheckLimit( "wire_dataplugs" ) ) then return false end
	
		local wire_dataplug = ents.Create( "gmod_wire_dataplug" )
		if (!wire_dataplug:IsValid()) then return false end

		wire_dataplug:SetAngles( Ang )
		wire_dataplug:SetPos( Pos )
		wire_dataplug:SetModel( Model("models/props_lab/tpplug.mdl") )
		wire_dataplug:Spawn()

		wire_dataplug:Setup( a, ar, ag, ab, aa)
		wire_dataplug:SetPlayer( pl )

		local ttable = {
			a				= a,
			ar				= ar,
			ag				= ag,
			ab				= ab,
			aa				= aa,
			pl              = pl,
			MySocket		= nil
			}

		table.Merge(wire_dataplug:GetTable(), ttable )
		
		pl:AddCount( "wire_dataplug", wire_dataplug )

		return wire_dataplug
	end

	duplicator.RegisterEntityClass("gmod_wire_dataplug", MakeWirePlug, "Pos", "Ang", "a", "ar", "ag", "ab", "aa")


	function MakeWireSocket( pl, Pos, Ang, a, ar, ag, ab, aa )
		if ( !pl:CheckLimit( "wire_datasockets" ) ) then return false end
	
		local wire_datasocket = ents.Create( "gmod_wire_datasocket" )
		if (!wire_datasocket:IsValid()) then return false end

		wire_datasocket:SetAngles( Ang )
		wire_datasocket:SetPos( Pos )
		wire_datasocket:SetModel( Model("models/props_lab/tpplugholder_single.mdl") )
		wire_datasocket:Spawn()

		wire_datasocket:Setup( a, ar, ag, ab, aa)
		wire_datasocket:SetPlayer( pl )

		local ttable = {
			a				= a,
			ar				= ar,
			ag				= ag,
			ab				= ab,
			aa				= aa,
			pl              = pl,
			ReceivedValue	= 0
			}

		table.Merge(wire_datasocket:GetTable(), ttable )
		
		pl:AddCount( "wire_datasocket", wire_datasocket )

		return wire_datasocket
	end

	duplicator.RegisterEntityClass("gmod_wire_datasocket", MakeWireSocket, "Pos", "Ang", "a", "ar", "ag", "ab", "aa")

end

function TOOL:UpdateGhostWireSocket( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_datasocket" ) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()

	local Pos = trace.HitPos
	
	Pos = Pos + self:Offset( trace.HitNormal:Angle(), Vector(-12, 13, 0) )

	//local min = ent:OBBMins()
	//ent:SetPos( Pos - trace.HitNormal * min.z )
	ent:SetPos( Pos )
	ent:SetAngles( Ang )

	ent:SetNoDraw( false )
end

function TOOL:Offset( ang, offsetvec )
	local offset = offsetvec
	local stackdir = ang:Up()
	
	offset = ang:Up() * offset.X + ang:Forward() * -1 * offset.Z + ang:Right() * offset.Y

	return stackdir * 2 + offset
end

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self.SocketModel ) then
		self:MakeGhostEntity( self.SocketModel, Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireSocket( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_dataplug_name", Description = "#Tool_wire_dataplug_desc" })

		panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_dataplug",

		Options = {
			["#Default"] = {
				wire_dataplug_a = "0",
				wire_dataplug_ar = "255",
				wire_dataplug_ag = "0",
				wire_dataplug_ab = "0",
				wire_dataplug_aa = "255",
			}
		},

		CVars = {
			[0] = "wire_dataplug_a",
			[1] = "wire_dataplug_ar",
			[2] = "wire_dataplug_ag",
			[3] = "wire_dataplug_ab",
			[4] = "wire_dataplug_aa",
		}
	})

	panel:AddControl("Color", {
		Label = "#WirePlugTool_colour",
		Red = "wire_dataplug_ar",
		Green = "wire_dataplug_ag",
		Blue = "wire_dataplug_ab",
		Alpha = "wire_dataplug_aa",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})
end
