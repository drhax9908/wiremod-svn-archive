TOOL.Category		= "Wire - Tools"
TOOL.Name			= "Expression 2 - Wirelink"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if CLIENT then
    language.Add( "Tool_wire_wirelink_name", "Expression 2 Wirelink Tool (Wire)" )
    language.Add( "Tool_wire_wirelink_desc", "Adds a wirelink output to any wire compatible device, for use with Expression 2" )
    language.Add( "Tool_wire_wirelink_0", "Primary: Add wirelink, Secondary: Remove wirelink" )
end

if SERVER then
	local _Wire_CreateSpecialOutputs = WireLib.CreateSpecialOutputs
	local _Wire_AdjustSpecialOutputs = WireLib.AdjustSpecialOutputs
	local _Wire_BuildDupeInfo = WireLib.BuildDupeInfo
	local _Wire_ApplyDupeInfo = WireLib.ApplyDupeInfo
	
	function RefreshSpecialOutputs(ent)
		local names = {}
		local types = {}
		local descs = {}
		
		if ent.Outputs then
			local index = 1
		
			for _,output in pairs(ent.Outputs) do
				names[index] = output.Name
				types[index] = output.Type
				descs[index] = output.Desc
				index = index + 1
			end
			
			ent.Outputs = WireLib.AdjustSpecialOutputs(ent, names, types, descs)
		else
			ent.Outputs = WireLib.CreateSpecialOutputs(ent, names, types, descs)
		end
		
		WireLib.TriggerOutput(ent, "link", ent)
	end
	
	function InfuseSpecialOutputs(func, ent, names, types, desc)
		if ent.extended == nil then
			return func(ent, names, types, desc)
		end
	
		if types == nil then types = {} end
		types[#names + 1] = "WIRELINK"
		names[#names + 1] = "link"
		local outputs = func(ent, names, types, desc)
		types[#names] = nil
		names[#names] = nil
		
		return outputs
	end
	
	function WireLib.BuildDupeInfo(ent)
		local info = _Wire_BuildDupeInfo(ent)
		if ent.extended then info.extended = true end
		return info
	end
	
	function WireLib.ApplyDupeInfo(ply, ent, info, GetEntByID)
		if info.extended then ent.extended = true end
		RefreshSpecialOutputs(ent)
		_Wire_ApplyDupeInfo(ply, ent, info, GetEntByID)
	end
	
	function WireLib.CreateSpecialOutputs(ent, names, types, desc)
		return InfuseSpecialOutputs(_Wire_CreateSpecialOutputs, ent, names, types, desc)
	end
	
	function WireLib.AdjustSpecialOutputs(ent, names, types, desc)
		return InfuseSpecialOutputs(_Wire_AdjustSpecialOutputs, ent, names, types, desc)
	end
	
	function WireLib.CreateOutputs(ent, names, desc)
		return WireLib.CreateSpecialOutputs(ent, names, {}, desc)
	end
	
	function WireLib.AdjustOutputs(ent, names, desc)
		return WireLib.AdjustSpecialOutputs(ent, names, {}, desc)
	end
	
	Wire_CreateOutputs = WireLib.CreateOutputs
	Wire_AdjustOutputs = WireLib.AdjustOutputs
end


function TOOL:LeftClick(trace)
	if !trace.HitPos then return false end
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end
	
	local ply = self:GetOwner()
	if ( trace.Entity:IsValid() && (trace.Entity.Base == "base_wire_entity" || trace.Entity.TriggerInput) && (trace.Entity.pl == ply || trace.Entity.pl == nil) ) then
		local ent = trace.Entity
		if ent.extended then return false end
		
		ent.extended = true
		RefreshSpecialOutputs(ent)
		
		return true
	end	

	return false
end

function TOOL:RightClick(trace)
	if !trace.HitPos then return false end
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end
	
	local ply = self:GetOwner()
	if ( trace.Entity:IsValid() && trace.Entity.TriggerInput && (trace.Entity.pl == ply || trace.Entity.pl == nil) ) then
		local ent = trace.Entity
		if !ent.extended then return false end
		
		ent.extended = false
		RefreshSpecialOutputs(ent)
		
		return true
	end	

	return false
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_wirelink_name", Description = "#Tool_wire_wirelink_desc" })
end