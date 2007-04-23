
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

cleanup.Register( "wire_cpus" )

function TOOL:LeftClick( trace )
	if trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_cpu" && trace.Entity.pl == ply ) then
		//trace.Entity:LoadProgram("CPUChip/"..TOOL.ClientConVar[ "filename" ])
		if (self:GetClientInfo( "compiler") == "ZyeliosASM") then
			//PrintTable(SourceCode)

			ply:PrintMessage(HUD_PRINTCONSOLE,"----> ZyeliosASM compiler - Version 1.1 <----\n")
			ply:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compiling...\n")
			ply:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Pass 1\n")
			trace.Entity.FatalError = false
			trace.Entity.WIP = 0
			trace.Entity.Labels = {}
			trace.Entity.Compiling = true
			if (self:GetClientInfo("userom") == 1) then
				trace.Entity.UseROM = true
			else
				trace.Entity.UseROM = false
			end
	
			trace.Entity.Labels["version"] = 110
			trace.Entity.Labels["platform"] = 0
			trace.Entity.Labels["true"] = 1
			trace.Entity.Labels["false"] = 0

			local linen = 0
			for i = 1,table.Count(SourceCode)-1 do
				linen = linen + 1
				line = SourceCode[tostring(linen)]
				trace.Entity:ParseProgram_ASM(ply,line,linen,true)
			end
	
			trace.Entity.WIP = 0
			ply:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Pass 2\n")

			local linen = 0
			for i = 1,table.Count(SourceCode)-1 do
				linen = linen + 1
				line = SourceCode[tostring(linen)]
				trace.Entity:ParseProgram_ASM(ply,line,linen,false)
			end

			if (trace.Entity.FatalError) then
				ply:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compile aborted: fatal error has occured\n")			
			else
				ply:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compile succeded! "..table.Count(SourceCode).." lines, "..trace.Entity.WIP.." bytes, "..table.Count(trace.Entity.Labels).." definitions.\n")
				if (self:GetClientInfo( "dumpcode") == 1) then //lololol codedump
					ply:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Dumping compiled data\n")
					local codedump = ""
					for i = 0,trace.Entity.WIP do
						codedump = codedump..trace.Entity.Memory[i].."\n"
					end
					ply:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Dumped, saving\n")
					file.Write("codedump.txt",codedump)
					ply:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Dump Saved!\n")
				end
			end
			trace.Entity:Reset()
			trace.Entity.Compiling = false
			return true
		end
		if (self:GetClientInfo( "compiler") == "ZyeliosBASIC") then
			ply:PrintMessage(HUD_PRINTCONSOLE,"----> ZyeliosBASIC compiler - Version 0.1 - CodeSet: Yellow <----\n")
			ply:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosBASIC: Compiling...\n")
			trace.Entity.FatalError = false
			trace.Entity.WIP = 0
			trace.Entity.Labels = {}
	
			trace.Entity.Labels["version"] = 100
			trace.Entity.Labels["platform"] = 0
			trace.Entity.Labels["true"] = 1
			trace.Entity.Labels["false"] = 0

			for i = 1,256 do
				if (self:GetClientInfo("line"..i)) then
					trace.Entity:ParseProgram_BASIC(ply, self:GetClientInfo( "line"..i),i,true)
				end
			end
			trace.Entity.WIP = 0
			for i = 1,256 do
				if (self:GetClientInfo("line"..i)) then
					trace.Entity:ParseProgram_BASIC(ply, self:GetClientInfo( "line"..i),i,false)
				end
			end
			if (trace.Entity.FatalError) then
				ply:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosBASIC: Compile aborted: fatal error has occured\n")			
			else
				ply:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosBASIC: Compile succeded! Wrote "..trace.Entity.WIP.." bytes.\n")
				trace.Entity.Clk = 0
			end
			return true
		end
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

if (CLIENT) then
	SourceLines = {}
	SourceLineNumbers = {}
	SourceLinesSent = 0
end

local function UploadProgram( pl )
	local SendLinesMax = SourceLinesSent + 50	
	if (SendLinesMax > table.Count(SourceLines)) then SendLinesMax = table.Count(SourceLines) end
	while (SourceLinesSent <= SendLinesMax) do
		SourceLinesSent = SourceLinesSent + 1
		local line = SourceLines[SourceLinesSent]
		local linen = SourceLinesSent

		if (line) && (line ~= "\n") && (string.gsub(line, "\n", "") ~= "") then
			pl:ConCommand('wire_cpu_addsrc "'..linen..'" "' .. string.gsub(line, "\n", "") .. '"')
		else
			pl:ConCommand('wire_cpu_addsrc "'..linen..'" ""')
		end	
	end
	local TempPercent = ((SourceLinesSent-1)/table.Count(SourceLines))*100
	pl:PrintMessage(HUD_PRINTCONSOLE,"CPU -> Sent packet ("..TempPercent.." )\n")
	if (TempPercent == 100) then
		pl:PrintMessage(HUD_PRINTTALK,"CPU Upload Done\n")
	end
end

local function LoadProgram( pl, command, args )//
	//SP only:
	//SourceCode = string.Explode("\n", file.Read("CPUChip\\"..pl:GetInfo("wire_cpu_filename")) )

	pl:ConCommand('wire_cpu_clearsrc')

	//timer.Create( String Name, Number delay, Number reps, Function func, ... )

	SourceLines = string.Explode("\n", file.Read("CPUChip\\"..pl:GetInfo("wire_cpu_filename")) )
	SourceLinesSent = 0
	//Send 50 lines
	if (SinglePlayer()) then
		local Reps = math.floor(table.Count(SourceLines)/50)+1	
		timer.Create("CPUSendTimer",0.1,Reps,UploadProgram,pl)
	else
		local Reps = math.floor(table.Count(SourceLines)/50)+1	
		timer.Create("CPUSendTimer",0.4,Reps,UploadProgram,pl)
	end

	//linen = 0
	//for _,line in pairs(lines) do
	//	if (line) && (line ~= "\n") && (string.gsub(line, "\n", "") ~= "") then
	//		pl:ConCommand('wire_cpu_addsrc "'..linen..'" "' .. string.gsub(line, "\n", "") .. '"')
	//	else
	//		pl:ConCommand('wire_cpu_addsrc "'..linen..'" ""')
	//	end
	//	linen = linen + 1
	//end

	//SourceCode = {}
	//local lines = string.Explode("\n", file.Read("CPUChip\\"..pl:GetInfo("wire_cpu_filename")) )
	//for i = 1,256 do
	//	if (lines[i]) && (lines[i] ~= "\n") && (string.gsub(lines[i], "\n", "") ~= "") then
	//		pl:ConCommand('wire_cpu_line'..i..' "' .. string.gsub(lines[i], "\n", "") .. '"')
	//	else
	//		pl:ConCommand('wire_cpu_line'..i..' ""')
	//	end
	//end
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
//	local lines = "";
//        for i = 1,256 do
//		if (pl:GetInfo("wire_cpu_line"..i) ~= "") then
//	                lines = lines .. pl:GetInfo("wire_cpu_line"..i) .. "\n"
//			pl:ConCommand('wire_cpu_line'..i..' ""')
//		end
//        end
//	local filenum = 0
//	while (file.Exists("CPUChip\\ClearSave\\SavedCode"..filenum..".txt")) do
//		filenum = filenum + 1
//	end
//        file.Write("CPUChip\\ClearSave\\SavedCode"..filenum..".txt",lines)
	pl:ConCommand('wire_cpu_clearsrc')
end
concommand.Add( "wire_cpu_clear", ClearProgram ) 

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
	
