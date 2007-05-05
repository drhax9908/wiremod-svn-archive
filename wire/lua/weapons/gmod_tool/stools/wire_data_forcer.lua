
TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Data Forcer"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_data_forcer_name", "data_forcer Tool (Wire)" )
    language.Add( "Tool_wire_data_forcer_desc", "Spawns a data_forcer for use with the wire system." )
    language.Add( "Tool_wire_data_forcer_0", "Primary: Create/Update data_forcer" )
    language.Add( "Wiredata_forcerTool_toggle", "Toggle:" )
    language.Add( "Wiredata_forcerTool_value_on", "Value On:" )
    language.Add( "Wiredata_forcerTool_value_off", "Value Off:" )
	language.Add( "sboxlimit_wire_data_forcers", "You've hit data_forcers limit!" )
	language.Add( "undone_wiredata_forcer", "Undone Wire data_forcer" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_data_forcers', 20)
end

TOOL.ClientConVar[ "model" ] = "models/props_c17/clock01.mdl"
TOOL.ClientConVar[ "value_on" ] = "1"
TOOL.ClientConVar[ "description" ] = ""

if (SERVER) then
	ModelPlug_Register("data_forcer")
end

cleanup.Register( "wire_data_forcers" )

function TOOL:LeftClick( trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()


	// Get client's CVars
	local _model			= self:GetClientInfo( "model" )
	local _value_on			= self:GetClientNumber( "value_on" )
	local _description		= self:GetClientInfo( "description" )

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_data_forcer" && trace.Entity.pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_data_forcers" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_data_forcer = MakeWiredata_forcer( ply, _model, trace.HitPos, Ang, _description )

	local min = wire_data_forcer:OBBMins()
	wire_data_forcer:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_data_forcer, trace.Entity, 0, trace.PhysicsBone, 0, true, true )
		// Don't disable collision if it's not attached to anything
		wire_data_forcer:GetPhysicsObject():EnableCollisions( false )
		wire_data_forcer.nocollide = true
	end

	undo.Create("Wire_data_forcer")
		undo.AddEntity( wire_data_forcer )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()


	ply:AddCleanup( "wire_data_forcers", wire_data_forcer )

	return true

end

TOOL.FirstLink = nil

function TOOL:RightClick(trace)
    local ply = self:GetOwner()
    
    if(self.FirstLink == nil)then
        if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_data_forcer" && trace.Entity.pl == ply ) then
            self.FirstLink = trace.Entity
            return true
        end
    else
        if ( trace.Entity:IsValid()) then
            local first = self.FirstLink
            local second = trace.Entity

            first:Setup(second)//first.HackEnt or what ever the name of the ent var for the target is
		//self.FirstLink = nil
		Msg("Bound.\n")
            return true
        end
    end
    Msg("Phailure") //debug
    return false
end

function TOOL:Reload(trace)
    local ply = self:GetOwner()
    if(self.FirstLink == nil) then Msg("No FirstLink.") return true 
    else
		self.FirstLink = nil
		if(trace.Entity:GetClass() == "gmod_wire_data_forcer") then
			trace.Entity.target = nil
		end
		return true
	end
	Msg("removal Phailure, NOES.   ".. self.FirstLink.. "\n") //debug
    return false
end

if (SERVER) then

	function MakeWiredata_forcer( pl, Model, Pos, Ang, description, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_data_forcers" ) ) then return false end
	
		local wire_data_forcer = ents.Create( "gmod_wire_data_forcer" )
		if (!wire_data_forcer:IsValid()) then return false end

		wire_data_forcer:SetModel( Model )
		wire_data_forcer:SetAngles( Ang )
		wire_data_forcer:SetPos( Pos )
		wire_data_forcer:Spawn()

		wire_data_forcer:SetPlayer( pl )

		local ttable = {
			pl              = pl
			}

		table.Merge(wire_data_forcer:GetTable(), ttable )
		
		pl:AddCount( "wire_data_forcers", wire_data_forcer )

		return wire_data_forcer
	end

	duplicator.RegisterEntityClass("gmod_wire_data_forcer", MakeWiredata_forcer, "Model", "Pos", "Ang", "description", "Vel", "aVel", "frozen" )

end

function TOOL:UpdateGhostWiredata_forcer( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_data_forcer" ) then
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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" ) ) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWiredata_forcer( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_data_forcer_name", Description = "#Tool_wire_data_forcer_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		Menudata_forcer = "1",
		Folder = "wire_data_forcer",

		Options = {
			Default = {
				wire_data_forcer_value_on = "1",
			}
		},

		CVars = {
			[1] = "wire_data_forcer_value_on",
		}
	})

	ModelPlug_AddToCPanel(panel, "data_forcer", "wire_data_forcer", "#data_forcer_Model", nil, "#data_forcer_Model")

//  ToDo: Move these to Wire Model Pack 1
//			["Start"] = { wire_data_forcer_model = "models/cheeze/data_forcers/chz_data_forcer_start.mdl" },
//			["Reset"] = { wire_data_forcer_model = "models/cheeze/data_forcers/chz_data_forcer_reset.mdl" },
//			["Enter"] = { wire_data_forcer_model = "models/cheeze/data_forcers/chz_data_forcer_enter.mdl" },
//			["Stop"] = { wire_data_forcer_model = "models/cheeze/data_forcers/chz_data_forcer_stop.mdl" },
//			["Key 1"] = { wire_data_forcer_model = "models/cheeze/data_forcers/chz_data_forcer1.mdl" },
//			["Key 2"] = { wire_data_forcer_model = "models/cheeze/data_forcers/chz_data_forcer2.mdl" },
//			["Key 3"] = { wire_data_forcer_model = "models/cheeze/data_forcers/chz_data_forcer3.mdl" },
//			["Key 4"] = { wire_data_forcer_model = "models/cheeze/data_forcers/chz_data_forcer4.mdl" },
//			["Key 5"] = { wire_data_forcer_model = "models/cheeze/data_forcers/chz_data_forcer5.mdl" },
//			["Key 6"] = { wire_data_forcer_model = "models/cheeze/data_forcers/chz_data_forcer6.mdl" },
//			["Key 7"] = { wire_data_forcer_model = "models/cheeze/data_forcers/chz_data_forcer7.mdl" },
//			["Key 8"] = { wire_data_forcer_model = "models/cheeze/data_forcers/chz_data_forcer8.mdl" },
//			["Key 9"] = { wire_data_forcer_model = "models/cheeze/data_forcers/chz_data_forcer9.mdl" },
//			["Key 0"] = { wire_data_forcer_model = "models/cheeze/data_forcers/chz_data_forcer0.mdl" },
//			["Set"] = { wire_data_forcer_model = "models/cheeze/data_forcers/chz_data_forcer_set.mdl" },
//			["Plus"] = { wire_data_forcer_model = "models/cheeze/data_forcers/chz_data_forcer_plus.mdl" },
//			["Minus"] = { wire_data_forcer_model = "models/cheeze/data_forcers/chz_data_forcer_minus.mdl" },
//			["Clear"] = { wire_data_forcer_model = "models/cheeze/data_forcers/chz_data_forcer_clear.mdl" },
//			["Arm"] = { wire_data_forcer_model = "models/cheeze/data_forcers/chz_data_forcer_arm.mdl" },
//			["Muffin!"] = { wire_data_forcer_model = "models/cheeze/data_forcers/muffin.mdl" },
	end
