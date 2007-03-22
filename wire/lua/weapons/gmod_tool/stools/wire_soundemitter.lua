
TOOL.Category		= "Wire - Display"
TOOL.Name			= "Sound Emitter"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_soundemitter_name", "Sound Emitter Tool (Wire)" )
    language.Add( "Tool_wire_soundemitter_desc", "Spawns a sound emitter for use with the wire system." )
    language.Add( "Tool_wire_soundemitter_0", "Primary: Create/Update Sound Emitter" )
    language.Add( "WireEmitterTool_sound", "Sound:" )
    language.Add( "WireEmitterTool_collision", "Collision:" )
    language.Add( "WireEmitterTool_model", "Model:" )
	language.Add( "sboxlimit_wire_soundemitters", "You've hit soundemitters limit!" )
	language.Add( "undone_wiresoundemitter", "Undone Wire Soundemitter" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_emitters', 10)
end

TOOL.ClientConVar[ "sound" ] = "common/warning.wav"
TOOL.ClientConVar[ "collision" ] = "0"
TOOL.ClientConVar[ "model" ] = "models/cheeze/wires/speaker.mdl"

if (SERVER) then
	ModelPlug_Register("speaker")
end

cleanup.Register( "wire_emitters" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	if (CLIENT) then return true end
	
	local ply = self:GetOwner()
	
	local sound			= Sound( self:GetClientInfo( "sound" ) )
	local collision		= (self:GetClientInfo( "collision" ) ~= 0)
	local model			= self:GetClientInfo( "model" )

	// If we shot a wire_emitter change its sound
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_soundemitter" && trace.Entity.pl == ply ) then
		trace.Entity:SetSound( Sound(sound) )
		trace.Entity.sound	= sound

		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_emitters" ) ) then return false end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	wire_emitter = MakeWireEmitter( ply, model, Ang, trace.HitPos, sound )
	
	local min = wire_emitter:OBBMins()
	wire_emitter:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local const, nocollide
	
	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_emitter, trace.Entity, 0, trace.PhysicsBone, 0, (collision == 0), true )
		// Don't disable collision if it's not attached to anything
		wire_emitter:GetPhysicsObject():EnableCollisions( false )
		wire_emitter.nocollide = true
	end

	undo.Create("WireSoundEmitter")
		undo.AddEntity( wire_emitter )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
		
	ply:AddCleanup( "wire_emitter", wire_emitter )
	ply:AddCleanup( "wire_emitter", const )
	ply:AddCleanup( "wire_emitter", nocollide )
	
	return true

end

if (SERVER) then

	function MakeWireEmitter( pl, Model, Ang, Pos, sound, nocollide, frozen )
	
		if ( !pl:CheckLimit( "wire_emitters" ) ) then return false end
	
		local wire_emitter = ents.Create( "gmod_wire_soundemitter" )
		if (!wire_emitter:IsValid()) then return false end
		wire_emitter:SetModel( Model )

		wire_emitter:SetAngles( Ang )
		wire_emitter:SetPos( Pos )
		wire_emitter:Spawn()
		
		wire_emitter:SetSound( Sound(sound) )
		wire_emitter:SetPlayer( pl )

		local etable = {
			pl	= pl,
			nocollide = nocollide
			}

		table.Merge(wire_emitter:GetTable(), etable )

		pl:AddCount( "wire_emitters", wire_emitter )

		return wire_emitter
		
	end

	duplicator.RegisterEntityClass("gmod_wire_soundemitter", MakeWireEmitter, "Model", "Ang", "Pos", "sound", "nocollide", "frozen")

end

function TOOL:UpdateGhostWireEmitter( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end
	
	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_emitter" || trace.Entity:IsPlayer()) then
	
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
	
	self:UpdateGhostWireEmitter( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_soundemitter_name", Description = "#Tool_wire_soundemitter_desc" })

	panel:AddControl("ComboBox", {
		Label = "#WireEmitterTool_sound",
		MenuButton = "0",

		Options = {
			["Warning"] = { wire_soundemitter_sound = "common/warning.wav" },
			["Talk"] = { wire_soundemitter_sound = "common/talk.wav" },
			["Button"] = { wire_soundemitter_sound = "buttons/button15.wav" },
			["Denied"] = { wire_soundemitter_sound = "buttons/weapon_cant_buy.wav" },
			["Zap"] = { wire_soundemitter_sound = "ambient/energy/zap2.wav" },
			["Oh No"] = { wire_soundemitter_sound = "vo/npc/male01/ohno.wav" },
			["Yeah"] = { wire_soundemitter_sound = "vo/npc/male01/yeah02.wav" },
		},

		CVars = {
			[0] = "wire_soundemitter_sound"
		}
	})

	panel:AddControl("TextBox", {
		Label = "#WireEmitterTool_sound",
		Command = "wire_soundemitter_sound",
		MaxLength = "200"
	})

	panel:AddControl("CheckBox", { Label = "#WireEmitterTool_collision", Command = "wire_emitter_collision" })

	ModelPlug_AddToCPanel(panel, "speaker", "wire_soundemitter", "#WireEmitterTool_model", nil, "#WireEmitterTool_model")
end
