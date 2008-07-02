AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')
include('compiler_asm.lua')
include('bitwise.lua')

ENT.WireDebugName = "CPU"

function ENT:Initialize()
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)

	self.Inputs = Wire_CreateInputs(self.Entity, { "MemBus", "IOBus", "Frequency", "Clk", "Reset", "NMI"})
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Error" }) 

	self.Debug = false //GLOBAL DEBUG MODE SWITCH
	self.DebugLines = {}
	self.DebugData = {}

	self.Memory = {}
	self.ROMMemory = {}
	self.PrecompileData = {}

	self.Page = {}
	for i = 0, 511 do
		self.Page[i] = true
	end

	self.IOBus = nil
	self.MemBus = nil
	self.UseROM = false

	self.Clk = 0
	self.InputClk = 0

	self:Reset()
	
	//= Different compiler vars========
	self.WIP = 0
	self.FatalError = false
	self.Labels = {}
	self.Compiling = false
	self.Dump = ""
	self.MakeDump = false
	self.LinePos = 0
	//=================================

	self.DeltaTime = 0
	self.ThinkTime = (1000)/100
	self.PrevTime = CurTime()
	self.CPUCyclesLeft = 0

	self:SetOverlayText("CPU")
	self:InitializeOpcodeTable()
	self:InitASMOpcodes()
end

function ENT:CPUID_Version()
	local SVNString = "$Revision: 643 $"

	return tonumber(string.sub(SVNString,12,14))
end

function DebugMessage(msg)
	Msg("============================================\n")
	Msg(msg.."\n")
end

function ENT:Reset()
	self.IP = 0

	for i = 0, 511 do
		self.Page[i] = true
	end

	self.EAX = 0
	self.EBX = 0
	self.ECX = 0
	self.EDX = 0

	self.ESI = 0
	self.EDI = 0
	self.ESP = 65535
	self.EBP = 0

	self.CS	= 0
	self.SS = 0
	self.DS = 0
	self.ES = 0
	self.GS = 0
	self.FS = 0

	self.IDTR = 0
	self.IF = 1
	self.NextIF = nil
	self.PF = 0
	
	self.CMPR = 0
	self.ILTC = 0
	self.XEIP = 0
	self.LADD = 0
	self.INTR = false
	self.TMR = 0
	self.TIMER = 0

	self.Idle = false

	self.Clk = self.InputClk

	self.HaltPort = -1

	if (self.UseROM) then
		for i = 0, 65535 do
			if (self.ROMMemory[i]) then
				self.Memory[i] = self.ROMMemory[i]
			else
				self.Memory[i] = nil
			end
		end
	end

	if (self.Debug) then
		DebugMessage("CPU RESET")
	end

	Wire_TriggerOutput(self.Entity, "Error", 0.0)
end

//INTERRUPTS TABLE
//Value | Meaning				| Passed parameters
//---------------------------------------------------------------------
//0.0	| Software restart			|
//2.0	| End of program execution		|
//3.0	| Division by zero			|
//4.0	| Unknown opcode 			| OPCODE,ADDRESS
//5.0	| Internal error			|
//6.0	| Stack error				|
//7.0   | Memory fault (Read/write violation)	| ADDRESS
//8.0   | External bus error			|
//9.0	| Page fault (Write access violation)	| ADDRESS
//10.0  | Port Bus fault			| ADDRESS
//11.0  | ROM Error				|
//12.0	| Page error (wrong page id)		|
//13.0	| General Protection Error		|
//14.0	| Idiot error				|
//31.0	| Debug trap				| OPCODE
//----------------------------------------------------------------------

//FIXME: fix cascade interrupts!!!
function ENT:Interrupt(intnumber)
	if (self.Compiling) then
		self.FatalError = true
		return
	end
	if (self.Debug) then
		DebugMessage("INTERRUPT: #"..intnumber.."\nADDRESS: "..self.XEIP.."\nLastReadAddress="..self.LADD.."\nLastReadOpcode="..self.ILTC)
	end

	if (self.INTR) then
		return
	end
	self.INTR = true
	if (intnumber <= 1) or (intnumber > 255) then
		local handlewrongint = false

		if ((intnumber == 0) || (intnumber == 1)) && (self.PF == 1) then
			local intaddress = self.IDTR + 1*2
			local intprops = self.Memory[intaddress+1]
			if (intprops == 96) then
				handlewrongint = true
			end
		end

		if (handlewrongint == false) then
			self:Reset()
			self.EAX = 10
			if (intnumber == 1) then
				self.Clk = 0
			end
			return
		end
	end
	Wire_TriggerOutput(self.Entity, "Error", intnumber)
	if (self.IF == 1) then
		if (self.PF == 0) then
			if (intnumber ~= 31) then //Dont die on debug trap
				self.Clk = 0
			end
			return
		else
			local intaddress = self.IDTR + intnumber*2
			if (intaddress > 65535) then intaddress = 65535 end
			if (intaddress < 0) then intaddress = 0 end
			local intoffset = self.Memory[intaddress]
			local intprops = self.Memory[intaddress+1]
			if ((intprops == 32) || (intprops == 96)) then //Interrupt active, temp fix
				if (self.Debug) then
					DebugMessage("INTERRUPT: #"..intnumber.." HANDLED\nJumpOffset="..intoffset.."\n")
				end

				self.INTR = false
				if (intnumber == 4 ) || 
				   (intnumber == 7 ) || 
				   (intnumber == 9 ) || 
				   (intnumber == 10) then
					self:Push(self.LADD)
				end
				if (intnumber == 4 ) ||
				   (intnumber == 31) then //If wrong opcode or debug trap, then store
					self:Push(self.ILTC)
				end
				if self:Push(self.IP) then //Store IRET
					self:Push(self.XEIP)
					self.IP = intoffset
				end
				self.CMPR = 0
				self.INTR = true
			else
				self.CMPR = 1
			end
		end
	end
end

function ENT:Write(value)
	if (value) then
		if (!tonumber(value)) then
			self:WriteCell(self.WIP,0)
			self.WIP = self.WIP + 1
			return
		end
		if (self.UseROM) then
			if (self.WIP < 65536) then
				self.ROMMemory[self.WIP] = value
			else
				if (self.Debug) then Msg("-> ZyeliosASM: Warning: writing value outside of 64KB ROM\n") end
			end
		end

		self:WriteCell(self.WIP,value)
		//if (self.Debug) && (value != 0) then Msg("-> ZyeliosASM: Wrote "..value.." at ["..self.WIP.."]\n") end

		self.WIP = self.WIP + 1
	else
		self.WIP = self.WIP + 1
	end
end

function ENT:Read()
	if (self.INTR) then //Lock the bus & eip
		if (self.Debug) then
			DebugMessage("Warning: Bus was read while locked")
		end
		return nil
	end
	if (!self.IP) then
		self:Reset()
		Wire_TriggerOutput(self.Entity, "Error", 5.0)
		return nil
	end
	self.IP = self.IP + 1
	return self:ReadCell(self.IP-1+self.CS)
end

function ENT:ReadCell(Address)
	if (self.INTR) then
		if (self.Debug) then
			DebugMessage("Warning: Bus was read while locked")
		end
		return nil
	end

	if (Address < 0) then
		return self:ReadPort(-Address-1)
	end
	if (Address < 65536) then
		if (self.Memory[math.floor(Address)]) then
			return self.Memory[math.floor(Address)]
		else
			return 0
		end
	else
		if (self.Inputs.MemBus.Src) then
			if (self.Inputs.MemBus.Src.LatchStore) then
				if (self.Inputs.MemBus.Src.LatchStore[math.floor(Address)-65536]) then
					return self.Inputs.MemBus.Src.LatchStore[math.floor(Address)-65536]
				else
					self.LADD = math.floor(Address)
					self:Interrupt(7)
					return nil
				end
			elseif (self.Inputs.MemBus.Src.ReadCell) then
				local var = self.Inputs.MemBus.Src:ReadCell(math.floor(Address)-65536)
				if (var) then
					return var
				else
					self.LADD = math.floor(Address)
					self:Interrupt(7)
					return nil
				end
			else
				self.LADD = math.floor(Address)
				self:Interrupt(8)
				return nil
			end
		else
			self.LADD = math.floor(Address)
			self:Interrupt(7)
			return nil
		end
	end
end

function ENT:WriteCell(Address, value)
	if (self.INTR) then
		if (self.Debug) then
			DebugMessage("Warning: Bus was written to while locked")
		end
		return nil
	end

	if (Address < 0) then
		return self:WritePort(-Address-1,value)
	end
	if (Address < 65536) then
		if (self.Page[math.floor(Address / 128)]) then
			self.Memory[math.floor(Address)] = value
		else
			self.LADD = math.floor(Address)
			self:Interrupt(9)
			return false
		end
		return true
	else
		if (self.Inputs.MemBus.Src) then
			if (self.Inputs.MemBus.Src.LatchStore) then
				if (self.Inputs.MemBus.Src.LatchStore[math.floor(Address)-65536]) then
					self.Inputs.MemBus.Src.LatchStore[math.floor(Address)-65536] = value
					return true
				else
					self.LADD = math.floor(Address)
					self:Interrupt(7)
					return false
				end
			elseif (self.Inputs.MemBus.Src.WriteCell) then
				if (self.Inputs.MemBus.Src:WriteCell(math.floor(Address)-65536,value)) then
					return true
				else
					self.LADD = math.floor(Address)
					self:Interrupt(7)
					return false
				end
			else
				self.LADD = math.floor(Address)
				self:Interrupt(8)
				return false
			end
		else
			self.LADD = math.floor(Address)
			self:Interrupt(7)
			return false
		end
	end
	return true
end

function ENT:ReadPort(Address)
	if (self.INTR) then //Lock the bus
		return nil
	end

	
	if (Address < 0) then
		self.LADD = -math.floor(Address)
		self:Interrupt(10)
		return nil
	end
	if (self.Inputs.IOBus.Src) then
		if (self.Inputs.IOBus.Src.LatchStore) then
			if (self.Inputs.IOBus.Src.LatchStore[math.floor(Address)]) then
				return self.Inputs.IOBus.Src.LatchStore[math.floor(Address)]
			else
				self.LADD = -math.floor(Address)
				self:Interrupt(10)
				return nil
			end
		elseif (self.Inputs.IOBus.Src.ReadCell) then
			local var = self.Inputs.IOBus.Src:ReadCell(math.floor(Address))
			if (var) then
				return var
			else
				self.LADD = -math.floor(Address)
				self:Interrupt(10)
				return nil
			end
		else
			self.LADD = -math.floor(Address)
			self:Interrupt(8)
			return nil
		end
	else
		return 0
	end
end

function ENT:WritePort(Address, value)
	if (self.INTR) then //Lock the bus
		return nil
	end

	if (Address < 0) then
		self.LADD = -math.floor(Address)
		self:Interrupt(8)
		return false
	end
	if (self.Inputs.IOBus.Src) then
		if (self.Inputs.IOBus.Src.LatchStore) then
			if (self.Inputs.IOBus.Src.LatchStore[math.floor(Address)]) then
				self.Inputs.IOBus.Src.LatchStore[math.floor(Address)] = value
				return true
			else
				self.LADD = -math.floor(Address)
				self:Interrupt(10)
				return false
			end
		elseif (self.Inputs.IOBus.Src.WriteCell) then
			if (self.Inputs.IOBus.Src:WriteCell(math.floor(Address),value)) then
				return true
			else
				self.LADD = -math.floor(Address)
				self:Interrupt(10)
				return false
			end
		else
			self.LADD = -math.floor(Address)
			self:Interrupt(8)
			return false
		end
	else
		return true
	end
end

function ENT:Push(value)
	if (self.INTR) then //Lock the bus
		return nil
	end

	self:WriteCell(self.ESP+self.SS,value)
	self.ESP = self.ESP - 1
	if (self.ESP < 0) then
		self.ESP = 0
		self:Interrupt(6)
		return false
	end
	return true
end

function ENT:Pop()
	if (self.INTR) then //Lock the bus
		return nil
	end

	self.ESP = self.ESP + 1
	if (self.ESP > 65535) then
		self.ESP = 65535
		self:Interrupt(6)
		return nil
	else
		return self:ReadCell(self.ESP+self.SS)
	end
end

//CPUID
//Value | EAX
//--------------------------------------------
//0	| CPU Version
//1	| RAM Size
//--------------------------------------------

function ENT:InitializeOpcodeTable()
	self.OpcodeTable = {}

	self.OpcodeTable[0] = function (Param1,Param2)	//END
		self:Interrupt(2)
	end
	self.OpcodeTable[1] = function (Param1,Param2)	//JNE
		if (self.CMPR ~= 0) then
			self.IP = Param1
		end
	end
	self.OpcodeTable[2] = function (Param1,Param2)	//JMP
		self.IP = Param1
	end
	self.OpcodeTable[3] = function (Param1,Param2)	//JG
		if (self.CMPR > 0) then
			self.IP = Param1
		end
	end
	self.OpcodeTable[4] = function (Param1,Param2)	//JGE
		if (self.CMPR >= 0) then
			self.IP = Param1
		end
	end
	self.OpcodeTable[5] = function (Param1,Param2)	//JL
		if (self.CMPR < 0) then
			self.IP = Param1
		end
	end
	self.OpcodeTable[6] = function (Param1,Param2)	//JLE
		if (self.CMPR <= 0) then
			self.IP = Param1
		end
	end
	self.OpcodeTable[7] = function (Param1,Param2)	//JE
		if (self.CMPR == 0) then
			self.IP = Param1
		end
	end
	//============================================================
	self.OpcodeTable[8] = function (Param1,Param2)	//CPUID
		if (Param1 == 0) then 			//CPU REVISION/VERSION
			self.EAX = self:CPUID_Version()	//= 3.00 BETA 2
		elseif (Param1 == 1) then		//AMOUNT OF RAM
			self.EAX = 65536		//= 64KB
		elseif (Param1 == 2) then		//TYPE (0 - ZCPU; 1 - ZGPU)
			self.EAX = 0			//= ZCPU
		else
			self.EAX = 0
		end
	end
	//============================================================
	self.OpcodeTable[9] = function (Param1,Param2)	//PUSH
		self:Push(Param1)
	end
	//------------------------------------------------------------
	self.OpcodeTable[10] = function (Param1,Param2)	//ADD
		return Param1 + Param2
	end
	self.OpcodeTable[11] = function (Param1,Param2)	//SUB
		return Param1 - Param2
	end
	self.OpcodeTable[12] = function (Param1,Param2)	//MUL
		return Param1 * Param2
	end
	self.OpcodeTable[13] = function (Param1,Param2)	//DIV
		if (math.abs(Param2) < 1e-12) then
			self:Interrupt(3)
		else
			return Param1 / Param2
		end
	end
	self.OpcodeTable[14] = function (Param1,Param2) //MOV
		return Param2
	end
	self.OpcodeTable[15] = function (Param1,Param2)	//CMP
		self.CMPR = Param1 - Param2
	end
	self.OpcodeTable[16] = function (Param1,Param2)	//RD
		if (self.Memory[Param2]) then
			return self.Memory[Param2]
		else
			return 0
		end
	end
	self.OpcodeTable[17] = function (Param1,Param2)	//WD
		self.Memory[Param1] = Param2
	end
	self.OpcodeTable[18] = function (Param1,Param2)	//MIN
		if (tonumber(Param2) < tonumber(Param1)) then
			return Param2
		else
			return Param1
		end
	end
	self.OpcodeTable[19] = function (Param1,Param2)	//MAX
		if (tonumber(Param2) > tonumber(Param1)) then
			return Param2
		else
			return Param1
		end
	end
	//------------------------------------------------------------
	self.OpcodeTable[20] = function (Param1,Param2)	//INC
		return Param1 + 1		
	end
	self.OpcodeTable[21] = function (Param1,Param2)	//DEC
		return Param1 - 1
	end
	self.OpcodeTable[22] = function (Param1,Param2)	//NEG
		return -Param1
	end
	self.OpcodeTable[23] = function (Param1,Param2)	//RAND
		return math.random()
	end
	self.OpcodeTable[24] = function (Param1,Param2)	//LOOP
		if (self.ECX ~= 0) then
			self.IP = Param1
			self.ECX = self.ECX-1
		end
		self.WriteBack = false
	end
	self.OpcodeTable[25] = function (Param1,Param2)	//LOOPA
		if (self.EAX ~= 0) then
			self.IP = Param1
			self.EAX = self.EAX-1
		end
		self.WriteBack = false
	end
	self.OpcodeTable[26] = function (Param1,Param2)	//LOOPB
		if (self.EBX ~= 0) then
			self.IP = Param1
			self.EBX = self.EBX-1
		end
		self.WriteBack = false
	end
	self.OpcodeTable[27] = function (Param1,Param2)	//LOOPD
		if (self.EDX ~= 0) then
			self.IP = Param1
			self.EDX = self.EDX-1
		end
		self.WriteBack = false
	end
	self.OpcodeTable[28] = function (Param1,Param2)	//SPG
		if (math.floor(Param1 / 128) >= 0) && (math.floor(Param1 / 128) < 512) then
			Page[math.floor(Param1 / 128)] = false
		else
			self:Interrupt(12)
		end
		self.WriteBack = false
	end
	self.OpcodeTable[29] = function (Param1,Param2)	//CPG
		if (math.floor(Param1 / 128) >= 0) && (math.floor(Param1 / 128) < 512) then
			Page[math.floor(Param1 / 128)] = true
		else
			self:Interrupt(12)
		end
		self.WriteBack = false
	end
	//------------------------------------------------------------
	self.OpcodeTable[30] = function (Param1,Param2)	//POP
		return self:Pop()
	end
	self.OpcodeTable[31] = function (Param1,Param2)	//CALL
		if self:Push(self.IP) then
			self.IP = Param1
		end
		self.WriteBack = false
	end
	self.OpcodeTable[32] = function (Param1,Param2)	//NOT
		if Param1 <= 0 then
			return 1
		else
			return 0
		end
	end
	self.OpcodeTable[33] = function (Param1,Param2)	//FINT
		return math.floor(Param1)
	end
	self.OpcodeTable[34] = function (Param1,Param2)	//RND
		return math.Round(Param1)
	end
	self.OpcodeTable[35] = function (Param1,Param2)	//FLOOR
		return Param1 - math.floor(Param1)
	end
	self.OpcodeTable[36] = function (Param1,Param2)	//INV
		if (math.abs(Param1) < 1e-12) then
			self:Interrupt(3)
		else
			return 1 / Param1
		end
	end
	self.OpcodeTable[37] = function (Param1,Param2)	//HALT
		self.HaltPort = math.Clamp(math.floor(Param1),0,7)
	end
	self.OpcodeTable[38] = function (Param1,Param2)	//FSHL
		return math.floor(Param1 * 2)
	end
	self.OpcodeTable[39] = function (Param1,Param2)	//FSHR
		return math.floor(Param1 / 2)
	end
	//------------------------------------------------------------
	self.OpcodeTable[40] = function (Param1,Param2)	//RET
		local newIP = self:Pop()
		if (newIP) then
			self.IP = newIP
		end
	end
	self.OpcodeTable[41] = function (Param1,Param2)	//IRET
		local newIP = self:Pop()
		if (newIP) then
			self.IP = newIP
		end
		Wire_TriggerOutput(self.Entity, "Error", 0)
	end
	self.OpcodeTable[42] = function (Param1,Param2)	//STI
		self.NextIF = 1
	end
	self.OpcodeTable[43] = function (Param1,Param2)	//CLI
		self.IF = 0
	end
	self.OpcodeTable[44] = function (Param1,Param2)	//STP
		self.PF = 1
	end
	self.OpcodeTable[45] = function (Param1,Param2)	//CLP
		self.PF = 0
	end
	self.OpcodeTable[46] = function (Param1,Param2)	//STD
		self.Debug = true
	end
	self.OpcodeTable[47] = function (Param1,Param2)	//RETF
		local newIP = self:Pop()
		local newCS = self:Pop()
		if (newIP) && (newCS) then
			self.IP = newIP
			self.CS = newCS
		end
	end
	self.OpcodeTable[48] = function (Param1,Param2)	//RCMPR
		self.EAX = self.CMPR
	end
	self.OpcodeTable[49] = function (Param1,Param2)	//TMR
		self.EAX = self.TMR
	end
	//------------------------------------------------------------
	self.OpcodeTable[50] = function (Param1,Param2)	//AND
		if (Param1 > 0) && (Param2 > 0) then
			return 1
		else
			return 0
		end
	end
	self.OpcodeTable[51] = function (Param1,Param2)	//OR
		if (Param1 > 0) || (Param2 > 0) then
			return 1
		else
			return 0
		end
	end
	self.OpcodeTable[52] = function (Param1,Param2)	//XOR
		if ((Param1 > 0) && (Param2 <= 0)) ||
		   ((Param1 <= 0) && (Param2 > 0)) then
			return 1
		else
			return 0
		end
	end
	self.OpcodeTable[53] = function (Param1,Param2)	//FSIN
		return math.sin(Param2)
	end
	self.OpcodeTable[54] = function (Param1,Param2)	//FCOS
		return math.cos(Param2)
	end
	self.OpcodeTable[55] = function (Param1,Param2)	//FTAN
		return math.tan(Param2)
	end
	self.OpcodeTable[56] = function (Param1,Param2)	//FASIN
		return math.asin(Param2)
	end
	self.OpcodeTable[57] = function (Param1,Param2)	//FACOS
		return math.acos(Param2)
	end
	self.OpcodeTable[58] = function (Param1,Param2)	//FATAN
		return math.atan(Param2)
	end
	self.OpcodeTable[59] = function (Param1,Param2)	//MOD
		return math.fmod(Param1,Param2)
	end
	//------------------------------------------------------------
	self.OpcodeTable[60] = function (Param1,Param2)	//BIT
		local bits = bit.tobits(math.floor(Param1))
		self.CMPR = bits[math.Clamp(Param2,0,31)]
	end
	self.OpcodeTable[61] = function (Param1,Param2)	//SBIT
		local bits = bit.tobits(math.floor(Param1))
		bits[math.Clamp(Param2,0,31)] = 1
		return bit.tonumb(bits)
	end
	self.OpcodeTable[62] = function (Param1,Param2)	//CBIT
		local bits = bit.tobits(math.floor(Param1))
		bits[math.Clamp(Param2,0,31)] = 0
		return bit.tonumb(bits)
	end
	self.OpcodeTable[63] = function (Param1,Param2)	//TBIT
		local bits = bit.tobits(math.floor(Param1))
		bits[math.Clamp(Param2,0,31)] = 1-bits[math.Clamp(Param2,0,31)]
		return bit.tonumb(bits)
	end
	self.OpcodeTable[64] = function(Param1,Param2) //BAND
		return bit.band(Param1,Param2)
	end
	self.OpcodeTable[65] = function(Param1,Param2) //BOR
		return bit.bor(Param1,Param2)
	end
	self.OpcodeTable[66] = function(Param1,Param2) //BXOR
		return bit.bxor(Param1,Param2)
	end
	self.OpcodeTable[67] = function(Param1,Param2) //BSHL
		return bit.blshift(Param1,Param2)
	end
	self.OpcodeTable[68] = function(Param1,Param2) //BSHR
		return bit.blogic_rshift(Param1,Param2)
	end
	self.OpcodeTable[69] = function (Param1,Param2)	//JMPF
		self.CS = Param2
		self.IP = Param1
	end
	self.OpcodeTable[70] = function (Param1,Param2)	//NMIINT
		if ((self.IF == 1) &&
		    self:Push(self.ES) && 
		    self:Push(self.GS) && 
    		    self:Push(self.FS) && 
    		    self:Push(self.DS) && 
		    self:Push(self.SS) && 
		    self:Push(self.CS) && 

		    self:Push(self.EDI) && 
		    self:Push(self.ESI) && 
		    self:Push(self.ESP) && 
		    self:Push(self.EBP) && 
		    self:Push(self.EDX) && 
		    self:Push(self.ECX) && 
		    self:Push(self.EBX) && 
		    self:Push(self.EAX) && 

		    self:Push(self.CMPR) && 
		    self:Push(self.IP)) then
			self:Interrupt(math.floor(Param1))
		end
	end
	//------------------------------------------------------------
	self.OpcodeTable[71] = function (Param1,Param2)	//CNE
		if (self.CMPR ~= 0) then
			if self:Push(self.IP) then
				self.IP = Param1
			end
		end
	end
	self.OpcodeTable[72] = function (Param1,Param2)	//CJMP
		if self:Push(self.IP) then
			self.IP = Param1
		end
	end
	self.OpcodeTable[73] = function (Param1,Param2)	//CG
		if (self.CMPR > 0) then
			if self:Push(self.IP) then
				self.IP = Param1
			end
		end
	end
	self.OpcodeTable[74] = function (Param1,Param2)	//CGE
		if (self.CMPR >= 0) then
			if self:Push(self.IP) then
				self.IP = Param1
			end
		end
	end
	self.OpcodeTable[75] = function (Param1,Param2)	//CL
		if (self.CMPR < 0) then
			if self:Push(self.IP) then
				self.IP = Param1
			end
		end
	end
	self.OpcodeTable[76] = function (Param1,Param2)	//CLE
		if (self.CMPR <= 0) then
			if self:Push(self.IP) then
				self.IP = Param1
			end
		end
	end
	self.OpcodeTable[77] = function (Param1,Param2)	//CE
		if (self.CMPR == 0) then
			if self:Push(self.IP) then
				self.IP = Param1
			end
		end
	end
	self.OpcodeTable[78] = function (Param1,Param2)	//MCOPY
		if (Param1 == 0) then return end
		for i = 1,math.Clamp(Param1,0,8192) do
			local val
			val = self:ReadCell(self.ESI+self[self.PrecompileData[self.XEIP].Segment1])
			if (val == nil) then return end
			if (self:WriteCell(self.EDI+self[self.PrecompileData[self.XEIP].Segment2],val) == false) then return end
			self.EDI = self.EDI + 1
			self.ESI = self.ESI + 1
		end
	end
	self.OpcodeTable[79] = function (Param1,Param2)	//MXCHG
		if (Param1 == 0) then return end
		for i = 1,math.Clamp(Param1,0,8192) do
			local val
			val1 = self:ReadCell(self.ESI+self[self.PrecompileData[self.XEIP].Segment1])
			val2 = self:ReadCell(self.EDI+self[self.PrecompileData[self.XEIP].Segment2])
			if (val1 == nil) || (val2 == nil) then return end
			if (self:WriteCell(self.EDI+self[self.PrecompileData[self.XEIP].Segment2],val1) == false) || (self:WriteCell(self.ESI+self[self.PrecompileData[self.XEIP].Segment1],val2) == false) then return end
			self.EDI = self.EDI + 1
			self.ESI = self.ESI + 1
		end
	end
	//------------------------------------------------------------
	self.OpcodeTable[80] = function (Param1,Param2)	//FPWR
		return Param1^Param2
	end
	self.OpcodeTable[81] = function (Param1,Param2)	//XCHG
		self.PrecompileData[self.XEIP].WriteBack2(Param1)
		return Param2
	end
	self.OpcodeTable[82] = function (Param1,Param2)	//FLOG
		return math.log(Param2)
	end
	self.OpcodeTable[83] = function (Param1,Param2)	//FLOG10
		return math.log10(Param2)
	end
	self.OpcodeTable[84] = function (Param1,Param2)	//IN
		return self:ReadPort(Param2)
	end
	self.OpcodeTable[85] = function (Param1,Param2)	//OUT
		self:WritePort(Param1,Param2)
	end
	self.OpcodeTable[86] = function (Param1,Param2)	//FABS
		return math.abs(Param2)
	end
	self.OpcodeTable[87] = function (Param1,Param2)	//FSGN
		if (Param2 > 0) then
			return 1
		elseif (Param2 < 0) then
			return -1
		else
			return 0
		end
	end
	self.OpcodeTable[88] = function (Param1,Param2)	//FEXP
		return math.exp(Param2)
	end
	self.OpcodeTable[89] = function (Param1,Param2)	//CALLF
		if self:Push(self.CS) && self:Push(self.IP)  then
			self.IP = Param1
			self.CS = Param2
		end
	end
	//------------------------------------------------------------
	self.OpcodeTable[90] = function (Param1,Param2) //FPI
		return 3.141592653589793
	end
	self.OpcodeTable[91] = function (Param1,Param2) //FE
		return 2.718281828459045
	end
	self.OpcodeTable[92] = function (Param1,Param2)	//INT
		self:Interrupt(Param1)
	end
	self.OpcodeTable[93] = function (Param1,Param2)	//TPG
		local tadd = Param1*128
		self.CMPR = 0
		while (tadd < Param1*128+128) do
			local val = self:ReadCell(tadd)
			if (val == nil) then
				self.CMPR = tadd
				tadd = Param1*128+128
			end
			tadd = tadd + 1
		end
	end
	self.OpcodeTable[94] = function (Param1,Param2)	//FCEIL
		return math.ceil(Param1)
	end
	self.OpcodeTable[95] = function (Param1,Param2) //ERPG
		if (Param1 >= 0) && (Param1 < 512) then
			local tadd = Param1*128
			while (tadd < Param1*128+128) do
				self.ROMMemory[tadd] = 0
				tadd = tadd + 1
			end
		else
			self:Interrupt(12)
		end
	end
	self.OpcodeTable[96] = function (Param1,Param2)	//WRPG
		if (Param1 >= 0) && (Param1 < 512) then
			local tadd = Param1*128
			while (tadd < Param1*128+128) do
				self.ROMMemory[tadd] = self.Memory[tadd]
				tadd = tadd + 1
			end
		else
			self:Interrupt(12)
		end
	end
	self.OpcodeTable[97] = function (Param1,Param2) //RDPG
		if (Param1 >= 0) && (Param1 < 512) then
			local tadd = Param1*128
			while (tadd < Param1*128+128) do
				self.Memory[tadd] = self.ROMMemory[tadd]
				tadd = tadd + 1
			end
		else
			self:Interrupt(12)
		end
	end
	self.OpcodeTable[98] = function (Param1,Param2)	//TIMER
		return self.TIMER
	end
	self.OpcodeTable[99] = function (Param1,Param2)	//LIDTR
		self.IDTR = Param1
	end
	//------------------------------------------------------------
	self.OpcodeTable[100] = function (Param1,Param2) 	//STATESTORE
		self:WriteCell(Param1 + 00,self.IP)

		self:WriteCell(Param1 + 01,self.EAX)
		self:WriteCell(Param1 + 02,self.EBX)
		self:WriteCell(Param1 + 03,self.ECX)
		self:WriteCell(Param1 + 04,self.EDX)

		self:WriteCell(Param1 + 05,self.ESI)
		self:WriteCell(Param1 + 06,self.EDI)
		self:WriteCell(Param1 + 07,self.ESP)
		self:WriteCell(Param1 + 08,self.EBP)

		self:WriteCell(Param1 + 09,self.CS)
		self:WriteCell(Param1 + 10,self.SS)
		self:WriteCell(Param1 + 11,self.DS)
		self:WriteCell(Param1 + 12,self.ES)
		self:WriteCell(Param1 + 13,self.GS)
		self:WriteCell(Param1 + 14,self.FS)
	
		self:WriteCell(Param1 + 15,self.CMPR)
	end
	self.OpcodeTable[101] = function (Param1,Param2) 	//JNER
		if (self.CMPR ~= 0) then
			self.IP = self.IP + Param1
		end
	end
	self.OpcodeTable[102] = function (Param1,Param2)	//JMPR
		self.IP = self.IP + Param1
	end
	self.OpcodeTable[103] = function (Param1,Param2)	//JGR
		if (self.CMPR > 0) then
			self.IP = self.IP + Param1
		end
	end
	self.OpcodeTable[104] = function (Param1,Param2)	//JGER
		if (self.CMPR >= 0) then
			self.IP = self.IP + Param1
		end
	end
	self.OpcodeTable[105] = function (Param1,Param2)	//JLR
		if (self.CMPR < 0) then
			self.IP = self.IP + Param1
		end
	end
	self.OpcodeTable[106] = function (Param1,Param2)	//JLER
		if (self.CMPR <= 0) then
			self.IP = self.IP + Param1
		end
	end
	self.OpcodeTable[107] = function (Param1,Param2)	//JER
		if (self.CMPR == 0) then
			self.IP = self.IP + Param1
		end
	end
	self.OpcodeTable[108] = function (Param1,Param2)	//LNEG
		return 1-math.Clamp(Param1,0,1)
	end
	self.OpcodeTable[109] = function (Param1,Param2) 	//STATERESTORE
		//self.IP = 	self:ReadCell(Param1 + 00)
				self:ReadCell(Param1 + 00)

		self.EAX = 	self:ReadCell(Param1 + 01)
		self.EBX = 	self:ReadCell(Param1 + 02)
		self.ECX = 	self:ReadCell(Param1 + 03)
		self.EDX = 	self:ReadCell(Param1 + 04)

		self.ESI = 	self:ReadCell(Param1 + 05)
		self.EDI = 	self:ReadCell(Param1 + 06)
		self.ESP = 	self:ReadCell(Param1 + 07)
		self.EBP = 	self:ReadCell(Param1 + 08)

		self.CS	= 	self:ReadCell(Param1 + 09)
		self.SS = 	self:ReadCell(Param1 + 10)
		self.DS = 	self:ReadCell(Param1 + 11)
		self.ES = 	self:ReadCell(Param1 + 12)
		self.GS = 	self:ReadCell(Param1 + 13)
		self.FS = 	self:ReadCell(Param1 + 14)

		self.CMPR = 	self:ReadCell(Param1 + 15)
	end
	//------------------------------------------------------------
	self.OpcodeTable[110] = function (Param1,Param2)	//NMIRET
		local newval

		//Interrupt data:
		newval = self:Pop() //XEIP
		newval = self:Pop() //Interrupt return EIP (FIXME: this might change, use this IP instead?)

		newval = self:Pop() if (newval) then self.IP = newval else return end
		newval = self:Pop() if (newval) then self.CMPR = newval else return end

		newval = self:Pop() if (newval) then self.EAX = newval else return end
		newval = self:Pop() if (newval) then self.EBX = newval else return end
		newval = self:Pop() if (newval) then self.ECX = newval else return end
		newval = self:Pop() if (newval) then self.EDX = newval else return end
		newval = self:Pop() if (newval) then self.EBP = newval else return end
		newval = self:Pop() if (newval) then else return end //ESP - not now
		newval = self:Pop() if (newval) then self.ESI = newval else return end
		newval = self:Pop() if (newval) then self.EDI = newval else return end

		newval = self:Pop() if (newval) then self.CS = newval else return end
		newval = self:Pop() if (newval) then else return end //SS - not now
		newval = self:Pop() if (newval) then self.DS = newval else return end
		newval = self:Pop() if (newval) then self.FS = newval else return end
		newval = self:Pop() if (newval) then self.GS = newval else return end
		newval = self:Pop() if (newval) then self.ES = newval else return end
	end
	self.OpcodeTable[111] = function (Param1,Param2)	//IDLE
		self.Idle = true
	end
	//------------------------------------------------------------
end

function ENT:PRead()
	self.TempIP = self.TempIP + 1
	return self:ReadCell(self.TempIP-1)
end

function ENT:Precompile(IP)
	self.TempIP = IP
	if (self.Debug) then
		DebugMessage("Precompiling instruction at address "..IP)
	end

	self.PrecompileData[IP] = {}
	self.PrecompileData[IP].Size = 0

	local Opcode = self:PRead()
	local RM = self:PRead()
	self.PrecompileData[IP].Size = self.PrecompileData[IP].Size + 2

	local Disp1 = 0
	local Disp2 = 0

	self.PrecompileData[IP].Valid = true
	self.PrecompileData[IP].UnknownOpcode = false

	if (Opcode == nil) || (RM == nil) then
		if (self.Debug) then Msg("Precompile failed (invalid opcode/RM)\n") end
		self.PrecompileData[IP].Valid = false
		return
	end
	
	Opcode = tonumber(Opcode)

	local dRM2 = math.floor(RM / 10000)
	local dRM1 = RM - dRM2*10000

	local Segment1 = "DS"
	local Segment2 = "DS"

	if (Opcode > 1000) then
		if (Opcode > 10000) then
			Segment2 = self:PRead() //FIXME wrong order
			self.PrecompileData[IP].Size = self.PrecompileData[IP].Size + 1

			Opcode = Opcode-10000
			if (Opcode > 1000) then
				Segment1 = self:PRead()
				self.PrecompileData[IP].Size = self.PrecompileData[IP].Size + 1

				Opcode = Opcode-1000
			end
		else
			Segment1 = self:PRead()
			self.PrecompileData[IP].Size = self.PrecompileData[IP].Size + 1

			Opcode = Opcode-1000
		end
	end

	self.PrecompileData[IP].Opcode = Opcode

	if (Segment1 == -2) then Segment1 = "CS" end
	if (Segment1 == -3) then Segment1 = "SS" end
	if (Segment1 == -4) then Segment1 = "DS" end
	if (Segment1 == -5) then Segment1 = "ES" end
	if (Segment1 == -6) then Segment1 = "GS" end
	if (Segment1 == -7) then Segment1 = "FS" end

	if (Segment2 == -2) then Segment2 = "CS" end
	if (Segment2 == -3) then Segment2 = "SS" end
	if (Segment2 == -4) then Segment2 = "DS" end
	if (Segment2 == -5) then Segment2 = "ES" end
	if (Segment2 == -6) then Segment2 = "GS" end
	if (Segment2 == -7) then Segment2 = "FS" end

	self.PrecompileData[IP].Segment1 = Segment1
	self.PrecompileData[IP].Segment2 = Segment2

	if (self.OpcodeCount[Opcode] && (self.OpcodeCount[Opcode] > 0)) then
		if (dRM1 == 0) || (dRM1 == 25) then
			self.PrecompileData[IP].PeekByte1 = self:PRead()
			self.PrecompileData[IP].Size = self.PrecompileData[IP].Size + 1

			if (self.PrecompileData[IP].PeekByte1 == nil) then
				if (self.Debug) then Msg("Precompile failed (could not peek next byte)\n") end
				self.PrecompileData[IP].Valid = false
				return
			end
		end
	end

	if (self.OpcodeCount[Opcode] && (self.OpcodeCount[Opcode] > 1)) then
		if (dRM2 == 0) || (dRM2 == 25) then
			self.PrecompileData[IP].PeekByte2 = self:PRead()
			self.PrecompileData[IP].Size = self.PrecompileData[IP].Size + 1

			if (self.PrecompileData[IP].PeekByte2 == nil) then
				if (self.Debug) then Msg("Precompile failed (could not peek next byte)\n") end
				self.PrecompileData[IP].Valid = false
				return
			end
		end
	end

	local Param1 = nil
	local Param2 = nil

	local ParamFunctions = {}
	ParamFunctions[0]  = function() return self.PrecompileData[self.XEIP].PeekByte1 end
	ParamFunctions[1]  = function() return self.EAX end
	ParamFunctions[2]  = function() return self.EBX end
	ParamFunctions[3]  = function() return self.ECX end
	ParamFunctions[4]  = function() return self.EDX end
	ParamFunctions[5]  = function() return self.ESI end
	ParamFunctions[6]  = function() return self.EDI end
	ParamFunctions[7]  = function() return self.ESP end
	ParamFunctions[8]  = function() return self.EBP end
	ParamFunctions[9]  = function() return self.CS end
	ParamFunctions[10] = function() return self.SS end
	ParamFunctions[11] = function() return self.DS end
	ParamFunctions[12] = function() return self.ES end
	ParamFunctions[13] = function() return self.GS end
	ParamFunctions[14] = function() return self.FS end

	self.PrecompileData[IP].dRM1 = dRM1
	self.PrecompileData[IP].dRM2 = dRM2

	for i=1000,2024 do
		ParamFunctions[i] = function() return self:ReadPort(self.PrecompileData[self.XEIP].dRM1-1000) end
	end

	if (self.OpcodeCount[Opcode] && (self.OpcodeCount[Opcode] > 0)) then
		ParamFunctions[17] = function() return self:ReadCell(self.EAX + self[self.PrecompileData[self.XEIP].Segment1]) end
		ParamFunctions[18] = function() return self:ReadCell(self.EBX + self[self.PrecompileData[self.XEIP].Segment1]) end
		ParamFunctions[19] = function() return self:ReadCell(self.ECX + self[self.PrecompileData[self.XEIP].Segment1]) end
		ParamFunctions[20] = function() return self:ReadCell(self.EDX + self[self.PrecompileData[self.XEIP].Segment1]) end
		ParamFunctions[21] = function() return self:ReadCell(self.ESI + self[self.PrecompileData[self.XEIP].Segment1]) end
		ParamFunctions[22] = function() return self:ReadCell(self.EDI + self[self.PrecompileData[self.XEIP].Segment1]) end
		ParamFunctions[23] = function() return self:ReadCell(self.ESP + self[self.PrecompileData[self.XEIP].Segment1]) end
		ParamFunctions[24] = function() return self:ReadCell(self.EBP + self[self.PrecompileData[self.XEIP].Segment1]) end
		ParamFunctions[25] = function() return self:ReadCell(self.PrecompileData[self.XEIP].PeekByte1 + self[self.PrecompileData[self.XEIP].Segment1]) end

		Param1 = ParamFunctions[dRM1]
		self.PrecompileData[IP].Param1 = Param1

		if (!Param1) then
			if (self.Debug) then Msg("Precompile failed (Parameter 1 calling function invalid)\n") end
			self.PrecompileData[IP].Valid = false
			return
		end
	end

	if (self.OpcodeCount[Opcode] && (self.OpcodeCount[Opcode] > 1)) then
		ParamFunctions[0]  = function() return self.PrecompileData[self.XEIP].PeekByte2 end

		ParamFunctions[17] = function() return self:ReadCell(self.EAX + self[self.PrecompileData[self.XEIP].Segment2]) end
		ParamFunctions[18] = function() return self:ReadCell(self.EBX + self[self.PrecompileData[self.XEIP].Segment2]) end
		ParamFunctions[19] = function() return self:ReadCell(self.ECX + self[self.PrecompileData[self.XEIP].Segment2]) end
		ParamFunctions[20] = function() return self:ReadCell(self.EDX + self[self.PrecompileData[self.XEIP].Segment2]) end
		ParamFunctions[21] = function() return self:ReadCell(self.ESI + self[self.PrecompileData[self.XEIP].Segment2]) end
		ParamFunctions[22] = function() return self:ReadCell(self.EDI + self[self.PrecompileData[self.XEIP].Segment2]) end
		ParamFunctions[23] = function() return self:ReadCell(self.ESP + self[self.PrecompileData[self.XEIP].Segment2]) end
		ParamFunctions[24] = function() return self:ReadCell(self.EBP + self[self.PrecompileData[self.XEIP].Segment2]) end
		ParamFunctions[25] = function() return self:ReadCell(self.PrecompileData[self.XEIP].PeekByte2 + self[self.PrecompileData[self.XEIP].Segment2]) end

		Param2 = ParamFunctions[dRM2]
		self.PrecompileData[IP].Param2 = Param2

		if (!Param2) then
			if (self.Debug) then Msg("Precompile failed (Parameter 2 calling function invalid)\n") end
			self.PrecompileData[IP].Valid = false
			return
		end
	end


	if (self.OpcodeTable[Opcode]) then
		self.PrecompileData[IP].Execute = function() //Most of magic is done here
			if (self.OpcodeTable[self.PrecompileData[self.XEIP].Opcode]) then
				if (self.PrecompileData[self.XEIP].Param1) then
					if (self.PrecompileData[self.XEIP].Param2) then
						return self.OpcodeTable[self.PrecompileData[self.XEIP].Opcode](tonumber(self.PrecompileData[self.XEIP].Param1()),tonumber(self.PrecompileData[self.XEIP].Param2()))
					else
						return self.OpcodeTable[self.PrecompileData[self.XEIP].Opcode](tonumber(self.PrecompileData[self.XEIP].Param1()),0)
					end
				else
					return self.OpcodeTable[self.PrecompileData[self.XEIP].Opcode](0,0)
				end
			else
				if (self.Debug) then Msg("Error: something gone terribly wrong, trying to call non-existing opcode ("..self.PrecompileData[self.XEIP].Opcode..") function without interrupt 4 triggered\n") end
			end
		end
	else
		if (self.Debug) then Msg("Precompile almost failed (Unknown opcode)\n") end
		self.PrecompileData[IP].UnknownOpcode = true
		self.PrecompileData[IP].Valid = false
		return
	end

	local WriteBackFunctions = {}
	WriteBackFunctions[0]  = function(Result) end
	WriteBackFunctions[1]  = function(Result) self.EAX = Result end
	WriteBackFunctions[2]  = function(Result) self.EBX = Result end
	WriteBackFunctions[3]  = function(Result) self.ECX = Result end
	WriteBackFunctions[4]  = function(Result) self.EDX = Result end
	WriteBackFunctions[5]  = function(Result) self.ESI = Result end
	WriteBackFunctions[6]  = function(Result) self.EDI = Result end
	WriteBackFunctions[7]  = function(Result) self.ESP = Result end
	WriteBackFunctions[8]  = function(Result) self.EBP = Result end
	WriteBackFunctions[9]  = function(Result) self:Interrupt(13) end
	WriteBackFunctions[10] = function(Result) self.SS = Result end
	WriteBackFunctions[11] = function(Result) self.DS = Result end
	WriteBackFunctions[12] = function(Result) self.ES = Result end
	WriteBackFunctions[13] = function(Result) self.GS = Result end
	WriteBackFunctions[14] = function(Result) self.FS = Result end

	if (self.OpcodeCount[Opcode] && (self.OpcodeCount[Opcode] > 0)) then
		WriteBackFunctions[17] = function(Result) self:WriteCell(self.EAX + self[Segment1],Result) end
		WriteBackFunctions[18] = function(Result) self:WriteCell(self.EBX + self[Segment1],Result) end
		WriteBackFunctions[19] = function(Result) self:WriteCell(self.ECX + self[Segment1],Result) end
		WriteBackFunctions[20] = function(Result) self:WriteCell(self.EDX + self[Segment1],Result) end
		WriteBackFunctions[21] = function(Result) self:WriteCell(self.ESI + self[Segment1],Result) end
		WriteBackFunctions[22] = function(Result) self:WriteCell(self.EDI + self[Segment1],Result) end
		WriteBackFunctions[23] = function(Result) self:WriteCell(self.ESP + self[Segment1],Result) end
		WriteBackFunctions[24] = function(Result) self:WriteCell(self.EBP + self[Segment1],Result) end
		WriteBackFunctions[25] = function(Result) self:WriteCell(self.PrecompileData[self.XEIP].PeekByte1 + self[Segment1],Result) end
		for i=1000,2024 do
			WriteBackFunctions[i] = function(Result) self:WritePort(self.PrecompileData[self.XEIP].dRM1-1000,Result) end
		end

		self.PrecompileData[IP].WriteBack = WriteBackFunctions[dRM1]

		if (self.PrecompileData[IP].WriteBack == nil) then
			if (self.Debug) then Msg("Precompile failed (Writeback function invalid)\n") end
			self.PrecompileData[IP].Valid = false
			return	
		end
	end

	//Second one
	if (self.OpcodeCount[Opcode] && (self.OpcodeCount[Opcode] > 1)) then
		WriteBackFunctions[17] = function(Result) self:WriteCell(self.EAX + self[Segment2],Result) end
		WriteBackFunctions[18] = function(Result) self:WriteCell(self.EBX + self[Segment2],Result) end
		WriteBackFunctions[19] = function(Result) self:WriteCell(self.ECX + self[Segment2],Result) end
		WriteBackFunctions[20] = function(Result) self:WriteCell(self.EDX + self[Segment2],Result) end
		WriteBackFunctions[21] = function(Result) self:WriteCell(self.ESI + self[Segment2],Result) end
		WriteBackFunctions[22] = function(Result) self:WriteCell(self.EDI + self[Segment2],Result) end
		WriteBackFunctions[23] = function(Result) self:WriteCell(self.ESP + self[Segment2],Result) end
		WriteBackFunctions[24] = function(Result) self:WriteCell(self.EBP + self[Segment2],Result) end
		WriteBackFunctions[25] = function(Result) self:WriteCell(self.PrecompileData[self.XEIP].PeekByte2 + self[Segment2],Result) end
		for i=1000,2024 do
			WriteBackFunctions[i] = function(Result) self:WritePort(self.PrecompileData[self.XEIP].dRM2-1000,Result) end
		end

		self.PrecompileData[IP].WriteBack2 = WriteBackFunctions[dRM2]


		if (self.PrecompileData[IP].WriteBack2 == nil) then
			if (self.Debug) then Msg("Precompile failed (Writeback2 function invalid)\n") end
			self.PrecompileData[IP].Valid = false
			return	
		end
	end

	if (self.Debug) then Msg("Precompile successful\n") end
end

function ENT:PrintState()
	Msg("TMR="..self.TMR.."  TIMER="..self.TIMER.."  XEIP="..self.XEIP.."  CMPR="..self.CMPR.."\n")
	Msg("EAX="..self.EAX.."  EBX="..self.EBX.."  ECX="..self.ECX.."  EDX="..self.EDX.."\n")
	Msg("ESI="..self.ESI.."  EDI="..self.EDI.."  ESP="..self.ESP.."  EBP="..self.EBP.."\n")
end

function ENT:Execute()
	self.DeltaTime = CurTime()-(self.PrevTime or CurTime())
	self.PrevTime = (self.PrevTime or CurTime())+self.DeltaTime

	self.TIMER = self.TIMER + self.DeltaTime
	self.TMR = self.TMR + 1

	if (!self.IP) then
		self:Reset()
		Wire_TriggerOutput(self.Entity, "Error", 5.0)
		return
	end

	self.XEIP = self.IP

	if (self.NextIF) then
		self.IF = self.NextIF
		self.NextIF = nil
	end

	if (self.Debug) then
		DebugMessage("CPU EXECUTION STEP")
	end

	//Dynamic precompiler: check if opcode was precompiled
	if (self.PrecompileData[self.XEIP]) then
		self.ILTC = self.PrecompileData[self.XEIP].Opcode

		//Simulate read
		self.IP = self.IP + self.PrecompileData[self.XEIP].Size

		//Verify opcode
		if (self.PrecompileData[self.XEIP].Valid) then
			//Execute
			local Result = self.PrecompileData[self.XEIP].Execute()
			if (Result) then
				self.PrecompileData[self.XEIP].WriteBack(Result)
			end
		else
			if (self.PrecompileData[self.XEIP].UnknownOpcode) then
				self:Interrupt(4) //Unknown Opcode
			else
				self:Interrupt(5) //Internal/opcode read error
			end
		end
	else
		self:Precompile(self.IP)
	end

	if (self.Debug) then
		if (!self.INTR) then
			DebugMessage("")
		end
		self:PrintState()
		if (self.DebugData[self.XEIP]) then
			print("")
			if (self.DebugLines[self.DebugData[self.XEIP]-2]) then
				Msg(self.DebugLines[self.DebugData[self.XEIP]-2].."\n")
			end
			if (self.DebugLines[self.DebugData[self.XEIP]-1]) then
				Msg(self.DebugLines[self.DebugData[self.XEIP]-1].."\n")
			end
			if (self.DebugLines[self.DebugData[self.XEIP]]) then
				print(self.DebugLines[self.DebugData[self.XEIP]])
			end
			if (self.DebugLines[self.DebugData[self.XEIP]+1]) then
				Msg(self.DebugLines[self.DebugData[self.XEIP]+1].."\n")
			end
			if (self.DebugLines[self.DebugData[self.XEIP]+2]) then
				Msg(self.DebugLines[self.DebugData[self.XEIP]+2].."\n")
			end
			print("")
		end
	end

	self.INTR = false
end

function ENT:Use()
end

function ENT:Think()
	local Iterations = self.ThinkTime*0.5
	while (Iterations > 0) && (self.Clk >= 1.0) && (!self.Idle) do
		self:Execute()
		Iterations = Iterations - 1
	end

	if (self.Idle) then
		self.Idle = false
	end

	if (self.Clk >= 1.0) then
		self.Entity:NextThink(CurTime()+0.01)
	end
	return true
end

function ENT:TriggerInput(iname, value)
	if (iname == "Clk") then
		self.Clk = value
		self.InputClk = value
		self.PrevTime = CurTime()

		self.Entity:NextThink(CurTime())
	elseif (iname == "Frequency") then
		if (!SinglePlayer() && (value > 20000)) then 
			self.ThinkTime = 200 
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
			if ((self.Clk >= 1.0) && (self.IF == 1) &&
			    self:Push(self.ES) && 
			    self:Push(self.GS) && 
    			    self:Push(self.FS) && 
    			    self:Push(self.DS) && 
			    self:Push(self.SS) && 
			    self:Push(self.CS) && 

			    self:Push(self.EDI) && 
			    self:Push(self.ESI) && 
			    self:Push(self.ESP) && 
			    self:Push(self.EBP) && 
			    self:Push(self.EDX) && 
			    self:Push(self.ECX) && 
			    self:Push(self.EBX) && 
			    self:Push(self.EAX) && 

			    self:Push(self.CMPR) && 
			    self:Push(self.IP)) then
				self:Interrupt(math.floor(value))
			end
		end
	end
end
