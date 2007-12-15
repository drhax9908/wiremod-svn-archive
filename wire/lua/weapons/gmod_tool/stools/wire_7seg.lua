TOOL.Category		= "Wire - Display"
TOOL.Name			= "7 Segment Display"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_7seg_name", "7-Segment Display Tool" )
    language.Add( "Tool_wire_7seg_desc", "Spawns 7 indicators for numeric display with the wire system." )
    language.Add( "Tool_wire_7seg_0", "Primary: Create display/Update Indicator" )
    language.Add( "ToolWire7Seg_a_colour", "Off Colour:" )
	language.Add( "ToolWire7Seg_b_colour", "On Colour:" )
	language.Add( "ToolWire7SegTool_worldweld", "Allow weld to world:" )
	language.Add( "undone_wire7seg", "Undone 7-Segment Display" )
end

TOOL.ClientConVar[ "model" ] = "models/segment.mdl"
TOOL.ClientConVar[ "ar" ] = "70" //default: dark grey off, full red on
TOOL.ClientConVar[ "ag" ] = "70" 
TOOL.ClientConVar[ "ab" ] = "70"
TOOL.ClientConVar[ "aa" ] = "255"
TOOL.ClientConVar[ "br" ] = "255"
TOOL.ClientConVar[ "bg" ] = "0"
TOOL.ClientConVar[ "bb" ] = "0"
TOOL.ClientConVar[ "ba" ] = "255"
TOOL.ClientConVar[ "worldweld" ] = "1"


function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end
	if (CLIENT) then return true end
	
	local ply = self:GetOwner()
	
	local model			= self:GetClientInfo( "model" )
	local ar			= math.min(self:GetClientNumber("ar"), 255)
	local ag			= math.min(self:GetClientNumber("ag"), 255)
	local ab			= math.min(self:GetClientNumber("ab"), 255)
	local aa			= math.min(self:GetClientNumber("aa"), 255)
	local br			= math.min(self:GetClientNumber("br"), 255)
	local bg			= math.min(self:GetClientNumber("bg"), 255)
	local bb			= math.min(self:GetClientNumber("bb"), 255)
	local ba			= math.min(self:GetClientNumber("ba"), 255)
	local worldweld		= self:GetClientNumber("worldweld") == 1

	// If we shot a wire_indicator change its force
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_indicator" && trace.Entity.pl == ply ) then
		trace.Entity:Setup(0, ar, ag, ab, aa, 1, br, bg, bb, ba)

		trace.Entity.a	= 0
		trace.Entity.ar	= ar
		trace.Entity.ag	= ag
		trace.Entity.ab	= ab
		trace.Entity.aa	= aa
		trace.Entity.b	= 1
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
	
	local wire_indicators = MakeWire7Seg( ply, model, Ang, trace.HitPos, trace.HitNormal, 0, ar, ag, ab, aa, 1, br, bg, bb, ba )	
	
	undo.Create("Wire7Seg")
		for x=1, 7 do
			--make welds
			local const = WireLib.Weld(wire_indicators[x], trace.Entity, trace.PhysicsBone, true, false, worldweld)
			undo.AddEntity( wire_indicators[x] )
			undo.AddEntity( const )
			ply:AddCleanup( "wire_indicators", wire_indicators[x] )
			ply:AddCleanup( "wire_indicators", const)
		end
		undo.SetPlayer( ply )
	undo.Finish()
	
	return true
end

if (SERVER) then

	function MakeWire7Seg( pl, Model, Ang, Pos, Norm, a, ar, ag, ab, aa, b, br, bg, bb, ba, nocollide, Vel, aVel, frozen  )
		
		if ( !pl:CheckLimit( "wire_indicators" ) ) then return false end
		
		local wire_indicators = {}
		
		//make the center one first so we can get use its OBBMins/OBBMaxs
		wire_indicators[1] = ents.Create( "gmod_wire_indicator" )
		if (!wire_indicators[1]:IsValid()) then return false end
		wire_indicators[1]:SetModel( Model )
		wire_indicators[1]:SetAngles( Ang + Angle(90, 0, 0) )
		wire_indicators[1]:SetPos( Pos )
		wire_indicators[1]:Spawn()
		wire_indicators[1]:Setup(a, ar, ag, ab, aa, b, br, bg, bb, ba)
		wire_indicators[1]:SetPlayer(pl)
		wire_indicators[1]:SetNetworkedString("WireName", "G")
		pl:AddCount( "wire_indicators", wire_indicators[1] )
		local min = wire_indicators[1]:OBBMins(wire_indicators[1])
		Pos = Pos - Norm * min.x //correct Pos for thichness of segment
		wire_indicators[1]:SetPos( Pos + Ang:Up() )
		
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
		table.Merge(wire_indicators[1]:GetTable(), ttable )

		local max = wire_indicators[1]:OBBMaxs(wire_indicators[1])
		
		local angles = {Angle( 90, 0, 90 ), Angle( 90, 0, 90 ), Angle( 90, 0, 90 ), Angle( 90, 0, 90 ), Angle( 90, 0, 0 ), Angle( 90, 0, 0 )}
		local vectors = {Vector( 1, (-1 * max.y), max.y ), Vector( 1, (-1 * max.y), (-1 * max.y) ), Vector( 1, max.y, max.y ), Vector( 1, max.y, (-1 * max.y) ), Vector( 1, 0, (2 * max.y) ), Vector( 1, 0, (-2 * max.y) ) }
		local segname = {"B", "C", "F", "E", "A", "D"}
		
		for x=2, 7 do
			wire_indicators[x] = ents.Create( "gmod_wire_indicator" )
			if (!wire_indicators[x]:IsValid()) then return false end
			wire_indicators[x]:SetModel( Model )
			wire_indicators[x]:SetPos( Pos + Ang:Up() * vectors[x-1].X + Ang:Forward() * -1 * vectors[x-1].Z + Ang:Right() * vectors[x-1].Y )
			wire_indicators[x]:SetAngles( Ang + angles[x-1] )
			wire_indicators[x]:Spawn()
			wire_indicators[x]:Setup(cmin, ar, ag, ab, aa, cmax, br, bg, bb, ba)
			wire_indicators[x]:SetPlayer(pl)
			wire_indicators[x]:SetNetworkedString("WireName", segname[x-1])
			if ( nocollide == true ) then wire_indicators[x]:GetPhysicsObject():EnableCollisions( false ) end
			table.Merge(wire_indicators[x]:GetTable(), ttable )
			pl:AddCount( "wire_indicators", wire_indicators[x] )
			
			//weld this segment to eveyone before it
			for y=1,x do
				const = constraint.Weld( wire_indicators[x], wire_indicators[y], 0, 0, 0, true, true )
			end
			wire_indicators[x-1]:DeleteOnRemove( wire_indicators[x] ) //when one is removed, all are. a linked chain
		end
		wire_indicators[7]:DeleteOnRemove( wire_indicators[1] ) //loops chain back to first
		
		return wire_indicators
	end

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
	
	local Ang = trace.HitNormal:Angle() + Angle(90, 0, 0)
	Ang.pitch = Ang.pitch + 90
	
	local min = ent:OBBMins()
	 ent:SetPos( trace.HitPos - trace.HitNormal * min.x )
	ent:SetAngles( Ang )
	
	ent:SetNoDraw( false )
	
end

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" )) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(90, 0, 0) )
	end
	
	self:UpdateGhostWireIndicator( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_7seg_name", Description = "#Tool_wire_7seg_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_7seg",

		Options = {
			["#Default"] = {
				wire_7seg_ar = "255",
				wire_7seg_ag = "0",
				wire_7seg_ab = "0",
				wire_7seg_aa = "255",
				wire_7seg_br = "79",
				wire_7seg_bg = "79",
				wire_7seg_bb = "79",
				wire_7seg_ba = "255"
			}
		},

		CVars = {
			[0] = "wire_7seg_ar",
			[1] = "wire_7seg_ag",
			[2] = "wire_7seg_ab",
			[3] = "wire_7seg_aa",
			[4] = "wire_7seg_br",
			[5] = "wire_7seg_bg",
			[6] = "wire_7seg_bb",
			[7] = "wire_7seg_ba"
		}
	})
	
	panel:AddControl("Color", {
		Label = "#ToolWire7Seg_a_colour",
		Red = "wire_7seg_ar",
		Green = "wire_7seg_ag",
		Blue = "wire_7seg_ab",
		Alpha = "wire_7seg_aa",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})
	
	panel:AddControl("Color", {
		Label = "#ToolWire7Seg_b_colour",
		Red = "wire_7seg_br",
		Green = "wire_7seg_bg",
		Blue = "wire_7seg_bb",
		Alpha = "wire_7seg_ba",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})

	panel:AddControl("ComboBox", {
		Label = "#ToolWireIndicator_Model",
		MenuButton = "0",

		Options = {
			["Medium 7-seg bar"]	= { wire_7seg_model = "models/segment2.mdl" },
			["Small 7-seg bar"]		= { wire_7seg_model = "models/segment.mdl" },
		}
	})
	
	panel:AddControl("CheckBox", {
		Label = "#ToolWire7SegTool_worldweld",
		Command = "wire_7seg_worldweld"
	})
	
end
