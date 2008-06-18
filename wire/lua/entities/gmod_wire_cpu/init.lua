AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')
include('compiler_asm.lua')

ENT.WireDebugName = "CPU"

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self.Entity, { "MemBus", "IOBus", "Frequency", "Clk", "Reset", "NMI"})
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Error" }) 

	self.Memory = {}
	for i = 0, 65535 do
		self.Memory[i] = 0
	end

	self.ROMMemory = {}
	for i = 0, 65535 do
		self.ROMMemory[i] = 0
	end

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

	//Execution "local" vars
	self.DeltaTime = 0
	self.Opcode = 0
	self.RM = 0
	self.Params = {0, 0}
	self.Result = 0
	self.dRM2 = 0
	self.dRM1 = 0
	self.Segment1 = 0
	self.Segment2 = 0
	self.WriteBack = false

	self.Disp1 = 0
	self.Disp2 = 0

	self.ThinkTime = (1000)/100
	self.PrevTime = CurTime()
	self.CPUCyclesLeft = 0

	self:SetOverlayText("CPU")
	self:InitializeOpcodeTable()
	self:InitASMOpcodes()
end

function ENT:CPUID_Version()
	local SVNString = "$Revision: 532 $"

	return tonumber(string.sub(SVNString,12,14))
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
	self.IF = true
	self.PF = false

	self.Debug = false
	
	self.CMPR = 0
	self.ILTC = 0
	self.XEIP = 0
	self.LADD = 0
	self.INTR = false
	self.TMR = 0
	self.TIMER = 0

	self.Clk = self.InputClk

	self.HaltPort = -1

	if (self.UseROM) then
		for i = 0, 65535 do
			self.Memory[i] = self.ROMMemory[i]
		end
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

function ENT:Interrupt( intnumber )
	if ( self.Compiling ) then
		self.FatalError = true
		return
	end
	if (self.Debug) then
		Msg("INTERRUPT: "..intnumber.." AT "..self.XEIP.." LADD="..self.LADD.." ILTC="..self.ILTC.."\n")
	end
	if ( self.INTR ) then
		return
	end
	self.INTR = true
	if ( intnumber <= 1 ) or ( intnumber > 255) then
		self:Reset()
		self.EAX = 10
		if (intnumber == 1) then
			self.Clk = 0
		end
		return
	end
	Wire_TriggerOutput(self.Entity, "Error", intnumber)
	if (self.IF) then
		if (self.PF == false) then
			self.Clk = 0
			return
		else
			local intaddress = self.IDTR + intnumber*2
			if (intaddress > 65535) then intaddress = 65535 end
			if (intaddress < 0) then intaddress = 0 end
			local intoffset = self.Memory[intaddress]
			local intprops = self.Memory[intaddress+1]
			if (intprops ~= 0) then //Interrupt active, temp fix
				self.INTR = false
				if ( intnumber == 4 ) || 
				   ( intnumber == 7 ) || 
				   ( intnumber == 9 ) || 
				   ( intnumber == 10) then
					self:Push(self.LADD)
				end
				if ( intnumber == 4 ) ||
				   ( intnumber == 31 ) then //If wrong opcode or debug trap, then store data
					self:Push(self.ILTC)
				end
				if self:Push(self.IP) then //Store IRET
					self:Push(self.XEIP)
					self.IP = intoffset
				end
				self.INTR = true
			end
		end
	end
end

function ENT:Write( value )
	if (value) then
		if (!tonumber(value)) then
			self.Memory[self.WIP] = 0
			self.WIP = self.WIP + 1
			return
		end
		if (self.UseROM) then
			if (self.WIP < 65536) then
				self.ROMMemory[self.WIP] = value
			end
		else
			self.Memory[self.WIP] = value
			//self:WriteCell(self.WIP,value)
		end
		if (self.Debug) then
			//Msg("-> ZyeliosASM: Wrote "..value.." at ["..self.WIP.."]\n")
		end

		self.WIP = self.WIP + 1
	end
end

function ENT:Read( )
	if (self.INTR) then //Lock the bus & eip
		if (self.Debug) then
			Msg("BUS READ WHILE LOCKED\n")
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

function ENT:ReadCell( Address )
	if (self.INTR) then //Lock the bus
		return nil
	end

	if (Address < 0) then
		return self:ReadPort(-Address-1)
	end
	if (Address < 65536) then
		return self.Memory[math.floor(Address)]
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

function ENT:WriteCell( Address, value )
	if (self.INTR) then //Lock the bus
		return nil
	end

	if (Address < 0) then
		//self.LADD = math.floor(Address)
		//self:Interrupt(8)
		//return false
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

function ENT:ReadPort( Address )
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

function ENT:WritePort( Address, value )
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

	self.OpcodeTable[0] = function ()	//END
		self:Interrupt(2)
	end
	self.OpcodeTable[1] = function ()	//JNE
		if (self.CMPR ~= 0) then
			self.IP = self.Params[1]
		end
		self.WriteBack = false
	end
	self.OpcodeTable[2] = function ()	//JMP
		self.IP = self.Params[1]
		self.WriteBack = false
	end
	self.OpcodeTable[3] = function ()	//JG
		if (self.CMPR > 0) then
			self.IP = self.Params[1]
		end
		self.WriteBack = false
	end
	self.OpcodeTable[4] = function ()	//JGE
		if (self.CMPR >= 0) then
			self.IP = self.Params[1]
		end
		self.WriteBack = false
	end
	self.OpcodeTable[5] = function ()	//JL
		if (self.CMPR < 0) then
			self.IP = self.Params[1]
		end
		self.WriteBack = false
	end
	self.OpcodeTable[6] = function ()	//JLE
		if (self.CMPR <= 0) then
			self.IP = self.Params[1]
		end
		self.WriteBack = false
	end
	self.OpcodeTable[7] = function ()	//JE
		if (self.CMPR == 0) then
			self.IP = self.Params[1]
		end
		self.WriteBack = false
	end
	//============================================================
	self.OpcodeTable[8] = function ()	//CPUID
		if (self.Params[1] == 0) then 		//CPU REVISION/VERSION
			self.EAX = self:CPUID_Version()	//= 3.00 BETA 2
		elseif (self.Params[1] == 1) then	//AMOUNT OF RAM
			self.EAX = 65536		//= 64KB
		elseif (self.Params[1] == 2) then	//TYPE (0 - ZCPU; 1 - ZGPU)
			self.EAX = 0			//= ZCPU
		else
			self.EAX = 0
		end
		self.WriteBack = false
	end
	//============================================================
	self.OpcodeTable[9] = function ()	//PUSH
		//self.Memory[ESP] = self.Params[1]
		self:Push(self.Params[1])
		self.WriteBack = false
	end
	//------------------------------------------------------------
	self.OpcodeTable[10] = function ()	//ADD
		self.Result = self.Params[1] + self.Params[2]
	end
	self.OpcodeTable[11] = function ()	//SUB
		self.Result = self.Params[1] - self.Params[2]
	end
	self.OpcodeTable[12] = function ()	//MUL
		self.Result = self.Params[1] * self.Params[2]
	end
	self.OpcodeTable[13] = function ()	//DIV
		if (math.abs(self.Params[2]) < 0.0000000001) then
			self:Interrupt(3)
		else
			self.Result = self.Params[1] / self.Params[2]
		end
	end
	self.OpcodeTable[14] = function () 	//MOV
		self.Result = self.Params[2]
	end
	self.OpcodeTable[15] = function ()	//CMP
		self.CMPR = self.Params[1] - self.Params[2]
		self.WriteBack = false
	end
	self.OpcodeTable[16] = function ()	//RD
		self.Result = self.Memory[self.Params[2]]
	end
	self.OpcodeTable[17] = function ()	//WD
		self.Memory[self.Params[1]] = self.Params[2]
		self.WriteBack = false
	end
	self.OpcodeTable[18] = function ()	//MIN
		if (tonumber(self.Params[2]) < tonumber(self.Params[1])) then
			self.Result = self.Params[2]
		else
			self.Result = self.Params[1]
		end
	end
	self.OpcodeTable[19] = function ()	//MAX
		if (tonumber(self.Params[2]) > tonumber(self.Params[1])) then
			self.Result = self.Params[2]
		else
			self.Result = self.Params[1]
		end
	end
	//------------------------------------------------------------
	self.OpcodeTable[20] = function ()	//INC
		self.Result = self.Params[1] + 1		
	end
	self.OpcodeTable[21] = function ()	//DEC
		self.Result = self.Params[1] - 1
	end
	self.OpcodeTable[22] = function ()	//NEG
		self.Result = -self.Params[1]
	end
	self.OpcodeTable[23] = function ()	//RAND
		self.Result = math.random()
	end
	self.OpcodeTable[24] = function ()	//LOOP
		if (self.ECX ~= 0) then
			self.IP = self.Params[1]
			self.ECX = self.ECX-1
		end
		self.WriteBack = false
	end
	self.OpcodeTable[25] = function ()	//LOOPA
		if (self.EAX ~= 0) then
			self.IP = self.Params[1]
			self.EAX = self.EAX-1
		end
		self.WriteBack = false
	end
	self.OpcodeTable[26] = function ()	//LOOPB
		if (self.EBX ~= 0) then
			self.IP = self.Params[1]
			self.EBX = self.EBX-1
		end
		self.WriteBack = false
	end
	self.OpcodeTable[27] = function ()	//LOOPD
		if (self.EDX ~= 0) then
			self.IP = self.Params[1]
			self.EDX = self.EDX-1
		end
		self.WriteBack = false
	end
	self.OpcodeTable[28] = function ()	//SPG
		if (math.floor(self.Params[1] / 128) >= 0) && (math.floor(self.Params[1] / 128) < 512) then
			Page[math.floor(self.Params[1] / 128)] = false
		else
			self:Interrupt(12)
		end
		self.WriteBack = false
	end
	self.OpcodeTable[29] = function ()	//CPG
		if (math.floor(self.Params[1] / 128) >= 0) && (math.floor(self.Params[1] / 128) < 512) then
			Page[math.floor(self.Params[1] / 128)] = true
		else
			self:Interrupt(12)
		end
		self.WriteBack = false
	end
	//------------------------------------------------------------
	self.OpcodeTable[30] = function ()	//POP
		self.Result = self:Pop()
	end
	self.OpcodeTable[31] = function ()	//CALL
		if self:Push(self.IP) then
			self.IP = self.Params[1]
		end
		self.WriteBack = false
	end
	self.OpcodeTable[32] = function ()	//NOT
		if self.Params[1] <= 0 then
			self.Result = 1
		else
			self.Result = 0
		end
	end
	self.OpcodeTable[33] = function ()	//FINT
		self.Result = math.floor(self.Params[1])
	end
	self.OpcodeTable[34] = function ()	//RND
		self.Result = math.Round(self.Params[1])
	end
	self.OpcodeTable[35] = function ()	//FLOOR
		self.Result = self.Params[1] - math.floor(self.Params[1])
	end
	self.OpcodeTable[36] = function ()	//INV
		if (math.abs(self.Params[1]) < 0.0000000001) then
			self:Interrupt(3)
		else
			self.Result = 1 / self.Params[1]
		end
	end
	self.OpcodeTable[37] = function ()	//HALT
		self.HaltPort = math.Clamp(math.floor(self.Params[1]),0,7)
		self.WriteBack = false
	end
	self.OpcodeTable[38] = function ()	//FSHL
		self.Result = math.floor(self.Params[1] * 2)
	end
	self.OpcodeTable[39] = function ()	//FSHR
		self.Result = math.floor(self.Params[1] / 2)
	end
	//------------------------------------------------------------
	self.OpcodeTable[40] = function ()	//RET
		local newIP = self:Pop()
		if (newIP) then
			self.IP = newIP
		end
		self.WriteBack = false
	end
	self.OpcodeTable[41] = function ()	//IRET
		local newIP = self:Pop()
		if (newIP) then
			self.IP = newIP
		end
		self.WriteBack = false
	end
	self.OpcodeTable[42] = function ()	//STI
		self.IF = true
		self.WriteBack = false
	end
	self.OpcodeTable[43] = function ()	//CLI
		self.IF = false
		self.WriteBack = false
	end
	self.OpcodeTable[44] = function ()	//STP
		self.PF = true
		self.WriteBack = false
	end
	self.OpcodeTable[45] = function ()	//CLP
		self.PF = false
		self.WriteBack = false
	end
	self.OpcodeTable[46] = function ()	//STD
		//self.Debug = true
		self.WriteBack = false
	end
	self.OpcodeTable[47] = function ()	//RETF
		local newIP = self:Pop()
		local newCS = self:Pop()
		if (newIP) && (newCS) then
			self.IP = newIP
			self.CS = newCS
		end
		self.WriteBack = false
	end
	self.OpcodeTable[48] = function ()	//RCMPR
		self.EAX = self.CMPR
		self.WriteBack = false
	end
	self.OpcodeTable[49] = function ()	//TMR
		self.EAX = self.TMR
		self.WriteBack = false
	end
	//------------------------------------------------------------
	self.OpcodeTable[50] = function ()	//AND
		if (self.Params[1] > 0) && (self.Params[2] > 0) then
			self.Result = 1
		else
			self.Result = 0
		end
	end
	self.OpcodeTable[51] = function ()	//OR
		if (self.Params[1] > 0) || (self.Params[2] > 0) then
			self.Result = 1
		else
			self.Result = 0
		end
	end
	self.OpcodeTable[52] = function ()	//XOR
		if ((self.Params[1] > 0) && (self.Params[2] <= 0)) ||
		   ((self.Params[1] <= 0) && (self.Params[2] > 0)) then
			self.Result = 1
		else
			self.Result = 0
		end
	end
	self.OpcodeTable[53] = function ()	//FSIN
		self.Result = math.sin(self.Params[2])
	end
	self.OpcodeTable[54] = function ()	//FCOS
		self.Result = math.cos(self.Params[2])
	end
	self.OpcodeTable[55] = function ()	//FTAN
		self.Result = math.tan(self.Params[2])
	end
	self.OpcodeTable[56] = function ()	//FASIN
		self.Result = math.asin(self.Params[2])
	end
	self.OpcodeTable[57] = function ()	//FACOS
		self.Result = math.acos(self.Params[2])
	end
	self.OpcodeTable[58] = function ()	//FATAN
		self.Result = math.atan(self.Params[2])
	end
	self.OpcodeTable[59] = function ()	//MOD
		self.Result = math.fmod(self.Params[1],self.Params[2])
	end
	//------------------------------------------------------------
	self.OpcodeTable[60] = function ()	//BIT
		local temp = self.Params[1]
		for i = 0,math.Clamp(self.Params[2],0,7)-1 do
			temp = math.floor(temp / 10)
		end
		self.CMPR = math.fmod(temp,10)
		self.WriteBack = false
	end
	self.OpcodeTable[61] = function ()	//SBIT
		local temp = self.Params[1]
		local temp2 = 0
		local temp3 = 1
		for i = 0,7 do
			if (i == self.Params[2]) then
				temp2 = temp2 + temp3*1
			else
				temp2 = temp2 + temp3*math.fmod(temp,10)
			end
			temp = math.floor(temp / 10)
			temp3 = temp3*10
		end
		self.Result = temp2
	end
	self.OpcodeTable[62] = function ()	//CBIT
		local temp = self.Params[1]
		local temp2 = 0
		local temp3 = 1
		for i = 0,7 do
			if (i == self.Params[2]) then
				temp2 = temp2 + temp3*0
			else
				temp2 = temp2 + temp3*math.fmod(temp,10)
			end
			temp = math.floor(temp / 10)
			temp3 = temp3*10
		end
		self.Result = temp2
	end
	self.OpcodeTable[69] = function ()	//JMPF
		self.CS = self.Params[2]
		self.IP = self.Params[1]
		self.WriteBack = false
	end
	//------------------------------------------------------------
	self.OpcodeTable[71] = function ()	//CNE
		if (self.CMPR ~= 0) then
			if self:Push(self.IP) then
				self.IP = self.Params[1]
			end
		end
		self.WriteBack = false
	end
	self.OpcodeTable[72] = function ()	//CJMP
		if self:Push(self.IP) then
			self.IP = self.Params[1]
		end
		self.WriteBack = false
	end
	self.OpcodeTable[73] = function ()	//CG
		if (self.CMPR > 0) then
			if self:Push(self.IP) then
				self.IP = self.Params[1]
			end
		end
		self.WriteBack = false
	end
	self.OpcodeTable[74] = function ()	//CGE
		if (self.CMPR >= 0) then
			if self:Push(self.IP) then
				self.IP = self.Params[1]
			end
		end
		self.WriteBack = false
	end
	self.OpcodeTable[75] = function ()	//CL
		if (self.CMPR < 0) then
			if self:Push(self.IP) then
				self.IP = self.Params[1]
			end
		end
		self.WriteBack = false
	end
	self.OpcodeTable[76] = function ()	//CLE
		if (self.CMPR <= 0) then
			if self:Push(self.IP) then
				self.IP = self.Params[1]
			end
		end
		self.WriteBack = false
	end
	self.OpcodeTable[77] = function ()	//CE
		if (self.CMPR == 0) then
			if self:Push(self.IP) then
				self.IP = self.Params[1]
			end
		end
		self.WriteBack = false
	end
	self.OpcodeTable[78] = function ()	//MCOPY
		if (self.Params[1] == 0) then return end
		for i = 1,math.Clamp(self.Params[1],1,8192) do
			local val
			val = self:ReadCell(self.ESI+self.Segment1)
			if (val == nil) then return end
			if (self:WriteCell(self.EDI+self.Segment2,val) == false) then return end
			self.EDI = self.EDI + 1
			self.ESI = self.ESI + 1
		end
		self.WriteBack = false
	end
	self.OpcodeTable[79] = function ()	//MXCHG
		if (self.Params[1] == 0) then return end
		for i = 1,math.Clamp(self.Params[1],1,8192) do
			local val
			val1 = self:ReadCell(self.ESI+self.Segment1)
			val2 = self:ReadCell(self.EDI+self.Segment2)
			if (val1 == nil) || (val2 == nil) then return end
			if (self:WriteCell(self.EDI+self.Segment2,val1) == false) || (self:WriteCell(self.ESI+self.Segment1,val2) == false) then return end
			self.EDI = self.EDI + 1
			self.ESI = self.ESI + 1
		end
		self.WriteBack = false
	end
	//------------------------------------------------------------
	self.OpcodeTable[80] = function ()	//FPWR
		self.Result = self.Params[1]^self.Params[2]
	end
	self.OpcodeTable[81] = function ()	//XCHG
		local val1 = self.Params[2]
		local val2 = self.Params[1]

		self.Result = val1
		if (self.dRM2 == 1) then self.EAX = val2
		elseif (self.dRM2 == 2) then	self.EBX = val2
		elseif (self.dRM2 == 3) then	self.ECX = val2
		elseif (self.dRM2 == 4) then	self.EDX = val2
		elseif (self.dRM2 == 5) then	self.ESI = val2
		elseif (self.dRM2 == 6) then	self.EDI = val2
		elseif (self.dRM2 == 7) then	self.ESP = val2
		elseif (self.dRM2 == 8) then	self.EBP = val2
		elseif (self.dRM2 == 9)  then self:Interrupt(13)
		elseif (self.dRM2 == 10) then self.SS = val2
		elseif (self.dRM2 == 11) then self.DS = val2
		elseif (self.dRM2 == 12) then self.ES = val2
		elseif (self.dRM2 == 13) then self.GS = val2
		elseif (self.dRM2 == 14) then self.FS = val2
		elseif (self.dRM2 >= 17) && (self.dRM2 <= 25) then
			self:WriteCell(self.Disp2+self.Segment2,val2)
		elseif (self.dRM2 >= 1000) && (self.dRM2 <= 2024) then
			self:WritePort(self.dRM2-1000,val2)
		end
	end
	self.OpcodeTable[82] = function ()	//FLOG
		self.Result = math.log(self.Params[2])
	end
	self.OpcodeTable[83] = function ()	//FLOG10
		self.Result = math.log10(self.Params[2])
	end
	self.OpcodeTable[84] = function ()	//IN
		self.Result = self:ReadPort(self.Params[2])
	end
	self.OpcodeTable[85] = function ()	//OUT
		self:WritePort(self.Params[1],self.Params[2])
		self.WriteBack = false
	end
	self.OpcodeTable[86] = function ()	//FABS
		self.Result = math.abs(self.Params[2])
	end
	self.OpcodeTable[87] = function ()	//FSGN
		if (self.Params[2] > 0) then
			self.Result = 1
		elseif (self.Params[2] < 0) then
			self.Result = -1
		else
			self.Result = 0
		end
	end
	self.OpcodeTable[88] = function ()	//FEXP
		self.Result = math.exp(self.Params[2])
	end
	self.OpcodeTable[89] = function ()	//CALLF
		if self:Push(self.CS) && self:Push(self.IP)  then
			self.IP = self.Params[1]
			self.CS = self.Params[2]
		end
		self.WriteBack = false
	end
	//------------------------------------------------------------
	self.OpcodeTable[90] = function () //FPI
		self.Result = 3.141592653589793
	end
	self.OpcodeTable[91] = function () //FE
		self.Result = 2.718281828459045
	end
	self.OpcodeTable[92] = function ()	//INT
		self:Interrupt(tonumber(self.Params[1]))
		self.WriteBack = false
	end
	self.OpcodeTable[93] = function ()	//TPG
		local tadd = self.Params[1]*128
		self.CMPR = 0
		while (tadd < self.Params[1]*128+128) do
			local val = self:ReadCell(tadd)
			if (val == nil) then
				self.CMPR = tadd
				tadd = self.Params[1]*128+128
			end
			tadd = tadd + 1
		end
		self.WriteBack = false
	end
	self.OpcodeTable[94] = function ()	//FCEIL
		self.Result = math.ceil(self.Params[1])
	end
	self.OpcodeTable[95] = function () //ERPG
		if (self.Params[1] >= 0) && (self.Params[1] < 512) then
			local tadd = self.Params[1]*128
			while (tadd < self.Params[1]*128+128) do
				self.ROMMemory[tadd] = 0
				tadd = tadd + 1
			end
		else
			self:Interrupt(12)
		end
		self.WriteBack = false
	end
	self.OpcodeTable[96] = function ()	//WRPG
		if (self.Params[1] >= 0) && (self.Params[1] < 512) then
			local tadd = self.Params[1]*128
			while (tadd < self.Params[1]*128+128) do
				self.ROMMemory[tadd] = self.Memory[tadd]
				tadd = tadd + 1
			end
		else
			self:Interrupt(12)
		end
		self.WriteBack = false
	end
	self.OpcodeTable[97] = function () //RDPG
		if (self.Params[1] >= 0) && (self.Params[1] < 512) then
			local tadd = self.Params[1]*128
			while (tadd < self.Params[1]*128+128) do
				self.Memory[tadd] = self.ROMMemory[tadd]
				tadd = tadd + 1
			end
		else
			self:Interrupt(12)
		end
		self.WriteBack = false
	end
	self.OpcodeTable[98] = function ()	//TIMER
		self.Result = self.TIMER
	end
	self.OpcodeTable[99] = function ()	//LIDTR
		self.IDTR = self.Params[1]
		self.WriteBack = false
	end
	//------------------------------------------------------------
	self.OpcodeTable[101] = function () 	//JNER
		if (self.CMPR ~= 0) then
			self.IP = self.IP + self.Params[1]
		end
		self.WriteBack = false
	end
	self.OpcodeTable[102] = function ()	//JMPR
		self.IP = self.IP + self.Params[1]
		self.WriteBack = false
	end
	self.OpcodeTable[103] = function ()	//JGR
		if (self.CMPR > 0) then
			self.IP = self.IP + self.Params[1]
		end
		self.WriteBack = false
	end
	self.OpcodeTable[104] = function ()	//JGER
		if (self.CMPR >= 0) then
			self.IP = self.IP + self.Params[1]
		end
		self.WriteBack = false
	end
	self.OpcodeTable[105] = function ()	//JLR
		if (self.CMPR < 0) then
			self.IP = self.IP + self.Params[1]
		end
		self.WriteBack = false
	end
	self.OpcodeTable[106] = function ()	//JLER
		if (self.CMPR <= 0) then
			self.IP = self.IP + self.Params[1]
		end
		self.WriteBack = false
	end
	self.OpcodeTable[107] = function ()	//JER
		if (self.CMPR == 0) then
			self.IP = self.IP + self.Params[1]
		end
		self.WriteBack = false
	end
	self.OpcodeTable[108] = function ()	//LNEG
		self.Result = 1-math.Clamp(self.Params[1],0,1)
	end
	//------------------------------------------------------------
	self.OpcodeTable[110] = function ()	//NMIRET
		local newval
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

		self.WriteBack = false
	end
	//------------------------------------------------------------
end

function ENT:Execute( )
	self.DeltaTime = CurTime()-(self.PrevTime or CurTime())
	self.PrevTime = (self.PrevTime or CurTime())+self.DeltaTime

	self.TIMER = self.TIMER + self.DeltaTime
	self.TMR = self.TMR + 1
	if (self.Debug) then
		Msg(">TMR="..self.TMR.." IP="..self.IP.." ");
	end
	
	if (!self.IP) then
		self:Reset()
		Wire_TriggerOutput(self.Entity, "Error", 5.0)
		return
	end

	self.XEIP = self.IP
	self.Opcode = self:Read( )
	self.RM = self:Read( )
	self.Params = {0, 0}
	self.Result = 0

	if (self.Opcode) then
		self.ILTC = self.Opcode
	else
		self.ILTC = -1
	end

	self.Disp1 = 0
	self.Disp2 = 0

	if (self.Opcode == nil) || (self.RM == nil) then
		self.INTR = false
		return
	end

	if (self.Debug) then
		Msg("OPCODE="..self.Opcode.." RM="..self.RM.." ");
	end

	self.Opcode = self.Opcode + 1 - 1 //Dont laugh, it helps

	self.dRM2 = math.floor(self.RM / 10000)
	self.dRM1 = self.RM - self.dRM2*10000

	self.Segment1 = self.DS
	self.Segment2 = self.DS

	//Fix problem here (the lua buttfux one):
	if (self.Opcode > 1000) then
		if (self.Opcode > 10000) then
			self.Segment2 = self:Read() //FIXME wrong order
			self.Opcode = self.Opcode-10000
			if (self.Opcode > 1000) then
				self.Segment1 = self:Read()
				self.Opcode = self.Opcode-1000
			end
		else
			self.Segment1 = self:Read()
			self.Opcode = self.Opcode-1000
		end
	end


	//if (self.Debug) then
	//	Msg("OPCODE2="..opcode.." S1="..segment1.." S2="..segment2.." ");
	//end

	if (self.Segment1 == -2) then self.Segment1 = self.CS end
	if (self.Segment1 == -3) then self.Segment1 = self.SS end
	if (self.Segment1 == -4) then self.Segment1 = self.DS end
	if (self.Segment1 == -5) then self.Segment1 = self.ES end
	if (self.Segment1 == -6) then self.Segment1 = self.GS end
	if (self.Segment1 == -7) then self.Segment1 = self.FS end
	if (self.Segment2 == -2) then self.Segment2 = self.CS end
	if (self.Segment2 == -3) then self.Segment2 = self.SS end
	if (self.Segment2 == -4) then self.Segment2 = self.DS end
	if (self.Segment2 == -5) then self.Segment2 = self.ES end
	if (self.Segment2 == -6) then self.Segment2 = self.GS end
	if (self.Segment2 == -7) then self.Segment2 = self.FS end

	if (self.OpcodeCount[self.Opcode] && (self.OpcodeCount[self.Opcode] > 0)) then
		    if (self.dRM1 == 0)  then self.Params[1] = self:Read( )
		elseif (self.dRM1 == 1)  then self.Params[1] = self.EAX
		elseif (self.dRM1 == 2)  then self.Params[1] = self.EBX
		elseif (self.dRM1 == 3)  then self.Params[1] = self.ECX
		elseif (self.dRM1 == 4)  then self.Params[1] = self.EDX
		elseif (self.dRM1 == 5)  then self.Params[1] = self.ESI
		elseif (self.dRM1 == 6)  then self.Params[1] = self.EDI
		elseif (self.dRM1 == 7)  then self.Params[1] = self.ESP
		elseif (self.dRM1 == 8)  then self.Params[1] = self.EBP
		elseif (self.dRM1 == 9)  then self.Params[1] = self.CS
		elseif (self.dRM1 == 10) then self.Params[1] = self.SS
		elseif (self.dRM1 == 11) then self.Params[1] = self.DS
		elseif (self.dRM1 == 12) then self.Params[1] = self.ES
		elseif (self.dRM1 == 13) then self.Params[1] = self.GS
		elseif (self.dRM1 == 14) then self.Params[1] = self.FS
		elseif (self.dRM1 == 17) then self.Disp1     = math.floor(self.EAX)
		elseif (self.dRM1 == 18) then self.Disp1     = math.floor(self.EBX)
		elseif (self.dRM1 == 19) then self.Disp1     = math.floor(self.ECX)
		elseif (self.dRM1 == 20) then self.Disp1     = math.floor(self.EDX)
		elseif (self.dRM1 == 21) then self.Disp1     = math.floor(self.ESI)
		elseif (self.dRM1 == 22) then self.Disp1     = math.floor(self.EDI)
		elseif (self.dRM1 == 23) then self.Disp1     = math.floor(self.ESP)
		elseif (self.dRM1 == 24) then self.Disp1     = math.floor(self.EBP)
		elseif (self.dRM1 == 25) then
			local addr = self:Read( )
			if (addr ~= nil) and (tonumber(addr)) then self.Disp1 = math.floor(addr) end
		end
		if (self.dRM1 >= 17) && (self.dRM1 <= 25) then
			self.Params[1] = self:ReadCell(self.Disp1+self.Segment1)
		end
		if (self.dRM1 >= 1000) && (self.dRM1 <= 2024) then
			self.Params[1] = self:ReadPort(self.dRM1-1000)
		end
	end
	if (self.OpcodeCount[self.Opcode] && (self.OpcodeCount[self.Opcode] > 1)) then
		    if (self.dRM2 == 0)  then self.Params[2] = self:Read( )
		elseif (self.dRM2 == 1)  then self.Params[2] = self.EAX
		elseif (self.dRM2 == 2)  then self.Params[2] = self.EBX
		elseif (self.dRM2 == 3)  then self.Params[2] = self.ECX
		elseif (self.dRM2 == 4)  then self.Params[2] = self.EDX
		elseif (self.dRM2 == 5)  then self.Params[2] = self.ESI
		elseif (self.dRM2 == 6)  then self.Params[2] = self.EDI
		elseif (self.dRM2 == 7)  then self.Params[2] = self.ESP
		elseif (self.dRM2 == 8)  then self.Params[2] = self.EBP
		elseif (self.dRM2 == 9)  then self.Params[2] = self.CS
		elseif (self.dRM2 == 10) then self.Params[2] = self.SS
		elseif (self.dRM2 == 11) then self.Params[2] = self.DS
		elseif (self.dRM2 == 12) then self.Params[2] = self.ES
		elseif (self.dRM2 == 13) then self.Params[2] = self.GS
		elseif (self.dRM2 == 14) then self.Params[2] = self.FS
		elseif (self.dRM2 == 17) then self.Disp2     = math.floor(self.EAX)
		elseif (self.dRM2 == 18) then self.Disp2     = math.floor(self.EBX)
		elseif (self.dRM2 == 19) then self.Disp2     = math.floor(self.ECX)
		elseif (self.dRM2 == 20) then self.Disp2     = math.floor(self.EDX)
		elseif (self.dRM2 == 21) then self.Disp2     = math.floor(self.ESI)
		elseif (self.dRM2 == 22) then self.Disp2     = math.floor(self.EDI)
		elseif (self.dRM2 == 23) then self.Disp2     = math.floor(self.ESP)
		elseif (self.dRM2 == 24) then self.Disp2     = math.floor(self.EBP)
		elseif (self.dRM2 == 25) then
			local addr = self:Read( )
			if (addr ~= nil) and (tonumber(addr)) then self.Disp2 = math.floor(addr) end
		end
		if (self.dRM2 >= 17) && (self.dRM2 <= 25) then
			self.Params[2] = self:ReadCell(self.Disp2+self.Segment2)
		end
		if (self.dRM2 >= 1000) && (self.dRM2 <= 2024) then
			self.Params[2] = self:ReadPort(self.dRM2-1000)
		end
	end

	if (self.Debug) then
		if (self.Params[1] && self.Params[2]) then
			Msg("PARAMS1="..self.Params[1].." PARAMS2="..self.Params[2].."\n");
		end
	end

	if (self.Params[1]) then
		self.Params[1] = tonumber(self.Params[1])
	end
	if (self.Params[2]) then
		self.Params[2] = tonumber(self.Params[2])
	end

	if (!self.Params[1]) then
		self:Interrupt(5)
		return
	end
	if (!self.Params[2]) then
		self:Interrupt(5)
		return
	end

	if (self.INTR) then
		self.INTR = false
		return
	end

	self.WriteBack = true

	if (self.OpcodeTable[self.Opcode]) then self.OpcodeTable[self.Opcode]()
	else self:Interrupt(4) end

	if (self.INTR) then
		self.INTR = false
		return
	end

	if (self.OpcodeCount[self.Opcode] && (self.OpcodeCount[self.Opcode] > 0)) && 
	   (self.dRM1 ~= 0) && 
	   (self.WriteBack) && 
	   (self.Clk == 1) then
		    if (self.dRM1 == 1) then  self.EAX = self.Result
		elseif (self.dRM1 == 2) then  self.EBX = self.Result
		elseif (self.dRM1 == 3) then  self.ECX = self.Result
		elseif (self.dRM1 == 4) then  self.EDX = self.Result
		elseif (self.dRM1 == 5) then  self.ESI = self.Result
		elseif (self.dRM1 == 6) then  self.EDI = self.Result
		elseif (self.dRM1 == 7) then  self.ESP = self.Result
		elseif (self.dRM1 == 8) then  self.EBP = self.Result
		elseif (self.dRM1 == 9)  then self:Interrupt(13)
		elseif (self.dRM1 == 10) then self.SS = self.Result
		elseif (self.dRM1 == 11) then self.DS = self.Result
		elseif (self.dRM1 == 12) then self.ES = self.Result
		elseif (self.dRM1 == 13) then self.GS = self.Result
		elseif (self.dRM1 == 14) then self.FS = self.Result
		elseif (self.dRM1 >= 17) && (self.dRM1 <= 25) then
			self:WriteCell(self.Disp1+self.Segment1,self.Result)
		elseif (self.dRM1 >= 1000) && (self.dRM1 <= 2024) then
			self:WritePort(self.dRM1-1000,self.Result)
		end
	end

	if (self.INTR) then
		self.INTR = false
	end
end

function ENT:Use()
end

function ENT:Think()
//	self.BaseClass.Think(self)
//
	self.CPUCyclesLeft = self.ThinkTime*10//self.CPUCyclesLeft + self.ThinkTime*5
	while (self.CPUCyclesLeft > 0) && (self.Clk >= 1.0) do
		self:Execute()
		self.CPUCyclesLeft = self.CPUCyclesLeft - 1
	end
	if (self.Clk >= 1.0) then
//		self.Entity:NextThink(CurTime()+0.05)
		self.Entity:NextThink(CurTime()+0.1)
	end
end

function ENT:TriggerInput(iname, value)
	if (iname == "Clk") then
		self.Clk = value
		self.InputClk = value
		self.PrevTime = CurTime()

		if (self.Clk >= 1.0) then
			self.Entity:NextThink(CurTime()+0.025)
		end
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
			Wire_TriggerOutput(self.Entity, "Error", 0.0)
		end		
	elseif (iname == "MemBus") then
		self.MemBus = self.Inputs.MemBus.Src /////////////
	elseif (iname == "IOBus") then
		self.IOBus = self.Inputs.IOBus.Src /////////////
	elseif (iname == "NMI") then
		if (value >= 32) then
			if ((self.Clk >= 1.0) && (self.IF) &&
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
				self:Interrupt(math.floor(value));
			end
		end
	end
end
