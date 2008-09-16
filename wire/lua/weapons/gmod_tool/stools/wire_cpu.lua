TOOL.Category	= "Wire - Control"
TOOL.Name	= "Chip - CPU"
TOOL.Command	= nil
TOOL.ConfigName	= ""

if (CLIENT) then
	language.Add("Tool_wire_cpu_name", "CPU Tool (Wire)")
	language.Add("Tool_wire_cpu_desc", "Spawns a central processing unit")
	language.Add("Tool_wire_cpu_0", "Primary: Create empty CPU / Upload current program to it")//; Secondary: Debug the CPU
	language.Add("sboxlimit_wire_cpu", "You've hit CPU limit!")
	language.Add("undone_wirecpu", "Undone the wire CPU")
end

if (SERVER) then
	CreateConVar('sbox_maxwire_cpus', 20)
end

TOOL.ClientConVar["model"] 		= "models/cheeze/wires/cpu.mdl"
TOOL.ClientConVar["filename"] 		= ""
TOOL.ClientConVar["packet_bandwidth"] 	= 400
TOOL.ClientConVar["packet_rate_sp"] 	= 0.05
TOOL.ClientConVar["packet_rate_mp"] 	= 0.4
TOOL.ClientConVar["compile_rate"] 	= 0.05
TOOL.ClientConVar["compile_bandwidth"] 	= 200
TOOL.ClientConVar["rom"] 		= 1
TOOL.ClientConVar["rom_present"]	= 1
TOOL.ClientConVar["dump_data"] 		= 0

cleanup.Register("wire_cpus")

//=============================================================================
if (SERVER) then
	SourceCode = {}

	local function AddSourceLine(pl, command, args)
		SourceCode[tonumber(args[1])] = tostring(args[2])
	end
	concommand.Add("wire_cpu_addsrc", AddSourceLine)
	
	local function ClearSource(pl, command, args)
		SourceCode = {}
	end
	concommand.Add("wire_cpu_clearsrc", ClearSource)
end
//=============================================================================

local function CPUStool_Version()
	local SVNString = "$Revision$"
	local rev = tonumber(string.sub(SVNString,12,14))
	if (rev) then
		return rev
	else
		return 0
	end
end

//=============================================================================

local function CompileProgram_Timer(tool,firstpass)
	if (firstpass && tool.FirstPassDone) 	then return end
	if (!firstpass && tool.SecondPassDone) 	then return end
	if (!tool:GetOwner()) 			then return end
	if (!tool.LineNumber) 			then return end

	local SendLinesMax = tool.LineNumber + tool:GetOwner():GetInfo("wire_cpu_compile_bandwidth")
	if (SendLinesMax > table.Count(SourceCode)) then SendLinesMax = table.Count(SourceCode) end
	local Rate = 0

	if (SourceCode[tostring(tool.LineNumber)]) then
		if (string.len(SourceCode[tostring(tool.LineNumber)]) > 256) then
			SendLinesMax = tool.LineNumber
		end
	end

	while (tool.LineNumber <= SendLinesMax) and (tool.CPU_Entity) do
		local line = SourceCode[tonumber(tool.LineNumber)]
		if (line) then
			if (string.len(line) > 254) then
				tool:GetOwner():PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Line "..tool.LineNumber.." too long! I compile it, but it may trigger infinite loop thing.\n")
			end
			if (tool.CPU_Entity.ParseProgram_ASM) then
				tool.CPU_Entity:ParseProgram_ASM(line,tool.LineNumber)
			end
		end

		tool.LineNumber = tool.LineNumber + 1
		Rate = Rate + 1
	end

	local TimeLeft = (table.Count(SourceCode)*2 - tool.LineNumber) / Rate
	if (not firstpass) then
		TimeLeft = (table.Count(SourceCode) - tool.LineNumber) / Rate
	end
	tool.PrevRate = (tool.PrevRate*1.5+TimeLeft*0.5) / 2
	TimeLeft = math.floor(tool.PrevRate / 10)

	local TempPercent = ((tool.LineNumber-1)/table.Count(SourceCode))*100
	if (firstpass) then
		if (!tool.FirstPassDone) then
			tool:GetOwner():ConCommand('wire_cpu_vgui_status "Compiling ('.. TimeLeft ..' seconds left), '..tool.LineNumber..' lines processed"')
			tool:GetOwner():ConCommand('wire_cpu_vgui_progress "'..math.floor(TempPercent/2)..'"')
		end
	else
		if (!tool.SecondPassDone) then
			tool:GetOwner():ConCommand('wire_cpu_vgui_status "Compiling ('.. TimeLeft ..' seconds left), '..tool.LineNumber..' lines processed"')
			tool:GetOwner():ConCommand('wire_cpu_vgui_progress "'..math.floor(50+TempPercent/2)..'"')
		end
	end

	if (tool.LineNumber > table.Count(SourceCode)) || (TempPercent >= 100) then
		if (!tool.FirstPassDone) then
			tool.FirstPassDone = true
			tool:Compile_Pass2()
		end
		if (!firstpass) && (!tool.SecondPassDone) then
			tool.SecondPassDone = true
			tool:Compile_End()
		end
	end

	if (tool.CPU_Entity.FatalError == true) then
		timer.Destroy("CPUCompileTimer1")
		timer.Destroy("CPUCompileTimer2")
		tool:Compile_End()
	end
end

//=============================================================================

function TOOL:StartCompile(pl)
	local ent = self.CPU_Entity
	if table.Count(SourceCode) == 0 then return end

	pl:PrintMessage(HUD_PRINTCONSOLE,"----> ZyeliosASM compiler - Version 2.0 (SVN REV "..CPUStool_Version().."/"..ent:CPUID_Version()..") <----\n")
	pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compiling...\n")

	pl:ConCommand('wire_cpu_vgui_open')
	pl:ConCommand('wire_cpu_vgui_title "ZyeliosASM - Compiling"')
	pl:ConCommand('wire_cpu_vgui_status "Initializing"')
	pl:ConCommand('wire_cpu_vgui_progress "0"')

	if (self:GetClientInfo("userom") == "1") then ent.UseROM = true
	else					      ent.UseROM = false
	end

	if (self:GetClientInfo("dump_data") == "1") then
		ent.MakeDump = true
		ent.Dump = "Code listing:\n"
	else
		ent.MakeDump = false
	end


	self.FirstPassDone = false
	self.SecondPassDone = false

	timer.Destroy("CPUCompileTimer1")
	timer.Destroy("CPUCompileTimer2")

	ent:Compiler_Stage0(pl)
	self:Compile_Pass1()
end

function TOOL:Compile_Pass1()
	if (!self:GetOwner()) then return end
	self:GetOwner():PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Pass 1\n")

	self.Compiling = true
	self.CPU_Entity:Compiler_Stage1()

	self.LineNumber = 1
	self.PrevRate = 0
	timer.Create("CPUCompileTimer1",self:GetOwner():GetInfo("wire_cpu_compile_rate"),0,CompileProgram_Timer,self,true)
end

function TOOL:Compile_Pass2()
	if (!self:GetOwner()) then return end
	self:GetOwner():PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Pass 2\n")

	self.Compiling = true
	self.CPU_Entity:Compiler_Stage2()

	self.LineNumber = 1
	timer.Create("CPUCompileTimer2",self:GetOwner():GetInfo("wire_cpu_compile_rate"),0,CompileProgram_Timer,self,false)
end


function TOOL:Compile_End()
 	local pl = self:GetOwner()
	local ent = self.CPU_Entity

	if (ent.FatalError) then pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compile aborted: fatal error has occured\n")			
	else			 pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compile succeded! "..(table.Count(SourceCode)-1).." lines, "..ent.WIP.." bytes, "..table.Count(ent.Labels).." definitions.\n")
	end

	pl:ConCommand('wire_cpu_vgui_close')

	if (self:GetClientInfo("dump_data") == "1") then
		pl:PrintMessage(HUD_PRINTCONSOLE,"ZyeliosASM: Dumping data\n")
		local codedump = "Count: "..ent.WIP.."\n"
		//local pointerdump = "Count: "..table.Count(ent.Labels).."\n"
		for i = 0,ent.WIP do
			if (ent.Memory[i]) then
				codedump = codedump.."["..i.."]".."="..ent.Memory[i].."\n"
			end
		end
		/*for k,v in pairs(ent.Labels) do
			pointerdump = pointerdump.."#pointer "..k.." "..v.."\n"
		end*/
		file.Write("cdump.txt",codedump)
		file.Write("ldump.txt",ent.Dump)
		//file.Write("pdump.txt",pointerdump)
		pl:PrintMessage(HUD_PRINTCONSOLE,"ZyeliosASM: Dumped!\n")
	end

	ent:Reset()
	ent.Compiling = false
end

//=============================================================================
function TOOL:LeftClick(trace)
	if trace.Entity:IsPlayer() then return false end
	if (CLIENT) 		   then return true end

	local ply = self:GetOwner()

	self.CPU_Entity = trace.Entity

	if (trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_cpu" && trace.Entity.pl == ply) then
		self:StartCompile(ply)
		return true
	end
	
	if (!self:GetSWEP():CheckLimit("wire_cpus")) 		then return false end
	if (not util.IsValidModel(self:GetClientInfo("model"))) then return false end
	if (not util.IsValidProp(self:GetClientInfo("model"))) 	then return false end
	
	local ang   = trace.HitNormal:Angle()
	local model = self:GetClientInfo("model")
	ang.pitch = ang.pitch + 90
	
	wire_cpu = MakeWireCpu(ply, ang, trace.HitPos, model)
	local min = wire_cpu:OBBMins()
	wire_cpu:SetPos(trace.HitPos - trace.HitNormal * min.z)
	
	local const = WireLib.Weld(wire_cpu, trace.Entity, trace.PhysicsBone, true)
	
	undo.Create("WireCpu")
		undo.AddEntity(wire_cpu)
		undo.AddEntity(const)
		undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCleanup("wire_cpus", wire_cpu)
	ply:AddCleanup("wire_cpus", const)

	return true
end

if (SERVER) then
	function MakeWireCpu(pl, ang, pos, model)
		if (!pl:CheckLimit("wire_cpus")) then return false end

		local wire_cpu = ents.Create("gmod_wire_cpu")
		if (!wire_cpu:IsValid()) then return false end
		wire_cpu:SetModel(model)

		wire_cpu:SetAngles(ang)
		wire_cpu:SetPos(pos)
		wire_cpu:Spawn()

		wire_cpu:SetPlayer(pl)

		local ttable = {
			pl = pl,
			model = model,
		}
		table.Merge(wire_cpu:GetTable(), ttable)
		pl:AddCount("wire_cpus", wire_cpu)

		return wire_cpu
	end
	duplicator.RegisterEntityClass("gmod_wire_cpu", MakeWireCpu, "ang", "pos", "model")
end

function TOOL:UpdateGhostWireCpu(ent, player)
	if (!ent) then return end
	if (!ent:IsValid()) then return end

	local tr 	= utilx.GetPlayerTrace(player, player:GetCursorAimVector())
	local trace 	= util.TraceLine(tr)
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_cpu" || trace.Entity:IsPlayer()) then
		ent:SetNoDraw(true)
		return
	end

	local ang = trace.HitNormal:Angle()
	ang.pitch = ang.pitch + 90

	local min = ent:OBBMins()
	ent:SetPos(trace.HitPos - trace.HitNormal * min.z)
	ent:SetAngles(ang)

	ent:SetNoDraw(false)
end

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo("model") || (not self.GhostEntity:GetModel())) then
		self:MakeGhostEntity(self:GetClientInfo("model"), Vector(0,0,0), Angle(0,0,0))
	end

	self:UpdateGhostWireCpu(self.GhostEntity, self:GetOwner())
end

//=============================================================================
// Code sending
//=============================================================================
if (CLIENT) then
	local Frame
	local StatusLabel
	local PLabel
	local ProgressBar
	local BGBar

	local function VGUI_Open(pl, command, args)
		if (Frame) then
			Frame:SetVisible(false)
		end

		Frame = vgui.Create("Panel")
		Frame:SetSize(400,50)
		Frame:SetPos(150,150)
		Frame:SetVisible(true)

		BGBar = vgui.Create("ProgressBar",Frame)
		BGBar:SetVisible(true)
		BGBar:SetSize(400,100)
		BGBar:SetPos(0,0)

		StatusLabel = vgui.Create("Label",Frame)
		StatusLabel:SetSize(380,30)
		StatusLabel:SetPos(10,10)
		StatusLabel:SetVisible(true)

		PLabel = vgui.Create("Label",Frame)
		PLabel:SetSize(30,30)
		PLabel:SetPos(360,10)
		PLabel:SetVisible(true)
	
		ProgressBar = vgui.Create("ProgressBar",Frame)
		ProgressBar:SetSize(280,30)
		ProgressBar:SetPos(10,60)
		ProgressBar:SetVisible(false)
	end
	concommand.Add("wire_cpu_vgui_open", VGUI_Open)

	local function VGUI_Close(pl, command, args)
		Frame:SetVisible(false);
	end
	concommand.Add("wire_cpu_vgui_close", VGUI_Close)

	local function VGUI_Title(pl, command, args)
		Frame:PostMessage("SetTitle", "text", args[1]);
	end
	concommand.Add("wire_cpu_vgui_title", VGUI_Title)

	local function VGUI_Status(pl, command, args)
		StatusLabel:PostMessage("SetText", "text", args[1]);
	end
	concommand.Add("wire_cpu_vgui_status", VGUI_Status)

	local function VGUI_Progress(pl, command, args)
		if (args[1]) then
			ProgressBar:PostMessage("SetValue", "Float", tonumber(args[1])/100);
			PLabel:PostMessage("SetText", "text", args[1] .. "%");
		end
	end
	concommand.Add("wire_cpu_vgui_progress", VGUI_Progress)
end

//if (CLIENT) then

SourceLines = {}
SourceLineNumbers = {}
SourceLinesSent = 0
SourcePrevCharRate = 0
SourceTotalChars = 0
SourceLoadedChars = 0

local function UploadProgram(pl)
	local SendLinesMax = SourceLinesSent + pl:GetInfo("wire_cpu_packet_bandwidth")	
	local TotalChars = 0
	if SendLinesMax > table.Count(SourceLines) then 
		SendLinesMax = table.Count(SourceLines)
	end

	while (SourceLinesSent <= SendLinesMax) && (TotalChars < 1024) do
		SourceLinesSent = SourceLinesSent + 1
		local line = SourceLines[SourceLinesSent]
		local linen = SourceLinesSent

		if (line) && (line ~= "\n") && (string.gsub(line, "\n", "") ~= "") then
			RunConsoleCommand("wire_cpu_addsrc",linen,string.gsub(line, "\n", ""))
			TotalChars = TotalChars + string.len(line)
		else
			RunConsoleCommand("wire_cpu_addsrc",linen,"")
		end	
	end
	SourceLoadedChars = SourceLoadedChars + TotalChars

	local CharRate = (SourcePrevCharRate*1.95 + TotalChars*0.05) / 2	
	SourcePrevCharRate = CharRate
		
	if SinglePlayer() then CharRate = CharRate / pl:GetInfo("wire_cpu_packet_rate_sp")
	else		       CharRate = CharRate / pl:GetInfo("wire_cpu_packet_rate_mp")
	end

	local TimeLeft = math.floor((SourceTotalChars - SourceLoadedChars) / CharRate)
	local TempPercent = math.floor(((SourceLinesSent-1)/table.Count(SourceLines))*100)

	pl:ConCommand('wire_cpu_vgui_status "Uploading @ '..math.floor(CharRate / 1024)..' kb/sec, avg. '..TimeLeft..' sec left, '..SourceLinesSent..' lines sent"')
	pl:ConCommand('wire_cpu_vgui_progress "'..TempPercent..'"')

	if (SourceLinesSent > table.Count(SourceLines)) then
		pl:ConCommand('wire_cpu_vgui_close')
		timer.Remove("CPUSendTimer")
	end
end
	
local function LoadProgram(pl, command, args)
	local fname = "CPUChip\\"..pl:GetInfo("wire_cpu_filename");
	if (!file.Exists(fname)) then
		fname = "CPUChip\\"..pl:GetInfo("wire_cpu_filename")..".txt";
	end
	
	if (!file.Exists(fname)) then
		pl:PrintMessage(HUD_PRINTTALK,"CPU -> Sorry! Requested file was not found\n")
		return
	end
	
	pl:ConCommand('wire_cpu_clearsrc')

	local filedata = file.Read(fname)
	if (!filedata) then
		pl:PrintMessage(HUD_PRINTTALK,"CPU -> Sorry! File was found, but leprechauns prevented it from getting read!\n") //This message occurs rarely enough to put something fun here
		return
	end

	SourceLines = string.Explode("\n", filedata)
	SourceLinesSent = 0
	SourceTotalChars = string.len(filedata)

	SourcePrevCharRate = string.len(SourceLines[1])
	SourceLoadedChars = 0

	pl:ConCommand('wire_cpu_vgui_open')
	pl:ConCommand('wire_cpu_vgui_title "CPU - Uploading program"')
	pl:ConCommand('wire_cpu_vgui_status "Initializing"')
	pl:ConCommand('wire_cpu_vgui_progress "0"')

	//Send 50 lines
	if (SinglePlayer()) then timer.Create("CPUSendTimer",pl:GetInfo("wire_cpu_packet_rate_sp"),0,UploadProgram,pl,false)
	else			 timer.Create("CPUSendTimer",pl:GetInfo("wire_cpu_packet_rate_mp"),0,UploadProgram,pl,false)
	end
end
concommand.Add("wire_cpu_load", LoadProgram)

local function ClearProgram(pl, command, args)
	pl:ConCommand('wire_cpu_clearsrc')
end
concommand.Add("wire_cpu_clear", ClearProgram) 

//end

//=============================================================================
function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_cpu_name", Description = "#Tool_wire_cpu_desc" })

	panel:AddControl("TextBox", {
		Label = "Source code file name",
		Command = "wire_cpu_filename",
		MaxLength = "128"
	})

	panel:AddControl("Button", {
		Text = "Quick Load",
		Name = "Load",
		Command = "wire_cpu_load"
	})

/*	panel:AddControl("Button", {
		Text = "Clear",
		Name = "Clear",
		Command = "wire_cpu_clear"
	})*/

	panel:AddControl("Label", {
		Text = ""
	})
	panel:AddControl("Label", {
		Text = "CPU settings:"
	})


	panel:AddControl("CheckBox", {
		Label = "Use CPU ROM",
		Command = "wire_cpu_rom"
	})
	panel:AddControl("Label", {
		Text = "ROM data is saved with advanced duplicator and is stored between CPU resets"
	})



	panel:AddControl("Label", {
		Text = ""
	})
	panel:AddControl("Label", {
		Text = "These do not work yet:"
	})

	panel:AddControl("CheckBox", {
		Label = "CPU ROM Present",
		Command = "wire_cpu_rom_present"
	})
	panel:AddControl("Label", {
		Text = "CPU can be without internal ROM/RAM (you need to attach RAM/ROM manually)"
	})


	panel:AddControl("CheckBox", {
		Label = "Dump CPU data",
		Command = "wire_cpu_dump_data"
	})
	panel:AddControl("Label", {
		Text = "Dumps CPU information and compiled code to pdump/cdump/ldump files in DATA folder (server host, or singleplayer only)"
	})


	panel:AddControl("Button", {
		Text = "Code editor"
	})
	panel:AddControl("Label", {
		Text = "Opens code editor (ZASM)"
	})
	panel:AddControl("Label", {
		Text = "Can be used for ZC code (requires ZCK addon)"
	})

	panel:AddControl("Button", {
		Text = "ZCPU documentation (online)"
	})
	panel:AddControl("Label", {
		Text = "Loads online CPU documentation and tutorials"
	})
end