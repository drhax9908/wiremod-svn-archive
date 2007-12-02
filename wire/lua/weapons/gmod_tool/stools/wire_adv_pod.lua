TOOL.Category = "Wire - I/O"
TOOL.Name = "Advanced Pod Controller"
TOOL.Command = nil -- What is this for?
TOOL.ConfigName = ""

if CLIENT then
	language.Add("Tool_wire_adv_pod_name", "Advanced Pod Controller Tool (Wire)")
	language.Add("Tool_wire_adv_pod_desc", "Spawn/link a Wire Advanced Pod controller.")
	language.Add("Tool_wire_adv_pod_0", "Primary: Create Advanced Pod controller. Secondary: Link Advanced controller.")
	language.Add("Tool_wire_adv_pod_1", "Now select the pod to link to.")
	language.Add("sboxlimit_wire_pods", "You've hit your Pod Controller limit!")
	language.Add("Undone_Advanced Wire Pod", "Undone Wire Advanced Pod Controller")
end

if SERVER then
	CreateConVar('sbox_maxwire_pods', 20)
end

TOOL.Model = "models/jaanus/wiretool/wiretool_siren.mdl"

cleanup.Register("wire_pods")

function TOOL:LeftClick(trace)
	if not trace.HitPos then return false end
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end

	local ply = self:GetOwner()

	if not self:GetSWEP():CheckLimit("wire_pods") then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_pod = MakeWireAdvPod(ply, trace.HitPos, Ang)

	wire_pod:SetPos(trace.HitPos - trace.HitNormal * wire_pod:OBBMins().z)
	
	local const = WireLib.Weld(wire_pod, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Advanced Wire Pod")
		undo.AddEntity(wire_pod)
		undo.AddEntity(const)
		undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCleanup("wire_pods", wire_pod)

	return true
end

function TOOL:RightClick(trace)
	if (self:GetStage() == 0) and trace.Entity:GetClass() == "gmod_wire_adv_pod" then
		self.PodCont = trace.Entity
		self:SetStage(1)
		return true
	elseif self:GetStage() == 1 and trace.Entity.GetPassenger then
		self.PodCont:Setup(trace.Entity)
		self:SetStage(0)
		self.PodCont = nil
		return true
	else
		return false
	end
end

function TOOL:Reload(trace)
	self:SetStage(0)
	self.PodCont = nil
end

if SERVER then

	function MakeWireAdvPod(pl, Pos, Ang)
		if not pl:CheckLimit("wire_pods") then return false end
		local wire_pod
		wire_pod = ents.Create("gmod_wire_adv_pod")
		if not wire_pod:IsValid() then return false end
		wire_pod:SetAngles(Ang)
		wire_pod:SetPos(Pos)
		wire_pod:Spawn()
		if pod then wire_pod:GetTable():Setup(pod) end
		wire_pod:GetTable():SetPlayer(pl)
		local ttable = {
			pl = pl
		}
		table.Merge(wire_pod:GetTable(), ttable)
		
		pl:AddCount("wire_pods", wire_pod)
		
		return wire_pod
	end
	duplicator.RegisterEntityClass("gmod_wire_adv_pod", MakeWireAdvPod, "Pos", "Ang", "Vel", "aVel", "frozen")
end

function TOOL:UpdateGhostWirePod(ent, player)
	if  not ent or not ent:IsValid() then return end

	local tr = utilx.GetPlayerTrace(player, player:GetCursorAimVector())
	local trace = util.TraceLine(tr)

	if not trace.Hit or trace.Entity:IsPlayer() or trace.Entity:GetClass() == "gmod_wire_adv_pod" then
		ent:SetNoDraw(true)
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	ent:SetPos(trace.HitPos - trace.HitNormal * ent:OBBMins().z)
	ent:SetAngles(Ang)

	ent:SetNoDraw(false)
end

function TOOL:Think()
	if not self.GhostEntity or not self.GhostEntity:IsValid() or self.GhostEntity:GetModel() ~= self.Model then
		self:MakeGhostEntity(self.Model, Vector(0,0,0), Angle(0,0,0))
	end

	self:UpdateGhostWirePod(self.GhostEntity, self:GetOwner())
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
end