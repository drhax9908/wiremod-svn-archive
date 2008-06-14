TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Hoverball"
TOOL.Command		= nil
TOOL.ConfigName		= ""


if ( CLIENT ) then
    language.Add( "Tool_wire_hoverball_name", "Wired Hoverball Tool" )
    language.Add( "Tool_wire_hoverball_desc", "Spawns a hoverball for use with the wire system." )
    language.Add( "Tool_wire_hoverball_0", "Primary: Create/Update Hoverball" )
    language.Add( "WireHoverballTool_starton", "Create with hover mode on:" )
	language.Add( "undone_wirehoverball", "Undone Wire Hoverball" )
	language.Add( "sboxlimit_wire_hoverballs", "You've hit wired hover balls limit!" )
end

if (SERVER) then
    CreateConVar('sbox_maxwire_hoverballs', 30)
end 

TOOL.ClientConVar[ "speed" ] = "1"
TOOL.ClientConVar[ "resistance" ] = "0"
TOOL.ClientConVar[ "strength" ] = "1"
TOOL.ClientConVar[ "starton" ] = "1"

cleanup.Register( "wire_hoverballs" )

function TOOL:LeftClick( trace )

	if ( trace.Entity && trace.Entity:IsPlayer() ) then return false end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end
	
	if (CLIENT) then return true end
	
	local ply = self:GetOwner()
	
	local speed 		= self:GetClientNumber( "speed" ) 
	local resistance 	= self:GetClientNumber( "resistance" ) 
	local strength	 	= self:GetClientNumber( "strength" ) 
	local starton	 	= self:GetClientNumber( "starton" ) == 1
	
	resistance 	= math.Clamp( resistance, 0, 20 )
	strength	= math.Clamp( strength, 0.1, 20 )
	
	// We shot an existing hoverball - just change its values
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_hoverball" && trace.Entity:GetTable().pl == ply ) then
	
		trace.Entity:GetTable():SetSpeed( speed )
		trace.Entity:GetTable():SetAirResistance( resistance )
		trace.Entity:GetTable():SetStrength( strength )
		
		trace.Entity:GetTable().speed		= speed
		trace.Entity:GetTable().strength	= strength
		trace.Entity:GetTable().resistance	= resistance
		
		if (!starton) then trace.Entity:GetTable():DisableHover() else trace.Entity:GetTable():EnableHover() end
	
		return true
	
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_hoverballs" ) ) then return false end
	
	// If we hit the world then offset the spawn position
	if ( trace.Entity:IsWorld() ) then
		trace.HitPos = trace.HitPos + trace.HitNormal * 8
	end

	local wire_ball = MakeWireHoverBall( ply, trace.HitPos, speed, resistance, strength )
	
	local const = WireLib.Weld(wire_ball, trace.Entity, trace.PhysicsBone, true)
	
	local nocollide
	if ( !trace.Entity:IsWorld() ) then
		nocollide = constraint.NoCollide( trace.Entity, wire_ball, 0, trace.PhysicsBone )
	end
	
	if (!starton) then wire_ball:GetTable():DisableHover() end
	
	undo.Create("WireHoverBall")
		undo.AddEntity( wire_ball )
		undo.AddEntity( const )
		undo.AddEntity( nocollide )
		undo.SetPlayer( ply )
	undo.Finish()
	
	ply:AddCleanup( "wire_hoverballs", wire_ball )
	ply:AddCleanup( "wire_hoverballs", const )
	ply:AddCleanup( "wire_hoverballs", nocollide )
	
	return true

end

if (SERVER) then

	function MakeWireHoverBall( ply, Pos, speed, resistance, strength, Vel, aVel, frozen, nocollide )
	
		if ( !ply:CheckLimit( "wire_hoverballs" ) ) then return nil end
	
		local wire_ball = ents.Create( "gmod_wire_hoverball" )
		if (!wire_ball:IsValid()) then return false end

		wire_ball:SetPos( Pos )
		wire_ball:Spawn()
		wire_ball:SetSpeed( speed )
		wire_ball:SetPlayer( ply )
		wire_ball:SetAirResistance( resistance )
		wire_ball:SetStrength( strength )

		local ttable = 
		{
			pl	= ply,
			nocollide = nocollide,
			speed = speed,
			strength = strength,
			resistance = resistance
		}
		table.Merge( wire_ball:GetTable(), ttable )
		
		ply:AddCount( "wire_hoverballs", wire_ball )
		
		return wire_ball
		
	end
	
	duplicator.RegisterEntityClass("gmod_wire_hoverball", MakeWireHoverBall, "Pos", "speed", "resistance", "strength", "Vel", "aVel", "frozen", "nocollide")

end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_hoverball_name", Description = "#Tool_wire_hoverball_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_hoverball",

		Options = {
			Default = {
				wire_hoverball_speed = "1",
				wire_hoverball_resistance = "0",
				wire_hoverball_strength = "1",
				wire_hoverball_starton = "1"
			}
		},

		CVars = {
			[0] = "wire_hoverball_speed",
			[1] = "wire_hoverball_strength",
			[2] = "wire_hoverball_resistance",
			[3] = "wire_hoverball_starton"
		}
	})

	panel:AddControl("Slider", {
		Label = "#Movement Speed",
		Type = "Float",
		Min = "1",
		Max = "10",
		Command = "wire_hoverball_speed"
	})
	
	panel:AddControl("Slider", {
		Label = "#Air Resistance",
		Type = "Float",
		Min = "1",
		Max = "10",
		Command = "wire_hoverball_resistance"
	})
	
	panel:AddControl("Slider", {
		Label = "#Strength",
		Type = "Float",
		Min = "0.1",
		Max = "10",
		Command = "wire_hoverball_strength"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireHoverballTool_starton",
		Command = "wire_hoverball_starton"
	})

end
