
TOOL.Category		= "Wire - Display"
TOOL.Name			= "Pixel"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_pixel_name", "Pixel Tool (Wire)" )
    language.Add( "Tool_wire_pixel_desc", "Spawns a Pixel for use with the wire system." )
    language.Add( "Tool_wire_pixel_0", "Primary: Create Pixel" )
    language.Add( "WirePixelTool_model", "Model:" )
 	language.Add( "sboxlimit_wire_pixels", "You've hit Pixels limit!" )
	language.Add( "undone_wirepixel", "Undone Wire Pixel" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_pixels', 20)
	ModelPlug_Register("pixel")
end

TOOL.ClientConVar[ "noclip" ] = "0"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"

cleanup.Register( "wire_pixels" )

function TOOL:LeftClick( trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	
	local noclip			= self:GetClientNumber( "noclip" ) == 1
	local model             = self:GetClientInfo( "model" )
	
	// If we shot a wire_pixel change its force
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_pixel" && trace.Entity:GetTable().pl == ply ) then
		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_pixels" ) ) then return false end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	wire_pixel = MakeWirePixel( ply, Ang, trace.HitPos, model, noclip )
	
	local min = wire_pixel:OBBMins()
	wire_pixel:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local const = WireLib.Weld(wire_pixel, trace.Entity, trace.PhysicsBone, true)
	
	undo.Create("WirePixel")
		undo.AddEntity( wire_pixel )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
	
	ply:AddCleanup( "wire_pixels", wire_pixel )
	ply:AddCleanup( "wire_pixels", const )
	
	return true
	
end

if (SERVER) then

	function MakeWirePixel( pl, Ang, Pos, Model, nocollide, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_pixels" ) ) then return false end
		
		local wire_pixel = ents.Create( "gmod_wire_pixel" )
		if (!wire_pixel:IsValid()) then return false end
		
		wire_pixel:SetModel( Model )
		wire_pixel:SetAngles( Ang )
		wire_pixel:SetPos( Pos )
		wire_pixel:Spawn()
		
		wire_pixel:GetTable():Setup()
		wire_pixel:GetTable():SetPlayer(pl)
		
		if ( nocollide == true ) then wire_pixel:SetCollisionGroup(COLLISION_GROUP_WORLD) end
		
		local ttable = {
			pl	= pl,
			nocollide = nocollide
			}
		
		table.Merge(wire_pixel:GetTable(), ttable )
		
		pl:AddCount( "wire_pixels", wire_pixel )
		
		return wire_pixel
	end

	duplicator.RegisterEntityClass("gmod_wire_pixel", MakeWirePixel, "Ang", "Pos", "Model", "nocollide", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhost( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end
	
	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_pixel" ) then
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
	self:UpdateGhost( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_pixel_name", Description = "#Tool_wire_pixel_desc" })
	
	panel:AddControl("CheckBox", {
		Label = "#WireGatesTool_noclip",
		Command = "wire_pixel_noclip"
	})
	
	ModelPlug_AddToCPanel(panel, "pixel", "wire_pixel", "#WirePixelTool_model", nil, "#WirePixelTool_model")
end
