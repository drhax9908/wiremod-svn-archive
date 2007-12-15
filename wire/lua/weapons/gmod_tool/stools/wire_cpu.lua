TOOL.Category		= "Wire - Control"
TOOL.Name			= "Chip - CPU"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
	language.Add( "Tool_wire_cpu_name", "CPU Tool (Wire)" )
	language.Add( "Tool_wire_cpu_desc", "Spawns a Central Processor Unit (Programmable gate)" )
	language.Add( "Tool_wire_cpu_0", "Primary: Create empty CPU / Upload current program to it" )
	language.Add( "sboxlimit_wire_cpu", "You've hit CPU limit!" )
	language.Add( "undone_wirecpu", "Undone Wire CPU" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_cpus', 20)
	SourceCode = {}
	SourceLines = 0
end

TOOL.ClientConVar[ "model" ] = "models/cheeze/wires/cpu.mdl"
TOOL.ClientConVar[ "filename" ] = ""
TOOL.ClientConVar[ "compiler" ] = "ZyeliosASM"
TOOL.ClientConVar[ "userom" ] = 1
TOOL.ClientConVar[ "dumpcode" ] = 0
TOOL.ClientConVar[ "packet_bandwidth" ] = 100
TOOL.ClientConVar[ "packet_rate_sp" ] = 0.05
TOOL.ClientConVar[ "packet_rate_mp" ] = 0.4
TOOL.ClientConVar[ "compile_rate" ] = 0.05
TOOL.ClientConVar[ "compile_bandwidth" ] = 100

cleanup.Register( "wire_cpus" )

//=============================================================================
// ZASM interface
//=============================================================================
local cpu_tool = nil
local cpu_ent = nil

local function CPUStool_Version()
	local SVNString = "$Revision: 532 $"

	return tonumber(string.sub(SVNString,12,14))
end

local function CompileProgram_Timer(firstpass)
	if (firstpass && cpu_tool.FirstPassDone) then return end
	if (!firstpass && cpu_tool.SecondPassDone) then return end
	if (!cpu_tool:GetOwner()) then return end

	local SendLinesMax = cpu_tool.LineNumber + cpu_tool:GetOwner():GetInfo("wire_cpu_compile_bandwidth")	
	if (SendLinesMax > table.Count(SourceCode)) then SendLinesMax = table.Count(SourceCode) end
	local Rate = 0

	//WORKAROUND FOR LOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOONG LINES
	if SourceCode[tostring(cpu_tool.LineNumber)] then
		if (string.len(SourceCode[tostring(cpu_tool.LineNumber)]) > 256) then
			SendLinesMax = cpu_tool.LineNumber
		end
	end

	while (cpu_tool.LineNumber <= SendLinesMax) do
		local line = SourceCode[tostring(cpu_tool.LineNumber)]
		if (!line) then
//			cpu_tool:GetOwner():PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Bad Line ["..cpu_tool.LineNumber.."]\n")
		else
			if (string.len(line) > 254) then
				cpu_tool:GetOwner():PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Line "..cpu_tool.LineNumber.." too long! I compile it, but it may trigger infinite loop thing.\n")
			end
			cpu_ent:ParseProgram_ASM(cpu_tool:GetOwner(),line,cpu_tool.LineNumber,firstpass)
		end

		cpu_tool.LineNumber = cpu_tool.LineNumber + 1
		Rate = Rate + 1
	end

	local TimeLeft = (table.Count(SourceCode) - cpu_tool.LineNumber) / Rate
	cpu_tool.PrevRate = (cpu_tool.PrevRate*1.5+TimeLeft*0.5) / 2
	TimeLeft = math.floor(cpu_tool.PrevRate)

	//TODO: FIX. NON FLOORD PERCENT, AND BAD RATE

	local TempPercent = ((cpu_tool.LineNumber-1)/table.Count(SourceCode))*100
	if (firstpass) then
		if (!cpu_tool.FirstPassDone) then
			cpu_tool:GetOwner():ConCommand('wire_cpu_vgui_status "Compiling ('.. TimeLeft ..' seconds left), '..cpu_tool.LineNumber..' lines processed"')
			cpu_tool:GetOwner():ConCommand('wire_cpu_vgui_progress "'..math.floor(TempPercent/2)..'"')
		end
	else
		if (!cpu_tool.SecondPassDone) then
			cpu_tool:GetOwner():ConCommand('wire_cpu_vgui_status "Compiling ('.. TimeLeft ..' seconds left), '..cpu_tool.LineNumber..' lines processed"')
			cpu_tool:GetOwner():ConCommand('wire_cpu_vgui_progress "'..math.floor(50+TempPercent/2)..'"')
		end
	end

	//(cpu_ent.FatalError) ||
	if (cpu_tool.LineNumber > table.Count(SourceCode)) || (TempPercent >= 100) then
		if (!cpu_tool.FirstPassDone) then
			cpu_tool.FirstPassDone = true
			cpu_tool:Compile_Pass2()
		end
		if (!firstpass) && (!cpu_tool.SecondPassDone) then
			cpu_tool.SecondPassDone = true
			cpu_tool:Compile_End()
		end
	end
end

function TOOL:StartCompile(pl,ent)
	if (table.Count(SourceCode) <= 0) then return end

	pl:PrintMessage(HUD_PRINTCONSOLE,"----> ZyeliosASM compiler - Version 2.0 (SVN REV "..CPUStool_Version().."/"..ent:Core_Version()..") <----\n")
	pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compiling...\n")

	pl:ConCommand("wire_cpu_editor_clearlog")
	pl:ConCommand("wire_cpu_editor_addlog \"".."---------------------------------------------------------------".."\"")
	pl:ConCommand("wire_cpu_editor_addlog \"".."----> ZyeliosASM compiler - Version (SVN REV "..CPUStool_Version()..") BETA <----".."\"")
	pl:ConCommand("wire_cpu_editor_addlog \"".."ZyeliosASM: Compiling...".."\"")

	pl:ConCommand('wire_cpu_vgui_open')
	pl:ConCommand('wire_cpu_vgui_title "ZyeliosASM - Compiling"')
	pl:ConCommand('wire_cpu_vgui_status "Initializing"')
	pl:ConCommand('wire_cpu_vgui_progress "0"')

	ent.FatalError = false
	ent.WIP = 0
	ent.Labels = {}
	ent.Compiling = true
	if (self:GetClientInfo("userom") == "1") then
		ent.UseROM = true
	else
		ent.UseROM = false
	end

	if (self:GetClientInfo("dumpcode") == "enable") then
		ent.MakeDump = true
		ent.Dump = "Code listing:\n"
	else
		ent.MakeDump = false
	end
	
	ent.Labels["version"] = 200
	ent.Labels["platform"] = 0
	ent.Labels["true"] = 1
	ent.Labels["false"] = 0

	self.FirstPassDone = false
	self.SecondPassDone = false

	timer.Destroy("CPUCompileTimer1")
	timer.Destroy("CPUCompileTimer2")

	self:Compile_Pass1()
end

function TOOL:Compile_Pass1()
	if (!cpu_tool:GetOwner()) then return end
	self:GetOwner():PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Pass 1\n")
	self:GetOwner():ConCommand("wire_cpu_editor_addlog \"".."ZyeliosASM: Pass 1".."\"")

	//Compile each line
//	local Reps = math.floor(table.Count(SourceCode)/self:GetOwner():GetInfo("wire_cpu_compile_bandwidth"))+1
	self.Compiling = true

	self.LineNumber = 1
	self.PrevRate = 0
	timer.Create("CPUCompileTimer1",self:GetOwner():GetInfo("wire_cpu_compile_rate"),0,CompileProgram_Timer,true)
end

function TOOL:Compile_Pass2()
//	timer.Remove("CPUCompileTimer1")
	if (!cpu_tool:GetOwner()) then return end
	self:GetOwner():PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Pass 2\n")
	self:GetOwner():ConCommand("wire_cpu_editor_addlog \"".."ZyeliosASM: Pass 2".."\"")

 	cpu_ent.WIP = 0

	//Compile each line
//	local Reps = math.floor(table.Count(SourceCode)/self:GetOwner():GetInfo("wire_cpu_compile_bandwidth"))+1
	self.Compiling = true

	self.LineNumber = 1
	timer.Create("CPUCompileTimer2",self:GetOwner():GetInfo("wire_cpu_compile_rate"),0,CompileProgram_Timer,false)
end


function TOOL:Compile_End()
//	timer.Remove("CPUCompileTimer2")
 	local pl = self:GetOwner()
	local ent = cpu_ent

	if (ent.FatalError) then
		pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compile aborted: fatal error has occured\n")			
		pl:ConCommand("wire_cpu_editor_addlog \"".."ZyeliosASM: Compile aborted: fatal error has occured".."\"")
	else
		pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compile succeded! "..(table.Count(SourceCode)-1).." lines, "..ent.WIP.." bytes, "..table.Count(ent.Labels).." definitions.\n")
		pl:ConCommand("wire_cpu_editor_addlog \"".."ZyeliosASM: Compile succeded! "..(table.Count(SourceCode)-1).." lines, "..ent.WIP.." bytes, "..table.Count(ent.Labels).." definitions.".."\"")
	end

	pl:ConCommand('wire_cpu_vgui_close')

	if (self:GetClientInfo("dumpcode") == "enable") then //lololol codedump
		pl:PrintMessage(HUD_PRINTCONSOLE,"ZyeliosASM: Dumping data\n")
		pl:ConCommand("wire_cpu_editor_addlog \"".."-> ZyeliosASM: Dumping data".."\"")
		local codedump = "Count: "..ent.WIP.."\n"
		local pointerdump = "Count: "..table.Count(ent.Labels).."\n"
		for i = 0,ent.WIP do
			codedump = codedump.."["..i.."]".."="..ent.Memory[i].."\n"
		end
		for k,v in pairs(ent.Labels) do
			pointerdump = pointerdump.."#pointer "..k.." "..v.."\n"
		end
		file.Write("cdump.txt",codedump)
		file.Write("ldump.txt",ent.Dump)
		file.Write("pdump.txt",pointerdump)
		pl:PrintMessage(HUD_PRINTCONSOLE,"ZyeliosASM: Dumped!\n")
		pl:ConCommand("wire_cpu_editor_addlog \"".."-> ZyeliosASM: Dumped!".."\"")
	end

	ent:Reset()
	ent.Compiling = false
end

if (SERVER) then
	local function CPU_Compile( pl, command, args )
		if (cpu_ent && (cpu_ent.ParseProgram_ASM)) then
			cpu_tool:StartCompile(pl,cpu_ent)
		else
			pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: No CPU entity - please click on some CPU before using this!\n")
			pl:ConCommand("wire_cpu_editor_addlog \"".."ZyeliosASM: No CPU entity - please click on some CPU before using this!".."\"")
		end
	end
	concommand.Add( "wire_cpu_compile", CPU_Compile )
end

//=============================================================================
// Toolgun shit
//=============================================================================
function TOOL:LeftClick( trace )
	if trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	cpu_tool = self
	cpu_ent = trace.Entity

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_cpu" && trace.Entity.pl == ply ) then
		self:StartCompile(ply,trace.Entity)
		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_cpus" ) ) then return false end
	
	if (not util.IsValidModel(self:GetClientInfo( "model" ))) then return false end
	if (not util.IsValidProp(self:GetClientInfo( "model" ))) then return false end
	
	local Ang = trace.HitNormal:Angle()
	local Smodel = self:GetClientInfo( "model" )
	Ang.pitch = Ang.pitch + 90
	
	wire_cpu = MakeWireCpu( ply, Ang, trace.HitPos, Smodel )
	local min = wire_cpu:OBBMins()
	wire_cpu:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local const = WireLib.Weld(wire_cpu, trace.Entity, trace.PhysicsBone, true)
	
	undo.Create("WireCpu")
		undo.AddEntity( wire_cpu )
		undo.SetPlayer( ply )
		undo.AddEntity( const )
	undo.Finish()

	ply:AddCleanup( "wire_cpus", wire_cpu )
	ply:AddCleanup( "wire_cpus", const )

	return true
end

if (SERVER) then

	function MakeWireCpu( pl, Ang, Pos, Smodel )
		
		if ( !pl:CheckLimit( "wire_cpus" ) ) then return false end
		
		local wire_cpu = ents.Create( "gmod_wire_cpu" )
		if (!wire_cpu:IsValid()) then return false end
		wire_cpu:SetModel("models/cheeze/wires/cpu.mdl")

		wire_cpu:SetAngles( Ang )
		wire_cpu:SetPos( Pos )
		wire_cpu:Spawn()
		
		wire_cpu:SetPlayer(pl)
			
		local ttable = {
			pl = pl,
			Smodel = Smodel,
		}
		table.Merge(wire_cpu:GetTable(), ttable )
		
		pl:AddCount( "wire_cpus", wire_cpu )
		
		return wire_cpu
	end

	duplicator.RegisterEntityClass("gmod_wire_cpu", MakeWireCpu, "Ang", "Pos", "Smodel")

end

function TOOL:UpdateGhostWireCpu( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_cpu" || trace.Entity:IsPlayer()) then
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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" ) || (not self.GhostEntity:GetModel()) ) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireCpu( self.GhostEntity, self:GetOwner() )
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

	local function VGUI_Open( pl, command, args )
		if (Frame) then
			Frame:SetVisible(false)
		end

		Frame = vgui.Create("Panel")
		Frame:SetSize(400,50)
		Frame:SetPos(150,150)
		Frame:SetVisible(true)
//		Frame:SetBGColor(Color(160,160,160))
//		Frame:MakePopup()

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
	concommand.Add( "wire_cpu_vgui_open", VGUI_Open )

	local function VGUI_Close( pl, command, args )
		Frame:SetVisible(false); //Make the frame	
	end
	concommand.Add( "wire_cpu_vgui_close", VGUI_Close )

	local function VGUI_Title( pl, command, args )
		Frame:PostMessage("SetTitle", "text", args[1]);
	end
	concommand.Add( "wire_cpu_vgui_title", VGUI_Title )

	local function VGUI_Status( pl, command, args )
		StatusLabel:PostMessage("SetText", "text", args[1]);
	end
	concommand.Add( "wire_cpu_vgui_status", VGUI_Status )
	concommand.Add( ";wire_cpu_vgui_status", VGUI_Status )

	local function VGUI_Progress( pl, command, args )
		if (args[1]) then
			ProgressBar:PostMessage("SetValue", "Float", tonumber(args[1])/100 );
			PLabel:PostMessage("SetText", "text", args[1] .. "%");
		end
	end
	concommand.Add( "wire_cpu_vgui_progress", VGUI_Progress )
	concommand.Add( ";wire_cpu_vgui_progress", VGUI_Progress )
end

//if (CLIENT) then
	SourceLines = {}
	SourceLineNumbers = {}
	SourceLinesSent = 0
	SourcePrevCharRate = 0
	SourceTotalChars = 0
	SourceLoadedChars = 0
	
	local function UploadProgram( pl, endwithcompile )
		local SendLinesMax = SourceLinesSent + pl:GetInfo("wire_cpu_packet_bandwidth")	
		local TotalChars = 0
		if (SendLinesMax > table.Count(SourceLines)) then SendLinesMax = table.Count(SourceLines) end
		while (SourceLinesSent <= SendLinesMax) && (TotalChars < 1024) do
			SourceLinesSent = SourceLinesSent + 1
			local line = SourceLines[SourceLinesSent]
			local linen = SourceLinesSent
	
			if (line) && (line ~= "\n") && (string.gsub(line, "\n", "") ~= "") then
				//Msg("CONCOMMAND: "..'wire_cpu_addsrc "'..linen..'" "' .. string.gsub(line, "\n", "") .. '"' .. "\n")
				//Filter out "exec"
				line = string.gsub(line,"exec","lolgarryfucksakes")
				line = string.gsub(line,"bind","fucksakesgarrywtf")
				pl:ConCommand('wire_cpu_addsrc "'..linen..'" "' .. string.gsub(line, "\n", "") .. '"')
				TotalChars = TotalChars + string.len(line)
			else
				pl:ConCommand('wire_cpu_addsrc "'..linen..'" ""')
			end	
		end
		SourceLoadedChars = SourceLoadedChars + TotalChars

		local CharRate = (SourcePrevCharRate*1.95 + TotalChars*0.05) / 2	
		SourcePrevCharRate = CharRate
		
		if (SinglePlayer()) then
			CharRate = CharRate / pl:GetInfo("wire_cpu_packet_rate_sp")
		else
			CharRate = CharRate / pl:GetInfo("wire_cpu_packet_rate_mp")
		end

		local TimeLeft = math.floor((SourceTotalChars - SourceLoadedChars) / CharRate)
		local TempPercent = math.floor(((SourceLinesSent-1)/table.Count(SourceLines))*100)

		//REPORT DATA
		pl:ConCommand('wire_cpu_vgui_status "Uploading @ '..math.floor(CharRate / 1024)..' kb/sec, avg. '..TimeLeft..' sec left, '..SourceLinesSent..' lines sent"')
		pl:ConCommand('wire_cpu_vgui_progress "'..TempPercent..'"')

		if (SourceLinesSent > table.Count(SourceLines)) then
			pl:ConCommand('wire_cpu_vgui_close')
			timer.Remove("CPUSendTimer")

			if (endwithcompile) then
				pl:ConCommand('wire_cpu_compile')
			end
		end
	end
	
	local function LoadProgram( pl, command, args )
		local fname = "CPUChip\\"..pl:GetInfo("wire_cpu_filename");
		if (!file.Exists(fname)) then
			fname = "CPUChip\\"..pl:GetInfo("wire_cpu_filename")..".txt";
		end
	
		if (!file.Exists(fname)) then
			pl:PrintMessage(HUD_PRINTTALK,"CPU -> Sorry! Requested file was not found\n")
			return
		end
		
		//SP only:
		//SourceCode = string.Explode("\n", file.Read(fname) )
	
		pl:ConCommand('wire_cpu_clearsrc')

		local filedata = file.Read(fname)
		SourceLines = string.Explode("\n", filedata )
		SourceLinesSent = 0
		SourceTotalChars = string.len(filedata)

		SourcePrevCharRate = string.len(SourceLines[1])
		SourceLoadedChars = 0

		pl:ConCommand('wire_cpu_vgui_open')
		pl:ConCommand('wire_cpu_vgui_title "CPU - Uploading program"')
		pl:ConCommand('wire_cpu_vgui_status "Initializing"')
		pl:ConCommand('wire_cpu_vgui_progress "0"')

		//Send 50 lines
		if (SinglePlayer()) then
			timer.Create("CPUSendTimer",pl:GetInfo("wire_cpu_packet_rate_sp"),0,UploadProgram,pl,false)
		else
			timer.Create("CPUSendTimer",pl:GetInfo("wire_cpu_packet_rate_mp"),0,UploadProgram,pl,false)
		end
	end
	concommand.Add( "wire_cpu_load", LoadProgram )

	local function LoadCompileProgram( pl, command, args )
		local fname = "CPUChip\\"..pl:GetInfo("wire_cpu_filename");
		if (!file.Exists(fname)) then
			fname = "CPUChip\\"..pl:GetInfo("wire_cpu_filename")..".txt";
		end
	
		if (!file.Exists(fname)) then
			pl:PrintMessage(HUD_PRINTTALK,"CPU -> Sorry! Requested file was not found\n")
			return
		end
		
		//SP only:
		//SourceCode = string.Explode("\n", file.Read(fname) )
	
		pl:ConCommand('wire_cpu_clearsrc')

		local filedata = file.Read(fname)
		SourceLines = string.Explode("\n", filedata )
		SourceLinesSent = 0
		SourceTotalChars = string.len(filedata)

		SourcePrevCharRate = string.len(SourceLines[1])
		SourceLoadedChars = 0

		pl:ConCommand('wire_cpu_vgui_open')
		pl:ConCommand('wire_cpu_vgui_title "CPU - Uploading program"')
		pl:ConCommand('wire_cpu_vgui_status "Initializing"')
		pl:ConCommand('wire_cpu_vgui_progress "0"')

		//Send 50 lines
		if (SinglePlayer()) then
			timer.Create("CPUSendTimer",pl:GetInfo("wire_cpu_packet_rate_sp"),0,UploadProgram,pl,true)
		else
			timer.Create("CPUSendTimer",pl:GetInfo("wire_cpu_packet_rate_mp"),0,UploadProgram,pl,true)
		end
	end
	concommand.Add( "wire_cpu_loadcompile", LoadCompileProgram )
	
	local function StoreProgram( pl, command, args )
		Msg("Storing program is disabled - its readonly!\n")
	end
	concommand.Add( "wire_cpu_store", StoreProgram )
	
	local function ClearProgram( pl, command, args )
		pl:ConCommand('wire_cpu_clearsrc')
	end
	concommand.Add( "wire_cpu_clear", ClearProgram ) 

//end
	
if (SERVER) then

	local function AddSourceLine( pl, command, args )
		SourceCode[args[1]] = tostring(args[2])
	end
	concommand.Add( "wire_cpu_addsrc", AddSourceLine )
	
	local function ClearSource( pl, command, args )
		SourceCode = {}
	end
	concommand.Add( "wire_cpu_clearsrc", ClearSource )

end

//=============================================================================
// ZyeliosEditor
//=============================================================================
if (CLIENT) then
	local frmMain
	local frmMain_Editor
	local frmMain_EditorLog
	local frmMain_EditorFileName

	local filedata

	local function Editor_Start( pl, command, args )
		if (!frmMain) then
			frmMain = vgui.Create("Frame")
			frmMain:SetSize(600,630)
			frmMain:SetPos(200,100)
			frmMain:SetVisible(true)
			frmMain:SetText("Zyelios Editor - V1.2")
			frmMain:MakePopup()

			frmMain_Editor = vgui.Create("TextEntry",frmMain)
			frmMain_Editor:SetVisible(true)
			frmMain_Editor:SetSize(580,420)
			frmMain_Editor:SetPos(10,30)
			frmMain_Editor:SetMultiline(true)
//			frmMain_Editor:SetBGColor(255,255,255,255)
			frmMain_Editor:SetText("")

			frmMain_EditorLog = vgui.Create("TextEntry",frmMain)
			frmMain_EditorLog:SetVisible(true)
			frmMain_EditorLog:SetSize(580,110)
			frmMain_EditorLog:SetPos(10,450)
			frmMain_EditorLog:SetMultiline(true)
//			frmMain_EditorLog:SetBGColor(255,255,255,255)
			frmMain_EditorLog:SetText("")

			frmMain_EditorFileName = vgui.Create("TextEntry",frmMain)
			frmMain_EditorFileName:SetVisible(true)
			frmMain_EditorFileName:SetSize(190,20)
			frmMain_EditorFileName:SetPos(100,600)
			frmMain_EditorFileName:SetText(pl:GetInfo("wire_cpu_filename"))

			local frmMain_OpenButton
			local frmMain_SaveButton
			local frmMain_UploadButton
			local frmMain_CompileButton

			frmMain_OpenButton = vgui.Create("Button", frmMain);
			frmMain_OpenButton:SetText("Open program");
			frmMain_OpenButton:SetPos(10,600);
			frmMain_OpenButton:SetSize(80,20)

			frmMain_SaveButton = vgui.Create("Button", frmMain);
			frmMain_SaveButton:SetText("Save program");
			frmMain_SaveButton:SetPos(300,600);
			frmMain_SaveButton:SetSize(100,20)

//			frmMain_UploadButton = vgui.Create("Button", frmMain);
//			frmMain_UploadButton:SetText("Upload program");
//			frmMain_UploadButton:SetPos(200,600);
//			frmMain_UploadButton:SetSize(100,20)

			frmMain_CompileButton = vgui.Create("Button", frmMain);
			frmMain_CompileButton:SetText("Upload & compile program");
			frmMain_CompileButton:SetPos(410,600);
			frmMain_CompileButton:SetSize(150,20)

			function frmMain_OpenButton:DoClick()
				LocalPlayer():ConCommand('wire_cpu_filename "'..frmMain_EditorFileName:GetValue()..'"')

				local fname = "CPUChip\\"..GetConVarString("wire_cpu_filename")
				if (!file.Exists(fname)) then fname = "CPUChip\\"..GetConVarString("wire_cpu_filename")..".txt" end
				if (!file.Exists(fname)) then return end

				filedata = file.Read(fname)
//				SrcCode = string.Explode("\n", filedata)
//				Msg(filedata)
				frmMain_Editor:SetText(filedata)

				LocalPlayer():ConCommand("wire_cpu_load")
			end
			
			function frmMain_SaveButton:DoClick()
				LocalPlayer():ConCommand('wire_cpu_filename "'..frmMain_EditorFileName:GetValue()..'"')

//				Msg(frmMain_Editor:GetValue())
//				SrcCode = string.Explode(frmMain_Editor:GetValue())
				file.Write("CPUChip\\"..GetConVarString("wire_cpu_filename"),frmMain_Editor:GetValue())
			end
	
//			function frmMain_UploadButton:DoClick()
//				SrcCode = string.Explode(frmMain_Editor:GetValue())
//				file.Write("CPUChip\\"..GetConVarString("wire_cpu_filename"),frmMain_Editor:GetValue())
//	
//				LocalPlayer():ConCommand("wire_cpu_load")
//			end
		
			function frmMain_CompileButton:DoClick()
				frmMain_EditorLog:SetText("")

				LocalPlayer():ConCommand('wire_cpu_filename "'..frmMain_EditorFileName:GetValue()..'"')

				file.Write("CPUChip\\"..GetConVarString("wire_cpu_filename"),frmMain_Editor:GetValue())
				LocalPlayer():ConCommand("wire_cpu_loadcompile")
			end
		else
			frmMain:SetVisible(true)
//			frmMain_Editor:SetText("")
			frmMain_EditorFileName:SetText(pl:GetInfo("wire_cpu_filename"))
		end
	end
	concommand.Add( "wire_cpu_editor_start", Editor_Start )

	local function Editor_AddLog( pl, command, args )
		if (frmMain_EditorLog) then
			frmMain_EditorLog:SetText(frmMain_EditorLog:GetValue() .. args[1] .. "\n")
		end
	end
	concommand.Add( "wire_cpu_editor_addlog", Editor_AddLog )
	concommand.Add( ";wire_cpu_editor_addlog", Editor_AddLog )

	local function Editor_ClearLog( pl, command, args )
		if (frmMain_EditorLog) then
			frmMain_EditorLog:SetText("")
		end
	end
	concommand.Add( "wire_cpu_editor_clearlog", Editor_ClearLog )
end

//=============================================================================
// Control panel
//=============================================================================
function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_cpu_name", Description = "#Tool_wire_cpu_desc" })

	panel:AddControl("TextBox", {
		Label = "Program file name",
		Command = "wire_cpu_filename",
		MaxLength = "128"
	})

	panel:AddControl("Button", {
		Text = "Quick Load",
		Name = "Load",
		Command = "wire_cpu_load"
	})
	
	panel:AddControl("Button", {
		Text = "Clear",
		Name = "Clear",
		Command = "wire_cpu_clear"
	})

	panel:AddControl("CheckBox", {
		Label = "Store in CPU ROM",
		Command = "wire_cpu_userom"
	})

	panel:AddControl("Button", {
		Text = "ZyeliosEditor",
		Name = "Edit",
		Command = "wire_cpu_editor_start"
	})
end
	
