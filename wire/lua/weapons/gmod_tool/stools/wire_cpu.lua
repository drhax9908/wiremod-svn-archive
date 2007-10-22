
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
TOOL.ClientConVar[ "userom" ] = 0
TOOL.ClientConVar[ "dumpcode" ] = 0
TOOL.ClientConVar[ "packet_bandwidth" ] = 100
TOOL.ClientConVar[ "packet_rate_sp" ] = 0.05
TOOL.ClientConVar[ "packet_rate_mp" ] = 0.4
TOOL.ClientConVar[ "compile_rate" ] = 0.05
TOOL.ClientConVar[ "compile_bandwidth" ] = 500

cleanup.Register( "wire_cpus" )

local cpu_tool = nil
local cpu_ent = nil

local function CompileProgram_Timer(firstpass)
	local SendLinesMax = cpu_tool.LineNumber + cpu_tool:GetOwner():GetInfo("wire_cpu_compile_bandwidth")	
	if (SendLinesMax > table.Count(SourceCode)) then SendLinesMax = table.Count(SourceCode) end

	while (cpu_tool.LineNumber <= SendLinesMax) do
		local line = SourceCode[tostring(cpu_tool.LineNumber)]
		if (!line) then
			cpu_tool:GetOwner():PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Bad Line ["..cpu_tool.LineNumber.."]\n")
		else
			if (string.len(line) > 254) then
				cpu_tool:GetOwner():PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Line "..cpu_tool.LineNumber.." too long, skipping!\n")
			else
				cpu_ent:ParseProgram_ASM(cpu_tool:GetOwner(),line,cpu_tool.LineNumber,firstpass)	
			end
		end

		cpu_tool.LineNumber = cpu_tool.LineNumber + 1

//		cpu_tool:GetOwner():PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Line["..cpu_tool.LineNumber.."] = "..line.."\n")
//		end
	end

	local TempPercent = ((cpu_tool.LineNumber-1)/table.Count(SourceCode))*100
//	cpu_tool:GetOwner():PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compiling... ["..TempPercent.."]\n")
	if (SinglePlayer()) then
		if (firstpass) then
			cpu_tool:GetOwner():PrintMessage(HUD_PRINTTALK,"-> ZyeliosASM: Compiling... ["..math.floor(TempPercent/2).."]\n")
		else
			cpu_tool:GetOwner():PrintMessage(HUD_PRINTTALK,"-> ZyeliosASM: Compiling... ["..50+math.floor(TempPercent/2).."]\n")
		end
	else
		if (firstpass) then
			Msg(HUD_PRINTTALK,"-> ZyeliosASM: Compiling... ["..math.floor(TempPercent/2).."]\n")
		else
			Msg(HUD_PRINTTALK,"-> ZyeliosASM: Compiling... ["..50+math.floor(TempPercent/2).."]\n")
		end
	end

	if (TempPercent == 100) then
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
	pl:PrintMessage(HUD_PRINTCONSOLE,"----> ZyeliosASM compiler - Version 2.0 <----\n")
	pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compiling...\n")

	ent.FatalError = false
	ent.WIP = 0
	ent.Labels = {}
	ent.Compiling = true
	if (self:GetClientInfo("userom") == "enable") then
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

	cpu_tool = self
	cpu_ent = ent
	self:Compile_Pass1()

//	local linen = 0
//	for i = 1,table.Count(SourceCode)-1 do
//		linen = linen + 1
//		line = SourceCode[tostring(linen)]
//		trace.Entity:ParseProgram_ASM(ply,line,linen,true)
//	end
//	
//	trace.Entity.WIP = 0
//	ply:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Pass 2\n")
//
//	local linen = 0
//	for i = 1,table.Count(SourceCode)-1 do
//		linen = linen + 1
//		line = SourceCode[tostring(linen)]
//		trace.Entity:ParseProgram_ASM(ply,line,linen,false)
//	end
end

function TOOL:Compile_Pass1()
	self:GetOwner():PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Pass 1\n")

	//Compile each line
	local Reps = math.floor(table.Count(SourceCode)/self:GetOwner():GetInfo("wire_cpu_compile_bandwidth"))+1
	self.Compiling = true

	self.LineNumber = 0
	timer.Create("CPUCompileTimer1",self:GetOwner():GetInfo("wire_cpu_compile_rate"),Reps,CompileProgram_Timer,true)
end

function TOOL:Compile_Pass2()
	self:GetOwner():PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Pass 2\n")

	//Compile each line
	local Reps = math.floor(table.Count(SourceCode)/self:GetOwner():GetInfo("wire_cpu_compile_bandwidth"))+1
	self.Compiling = true

	self.LineNumber = 0
	timer.Create("CPUCompileTimer2",self:GetOwner():GetInfo("wire_cpu_compile_rate"),Reps,CompileProgram_Timer,false)
end


function TOOL:Compile_End()
 	local pl = self:GetOwner()
	local ent = cpu_ent

	if (ent.FatalError) then
		pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compile aborted: fatal error has occured\n")			
	else
		pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compile succeded! "..table.Count(SourceCode).." lines, "..ent.WIP.." bytes, "..table.Count(ent.Labels).." definitions.\n")
	end

	if (self:GetClientInfo("dumpcode") == "enable") then //lololol codedump
		pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Dumping data\n")
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
		pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Dumped!\n")
	end

	ent:Reset()
	ent.Compiling = false
end

function TOOL:LeftClick( trace )
	if trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

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
	
	/*local const, nocollide
	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_cpu, trace.Entity, 0, trace.PhysicsBone, 0, true, true )
		// Don't disable collision if it's not attached to anything
		wire_cpu:GetPhysicsObject():EnableCollisions( false )
		wire_cpu.nocollide = true
	end*/
	local const = WireLib.Weld(wire_cpu, trace.Entity, trace.PhysicsBone, true)
	
	undo.Create("WireCpu")
		undo.AddEntity( wire_cpu )
		undo.SetPlayer( ply )
		undo.AddEntity( const )
	undo.Finish()

	ply:AddCleanup( "wire_cpus", wire_cpu )

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

//if (CLIENT) then
	SourceLines = {}
	SourceLineNumbers = {}
	SourceLinesSent = 0
	SourcePrevCharRate = 0
	SourceSent = false
	SourceTotalChars = 0
	SourceLoadedChars = 0
	
	local function UploadProgram( pl )
		local SendLinesMax = SourceLinesSent + pl:GetInfo("wire_cpu_packet_bandwidth")	
		local TotalChars = 0
		if (SendLinesMax > table.Count(SourceLines)) then SendLinesMax = table.Count(SourceLines) end
		while (SourceLinesSent <= SendLinesMax) && (TotalChars < 10000) do
			SourceLinesSent = SourceLinesSent + 1
			local line = SourceLines[SourceLinesSent]
			local linen = SourceLinesSent
	
			if (line) && (line ~= "\n") && (string.gsub(line, "\n", "") ~= "") then
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

//		SourcePrevChars = SourcePrevChars+TotalChars
		local TempPercent = math.floor(((SourceLinesSent-1)/table.Count(SourceLines))*100)
		if (TempPercent == 100) && (!SourceSent) then
			pl:PrintMessage(HUD_PRINTTALK,"CPU -> Program uploaded\n")
			SourceSent = true
		else
			if (SinglePlayer()) then
				pl:PrintMessage(HUD_PRINTTALK,"CPU -> Sent packet ("..TempPercent.."% @ "..math.floor(CharRate / 1024).." kb/sec, avg. "..TimeLeft.." sec left)\n")
			else
				Msg("CPU -> Sent packet ("..TempPercent.."% @ "..math.floor(CharRate / 1024).." kb/sec, avg. "..TimeLeft.." sec left)\n")
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
		SourceSent = false
		SourceTotalChars = string.len(filedata)

		SourcePrevCharRate = string.len(SourceLines[1])
		SourceLoadedChars = 0

		//Send 50 lines
		pl:PrintMessage(HUD_PRINTTALK,"CPU -> Starting uploading program...\n")
		if (SinglePlayer()) then
			local Reps = math.floor(table.Count(SourceLines)/pl:GetInfo("wire_cpu_packet_bandwidth"))+1	
			timer.Create("CPUSendTimer",pl:GetInfo("wire_cpu_packet_rate_sp"),Reps,UploadProgram,pl)
		else
			local Reps = math.floor(table.Count(SourceLines)/pl:GetInfo("wire_cpu_packet_bandwidth"))+1	
			timer.Create("CPUSendTimer",pl:GetInfo("wire_cpu_packet_rate_mp"),Reps,UploadProgram,pl)
		end
	end
	concommand.Add( "wire_cpu_load", LoadProgram )
	
	local function StoreProgram( pl, command, args )
	        //local lines = "";
	        //for i = 1,256 do
		//	if (pl:GetInfo("wire_cpu_line"..i) ~= "") then
		//                lines = lines .. pl:GetInfo("wire_cpu_line"..i) .. "\n"
		//	end
	        //end
	        //file.Write("CPUChip\\"..pl:GetInfo("wire_cpu_filename"),lines)
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


function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_cpu_name", Description = "#Tool_wire_cpu_desc" })

	panel:AddControl("TextBox", {
		Label = "Program file name",
		Command = "wire_cpu_filename",
		MaxLength = "128"
	})

	panel:AddControl("Button", {
		Text = "Load",
		Name = "Load",
		Command = "wire_cpu_load"
	})

//	panel:AddControl("Button", {
//		Text = "Store",
//		Name = "Store",
//		Command = "wire_cpu_store"
//	})
	
	panel:AddControl("Button", {
		Text = "Clear",
		Name = "Clear",
		Command = "wire_cpu_clear"
	})

	panel:AddControl("CheckBox", {
		Label = "Store in CPU ROM",
		Command = "wire_cpu_userom"
	})

//	panel:AddControl("ComboBox", {
//		Label = "Compiler",
//		MenuButton = "0",
//
//		Options = {
//			["ZyeliosASM"]		= { wire_cpu_compiler = "ZyeliosASM" }
//			["ZyeliosBASIC"]	= { wire_cpu_compiler = "ZyeliosBASIC" }
//		}
//	})
	//Bye till better times:
//	for i = 1,256 do
//		panel:AddControl("TextBox", {
//			Label = "Line "..i..":",
//			Command = "wire_cpu_line"..i,
//			MaxLength = "128"
//		})
//	end
end
	
