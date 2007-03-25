
TOOL.Category		= "Wire - Display"
TOOL.Name			= "Lamps"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_lamp_name", "Wire Lamps" )
    language.Add( "Tool_wire_lamp_desc", "Spawns a lamp for use with the wire system." )
    language.Add( "Tool_wire_lamp_0", "Primary: Create hanging lamp Secondary: Create unattached lamp" )
    language.Add( "WireLampTool_RopeLength", "Rope Length:")
    language.Add( "WireLampTool_Color", "Color:" )
	language.Add( "SBoxLimit_wire_lamps", "You've hit the wire lamps limit!" )
	language.Add( "undone_WireLamp", "Undone Wire Lamp" )
    language.Add( "Cleanup_wire_lamp", "Wire Lamps" )
	language.Add( "Cleaned_wire_lamp", "Cleaned up all Wire Lamps" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_lamps', 10)
end

TOOL.ClientConVar[ "ropelength" ] = "64"
TOOL.ClientConVar[ "ropematerial" ] = "cable/rope"
TOOL.ClientConVar[ "r" ] = "255"
TOOL.ClientConVar[ "g" ] = "255"
TOOL.ClientConVar[ "b" ] = "255"

cleanup.Register( "wire_lamp" )

function TOOL:LeftClick( trace, attach )

	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
	if (attach == nil) then attach = true end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && attach && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end
	
	local ply = self:GetOwner()
	
	local pos, ang = trace.HitPos + trace.HitNormal * 10, trace.HitNormal:Angle() - Angle( 90, 0, 0 )

	local r 	= math.Clamp( self:GetClientNumber( "r" ), 0, 255 )
	local g 	= math.Clamp( self:GetClientNumber( "g" ), 0, 255 )
	local b 	= math.Clamp( self:GetClientNumber( "b" ), 0, 255 )
	
	if	trace.Entity:IsValid() && 
		trace.Entity:GetClass() == "gmod_wire_lamp" &&
		trace.Entity:GetTable():GetPlayer() == ply
	then
		trace.Entity:GetTable():SetLightColor( r, g, b )
		trace.Entity:GetTable().r = r
		trace.Entity:GetTable().g = g
		trace.Entity:GetTable().b = b
		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_lamps" ) ) then return false end
	wire_lamp = MakeWireLamp( ply, pos, ang, r, g, b )
	
	if (!attach) then 
	
		undo.Create("WireLamp")
			undo.AddEntity( wire_lamp )
			undo.SetPlayer( self:GetOwner() )
		undo.Finish()
		
		return true
		
	end

	local length 	= self:GetClientNumber( "ropelength" )
	local material 	= self:GetClientInfo( "ropematerial" )
	
	local LPos1 = Vector( 0, 0, 5 )
	local LPos2 = trace.Entity:WorldToLocal( trace.HitPos )
	
	if (trace.Entity:IsValid()) then     
		
		local phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
		if (phys:IsValid()) then
			LPos2 = phys:WorldToLocal( trace.HitPos )
		end
	
	end
	
	local constraint, rope = constraint.Rope( wire_lamp, trace.Entity, 
											  0, trace.PhysicsBone, 
											  LPos1, LPos2, 
											  0, length,
											  0, 
											  1.5, 
											  material, 
											  nil )
	
	undo.Create("WireLamp")
		undo.AddEntity( wire_lamp )
		undo.AddEntity( rope )
		undo.AddEntity( constraint )
		undo.SetPlayer( ply )
	undo.Finish()

	return true

end

function TOOL:RightClick( trace )

	return self:LeftClick( trace, false )

end

function MakeWireLamp( pl, Pos, Ang, r, g, b, Vel, aVel, frozen )

	if ( !pl:CheckLimit( "wire_lamps" ) ) then return false end

	local wire_lamp = ents.Create( "gmod_wire_lamp" )
	if (!wire_lamp:IsValid()) then return end
		wire_lamp:SetPos( Pos )
		wire_lamp:SetAngles( Ang )
		wire_lamp:GetTable():SetLightColor( r, g, b )
	wire_lamp:Spawn()

	wire_lamp:Setup( r, g, b )
	wire_lamp:GetTable():SetPlayer( pl )


	if (wire_lamp:GetPhysicsObject():IsValid()) then
		Phys = wire_lamp:GetPhysicsObject()
		if Vel then Phys:SetVelocity(Vel) end
		if Vel then Phys:AddAngleVelocity(aVel) end
		Phys:EnableMotion(frozen != true)
	end
	
	pl:AddCount( "wire_lamps", wire_lamp )
	pl:AddCleanup( "wire_lamp", wire_lamp )
	
	return wire_lamp
end

duplicator.RegisterEntityClass( "gmod_wire_lamp", MakeWireLamp, "Pos", "Ang", "lightr", "lightg", "lightb", "Vel", "aVel", "frozen" )

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_lamp_name", Description = "#Tool_wire_lamp_desc" })
	
	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_lamp",

		Options = {
			["#Default"] = {
				wire_lamp_ropelength = "64",
				wire_lamp_ropematerial = "cable/rope",
				wire_lamp_r = "0",
				wire_lamp_g = "0",
				wire_lamp_b = "0"
			}
		},

		CVars = {
			[0] = "wire_lamp_ropelength",
			[1] = "wire_lamp_ropematerial",
			[2] = "wire_lamp_r",
			[3] = "wire_lamp_g",
			[4] = "wire_lamp_b",
		}
	})

	panel:AddControl("Slider", {
		Label = "#WireLampTool_RopeLength",
		Type = "Float",
		Min = "4",
		Max = "400",
		Command = "wire_lamp_ropelength"
	})
	
	panel:AddControl("Color", {
		Label = "#WireLampTool_Color",
        Red	= "wire_lamp_r",
		Green = "wire_lamp_g",
		Blue = "wire_lamp_b",
		ShowAlpha = "0",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})
end


TOOL.ClientConVar[ "ropelength" ] = "64"
TOOL.ClientConVar[ "ropematerial" ] = "cable/rope"
TOOL.ClientConVar[ "r" ] = "255"
TOOL.ClientConVar[ "g" ] = "255"
TOOL.ClientConVar[ "b" ] = "255"