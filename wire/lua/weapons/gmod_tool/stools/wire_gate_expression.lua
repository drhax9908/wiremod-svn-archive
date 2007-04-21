-- check what approach angle does... useful?
-- high speed links to memory some how would be nice    read()   write() ?
-- fix playsound for errors in "init.lua"
-- EXPECT should report line of PREVIOUS token (not the one that it is on when reporting an error)
-- the parser should verify which functions actually exists
-- make better transfer from client->server (server->client needed?) ... limit of like 100 chars per line now

TOOL.Category		= "Wire - Control"
TOOL.Name			= "Gate - Expression"
TOOL.Command		= nil
TOOL.ConfigName		= ""

--[[function StringTrimRight(str)
	local i = string.len(str)
	while i > 0 do
		local s = string.sub(str, i, i)
		if s == " " or s == "\n" or s == "\r" or s == "\t" then else break end
		i = i - 1
	end
	return string.sub(str, 1, i)
end--]]

function StringExplode(sep, str)
	local lines = {}
	
	while str and str ~= "" do
		local pos = string.find(str, sep)
		if pos == nil then
			table.insert(lines, str)
			break
		end
		
		if pos > 1 then
			table.insert(lines, string.sub(str, 1, pos - 1))				
		else
			table.insert(lines, "")
		end
		
		str = string.sub(str, pos + 1)
	end
	
	return lines
end

function WireExpressionGetLines(player)
	local lines = {}
	local blank = 0
	for i = 1,60 do
		local line = player:GetInfo('wire_gate_expression_line' .. i)
		if line and line ~= "" then
			while blank > 0 do table.insert(lines, "") blank = blank - 1 end
			table.insert(lines, line)
		else
			blank = blank + 1
		end
	end
	return lines
end

function MakeWireGateExpressionParser(lines, inputs, outputs)
	local code = ""
	for _,line in ipairs(lines) do
		if string.sub(line, 1, 1) ~= "#" then
			code = code .. line .. "\n"
		else
			code = code .. "\n"
		end
	end
	return WireGateExpressionParser:New(code, inputs, outputs)
end

if CLIENT then
    language.Add("Tool_wire_gate_expression_name", "Expression Gate Tool (Wire)")
    language.Add("Tool_wire_gate_expression_desc", "Spawns an expression gate for use with the wire system.")
    language.Add("Tool_wire_gate_expression_0",    "Primary: Create/Update Expression Gate, Secondary: Load Expression Gate, Reload: Reset Variables")
	language.Add("sboxlimit_wire_gate_expression", "You've hit expression gates limit!")
	language.Add("undone_wiregateexpression",      "Undone Wire Expression Gate")
end

if SERVER then
	CreateConVar('sbox_maxwire_gate_expressions', 20)
end

TOOL.ClientConVar["model"]     = "models/cheeze/wires/cpu.mdl"
TOOL.ClientConVar["filename"]  = ""
TOOL.ClientConVar["label"]     = ""
TOOL.ClientConVar["inputs"]    = ""
TOOL.ClientConVar["outputs"]   = ""

for i = 1,60 do
	TOOL.ClientConVar["line" .. i] = ""
end

cleanup.Register("wire_gate_expressions")


function TOOL:LeftClick(trace)
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end
	
	local player = self:GetOwner()
	
	local name = self:GetClientInfo("label")
	local inputs = self:GetClientInfo("inputs")
	local outputs = self:GetClientInfo("outputs")
	
	local lines = WireExpressionGetLines(player)
	
	if (trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_expression" && trace.Entity.player == player) then
		local parser = VerifyWireGateExpression(player, lines, inputs, outputs)
		if !parser then return false end
		SetupWireGateExpression(trace.Entity, parser, name, lines, inputs, outputs)
		return true
	end
	
	if !self:GetSWEP():CheckLimit("wire_gate_expressions") then return false end
	if !util.IsValidModel(self:GetClientInfo("model")) then return false end
	if !util.IsValidProp(self:GetClientInfo("model")) then return false end

	local Model = self:GetClientInfo("model")
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	wire_gate = MakeWireGateExpression(player, Ang, trace.HitPos, Model, name, lines, inputs, outputs)
	if !wire_gate then return false end
	
	--wire_gate:GetPhysicsObject():EnableMotion(false)
	wire_gate:SetPos(trace.HitPos - trace.HitNormal * wire_gate:OBBMins().z)
	local constraint = WireLib.Weld(wire_gate, trace.Entity, trace.PhysicsBone, true)
	
	undo.Create("WireGateExpression")
	undo.AddEntity(wire_gate)
	undo.SetPlayer(player)
	undo.AddEntity(constraint)
	undo.Finish()

	player:AddCleanup("wire_gate_expressions", wire_gate)

	return true
end

function TOOL:RightClick(trace)
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end

	local player = self:GetOwner()

	if (trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_expression" && trace.Entity.player == player) then
		player:ConCommand('wire_gate_expression_filename ""')
		player:ConCommand('wire_gate_expression_label "' .. trace.Entity.GateName .. '"')
		player:ConCommand('wire_gate_expression_inputs "' .. trace.Entity.GateInputs .. '"')
		player:ConCommand('wire_gate_expression_outputs "' .. trace.Entity.GateOutputs .. '"')
		
		for i = 1,60 do
			local line = trace.Entity.GateLines[i]
			if (line and line ~= "") then
				player:ConCommand('wire_gate_expression_line' .. i .. ' "' .. line .. '"')
			else
				player:ConCommand('wire_gate_expression_line' .. i .. ' ""')
			end
		end
		
		player:SendLua('wire_gate_expression_filename = "(loaded expression)"')
		player:SendLua('wire_gate_expression_status = "Successfully fetched \\"' .. trace.Entity.GateName .. '\\""')
		player:SendLua('wire_gate_expression_label = "' .. trace.Entity.GateName .. '"')
		player:SendLua('wire_gate_expression_inputs = "' .. trace.Entity.GateInputs .. '"')
		player:SendLua('wire_gate_expression_outputs = "' .. trace.Entity.GateOutputs .. '"')
		player:SendLua('WireGateExpressionRebuildCPanel()')
		return true
	else
		return false
	end
end

function TOOL:Reload(trace)
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end

	local player = self:GetOwner()
	if (trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_expression" && trace.Entity.player == player) then		
		trace.Entity:Reset()
		return true
	else
		return false
	end
end

function TOOL:UpdateGhostWireGateExpression(ent, player)
	if !ent or !ent:IsValid() then return end

	local trace = util.TraceLine(utilx.GetPlayerTrace(player, player:GetCursorAimVector()))
	if !trace.Hit then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_expression" || trace.Entity:IsPlayer()) then
		ent:SetNoDraw(true)
	else 
		local Ang = trace.HitNormal:Angle()
		Ang.pitch = Ang.pitch + 90

		ent:SetPos(trace.HitPos - trace.HitNormal * ent:OBBMins().z)
		ent:SetAngles(Ang)
		ent:SetNoDraw(false)
	end
end

function TOOL:Think()
	if !self.GhostEntity || !self.GhostEntity:IsValid() || !self.GhostEntity:GetModel() || self.GhostEntity:GetModel() != self:GetClientInfo("model") then
		self:MakeGhostEntity(self:GetClientInfo("model"), Vector(0, 0, 0), Angle(0, 0, 0))
	end

	self:UpdateGhostWireGateExpression(self.GhostEntity, self:GetOwner())
end

function TOOL.BuildCPanel(panel)
	WireGateExpressionRebuildCPanel(panel)
end

if SERVER then
	function SetupWireGateExpression(entity, parser, name, lines, inputs, outputs)
		entity.GateName =    name
		entity.GateLines =   lines
		entity.GateInputs =  inputs
		entity.GateOutputs = outputs
		
		entity:Setup(name, parser)
	end
	
	function VerifyWireGateExpression(player, lines, inputs, outputs)
		local parser = MakeWireGateExpressionParser(lines, inputs, outputs)
		if !parser:GetError() then
			return parser
		else
			player:SendLua('wire_gate_expression_status = "' .. parser:GetError() .. '"')
			player:SendLua('WireGateExpressionRebuildCPanel()')
			player:SendLua('GAMEMODE:AddNotify("' .. parser:GetError() .. '", NOTIFY_ERROR, 7)')
			return
		end
	end

	function MakeWireGateExpression(player, ang, pos, model, name, lines, inputs, outputs)
		if !player:CheckLimit("wire_gate_expressions") then return false end
		
		local parser = VerifyWireGateExpression(player, lines, inputs, outputs)
		if !parser then return false end
		
		local entity = ents.Create("gmod_wire_expression")
		if !entity:IsValid() then return false end
		
		entity:SetModel(model)
		entity:SetAngles(ang)
		entity:SetPos(pos)
		entity:Spawn()
		entity:SetPlayer(player)

		SetupWireGateExpression(entity, parser, name, lines, inputs, outputs)
		
		table.Merge(entity:GetTable(), { player = player })
		player:AddCount("wire_gate_expressions", entity)
		return entity
	end
	
	duplicator.RegisterEntityClass("gmod_wire_expression", MakeWireGateExpression, "Ang", "Pos", "Model", "GateName", "GateLines", "GateInputs", "GateOutputs")
end

if CLIENT then
	function WireGateExpressionUpdateFilelist()
		local fileindex, foldindex = 1, 1
		local filelist, filemap = {}, {}
		local foldlist, foldmap = {}, {}
		
		if (file.Exists(wire_gate_expression_basefolder .. wire_gate_expression_folder) && file.IsDir(wire_gate_expression_basefolder .. wire_gate_expression_folder)) then
			for key,value in pairs(file.Find(wire_gate_expression_basefolder .. wire_gate_expression_folder .. "/*")) do
				if (file.IsDir(wire_gate_expression_basefolder .. wire_gate_expression_folder .. "/" .. value)) then
					foldlist[value] = { wire_gate_expression_folder = foldindex }
					foldmap[foldindex] = wire_gate_expression_folder .. "/" .. value
					foldindex = foldindex + 1
				elseif (string.sub(value, -4) == ".txt") then
					filelist[string.sub(value, 1, -5)] = { wire_gate_expression_select = fileindex }
					filemap[fileindex] = wire_gate_expression_folder .. "/" .. string.sub(value, 1, -5)
					fileindex = fileindex + 1
				end
			end
		end
		
		wire_gate_expression_filelist = filelist
		wire_gate_expression_filemap = filemap
		wire_gate_expression_foldlist = foldlist
		wire_gate_expression_foldmap = foldmap
	end
end

if SERVER then
	local function WireGateExpressionPanelParent(player, command, args) player:SendLua('WireGateExpressionPanelParent()') end
	concommand.Add("wire_gate_expression_parent", WireGateExpressionPanelParent)
else
	function WireGateExpressionPanelParent()
		local lasthit
		local pos = 1
		while pos <= string.len(wire_gate_expression_folder) do
			if string.sub(wire_gate_expression_folder, pos, pos) == "/" then lasthit = pos end
			pos = pos + 1
		end
		
		if lasthit and lasthit > 1 then
			wire_gate_expression_folder = string.sub(wire_gate_expression_folder, 1, lasthit - 1)
		else
			wire_gate_expression_folder = ""
		end
		
		WireGateExpressionUpdateFilelist()
		WireGateExpressionRebuildCPanel()
	end
end

if SERVER then
	local function WireGateExpressionPanelFolder(player, command, args) player:SendLua('WireGateExpressionPanelFolder(' .. args[1] .. ')') end
	concommand.Add("wire_gate_expression_folder", WireGateExpressionPanelFolder)
else
	function WireGateExpressionPanelFolder(index)
		wire_gate_expression_folder = wire_gate_expression_foldmap[index]
		WireGateExpressionUpdateFilelist()
		WireGateExpressionRebuildCPanel()
	end
end

if SERVER then
	local function WireGateExpressionPanelValidate(player, command, args) player:SendLua('WireGateExpressionPanelValidate()') end
	concommand.Add("wire_gate_expression_validate", WireGateExpressionPanelValidate)
else
	function WireGateExpressionPanelValidate()
		local player = LocalPlayer()
		
		local inputs = player:GetInfo("wire_gate_expression_inputs")
		local outputs = player:GetInfo("wire_gate_expression_outputs")
		local lines = WireExpressionGetLines(player)
		
		local parser = MakeWireGateExpressionParser(lines, inputs, outputs)
		local status = parser:GetError()
		if !status then status = "Successfully validated" end
		wire_gate_expression_status = status
		
		WireGateExpressionRebuildCPanel()
	end
end

if SERVER then
	local function WireGateExpressionPanelLoad(player, command, args) player:SendLua('WireGateExpressionPanelLoad()') end
	concommand.Add("wire_gate_expression_load", WireGateExpressionPanelLoad)
else
	function WireGateExpressionPanelLoad()
		local player = LocalPlayer()
		WireGateExpressionLoad(player:GetInfo('wire_gate_expression_filename'))
	end
end

if SERVER then
	local function WireGateExpressionMenuSave(player, command, args) player:SendLua('WireGateExpressionMenuSave()') end
	concommand.Add("wire_gate_expression_save", WireGateExpressionMenuSave)
else
	function WireGateExpressionMenuSave()
		local player = LocalPlayer()
		
		local str = ""
		local name = player:GetInfo('wire_gate_expression_label')
		local inputs = player:GetInfo('wire_gate_expression_inputs')
		local outputs = player:GetInfo('wire_gate_expression_outputs')
		
		if name and name ~= "" then str = str .. "N@" .. name .. "\n" end		
		if inputs and inputs ~= "" then str = str .. "I@" .. inputs .. "\n" end
		if outputs and outputs ~= "" then str = str .. "O@" .. outputs .. "\n" end
		
		local lines = WireExpressionGetLines(player)
		for _,line in ipairs(lines) do str = str .. line .. "\n" end
		
		local filename = player:GetInfo('wire_gate_expression_filename')
		
		wire_gate_expression_filename = filename
		wire_gate_expression_label = name
		wire_gate_expression_inputs = inputs
		wire_gate_expression_outputs = outputs
		
		file.Write("/" .. wire_gate_expression_basefolder .. "/" .. filename .. ".txt", str)
		if file.Exists("/" .. wire_gate_expression_basefolder .. "/" .. filename .. ".txt") then
			wire_gate_expression_status = "Successfully saved \"" .. filename .. "\""
		else
			wire_gate_expression_status = "Could not save \"" .. filename .. "\""
		end
		WireGateExpressionRebuildCPanel()
	end
end

if CLIENT then
	function WireGateExpressionLoad(filename)
		local player = LocalPlayer()
		
		local code
		if file.Exists(wire_gate_expression_basefolder .. "/" .. filename .. ".txt") then
			code = file.Read(wire_gate_expression_basefolder .. "/" .. filename .. ".txt")
			if code == nil then
				wire_gate_expression_status = "Could not load \"" .. filename .. "\""
				WireGateExpressionRebuildCPanel()
				return
			end
		else
			wire_gate_expression_status = "Unable to find \"" .. filename .. "\""
			WireGateExpressionRebuildCPanel()
			return
		end
		
		local lines = StringExplode("\n", code)
		
		wire_gate_expression_filename = filename
		player:ConCommand('wire_gate_expression_filename "' .. filename .. '"')
		
		if lines[1] and string.sub(lines[1], 1, 2) == "N@" then
			str = string.sub(table.remove(lines, 1), 3)
			player:ConCommand('wire_gate_expression_label "' .. str .. '"')
			wire_gate_expression_label = str
		else
			player:ConCommand('wire_gate_expression_label "' .. filename .. '"')
			wire_gate_expression_label = filename
		end
		
		if lines[1] and string.sub(lines[1], 1, 2) == "I@" then
			str = string.sub(table.remove(lines, 1), 3)
			player:ConCommand('wire_gate_expression_inputs "' ..str .. '"')
			wire_gate_expression_inputs = str
		else
			player:ConCommand('wire_gate_expression_inputs ""')
			wire_gate_expression_inputs = ""
		end
		
		if lines[1] and string.sub(lines[1], 1, 2) == "O@" then
			str = string.sub(table.remove(lines, 1), 3)
			player:ConCommand('wire_gate_expression_outputs "' .. str .. '"')
			wire_gate_expression_outputs = str
		else
			player:ConCommand('wire_gate_expression_outputs ""')
			wire_gate_expression_outputs = ""
		end
		
		for i,line in ipairs(lines) do
			player:ConCommand('wire_gate_expression_line' .. i .. ' "' .. line .. '"')
		end
		
		for i = #lines+1,60 do
			player:ConCommand('wire_gate_expression_line' .. i .. ' ""')
		end
	
		wire_gate_expression_status = "Successfully loaded \"" .. filename .. "\""
		WireGateExpressionRebuildCPanel()
	end
end

if SERVER then
	local function WireGateExpressionPanelDelete(player, command, args) player:SendLua('WireGateExpressionPanelDelete()') end
	concommand.Add("wire_gate_expression_delete", WireGateExpressionPanelDelete)
else
	function WireGateExpressionPanelDelete()
		local player = LocalPlayer()
		
		local filename = player:GetInfo('wire_gate_expression_filename')
		if file.Exists(wire_gate_expression_basefolder .. "/" .. filename .. ".txt") then
			file.Delete(wire_gate_expression_basefolder .. "/" .. filename .. ".txt")
			if file.Exists(wire_gate_expression_basefolder .. "/" .. filename .. ".txt") then
				wire_gate_expression_status = "Could not delete \"" .. filename .. "\""
			else
				wire_gate_expression_status = "Successfully deleted \"" .. filename .. "\""
			end
		else
			wire_gate_expression_status = "Unable to find \"" .. filename .. "\""
		end
		
		WireGateExpressionRebuildCPanel()
	end
end

if SERVER then
	local function WireGateExpressionPanelSelect(player, command, args) player:SendLua('WireGateExpressionPanelSelect(' .. args[1] .. ')') end
	concommand.Add("wire_gate_expression_select", WireGateExpressionPanelSelect)
else
	function WireGateExpressionPanelSelect(index)
		WireGateExpressionLoad(wire_gate_expression_filemap[index])
	end
end

if SERVER then
	local function WireGateExpressionPanelRefresh(player, command, args) player:SendLua('WireGateExpressionPanelRefresh()') end
	concommand.Add("wire_gate_expression_refresh", WireGateExpressionPanelRefresh)
else
	function WireGateExpressionPanelRefresh()
		--[[
		local gui = {}
		gui.frame = vgui.Create( "Frame" )
		gui.frame:SetName( "basic" )
		gui.frame:LoadControlsFromString(AdvDupeClient.res.gengui("Save to File"))
		gui.frame:SetName("AdvDuplicatorSave")
		gui.frame:SetSize(320,135)
		gui.frame:SetPos(400,250)
		
		
		gui.lblFile = vgui.Create("Label",gui.frame,"lblFile")
		gui.lblFile:SetPos(6,25)
		gui.lblFile:SetSize(185,25)
		gui.lblFile:SetText("Filename:")
		
		gui.lblDesc = vgui.Create("Label",gui.frame,"lblDesc")
		gui.lblDesc:SetPos(6,65)
		gui.lblDesc:SetSize(185,25)
		gui.lblDesc:SetText("Description:")
		
		gui.btnSave = vgui.Create("Button",gui.frame,"btnSave")
		gui.btnSave:SetPos(184,110)
		gui.btnSave:SetSize(110,20)
		gui.btnSave:SetText("Save")
		gui.btnSave:SetCommand("Save")
		
		gui.txtFile = vgui.Create("TextEntry",gui.frame,"txtFile")
		gui.txtFile:SetPos(6,45)
		gui.txtFile:SetSize(289,100)
		gui.txtFile:SetCommand("SetMultiline", "b", "1");


		
		
		//gui.txtDesc = vgui.Create("TextEntry",gui.frame,"txtDesc")
		//gui.txtDesc:SetPos(6,85)
		//gui.txtDesc:SetSize(189,20)
		
		function gui.frame:ActionSignal(key,value)
			if key == "Save" then
				local filename	= gui.txtFile:GetValue()
				local desc		= gui.txtDesc:GetValue()
				
				LocalPlayer():ConCommand("adv_duplicator_save \""..filename.."\" \""..desc.."\"")
				
				gui.frame:SetVisible(false)
			end
		end
		
		gui.txtFile:SetText("")
		--gui.txtDesc:SetText("")
		
		gui.frame:SetKeyBoardInputEnabled( true )
		gui.frame:SetMouseInputEnabled( true )
		gui.frame:SetVisible( true )
		--]]
	
	
		WireGateExpressionUpdateFilelist()
		WireGateExpressionRebuildCPanel()
	end
end

if SERVER then
	local function WireGateExpressionPanelProcess(player, command, args) player:SendLua('WireGateExpressionPanelProcess()') end
	concommand.Add("wire_gate_expression_process", WireGateExpressionPanelProcess)
else
	function WireGateExpressionPanelProcess()
		local player = LocalPlayer()
		
		local lines = {}
		for i = 1,60 do
			local line = player:GetInfo('wire_gate_expression_line' .. i)
			if line and line ~= "" then
				local split = StringExplode("\\", line)
				for _,value in ipairs(split) do
					table.insert(lines, value)
				end
			end
		end
		
		for i,line in ipairs(lines) do
			player:ConCommand('wire_gate_expression_line' .. i .. ' "' .. line .. '"')
		end
		
		for i = #lines+1,60 do
			player:ConCommand('wire_gate_expression_line' .. i .. ' ""')
		end
		
		WireGateExpressionRebuildCPanel()
	end
end

if SERVER then
	local function WireGateExpressionPanelEdit(player, command, args) player:SendLua('WireGateExpressionPanelEdit()') end
	concommand.Add("wire_gate_expression_edit", WireGateExpressionPanelEdit)
else
	function WireGateExpressionPanelEdit()
		wire_gate_expression_state = 1
		WireGateExpressionRebuildCPanel()
	end
end

if SERVER then
	local function WireGateExpressionPanelBrowse(player, command, args) player:SendLua('WireGateExpressionPanelBrowse()') end
	concommand.Add("wire_gate_expression_browse", WireGateExpressionPanelBrowse)
else
	function WireGateExpressionPanelBrowse()
		local player = LocalPlayer()
		
		wire_gate_expression_state =   0
		wire_gate_expression_label =   player:GetInfo('wire_gate_expression_label')
		wire_gate_expression_inputs =  player:GetInfo('wire_gate_expression_inputs')
		wire_gate_expression_outputs = player:GetInfo('wire_gate_expression_outputs')
		
		WireGateExpressionRebuildCPanel()
	end
end

if SERVER then
	local function WireGateExpressionPanelNew(player, command, args) player:SendLua('WireGateExpressionPanelNew()') end
	concommand.Add("wire_gate_expression_new", WireGateExpressionPanelNew)
else
	function WireGateExpressionPanelNew()
		local player = LocalPlayer()
		
		wire_gate_expression_state =    1
		wire_gate_expression_filename = ""
		wire_gate_expression_label =    ""
		wire_gate_expression_inputs =   ""
		wire_gate_expression_outputs =  ""
		wire_gate_expression_status =   "New expression created"
		
		player:ConCommand('wire_gate_expression_filename ""')
		player:ConCommand('wire_gate_expression_label ""')
		player:ConCommand('wire_gate_expression_inputs ""')
		player:ConCommand('wire_gate_expression_outputs ""')
		
		for i = 1,60 do
			player:ConCommand('wire_gate_expression_line' .. i .. ' ""')
		end
		
		WireGateExpressionRebuildCPanel()
	end
end

if CLIENT then
	function WireGateExpressionRebuildCPanel(panel)
		if !panel then
			panel = GetControlPanel("wire_gate_expression")
			if !panel then return end
		end
		
		panel:ClearControls()
		
		panel:AddControl("Header", {
			Text = "#Tool_wire_gate_expression_name",
			Description = "Written by Syranide, me@syranide.com"
		})

		ModelPlug_AddToCPanel(panel, "gate", "wire_gate_expression", "Model:", nil, "Model:")
		
		if wire_gate_expression_state == 0 then
			panel:AddControl("Button", {
				Text = "New Expression...",
				Name = "New Expression...",
				Command = "wire_gate_expression_new"
			})
			
			panel:AddControl("Label", {
				Label = "Location:",
				Text = "                 " .. wire_gate_expression_folder .. "/",
			})
			
			panel:AddControl("Button", {
				Text = "Parent Directory",
				Name = "Parent Directory",
				Command = "wire_gate_expression_parent"
			})
			
			panel:AddControl("ListBox", {
				Label = "Folders",
				Height = 4 * 15 + 26,
				Options = wire_gate_expression_foldlist
			})
			
			panel:AddControl("ListBox", {
				Label = "Expressions",
				Height = 18 * 15 + 26,
				Options = wire_gate_expression_filelist
			})
			
			panel:AddControl("Button", {
				Text = "Refresh",
				Name = "Refresh",
				Command = "wire_gate_expression_refresh"
			})
			
			if wire_gate_expression_filename == "" then
				panel:AddControl("Label", {
					Label = "Filename:",
					Text = "                 " .. "(new expression)",
				})
			else
				panel:AddControl("Label", {
					Label = "Filename:",
					Text = "                 " .. wire_gate_expression_filename,
				})
			end
			
			panel:AddControl("Label", {
				Label = "Label:",
				Text = "                 " .. wire_gate_expression_label,
			})
			
			panel:AddControl("Label", {
				Label = "Inputs:",
				Text = "                 " .. wire_gate_expression_inputs,
			})
			
			panel:AddControl("Label", {
				Label = "Outputs:",
				Text = "                 " .. wire_gate_expression_outputs,
			})
			
			panel:AddControl("Button", {
				Text = "Edit Expression...",
				Name = "Edit Expression...",
				Command = "wire_gate_expression_edit"
			})
		elseif wire_gate_expression_state == 1 then
			panel:AddControl("Button", {
				Text = "Browse Expressions...",
				Name = "Browse Expressions...",
				Command = "wire_gate_expression_browse"
			})
			
			panel:AddControl("TextBox", {
				Label = "Filename:",
				Command = "wire_gate_expression_filename",
				MaxLength = 100
			})
			
			panel:AddControl("Button", {
				Text = "Load",
				Name = "Load",
				Command = "wire_gate_expression_load"
			})

			panel:AddControl("Button", {
				Text = "Save",
				Name = "Save",
				Command = "wire_gate_expression_save"
			})
			
			panel:AddControl("Button", {
				Text = "Delete",
				Name = "Delete",
				Command = "wire_gate_expression_delete"
			})

			panel:AddControl("Label", {
				Label = "Status:",
				Text = "             " .. wire_gate_expression_status,
			})
			
			panel:AddControl("Button", {
				Text = "Validate",
				Name = "Validate",
				Command = "wire_gate_expression_validate"
			})
			
			panel:AddControl("TextBox", {
				Label = "Label:",
				Command = "wire_gate_expression_label",
				MaxLength = 40
			})
			
			panel:AddControl("TextBox", {
				Label = "Inputs:",
				Command = "wire_gate_expression_inputs",
				MaxLength = 100
			})
			
			panel:AddControl("TextBox", {
				Label = "Outputs:",
				Command = "wire_gate_expression_outputs",
				MaxLength = 100
			})
			
			panel:AddControl("Button", {
				Text = "Process (split lines with a backslash \\ into multiple rows)",
				Name = "Process",
				Command = "wire_gate_expression_process"
			})
			
			for i = 1,60 do
				panel:AddControl("TextBox", {
					Label = "Line " .. i .. ":",
					Command = "wire_gate_expression_line" .. i,
					MaxLength = 100
				})
			end
		end
		
		panel:AddControl("Label", {
			Text = "               Written by Syranide, me@syranide.com"
		})
	end
end

if CLIENT then
	local player = LocalPlayer()
	
	wire_gate_expression_state =      0
	wire_gate_expression_filename =   player:GetInfo('wire_gate_expression_filename')
	wire_gate_expression_label =      player:GetInfo('wire_gate_expression_label')
	wire_gate_expression_inputs =     player:GetInfo('wire_gate_expression_inputs')
	wire_gate_expression_outputs =    player:GetInfo('wire_gate_expression_outputs')
	wire_gate_expression_basefolder = "ExpressionGate"
	wire_gate_expression_folder =     ""
	wire_gate_expression_status =     "Previous expression resumed"
	WireGateExpressionUpdateFilelist()

	if !wire_gate_expression_filename then wire_gate_expression_filename = "" end
	if !wire_gate_expression_label    then wire_gate_expression_label =    "" end
	if !wire_gate_expression_inputs   then wire_gate_expression_inputs =   "" end
	if !wire_gate_expression_outputs  then wire_gate_expression_outputs =  "" end
	if !wire_gate_expression_status   then wire_gate_expression_status =   "" end
end