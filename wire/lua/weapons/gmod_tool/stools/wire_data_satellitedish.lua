TOOL.Category		= "Wire - Data"
TOOL.Name			= "Satellite Dish"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_data_satellitedish_name", "Satellite Dish Tool (Wire)" )
    language.Add( "Tool_wire_data_satellitedish_desc", "Spawns a Satellite Dish." )
    language.Add( "Tool_wire_data_satellitedish_0", "Primary: Create/Update Satellite Dish, Secondary: Change model, Reload link satellite dish" )
    language.Add( "WireDataTransfererTool_data_satellitedish", "Satellite Dish:" )
	language.Add( "sboxlimit_wire_data_satellitedishs", "You've hit Satellite Dishs limit!" )
	language.Add( "undone_Wire Data Satellite Dish", "Undone Wire Satellite Dish" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_data_satellitedishs', 20)
end

TOOL.ClientConVar["Model"] = "models/kobilica/wiremonitorrtbig.mdl"

TOOL.FirstSelected = nil

cleanup.Register( "wire_data_satellitedishs" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_data_satellitedish" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_data_satellitedishs" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_data_satellitedish = MakeWireSatellitedish( ply, trace.HitPos, Ang , self:GetClientInfo("Model"))

	local min = wire_data_satellitedish:OBBMins()
	wire_data_satellitedish:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_data_satellitedish, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Data Satellite Dish")
		undo.AddEntity( wire_data_satellitedish )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_data_satellitedishs", wire_data_satellitedish )
	ply:AddCleanup( "wire_data_satellitedishs", const )

	return true
end

function TOOL:RightClick( trace )
	if (CLIENT) then return true end
	
	if (trace.Entity and trace.Entity:IsValid()) then
		if (trace.Entity:GetClass() == "prop_physics") then
			self:GetOwner():ConCommand('wire_data_satellitedish_Model "'..trace.Entity:GetModel()..'"\n')
			
			Msg("Satellite Dish model set to "..trace.Entity:GetModel())
		else
			Msg("Satellite Dishs only accept physics models!")
		end
	end
	
	return true
end

function TOOL:Reload( trace )
    if(trace.Entity and trace.Entity:IsValid()) then
        if(self.FirstSelected == nil)then
            self.FirstSelected = trace.Entity
            Msg("First\n")
        else
            self.FirstSelected.Transmitter = trace.Entity
            self.FirstSelected = nil
            Msg("Linked\n")
        end
        return true
    end
    return false
end


if (SERVER) then

	function MakeWireSatellitedish( pl, Pos, Ang, Model )
		if ( !pl:CheckLimit( "wire_data_satellitedishs" ) ) then return false end
	
		local wire_data_satellitedish = ents.Create( "gmod_wire_data_satellitedish" )
		if (!wire_data_satellitedish:IsValid()) then return false end

		wire_data_satellitedish:SetAngles( Ang )
		wire_data_satellitedish:SetPos( Pos )
		wire_data_satellitedish:SetModel( Model )
		wire_data_satellitedish:Spawn()

		wire_data_satellitedish:SetPlayer( pl )
		wire_data_satellitedish.pl = pl

		pl:AddCount( "wire_data_satellitedishs", wire_data_satellitedish )

		return wire_data_satellitedish
	end
	
	duplicator.RegisterEntityClass("gmod_wire_data_satellitedish", MakeWireSatellitedish, "Pos", "Ang", "Model", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireSatellitedish( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_data_satellitedish" ) then
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
		self:MakeGhostEntity( self:GetClientInfo("Model"), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireSatellitedish( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_data_satellitedish_name", Description = "#Tool_wire_data_satellitedish_desc" })
end
