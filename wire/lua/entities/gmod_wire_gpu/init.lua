AddCSLuaFile("gpu_vm.lua")
AddCSLuaFile("gpu_opcodes.lua")
AddCSLuaFile("gpu_serverbus.lua")
AddCSLuaFile("gpu_interrupt.lua")
AddCSLuaFile("gpu_clientbus.lua")

AddCSLuaFile("entities/gmod_wire_cpu/cpu_opcodes.lua")
AddCSLuaFile("entities/gmod_wire_cpu/cpu_vm.lua")
AddCSLuaFile("entities/gmod_wire_cpu/cpu_bitwise.lua")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')
include('entities/gmod_wire_cpu/compiler_asm.lua')	//Include ZASM
include('entities/gmod_wire_cpu/cpu_opcodes.lua')	//Include ZCPU opcodes
include('gpu_serverbus.lua')				//Include ZGPU serverside bus
include('gpu_opcodes.lua')				//Include ZGPU opcodes for ZASM

ENT.WireDebugName = "GPU"

function ENT:Initialize()
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "Clk", "Reset", "MemBus", "IOBus" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Memory" }) 

	self.Clk = 1
	self.IOBus = nil
	self.MemBus = nil

	self.Debug = false //will cause massive fps drop!

	self.DebugLines = {}
	self.DebugData = {}

	self.Memory = {}
	self.PrecompileData = {}
	self.PrecompileMemory = {}

	self.IsGPU = true
	self.UseROM = false

	self.SerialNo = 30000000 + math.floor(math.random()*1000000)

	self:SetOverlayText("Graphical Processing Unit")

	self:InitializeGPUOpcodeNames()
	self:InitializeASMOpcodes()
	self:InitializeRegisterNames()
	self:InitializeBus()
end

function ENT:GPU_ResendData(pl)
	//FIXME
	//self:FlushCache()
end

function GPU_PlayerRespawn(pl)
	print("Player has occured")
	for k,v in pairs(ents.GetAll()) do
		if (v:GetClass() == "gmod_wire_gpu") then
			v:GPU_ResendData(pl)
		end
	end
end
hook.Add("PlayerSpawn", "GPUPlayerRespawn", GPU_PlayerRespawn) 

function ENT:Reset()
	self:WriteCell(65534,1)
end

function ENT:TriggerInput(iname, value)
	if (iname == "Clk") then
		self.Clk = value
		self:WriteCell(65535,self.Clk)
	elseif (iname == "Reset") then
		if (value >= 1.0) then
			self:WriteCell(65534,1)
		end
	end
end

function ENT:Think()
	if (self.Inputs.IOBus.Src) then
		local DataUpdated = false

		for i = 0, 1023 do
			if (self.Inputs.IOBus.Src.ReadCell) then
				local var = self.Inputs.IOBus.Src:ReadCell(i)
				if (var) then
					if (self:ReadCell(i+63488) ~= var) then
						self:WriteCell(i+63488,var)
						DataUpdated = true
					end
				end
			end
		end

		if (DataUpdated == true) then
			self:FlushCache()
		end
	end
	self.Entity:NextThink(CurTime()+0.05)
	return true
end


function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	info.SerialNo = self.SerialNo
	info.Memory = {}
	for i=0,65535 do
		if (self.Memory[i]) then
			info.Memory[i] = self.Memory[i]
		end
	end

	return info
end

function Resend_GPU_Data(gpuent)
	gpuent:InitializeBus()
	gpuent:FlushCache()
	for i=0,65535 do
		if (gpuent.Memory[i]) then
			gpuent:WriteCell(i,gpuent.Memory[i])
		end
	end
	gpuent:FlushCache()

	gpuent:WriteCell(65534,1) //reset
	gpuent:WriteCell(65535,gpuent.Clk)
end


function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self.SerialNo = info.SerialNo
	self.Memory = {}

	for i=0,65535 do
		if (info.Memory[i]) then
			self.Memory[i] = info.Memory[i]
		end
	end

	timer.Create("GPU_Paste_Timer",0.1,1,Resend_GPU_Data,self)
end