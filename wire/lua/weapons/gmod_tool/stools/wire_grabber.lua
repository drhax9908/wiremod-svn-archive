TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Grabber"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_grabber_name", "Grabber Tool (Wire)" )
    language.Add( "Tool_wire_grabber_desc", "Spawns a constant grabber prop for use with the wire system." )
    language.Add( "Tool_wire_grabber_0", "Primary: Create/Update Grabber Secondary: link the grabber to its extra prop that is attached for stabilty" )
    language.Add( "WireGrabberTool_grabber", "Grabber:" )
    language.Add( "WireGrabberTool_Range", "Max Range:" )
    language.Add( "WireGrabberTool_Gravity", "Disable Gravity:" )
    language.Add( "WireGrabberTool_Model", "Choose a Model:")
    language.Add( "sboxlimit_wire_grabbers", "You've hit grabbers limit!" )
    language.Add( "undone_Wire Grabber", "Undone Wire Grabber" )
    language.Add( "Cleanup_wire_grabbers", "Wire Grabbers" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_grabbers', 20)
	CreateConVar('sbox_wire_grabbers_onlyOwnersProps', 1)
end

TOOL.ClientConVar[ "Model" ] = "models/jaanus/wiretool/wiretool_range.mdl"
TOOL.ClientConVar[ "Range" ] = "100"
TOOL.ClientConVar[ "Gravity" ] = "1"

local grabbermodels = {
    ["models/jaanus/wiretool/wiretool_grabber_forcer.mdl"] = {},
    ["models/jaanus/wiretool/wiretool_range.mdl"] = {}};

cleanup.Register( "wire_grabbers" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	local range = self:GetClientNumber("Range")
	local gravity = (self:GetClientNumber("Gravity") != 0)
	local model = self:GetClientInfo("Model")

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_grabber" && trace.Entity:GetTable().pl == ply ) then
		trace.Entity:Setup(range, gravity)
		trace.Entity.Gange = range
		trace.Entity.Gravity = gravity
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_grabbers" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local wire_grabber = MakeWireGrabber( ply, trace.HitPos, range, gravity, model, Ang )

	local min = wire_grabber:OBBMins()
	if(model == "models/jaanus/wiretool/wiretool_grabber_forcer.mdl")then
	   wire_grabber:SetPos( trace.HitPos - trace.HitNormal * (min.z + 20) )
	else
	   wire_grabber:SetPos( trace.HitPos - trace.HitNormal * min.z )
	end

	local const = WireLib.Weld(wire_grabber, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Grabber")
		undo.AddEntity( wire_grabber )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_grabbers", wire_grabber )

	return true
end

function TOOL:RightClick( trace )
	if (!trace.HitPos) then return false end
    if ( CLIENT ) then return true end
    if!(trace.Entity)then return false end
    if!(trace.Entity:IsValid())then return false end
    if (self.Oldent) then
        self.Oldent.ExtraProp = trace.Entity;
        self.Oldent = nil;
        return true
    else
        if (trace.Entity:GetClass() == "gmod_wire_grabber") then
            self.Oldent = trace.Entity;
            return true
        end
    end
end

if (SERVER) then

	function MakeWireGrabber( pl, Pos, Range, Gravity, Model, Ang )
		if ( !pl:CheckLimit( "wire_grabbers" ) ) then return false end
	
		local wire_grabber = ents.Create( "gmod_wire_grabber" )
		if (!wire_grabber:IsValid()) then return false end

		wire_grabber:SetAngles( Ang )
		wire_grabber:SetPos( Pos )
		wire_grabber:SetModel( Model )
		wire_grabber:Spawn()
		wire_grabber:Setup(Range, Gravity)

		wire_grabber:SetPlayer( pl )

		local ttable = {
		    Range = Range,
		    Gravity = Gravity,
			pl = pl
		}
		table.Merge(wire_grabber:GetTable(), ttable )
		
		pl:AddCount( "wire_grabbers", wire_grabber )

		return wire_grabber
	end
	
	duplicator.RegisterEntityClass("gmod_wire_grabber", MakeWireGrabber, "Pos", "Range", "Gravity", "Model", "Ang", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireGrabber( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_grabber" ) then
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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo("Model") ) then
		self:MakeGhostEntity( self:GetClientInfo("Model"), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireGrabber( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_grabber_name", Description = "#Tool_wire_grabber_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_grabber",

		Options = {
			Default = {
				wire_grabber_grabber = "0",
			}
		},
		CVars = {
		}
	})
	
	panel:AddControl( "PropSelect", { Label = "#WireGrabberTool_Model",
									 ConVar = "wire_grabber_Model",
									 Category = "Wire Grabber",
									 Models = grabbermodels } )
	
	panel:AddControl("CheckBox", {
		Label = "#WireGrabberTool_Gravity",
		Command = "wire_grabber_Gravity"
	})
	
	panel:AddControl("Slider", {
		Label = "#WireGrabberTool_Range",
		Type = "Float",
		Min = "1",
		Max = "10000",
		Command = "wire_grabber_Range"
	})
end

