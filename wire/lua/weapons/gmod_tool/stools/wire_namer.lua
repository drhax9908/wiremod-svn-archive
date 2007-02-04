
TOOL.Category		= "Wire - Tools"
TOOL.Name			= "Namer"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_namer_name", "Naming Tool" )
    language.Add( "Tool_wire_namer_desc", "Names components." )
    language.Add( "Tool_wire_namer_0", "Primary: Set name\nSecondary: Get name" )
    language.Add( "WireNamerTool_name", "Name:" )
end

TOOL.ClientConVar[ "name" ] = ""

function TOOL:LeftClick(trace)
	if (not trace.Entity:IsValid()) then return end
	if (CLIENT) then return end
	if (not trace.Entity.IsWire) then return end

	local name = self:GetClientInfo("name")
	
	trace.Entity:SetNetworkedString("WireName", name)

	return true
end


function TOOL:RightClick(trace)
	if (not trace.Entity:IsValid()) then return end
	if (CLIENT) then return end

	local name = trace.Entity:GetNetworkedString("WireName")
	if (not name) then return end

    self:GetOwner():ConCommand('wire_namer_name "' .. name .. '"')
end


function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_namer_name", Description = "#Tool_wire_namer_desc" })

	panel:AddControl("TextBox", {
		Label = "#WireNamerTool_name",
		Command = "wire_namer_name",
		MaxLength = "20"
	})
end
