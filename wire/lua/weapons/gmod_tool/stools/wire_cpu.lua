
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

cleanup.Register( "wire_cpus" )

function TOOL:LeftClick( trace )
	if trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_cpu" && trace.Entity.pl == ply ) then
		//trace.Entity:LoadProgram("CPUChip/"..TOOL.ClientConVar[ "filename" ])
		if (self:GetClientInfo( "compiler") == "ZyeliosASM") then
			//PrintTable(SourceCode)
			ply:PrintMessage(HUD_PRINTCONSOLE,"----> ZyeliosASM compiler - Version 1.2 <----\n")
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

			if (self:GetClientInfo("dumpcode") == "enable") then
				trace.Entity.MakeDump = true
				trace.Entity.Dump = "Code listing:\n"
			else
				trace.Entity.MakeDump = false
			end
	
			trace.Entity.Labels["version"] = 120
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
			end

			if (self:GetClientInfo("dumpcode") == "enable") then //lololol codedump
				ply:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Dumping data\n")
				local codedump = "Count: "..trace.Entity.WIP.."\n"
				local pointerdump = "Count: "..table.Count(trace.Entity.Labels).."\n"
				for i = 0,trace.Entity.WIP do
					codedump = codedump.."["..i.."]".."="..trace.Entity.Memory[i].."\n"
				end
				for k,v in pairs(trace.Entity.Labels) do
					pointerdump = pointerdump.."#pointer "..k.." "..v.."\n"
				end
				file.Write("cdump.txt",codedump)
				file.Write("ldump.txt",trace.Entity.Dump)
				file.Write("pdump.txt",pointerdump)
				ply:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Dumped!\n")
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

//if (CLIENT) then
	SourceLines = {}
	SourceLineNumbers = {}
	SourceLinesSent = 0
	SourceSent = false
	
	local function UploadProgram( pl )
		local SendLinesMax = SourceLinesSent + pl:GetInfo("wire_cpu_packet_bandwidth")	
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
		pl:PrintMessage(HUD_PRINTTALK,"CPU -> Sent packet ("..TempPercent.." )\n")
		Msg("Temp packet: "..TempPercent.."\n")
		if (TempPercent == 100) && (!SourceSent) then
			pl:PrintMessage(HUD_PRINTTALK,"CPU -> Program uploaded\n")
			SourceSent = true
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
	
	
		SourceLines = string.Explode("\n", file.Read(fname) )
		SourceLinesSent = 0
		SourceSent = false
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
	
