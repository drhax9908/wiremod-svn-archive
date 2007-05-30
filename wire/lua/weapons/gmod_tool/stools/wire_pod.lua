TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Pod Controller"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_pod_name", "Pod Controller Tool (Wire)" )
    language.Add( "Tool_wire_pod_desc", "Spawn/link a Wire Pod controller." )
    language.Add( "Tool_wire_pod_0", "Primary: Create Pod controller. Secondary: Link controller." )
    language.Add( "WirePodTool_pod", "Pod:" )
    language.Add( "WirePodTool_Advanced", "Advanced Controller?:" )
	language.Add( "sboxlimit_wire_pods", "You've hit your Pod Controller limit!" )
	language.Add( "undone_wirepod", "Undone Wire Pod Controller" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_pods', 20)
end

TOOL.Model = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar["Advanced"] = "0"

cleanup.Register( "wire_pods" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_pod" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_pods" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

    local Advanced = (self:GetClientNumber( "Advanced" ) ~= 0)

	local wire_pod = MakeWirePod( ply, trace.HitPos, Advanced, Ang )

	local min = wire_pod:OBBMins()
	wire_pod:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local const = WireLib.Weld(wire_pod, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Pod")
		undo.AddEntity( wire_pod )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()


	ply:AddCleanup( "wire_pods", wire_pod )

	return true
end

function TOOL:RightClick( trace )
    if (!trace.HitPos) then return false end
    --if trace.Entity:GetClass() != "gmod_wire_pod" || "prop_vehicle_prisoner_pod" then return false end
    if ( CLIENT ) then return true end
    if!(trace.Entity)then return false end
    if!(trace.Entity:IsValid())then return false end
    if (self.Oldent) then
        -- Don't ask...
        if trace.Entity:GetClass() == "prop_vehicle_prisoner_pod" or true then self.Oldent:GetTable():Setup(trace.Entity); self.Oldent = nil; return true end
    else
        if (trace.Entity:GetClass() == "gmod_wire_pod" || trace.Entity:GetClass() == "gmod_wire_adv_pod") then self.Oldent = trace.Entity; return true end
    end
    return false
end

function TOOL:Reload(trace)
	self.Oldent = nil
end

if (SERVER) then

	function MakeWirePod( pl, Pos, Advanced, Ang, pod )
		if ( !pl:CheckLimit( "wire_pods" ) ) then return false end
	    
	    local wire_pod
	    if(Advanced)then
	       wire_pod = ents.Create( "gmod_wire_adv_pod" )
	    else
		  wire_pod = ents.Create( "gmod_wire_pod" )
		end
		
		if (!wire_pod:IsValid()) then return false end

		wire_pod:SetAngles( Ang )
		wire_pod:SetPos( Pos )
		wire_pod:SetModel( Model("models/jaanus/wiretool/wiretool_siren.mdl") )
		wire_pod:Spawn()
		--Setup on secondary
		--wire_pod:GetTable():Setup( )
		if pod then wire_pod:GetTable():Setup( pod ) end
		wire_pod:GetTable():SetPlayer( pl )

		local ttable = {
			pl = pl,
		}

		table.Merge(wire_pod:GetTable(), ttable )
		
		pl:AddCount( "wire_pods", wire_pod )

		return wire_pod
	end
	
	duplicator.RegisterEntityClass("gmod_wire_pod", MakeWirePod, "Pos", "Advanced", "Ang", "Pod", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWirePod( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_pod" ) then
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
		self:MakeGhostEntity( self.Model, Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWirePod( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_pod_name", Description = "#Tool_wire_pod_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_pod",

		Options = {
			Default = {
				wire_pod_pod = "0",
			}
		},
		CVars = {
		}
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WirePodTool_Advanced",
		Command = "wire_pod_Advanced"
	})
end
