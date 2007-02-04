
TOOL.Category		= "Wire - Display"
TOOL.Name			= "Indicator"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_indicator_name", "Indicator Tool (Wire)" )
    language.Add( "Tool_wire_indicator_desc", "Spawns a indicator for use with the wire system." )
    language.Add( "Tool_wire_indicator_0", "Primary: Create/Update Indicator" )
    language.Add( "ToolWireIndicator_Model", "Model:" )
    language.Add( "ToolWireIndicator_a_value", "A Value:" )
    language.Add( "ToolWireIndicator_a_colour", "A Colour:" )
    language.Add( "ToolWireIndicator_b_value", "B Value:" )
    language.Add( "ToolWireIndicator_b_colour", "B Colour:" )
	language.Add( "sboxlimit_wire_indicators", "You've hit indicators limit!" )
	language.Add( "undone_wireindicator", "Undone Wire Indicator" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_indicators', 20)
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar[ "a" ] = "0"
TOOL.ClientConVar[ "ar" ] = "255"
TOOL.ClientConVar[ "ag" ] = "0"
TOOL.ClientConVar[ "ab" ] = "0"
TOOL.ClientConVar[ "aa" ] = "255"
TOOL.ClientConVar[ "b" ] = "1"
TOOL.ClientConVar[ "br" ] = "0"
TOOL.ClientConVar[ "bg" ] = "255"
TOOL.ClientConVar[ "bb" ] = "0"
TOOL.ClientConVar[ "ba" ] = "255"

cleanup.Register( "wire_indicators" )

function TOOL:LeftClick( trace )

	if trace.Entity && trace.Entity:IsPlayer() then return false end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	if (CLIENT) then return true end
	
	local ply = self:GetOwner()
	
	local model			= self:GetClientInfo( "model" )
	local a				= self:GetClientNumber("a")
	local ar			= math.min(self:GetClientNumber("ar"), 255)
	local ag			= math.min(self:GetClientNumber("ag"), 255)
	local ab			= math.min(self:GetClientNumber("ab"), 255)
	local aa			= math.min(self:GetClientNumber("aa"), 255)
	local b				= self:GetClientNumber("b")
	local br			= math.min(self:GetClientNumber("br"), 255)
	local bg			= math.min(self:GetClientNumber("bg"), 255)
	local bb			= math.min(self:GetClientNumber("bb"), 255)
	local ba			= math.min(self:GetClientNumber("ba"), 255)

	// If we shot a wire_indicator change its force
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_indicator" && trace.Entity.pl == ply ) then
		trace.Entity:Setup(a, ar, ag, ab, aa, b, br, bg, bb, ba)

		trace.Entity.a	= a
		trace.Entity.ar	= ar
		trace.Entity.ag	= ag
		trace.Entity.ab	= ab
		trace.Entity.aa	= aa
		trace.Entity.b	= b
		trace.Entity.br	= br
		trace.Entity.bg	= bg
		trace.Entity.bb	= bb
		trace.Entity.ba	= ba

		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_indicators" ) ) then return false end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end		// Allow ragdolls to be used?

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	wire_indicator = MakeWireIndicator( ply, model, Ang, trace.HitPos, a, ar, ag, ab, aa, b, br, bg, bb, ba )
	
	local min = wire_indicator:OBBMins()
	wire_indicator:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local const, nocollide
	
	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_indicator, trace.Entity, 0, trace.PhysicsBone, 0, true )
		trace.Entity:DeleteOnRemove( wire_indicator )
		
		// Don't disable collision if it's not attached to anything
		if ( collision == 0 ) then 
			wire_indicator:GetPhysicsObject():EnableCollisions( false )
			wire_indicator.nocollide = true
		end
	end
	
	undo.Create("WireIndicator")
		undo.AddEntity( wire_indicator )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
		
	ply:AddCleanup( "wire_indicators", wire_indicator )
	ply:AddCleanup( "wire_indicators", const )
	ply:AddCleanup( "wire_indicators", nocollide )
	
	return true

end

if (SERVER) then

	function MakeWireIndicator( pl, Model, Ang, Pos, a, ar, ag, ab, aa, b, br, bg, bb, ba, nocollide, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_indicators" ) ) then return false end
	
		local wire_indicator = ents.Create( "gmod_wire_indicator" )
		if (!wire_indicator:IsValid()) then return false end
		wire_indicator:SetModel( Model )

		wire_indicator:SetAngles( Ang )
		wire_indicator:SetPos( Pos )
		wire_indicator:Spawn()

		wire_indicator:Setup(a, ar, ag, ab, aa, b, br, bg, bb, ba)
		wire_indicator:SetPlayer(pl)

		if (nocollide) then explosive:GetPhysicsObject():EnableCollision(false) end

		local ttable = {
			a	= a,
			ar	= ar,
			ag	= ag,
			ab	= ab,
			aa	= aa,
			b	= b,
			br	= br,
			bg	= bg,
			bb	= bb,
			ba	= ba,
			pl	= pl,
			nocollide = nocollide
			}

		table.Merge(wire_indicator:GetTable(), ttable )

		pl:AddCount( "wire_indicators", wire_indicator )

		return wire_indicator
	end

	duplicator.RegisterEntityClass("gmod_wire_indicator", MakeWireIndicator, "Model", "Ang", "Pos", "a", "ar", "ag", "ab", "aa", "b", "br", "bg", "bb", "ba", "nocollide", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireIndicator( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end
	
	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_indicator" || trace.Entity:IsPlayer()) then
	
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
	
	self:UpdateGhostWireIndicator( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_indicator_name", Description = "#Tool_wire_indicator_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_indicator",

		Options = {
			["#Default"] = {
				wire_indicator_a = "0",
				wire_indicator_ar = "255",
				wire_indicator_ag = "0",
				wire_indicator_ab = "0",
				wire_indicator_aa = "255",
				wire_indicator_b = "1",
				wire_indicator_br = "0",
				wire_indicator_bg = "255",
				wire_indicator_bb = "0",
				wire_indicator_ba = "255"
			}
		},

		CVars = {
			[0] = "wire_indicator_a",
			[1] = "wire_indicator_ar",
			[2] = "wire_indicator_ag",
			[3] = "wire_indicator_ab",
			[4] = "wire_indicator_aa",
			[5] = "wire_indicator_b",
			[6] = "wire_indicator_br",
			[7] = "wire_indicator_bg",
			[8] = "wire_indicator_bb",
			[9] = "wire_indicator_ba"
		}
	})

	panel:AddControl("Slider", {
		Label = "#ToolWireIndicator_a_value",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_indicator_a"
	})
	panel:AddControl("Color", {
		Label = "#ToolWireIndicator_a_colour",
		Red = "wire_indicator_ar",
		Green = "wire_indicator_ag",
		Blue = "wire_indicator_ab",
		Alpha = "wire_indicator_aa",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})

	panel:AddControl("Slider", {
		Label =	"#ToolWireIndicator_b_value",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_indicator_b"
	})
	panel:AddControl("Color", {
		Label = "#ToolWireIndicator_b_colour",
		Red = "wire_indicator_br",
		Green = "wire_indicator_bg",
		Blue = "wire_indicator_bb",
		Alpha = "wire_indicator_ba",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})

	panel:AddControl("ComboBox", {
		Label = "#ToolWireIndicator_Model",
		MenuButton = "0",

		Options = {
			["Siren"]				= { wire_indicator_model = "models/jaanus/wiretool/wiretool_siren.mdl" },
			["Medium 7-seg bar"]	= { wire_indicator_model = "models/segment2.mdl" },
			["Small 7-seg bar"]		= { wire_indicator_model = "models/segment.mdl" },
		}
	})
end
