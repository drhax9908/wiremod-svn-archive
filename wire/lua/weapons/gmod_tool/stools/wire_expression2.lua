TOOL.Category		= "Wire - Control"
TOOL.Name			= "Chip - Expression 2"
TOOL.Command 		= nil 
TOOL.ConfigName 	= ""

TOOL.ClientConVar = {
	model    = "models/beer/wiremod/gate_e2.mdl",
	size     = "",
	select   = "",
}

if CLIENT then
    language.Add("Tool_wire_expression2_name", "Expression 2 Tool (Wire)")
    language.Add("Tool_wire_expression2_desc", "Spawns an Expression 2 chip for use with the wire system.")
    language.Add("Tool_wire_expression2_0",    "Primary: Create/Update Expression, Secondary: Open Expression in Editor")
	language.Add("sboxlimit_wire_expression",  "You've hit the Expression limit!")
	language.Add("Undone_wire_expression2",    "Undone Expression 2")
else
	CreateConVar('sbox_maxwire_expressions', 20)
	CreateConVar('wire_expression2_protected', 1)
	CreateConVar('wire_expression2_restricted', 1)
end

cleanup.Register("wire_gate_expressions")

if SERVER then
	function TOOL:LeftClick(trace)
		if trace.Entity:IsPlayer() then return false end

		local player = self:GetOwner()
		local model = self:GetModel()
		local pos = trace.HitPos
		local ang = trace.HitNormal:Angle()
		ang.pitch = ang.pitch + 90
		
		if (trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_expression2" && (trace.Entity:GetPlayer() == player || GetConVarNumber('wire_expression2_protected') == 0)) then
			trace.Entity:SetPlayer(player)
			trace.Entity.player = player
			trace.Entity:Prepare(player)
			player:SendLua("wire_expression2_upload()")
			return true
		end
		
		if !self:GetSWEP():CheckLimit("wire_expressions") then return false end
		
		local entity = ents.Create("gmod_wire_expression2")
		if !entity:IsValid() then return false end
		
		player:AddCount("wire_expressions", entity)
		
		entity:SetModel(model)
		entity:SetAngles(ang)
		entity:SetPos(pos)
		entity:Spawn()
		entity:SetPlayer(player)
		entity.player = player
		
		if !entity then return false end
		
		entity:SetPos(trace.HitPos - trace.HitNormal * entity:OBBMins().z)
		local constraint = WireLib.Weld(entity, trace.Entity, trace.PhysicsBone, true)
		
		undo.Create("wire_expression2")
			undo.AddEntity(entity)
			undo.SetPlayer(player)
			undo.AddEntity(constraint)
		undo.Finish()
		
		player:AddCleanup("wire_expressions", entity)

		entity:Prepare(player)
		player:SendLua("wire_expression2_upload()")
		return true
	end
	
	function MakeWireExpression2(player, ang, pos, model, buffer, name, inputs, outputs, vars)
		if !player:CheckLimit("wire_gate_expressions") then return false end
		
		local entity = ents.Create("gmod_wire_expression2")
		if !entity:IsValid() then return false end
		
		entity:SetModel(model)
		entity:SetAngles(ang)
		entity:SetPos(pos)
		entity:Spawn()
		entity:SetPlayer(player)
		entity.player = player
		
		buffer = string.Replace(string.Replace(buffer,"£","\""),"€","\n")
		
		entity:SetOverlayText("Expression 2\n" .. name)
		entity.buffer = buffer
		
		entity.Inputs = WireLib.AdjustSpecialInputs(entity, inputs[1], inputs[2])
		entity.Outputs = WireLib.AdjustSpecialOutputs(entity, outputs[1], outputs[2])
		entity:Setup(buffer, true)
		
		for k,v in pairs(vars) do
			entity.context.vars[k] = v
		end
		
		entity:Execute()
		
		player:AddCount("wire_gate_expressions", entity)
		return entity
	end
	
	duplicator.RegisterEntityClass("gmod_wire_expression2", MakeWireExpression2, "Ang", "Pos", "Model", "_original", "_name", "_inputs", "_outputs", "_vars")
	
	function TOOL:RightClick(trace)
		if trace.Entity:IsPlayer() then return false end
		
		local player = self:GetOwner()
		
		if (trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_expression2" && (trace.Entity:GetPlayer() == player || GetConVarNumber('wire_expression2_protected') == 0 || GetConVarNumber('wire_expression2_protected') == 2)) then
			trace.Entity:SendCode(player)
			trace.Entity:Prepare(player)
			return true
		end
		
		player:SendLua("openE2Editor()")
		return false
	end
	
	function TOOL:Think()
		if !self.GhostEntity || !self.GhostEntity:IsValid() || !self.GhostEntity:GetModel() || self.GhostEntity:GetModel() != self:GetModel() then
			self:MakeGhostEntity(self:GetModel(), Vector(0, 0, 0), Angle(0, 0, 0))
		end
		self:UpdateGhostWireExpression2(self.GhostEntity, self:GetOwner())
	end
	
	function TOOL:UpdateGhostWireExpression2(entity, player)
		if !entity or !entity:IsValid() then return end

		local trace = util.TraceLine(utilx.GetPlayerTrace(player, player:GetCursorAimVector()))
		if !trace.Hit then return end

		if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_expression2" || trace.Entity:IsPlayer()) then
			entity:SetNoDraw(true)
		else 
			local ang = trace.HitNormal:Angle()
			ang.pitch = ang.pitch + 90

			entity:SetPos(trace.HitPos - trace.HitNormal * entity:OBBMins().z)
			entity:SetAngles(ang)
			entity:SetNoDraw(false)
		end
	end
	
	function TOOL:GetModel()
		local model = self:GetClientInfo("model")
		local size = self:GetClientInfo("size")
		
		if model and size then
			return string.sub(model, 1, -5) .. size .. string.sub(model, -4)
		end
	end
end

if CLIENT then
	local dir
	local lastclick = CurTime()
	local download = {}
	local Editor, Validation
	
	function wire_expression2_upload()
		local result = wire_expression_validate(Editor:GetCode())
		if result then
			GAMEMODE:AddNotify(result, NOTIFY_ERROR, 7)
			surface.PlaySound("ambient/water/drip3.wav")
		return end
		
		transfer(Editor:GetCode())
	end
	
	function wire_expression2_download(um)
		if(!um) then return end
		local chunks = um:ReadShort()
		if(!download.downloading) then
			download.downloading = true
			download.chunks = chunks
			download.current = -1
			download.code = ""
			download.name = um:ReadString()
		return end
		
		if( download.current + 1 == chunks ) then
			download.current = chunks
			download.code = download.code .. um:ReadString()
		else
			download = {}
		end
			
		if( download.downloading && download.chunks == chunks) then
			Editor:Open(download.name, download.code)
			Editor.chip = true
			download = {}
		return end
		
	end
	
	usermessage.Hook("wire_expression2_download", wire_expression2_download)  

	function TOOL.BuildCPanel(panel)
		panel:ClearControls()
		panel:AddControl("Header", { Text = "#Tool_wire_expression2_name", Description = "#Tool_wire_expression2_desc" })
		
		//ModelPlug_AddToCPanel(panel, "expr2", "wire_expression2", nil, nil, nil, 2)
		
		panel:AddControl("ComboBox", {
			MenuButton = "0",
			Options = {
				["Normal"] = { wire_expression2_size = "" },
				["Mini"] = { wire_expression2_size = "_mini" },
				["Nano"] = { wire_expression2_size = "_nano" },
			}
		})
		
		panel:AddControl("MaterialGallery", { 
			Height = "100",
			Width = "100",
			Rows = 2,
			Stretch = false,
			ConVar = "wire_expression2_select",
			Options = {
				["Modern"] =     { wire_expression2_select = "Modern",     Value = "Modern",     Material = "beer/wiremod/gate_e2",        wire_expression2_model = "models/beer/wiremod/gate_e2.mdl" },
				["Expression"] = { wire_expression2_select = "Expression", Value = "Expression", Material = "models/expression 2/exprssn", wire_expression2_model = "models/expression 2/cpu_expression.mdl" },
				["Microchip"] =  { wire_expression2_select = "Microchip",  Value = "Microchip",  Material = "models/expression 2/mcrochp", wire_expression2_model = "models/expression 2/cpu_microchip.mdl" },
				["Interface"] =  { wire_expression2_select = "Interface",  Value = "Interface",  Material = "models/expression 2/intrfce", wire_expression2_model = "models/expression 2/cpu_interface.mdl" },
				["Controller"] = { wire_expression2_select = "Controller", Value = "Controller", Material = "models/expression 2/cntrllr", wire_expression2_model = "models/expression 2/cpu_controller.mdl" },
				["Processor"] =  { wire_expression2_select = "Processor",  Value = "Processor",  Material = "models/expression 2/prcssor", wire_expression2_model = "models/expression 2/cpu_processor.mdl" },
			}
		})
		
		Editor = vgui.Create( "Expression2EditorFrame")
		Editor:Setup("Expression 2 Editor","Expression2",true)

		local FileBrowser = vgui.Create("wire_expression2_browser" , panel)
		panel:AddPanel(FileBrowser)
		FileBrowser:Setup("Expression2")
		FileBrowser:SetSize(235,400)
		function FileBrowser:OnFileClick()
			if(dir == self.File.FileDir and CurTime() - lastclick < 1) then
				Editor:Open(dir)
			else
				lastclick = CurTime()
				dir = self.File.FileDir
				Editor:LoadFile(dir)
				Validation:Validate()
			end
		end
		
		Validation = vgui.Create("Label" , panel)
		panel:AddPanel(Validation)
		Validation.OnMousePressed = function(panel) panel:Validate() end
		Validation.Validate = function(panel) 
			local errors = wire_expression_validate(Editor:GetCode())
			if(!errors) then 
				panel:SetText("Validation Successful")
			else
				panel:SetText("Error in file")
			end
		end
		Validation:SetText("Click to validate...")
		local OpenEditor = vgui.Create("DButton" , panel)
		panel:AddPanel(OpenEditor)
		OpenEditor:SetTall(30)
		OpenEditor:SetText("Open Editor")
		OpenEditor.DoClick = function(button) 
			Editor:Open()
		end
		
		local NewExpression = vgui.Create("DButton" , panel)
		panel:AddPanel(NewExpression)
		NewExpression:SetTall(30)
		NewExpression:SetText("New Expression")
		NewExpression.DoClick = function(button) 
			Editor:Open()
			Editor:NewScript()
		end
		
	end
	
	function openE2Editor()
		Editor:Open()
	end
	
	
	// BEGIN ENCODER

	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890 +-*/%^!?~=@&|.,:(){}"
	local hex = {"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}
	local tbl = {}

	for i=1,chars:len() do
		tbl[chars:byte(i)] = chars:sub(i, i)
	end

	for byte=1,255 do
		if(tbl[byte] == nil) then tbl[byte] = "#" .. hex[(byte - byte % 16) / 16 + 1] .. hex[byte % 16 + 1] end
	end

	function encode(str)
		local encoded = ""
		local length = str:len()
		
		for i=1,length do
			encoded = encoded .. tbl[str:byte(i)]	
		end
		
		return encoded;
	end

	// END ENCODER

	function transfer(code)
		local encoded = encode(code)
		local length = encoded:len()
		local chunks = math.ceil(length / 480)

		Expression2SetProgress(0)
		RunConsoleCommand("wire_expression_upload_begin", code:len(), chunks)
		
		timer.Create("wire_expression_upload", 0.05, chunks, transfer_callback, { encoded, 1, chunks })
		timer.Start("wire_expression_upload")
	end

	function transfer_callback(state)
		local i = state[2] - 1
		
		Expression2SetProgress(math.Round((state[2] / state[3]) * 100))
		RunConsoleCommand("wire_expression_upload_data", state[1]:sub(i * 480 + 1, (i + 1) * 480))
		
		if state[2] == state[3] then
			timer.Create("wire_expression_upload_reset", 0.5, 1, function() Expression2SetProgress(nil) end )
			
			timer.Destroy("wire_expression_upload")
			RunConsoleCommand("wire_expression_upload_end")
		end
		
		state[2] = state[2] + 1
	end
	
end
