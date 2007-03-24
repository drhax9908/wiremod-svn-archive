TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Prop Spawner"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "delay" ]		= "0"
TOOL.ClientConVar[ "undo_delay" ]	= "0"

// Add Default Language translation (saves adding it to the txt files)
if ( CLIENT ) then

	language.Add( "Tool_wire_spawner_name", "Prop Spawner (Wire)" )
	language.Add( "Tool_wire_spawner_desc", "Spawns a prop at a pre-defined location" )
	language.Add( "Tool_wire_spawner_0", "Click a prop to turn it into a prop spawner." )

	language.Add( "Undone_wirespawner", "Undone Wire Spawner" )
	language.Add( "Cleanup_wire_spawner", "Wire Spawners" )
	language.Add( "Cleaned_wire_spawner", "Cleaned up all Wire Spawners" )

end

if (SERVER) then
	CreateConVar("sbox_maxwire_spawners",10)
end

cleanup.Register( "wire_spawners" )

function TOOL:LeftClick( trace, attach )

	local ent = trace.Entity
	
	// Has to be an entity
	if ( !ent || !ent:IsValid() ) then return false end
	
	// Has to be a prop - or a spawner..
	if ( ent:GetClass() != "prop_physics" && ent:GetClass() != "gmod_wire_spawner" ) then return false end

	if (CLIENT) then return true end

	// If there's no physics object then we can't constraint it!
	if SERVER && !util.IsValidPhysicsObject( ent, trace.PhysicsBone ) then return false end

	local phys			= ent:GetPhysicsObject()
	local pl			= self:GetOwner()
	local delay			= self:GetClientNumber( "delay", 0 )
	local undo_delay		= self:GetClientNumber( "undo_delay", 0 )
	local model 		= trace.Entity:GetModel()
	local Vel			= phys:GetVelocity()
	local aVel			= phys:GetAngleVelocity()
	local frozen		= !phys:IsMoveable()

	// In multiplayer we clamp the delay to help prevent people being idiots
	if ( !SinglePlayer() && delay < 0.2 ) then
		delay = 0.33
	end

	if ( ent:GetClass() == "gmod_wire_spawner" && ent:GetTable().Player == pl ) then
		local spawner = ent
		spawner:GetTable():SetDelays( delay, undo_delay )
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_spawners" ) ) then return false end

	local Pos = ent:GetPos()
	local Ang = ent:GetAngles()

	local wire_spawner = MakeWireSpawner( pl, Pos, Ang, delay, undo_delay, model, vel, avel, frozen )
	if !wire_spawner:IsValid() then return end

	//!!TODO!! copy existing constraints to the spawner
	ent:Remove()

	undo.Create("WireSpawner")
	undo.AddEntity( wire_spawner )
	undo.SetPlayer( pl )
	undo.Finish()

	pl:AddCleanup( "wire_spawner", wire_spawner )

	return true

end

function MakeWireSpawner( pl, Pos, Ang, delay, undo_delay, model, vel, avel, frozen )

	if ( !pl:CheckLimit( "wire_spawners" ) ) then return nil end

	local spawner = ents.Create( "gmod_wire_spawner" )
	if (!spawner:IsValid()) then return end
		spawner:SetPos( Pos )
		spawner:SetAngles( Ang )
		spawner:SetModel( model )
		spawner:SetRenderMode( 3 )
		spawner:SetColor( 255,255,255,100 )
	spawner:Spawn()

	if (spawner:GetPhysicsObject():IsValid()) then
		Phys = spawner:GetPhysicsObject()
		if Vel then Phys:SetVelocity(Vel) end
		if Vel then Phys:AddAngleVelocity(aVel) end
		Phys:EnableMotion( !frozen )
	end

	spawner:SetPlayer(pl)
	spawner:GetTable():SetDelays( delay, undo_delay )

	local tbl = {
		Player 		= pl,
		delay		= delay,
		undo_delay	= undo_delay
		}

	table.Merge(spawner:GetTable(), tbl )

	pl:AddCount( "wire_spawners", spawner )

	return spawner

end

duplicator.RegisterEntityClass( "gmod_wire_spawner", MakeWireSpawner, "Pos", "Ang", "delay", "undo_delay", "model", "Vel", "aVel", "frozen" )


function TOOL.BuildCPanel( CPanel )

	CPanel:AddControl( "Header", { Text = "#Tool_wire_spawner_name", Description	= "#Tool_wire_spawner_desc" }  )
	
	local params = { 
		Label = "#Presets", 
		MenuButton = 1, 
		Folder = "wire_spawner", 
		Options = {
			default = {
				wire_spawner_delay	= 0,
				wire_spawner_undo_delay	= 0,
			}
		}, 
		CVars = {
			"wire_spawner_delay",
			"wire_spawner_undo_delay",
		}
	}
	CPanel:AddControl( "ComboBox", params )
	
	params = { 
		Label	= "#Spawn Delay",
		Type	= "Float",
		Min		= "0",
		Max		= "100",
		Command	= "wire_spawner_delay",
	}
	CPanel:AddControl( "Slider",  params )

	params = { 
		Label	= "#Automatic Undo Delay",
		Type	= "Float",
		Min		= "0",
		Max		= "100",
		Command	= "wire_spawner_undo_delay",
	}
	CPanel:AddControl( "Slider",  params )

end
