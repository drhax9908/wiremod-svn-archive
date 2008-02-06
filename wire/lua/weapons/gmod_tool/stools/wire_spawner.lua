TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Prop Spawner"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar = {
	delay = 0,
	undo_delay = 0
}

if CLIENT then
	language.Add( "Tool_wire_spawner_name", "Prop Spawner (Wire)" )
	language.Add( "Tool_wire_spawner_desc", "Spawns a prop at a pre-defined location" )
	language.Add( "Tool_wire_spawner_0", "Click a prop to turn it into a prop spawner." )
	language.Add( "Undone_gmod_wire_spawner", "Undone Wire Spawner" )
	language.Add( "Cleanup_gmod_wire_spawner", "Wire Spawners" )
	language.Add( "Cleaned_gmod_wire_spawner", "Cleaned up Wire Spawners" )
end

if SERVER then
	CreateConVar("sbox_maxwire_spawners",10)
end

cleanup.Register("gmod_wire_spawner")

function TOOL:LeftClick(trace)
	local ent = trace.Entity
	if !ent or !ent:IsValid() then return false end
	if ent:GetClass() != "prop_physics" && ent:GetClass() != "gmod_wire_spawner" then return false end
	if CLIENT then return true end

	local pl			= self:GetOwner()
	local delay			= self:GetClientNumber("delay", 0)
	local undo_delay	= self:GetClientNumber("undo_delay", 0)

	if ent:GetClass() == "gmod_wire_spawner" && ent:GetTable().pl == pl then
		local spawner = ent
		spawner:SetDelays(delay, undo_delay)
		return true
	end

	if !self:GetSWEP():CheckLimit("wire_spawners") then return false end

	local phys			= ent:GetPhysicsObject()
	if !phys:IsValid() then return false end

	local model 		= ent:GetModel()
	local frozen		= !phys:IsMoveable()
	local Pos			= ent:GetPos()
	local Ang			= ent:GetAngles()
	local mat			= ent:GetMaterial()
	local r,b,g,a		= ent:GetColor()

	local wire_spawner = MakeWireSpawner( pl, Pos, Ang, delay, undo_delay, model, mat, r, g, b, nil, nil, frozen )
	if !wire_spawner:IsValid() then return end

	ent:Remove()

	undo.Create("gmod_wire_spawner")
		undo.AddEntity( wire_spawner )
		undo.SetPlayer( pl )
	undo.Finish()

	return true
end

if SERVER then

	function MakeWireSpawner( pl, Pos, Ang, delay, undo_delay, model, mat, r, g, b, vel, avel, frozen )

		if !pl:CheckLimit("wire_spawners") then return nil end

		local spawner = ents.Create("gmod_wire_spawner")
		if !spawner:IsValid() then return end
			spawner:SetPos(Pos)
			spawner:SetAngles(Ang)
			spawner:SetModel(model)
			spawner:SetRenderMode(3)
			spawner:SetMaterial(mat or "")
			spawner:SetColor((r or 255),(g or 255),(b or 255),100)
		spawner:Spawn()

		if spawner:GetPhysicsObject():IsValid() then
			local Phys = spawner:GetPhysicsObject()
			Phys:EnableMotion(!frozen)
		end

		// In multiplayer we clamp the delay to help prevent people being idiots
		if !SinglePlayer() and delay < 0.2 then
			delay = 0.33
		end

		spawner:SetPlayer(pl)
		spawner:GetTable():SetDelays(delay, undo_delay)

		local tbl = {
			pl 			= pl,
			delay		= delay,
			undo_delay	= undo_delay;
			mat			= mat,
			r			= r,
			g			= g,
			b			= b
		}
		table.Merge(spawner:GetTable(), tbl)

		pl:AddCount("wire_spawners", spawner)
		pl:AddCleanup("gmod_wire_spawner", spawner)

		return spawner
	end

	duplicator.RegisterEntityClass("gmod_wire_spawner", MakeWireSpawner, "Pos", "Ang", "delay", "undo_delay", "model", "mat", "r", "g", "b", "Vel", "aVel", "frozen")

end

function TOOL.BuildCPanel( CPanel )

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
	
	local params = { 
		Label	= "#Spawn Delay",
		Type	= "Float",
		Min		= "0",
		Max		= "100",
		Command	= "wire_spawner_delay",
	}
	CPanel:AddControl( "Slider",  params )

	local params = { 
		Label	= "#Automatic Undo Delay",
		Type	= "Float",
		Min		= "0",
		Max		= "100",
		Command	= "wire_spawner_undo_delay",
	}
	CPanel:AddControl( "Slider",  params )

end
