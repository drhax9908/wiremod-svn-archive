
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
end

TOOL.ClientConVar[ "model" ] = "models/cheeze/wires/cpu.mdl"
TOOL.ClientConVar[ "filename" ] = ""

for i = 1,512 do
	TOOL.ClientConVar[ "line"..i ] = ""
end

cleanup.Register( "wire_cpus" )

function TOOL:LeftClick( trace )
	if trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_cpu" && trace.Entity.pl == ply ) then
		//trace.Entity:LoadProgram("CPUChip/"..TOOL.ClientConVar[ "filename" ])
		ply:PrintMessage(HUD_PRINTCONSOLE,"----> ZyeliosASM compiler - Version 0.9 <----\n")
		ply:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compiling...\n")
		ply:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Pass 1\n")
		trace.Entity.FatalError = false
		trace.Entity.WIP = 0
		trace.Entity.Labels = {}

		trace.Entity.Labels["version"] = 090
		trace.Entity.Labels["platform"] = 0
		trace.Entity.Labels["true"] = 1
		trace.Entity.Labels["false"] = 0

		for i = 1,512 do
			if (self:GetClientInfo("line"..i)) then
				trace.Entity:ParseProgram(ply, self:GetClientInfo( "line"..i),i,true)
			end
		end
		trace.Entity.WIP = 0
		ply:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Pass 2\n")
		for i = 1,512 do
			if (self:GetClientInfo("line"..i)) then
				trace.Entity:ParseProgram(ply, self:GetClientInfo( "line"..i),i,false)
			end
		end
		if (trace.Entity.FatalError) then
			ply:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compile aborted: fatal error has occured\n")			
		else
			ply:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compile succeded! Wrote "..trace.Entity.WIP.." bytes.\n")
			trace.Entity.Clk = 0
		end
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

local function LoadProgram( pl, command, args )//
	local lines = string.Explode("\n", file.Read("CPUChip\\"..pl:GetInfo("wire_cpu_filename")) or {} )
	for i = 1,512 do
		if (lines[i] && (lines[i] ~= "\n")) then
			pl:ConCommand('wire_cpu_line'..i..' "' .. lines[i] .. '"')
		else
			pl:ConCommand('wire_cpu_line'..i..' ""')
		end
	end
end
concommand.Add( "wire_cpu_load", LoadProgram )

local function StoreProgram( pl, command, args )
        local lines = "";
        for i = 1,512 do
		if (pl:GetInfo("wire_cpu_line"..i) ~= "") then
	                lines = lines .. pl:GetInfo("wire_cpu_line"..i) .. "\n"
		end
        end
        file.Write("CPUChip\\"..pl:GetInfo("wire_cpu_filename"),lines)
end
concommand.Add( "wire_cpu_store", StoreProgram )

local function ClearProgram( pl, command, args )
	local lines = "";
        for i = 1,512 do
		if (pl:GetInfo("wire_cpu_line"..i) ~= "") then
	                lines = lines .. pl:GetInfo("wire_cpu_line"..i) .. "\n"
			pl:ConCommand('wire_cpu_line'..i..' ""')
		end
        end
	local filenum = 0
	while (file.Exists("CPUChip\\ClearSave\\SavedCode"..filenum..".txt")) do
		filenum = filenum + 1
	end
        file.Write("CPUChip\\ClearSave\\SavedCode"..filenum..".txt",lines)
end
concommand.Add( "wire_cpu_clear", ClearProgram )

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

	panel:AddControl("Button", {
		Text = "Store",
		Name = "Store",
		Command = "wire_cpu_store"
	})
	
	panel:AddControl("Button", {
		Text = "Clear",
		Name = "Clear",
		Command = "wire_cpu_clear"
	})
	
	for i = 1,512 do
		panel:AddControl("TextBox", {
			Label = "Line "..i..":",
			Command = "wire_cpu_line"..i,
			MaxLength = "128"
		})
	end
end
	
