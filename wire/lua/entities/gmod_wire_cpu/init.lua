AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')
include('compiler_asm.lua')

include('cpu_bitwise.lua')
include('cpu_vm.lua')
include('cpu_opcodes.lua')
include('cpu_bus.lua')
include('cpu_interrupt.lua')

ENT.WireDebugName = "CPU"

function ENT:Initialize()
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)

	self.Inputs = Wire_CreateInputs(self.Entity, { "MemBus", "IOBus", "Frequency", "Clk", "Reset", "NMI"})
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Error" }) 

	self.Debug = false //!!!GLOBAL DEBUG MODE SWITCH!!!

	//Debug mode is cool. All cool guys use it to debug their programs
	//It spams your console with step-by-step description of what your CPU does

	self.DebugLines = {}
	self.DebugData = {}

	self.Memory = {}
	self.ROMMemory = {}
	self.PrecompileData = {}
	self.PrecompileMemory = {}

	self.SerialNo = math.floor(math.random()*1000000)

	self.IOBus = nil
	self.MemBus = nil
	self.UseROM = false

	self.Clk = 0
	self.InputClk = 0

	self:Reset()

	self.DeltaTime = 0
	self.ThinkTime = (1000)/100
	self.PrevTime = CurTime()
	self.SkipIterations = false

	self:SetOverlayText("CPU")
	self:InitializeOpcodeTable()
	self:InitializeLookupTables()
	self:InitializeOpcodeNames()
	self:InitializeRegisterNames()
	self:InitializeCPUVariableSet()
	self:InitializeASMOpcodes()
end

function ENT:CPUID_Version()
	local SVNString = "$Revision: 643 $"
	return tonumber(string.sub(SVNString,12,14))
end

function DebugMessage(msg)
	Msg("============================================\n")
	Msg(msg.."\n")
end


//CPUID
//Value | EAX
//--------------------------------------------
//0	| CPU Version
//1	| RAM Size
//--------------------------------------------

function ENT:Think()
	local Iterations = self.ThinkTime*0.5
	while (Iterations > 0) && (self.Clk >= 1.0) && (!self.Idle) do
		self:Execute()
		if (self.SkipIterations == true) then
			self.SkipIterations = false
			Iterations = Iterations - 30
		else
			Iterations = Iterations - 1
		end
	end

	if (self.Idle) then
		self.Idle = false
	end

	if (self.Clk >= 1.0) then
		self.Entity:NextThink(CurTime()+0.01)
	end
	return true
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	info.UseROM = self.UseROM
	info.SerialNo = self.SerialNo
	if (self.UseROM) then
		info.Memory = {}
		for i=0,65535 do
			if (self.ROMMemory[i]) then
				info.Memory[i] = self.ROMMemory[i]
			end
		end
	end

	return info
end


function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self.SerialNo = info.SerialNo
	if ((info.UseROM) && (info.UseROM == true)) then
		self.UseROM = info.UseROM
		self.ROMMemory = {}
		for i=0,65535 do
			if (info.Memory[i]) then
				self.ROMMemory[i] = info.Memory[i]
			end
		end


		self:Reset()
	end
end

function ENT:TriggerInput(iname, value)
	if (iname == "Clk") then
		self.Clk = value
		self.InputClk = value
		self.PrevTime = CurTime()

		self.Entity:NextThink(CurTime())
	elseif (iname == "Frequency") then
		if (!SinglePlayer() && (value > 120000)) then 
			self.ThinkTime = 1200
			return
		end
		if (value > 0) then
			self.ThinkTime = value/100
		end
	elseif (iname == "Reset") then
		if (value >= 1.0) then
			self:Reset()
		end		
	elseif (iname == "MemBus") then
		self.MemBus = self.Inputs.MemBus.Src /////////////
	elseif (iname == "IOBus") then
		self.IOBus = self.Inputs.IOBus.Src /////////////
	elseif (iname == "NMI") then
		if (value >= 32) && (value < 256) then
			if (self.Clk >= 1.0) then
				self:NMIInterrupt(math.floor(value))
			end
		end
	end
end
