AddCSLuaFile( "cl_init.lua" )
//AddCSLuaFile( "shared.lua" )
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
	//=================================

	self.ThinkTime = 10
	self.PrevTime = CurTime()
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
//4.0	| Unknown opcode 			| OPCODE
//5.0	| Internal error			|
//6.0	| Stack error				|
//7.0   | Memory fault (Read/write violation)	| ADDRESS
//8.0   | External bus error			|
//9.0	| Page fault (Write access violation)	| ADDRESS
//10.0  | Port Bus fault			| ADDRESS
//11.0  | ROM Error				|
//12.0	| Page error (wrong page id)		|
//13.0	| General Protection Error		|
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
	if (self.IF) then
		if (self.PF == false) then
			Wire_TriggerOutput(self.Entity, "Error", intnumber)
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
				if self:Push(self.IP) then //Store IRET
					self:Push(self.XEIP)
					if ( intnumber == 4 ) then //If wrong opcode then store data
						self:Push(self.ILTC)
					end
					if ( intnumber == 7 ) || ( intnumber == 9 ) || ( intnumber == 10) then
						self:Push(self.LADD)
					end
					self.IP = intoffset
				end
				self.INTR = true
			else
				//Msg("Baad thing\n")
				//self:Interrupt( 0 )
			end
		end
	end
end

function ENT:Write( value )
	if (value) then
		//self.BIOSMemory
		if (self.UseROM) then
			if (self.WIP < 65536) then
				self.ROMMemory[self.WIP] = value
			end
		else
			self:WriteCell(self.WIP,value)
		end
		if (self.Debug) then
			//Msg("-> ZyeliosASM: Wrote "..value.." at ["..self.WIP.."]\n")
		end

		self.WIP = self.WIP + 1
	else
		if (self.Debug) then
			Msg("-> ZyeliosASM: NIL VALUE at ["..self.WIP.."]\n")
		end
	end
end

function ENT:Read( )
	if (self.INTR) then //Lock the bus & eip
		if (self.Debug) then
			Msg("BUS READ WHILE LOCKED\n")
		end
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
		//self.LADD = math.floor(Address)
		//self:Interrupt(8)
		//return nil
		return self.ReadPort(-Address-1)
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
		return WritePort(-Address-1,value)
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

function ENT:Execute( )
	local DeltaTime = CurTime()-(self.PrevTime or CurTime())
	self.PrevTime = (self.PrevTime or CurTime())+DeltaTime

	self.TIMER = self.TIMER + DeltaTime
	self.TMR = self.TMR + 1
	if (self.Debug) then
		Msg(">TMR="..self.TMR.." IP="..self.IP.." ");
	end

	//-OBSOLETE---------------------------------
	//if (self.HaltPort ~= -1) then
	//	return
	//end
	//------------------------------------------
	
	self.XEIP = self.IP

	local opcode = self:Read( ) //Temp buttfux fix
	local rm = self:Read( )
	local params = {0, 0}
	local result = 0

	if (self.Debug) then
		Msg("OPCODE="..opcode.." RM="..rm.." ");
	end

	if (opcode) then
		self.ILTC = opcode
	else
		self.ILTC = -1
	end

	local disp1 = 0
	local disp2 = 0

	if (opcode == nil) || (rm == nil) then
		self.INTR = false
		return
	end

	opcode = opcode + 1 - 1 //Dont laugh, it helps

	local drm2 = math.floor(rm / 10000)
	local drm1 = rm - drm2*10000

	local segment1 = self.DS
	local segment2 = self.DS

	//Fix problem here (the lua buttfux one):
	if (opcode > 1000) then
		if (opcode > 10000) then
			segment2 = self:Read()
			opcode = opcode-10000
			if (opcode > 1000) then
				segment1 = self:Read()
				opcode = opcode-1000
			end
		else
			segment1 = self:Read()
			opcode = opcode-1000
		end
	end


	//if (self.Debug) then
	//	Msg("OPCODE2="..opcode.." S1="..segment1.." S2="..segment2.." ");
	//end

	if (segment1 == -2) then segment1 = self.CS end
	if (segment1 == -3) then segment1 = self.SS end
	if (segment1 == -4) then segment1 = self.DS end
	if (segment1 == -5) then segment1 = self.ES end
	if (segment1 == -6) then segment1 = self.GS end
	if (segment1 == -7) then segment1 = self.FS end
	if (segment2 == -2) then segment2 = self.CS end
	if (segment2 == -3) then segment2 = self.SS end
	if (segment2 == -4) then segment2 = self.DS end
	if (segment2 == -5) then segment2 = self.ES end
	if (segment2 == -6) then segment2 = self.GS end
	if (segment2 == -7) then segment2 = self.FS end

	if (self:OpcodeParamCount( opcode ) > 0) then
		if (drm1 == 0) then params[1] = self:Read( )
		elseif (drm1 == 1) then	params[1] = self.EAX
		elseif (drm1 == 2) then	params[1] = self.EBX
		elseif (drm1 == 3) then	params[1] = self.ECX
		elseif (drm1 == 4) then	params[1] = self.EDX
		elseif (drm1 == 5) then	params[1] = self.ESI
		elseif (drm1 == 6) then	params[1] = self.EDI
		elseif (drm1 == 7) then	params[1] = self.ESP
		elseif (drm1 == 8) then params[1] = self.EBP
		elseif (drm1 == 9)  then params[1] = self.CS
		elseif (drm1 == 10) then params[1] = self.SS
		elseif (drm1 == 11) then params[1] = self.DS
		elseif (drm1 == 12) then params[1] = self.ES
		elseif (drm1 == 13) then params[1] = self.GS
		elseif (drm1 == 14) then params[1] = self.FS
		elseif (drm1 == 17) then disp1 = math.floor(self.EAX)
		elseif (drm1 == 18) then disp1 = math.floor(self.EBX)
		elseif (drm1 == 19) then disp1 = math.floor(self.ECX)
		elseif (drm1 == 20) then disp1 = math.floor(self.EDX)
		elseif (drm1 == 21) then disp1 = math.floor(self.ESI)
		elseif (drm1 == 22) then disp1 = math.floor(self.EDI)
		elseif (drm1 == 23) then disp1 = math.floor(self.ESP)
		elseif (drm1 == 24) then disp1 = math.floor(self.EBP)
		elseif (drm1 == 25) then
			local addr = self:Read( )
			if (addr ~= nil) then disp1 = math.floor(addr) end
		end
		if (drm1 >= 17) && (drm1 <= 25) then
			params[1] = self:ReadCell(disp1+segment1)
		end
		if (drm1 >= 1000) && (drm1 <= 2024) then
			params[1] = self:ReadPort(drm1-1000)
		end
	end
	if (self:OpcodeParamCount( opcode ) > 1) then
		if (drm2 == 0) then params[2] = self:Read( )
		elseif (drm2 == 1) then	params[2] = self.EAX
		elseif (drm2 == 2) then	params[2] = self.EBX
		elseif (drm2 == 3) then	params[2] = self.ECX
		elseif (drm2 == 4) then	params[2] = self.EDX
		elseif (drm2 == 5) then	params[2] = self.ESI
		elseif (drm2 == 6) then	params[2] = self.EDI
		elseif (drm2 == 7) then	params[2] = self.ESP
		elseif (drm2 == 8) then	params[2] = self.EBP
		elseif (drm2 == 9)  then params[2] = self.CS
		elseif (drm2 == 10) then params[2] = self.SS
		elseif (drm2 == 11) then params[2] = self.DS
		elseif (drm2 == 12) then params[2] = self.ES
		elseif (drm2 == 13) then params[2] = self.GS
		elseif (drm2 == 14) then params[2] = self.FS
		elseif (drm2 == 17) then disp2 = math.floor(self.EAX)
		elseif (drm2 == 18) then disp2 = math.floor(self.EBX)
		elseif (drm2 == 19) then disp2 = math.floor(self.ECX)
		elseif (drm2 == 20) then disp2 = math.floor(self.EDX)
		elseif (drm2 == 21) then disp2 = math.floor(self.ESI)
		elseif (drm2 == 22) then disp2 = math.floor(self.EDI)
		elseif (drm2 == 23) then disp2 = math.floor(self.ESP)
		elseif (drm2 == 24) then disp2 = math.floor(self.EBP)
		elseif (drm2 == 25) then
			local addr = self:Read( )
			if (addr ~= nil) then disp2 = math.floor(addr) end
		end
		if (drm2 >= 17) && (drm2 <= 25) then
			params[2] = self:ReadCell(disp2+segment2)
		end
		if (drm2 >= 1000) && (drm2 <= 2024) then
			params[2] = self:ReadPort(drm2-1000)
		end
	end

	if (self.Debug) then
		if (params[1] && params[2]) then
			Msg("PARAMS1="..params[1].." PARAMS2="..params[2].."\n");
		end
	end

	if (params[1]) then
		params[1] = params[1] + 1 - 1
	end
	if (params[2]) then
		params[2] = params[2] + 1 - 1
	end

	if (self.INTR) then
		self.INTR = false
		return
	end

	local WriteBack = true
	
	// ------------------------------------------------ //
	//| OPCODES COME HERE:                             |//
	// ------------------------------------------------ //
	if (opcode == 0) then
		self:Interrupt(2)
	elseif (opcode == 1) then	//JNE
		if (self.CMPR ~= 0) then
			self.IP = params[1]
		end
		WriteBack = false
	elseif (opcode == 2) then	//JMP
		self.IP = params[1]
		WriteBack = false
	elseif (opcode == 3) then	//JG
		if (self.CMPR > 0) then
			self.IP = params[1]
		end
		WriteBack = false
	elseif (opcode == 4) then	//JGE
		if (self.CMPR >= 0) then
			self.IP = params[1]
		end
		WriteBack = false
	elseif (opcode == 5) then	//JL
		if (self.CMPR < 0) then
			self.IP = params[1]
		end
		WriteBack = false
	elseif (opcode == 6) then	//JLE
		if (self.CMPR <= 0) then
			self.IP = params[1]
		end
		WriteBack = false
	elseif (opcode == 7) then	//JE
		if (self.CMPR == 0) then
			self.IP = params[1]
		end
		WriteBack = false
	//============================================================
	elseif (opcode == 8) then	//CPUID
		if (params[1] == 0) then 	//CPU VERSION
			self.EAX = 220		//= 2.20
		elseif (params[1] == 1) then	//AMOUNT OF RAM
			self.EAX = 65536	//= 64KB
		elseif (params[1] == 2) then	//TYPE (0 - ZCPU; 1 - ZGPU)
			self.EAX = 0		//= ZCPU
		else
			self.EAX = 0
		end
		WriteBack = false
	//============================================================
	elseif (opcode == 9) then	//PUSH
		//self.Memory[ESP] = params[1]
		self:Push(params[1])
		WriteBack = false
	//------------------------------------------------------------
	elseif (opcode == 10) then	//ADD
		result = params[1] + params[2]
	elseif (opcode == 11) then	//SUB
		result = params[1] - params[2]
	elseif (opcode == 12) then	//MUL
		result = params[1] * params[2]
	elseif (opcode == 13) then	//DIV
		if (math.abs(params[2]) < 0.0000000001) then
			self:Interrupt(3)
		else
			result = params[1] / params[2]
		end
	elseif (opcode == 14) then	//MOV
		result = params[2]
	elseif (opcode == 15) then	//CMP
		self.CMPR = params[1] - params[2]
		WriteBack = false
	elseif (opcode == 16) then	//RD
		result = self.Memory[params[2]]
	elseif (opcode == 17) then	//WD
		self.Memory[params[1]] = params[2]
		WriteBack = false
	elseif (opcode == 18) then	//MIN
		if (tonumber(params[2]) < tonumber(params[1])) then
			result = params[2]
		else
			result = params[1]
		end
	elseif (opcode == 19) then	//MAX
		if (tonumber(params[2]) > tonumber(params[1])) then
			result = params[2]
		else
			result = params[1]
		end
	//------------------------------------------------------------
	elseif (opcode == 20) then	//INC
		result = params[1] + 1		
	elseif (opcode == 21) then	//DEC
		result = params[1] - 1
	elseif (opcode == 22) then	//NEG
		result = -params[1]
	elseif (opcode == 23) then	//RAND
		result = math.random()
	elseif (opcode == 24) then	//LOOP
		if (self.ECX ~= 0) then
			self.IP = params[1]
			self.ECX = self.ECX-1
		end
		WriteBack = false
	elseif (opcode == 25) then	//LOOPA
		if (self.EAX ~= 0) then
			self.IP = params[1]
			self.EAX = self.EAX-1
		end
		WriteBack = false
	elseif (opcode == 26) then	//LOOPB
		if (self.EBX ~= 0) then
			self.IP = params[1]
			self.EBX = self.EBX-1
		end
		WriteBack = false
	elseif (opcode == 27) then	//LOOPD
		if (self.EDX ~= 0) then
			self.IP = params[1]
			self.EDX = self.EDX-1
		end
		WriteBack = false
	elseif (opcode == 28) then	//SPG
		if (math.floor(params[1] / 128) >= 0) && (math.floor(params[1] / 128) < 512) then
			Page[math.floor(params[1] / 128)] = false
		else
			self:Interrupt(12)
		end
		WriteBack = false
	elseif (opcode == 29) then	//CPG
		if (math.floor(params[1] / 128) >= 0) && (math.floor(params[1] / 128) < 512) then
			Page[math.floor(params[1] / 128)] = true
		else
			self:Interrupt(12)
		end
		WriteBack = false
	//------------------------------------------------------------
	elseif (opcode == 30) then	//POP
		result = self:Pop()
	elseif (opcode == 31) then	//CALL
		if self:Push(self.IP) then
			self.IP = params[1]
		end
		WriteBack = false
	elseif (opcode == 32) then	//NOT
		if params[1] <= 0 then
			result = 1
		else
			result = 0
		end
	elseif (opcode == 33) then	//INT
		result = math.floor(params[1])
	elseif (opcode == 34) then	//RND
		result = math.round(params[1])
	elseif (opcode == 35) then	//FLOOR
		result = params[1] - math.floor(params[1])
	elseif (opcode == 36) then	//INV
		if (math.abs(params[1]) < 0.0000000001) then
			self:Interrupt(3)
			self.Clk = 0
		else
			result = 1 / params[1]
		end
	elseif (opcode == 37) then	//HALT
		self.HaltPort = math.floor(params[1])
		if self.HaltPort > 7 then 
			self.HaltPort = 7
		end
		if self.HaltPort < 0 then
			self.HaltPort = 0
		end
		WriteBack = false
	elseif (opcode == 38) then	//FSHL
		result = math.floor(params[1] * 2)
	elseif (opcode == 39) then	//FSHR
		result = math.floor(params[1] / 2)
	//------------------------------------------------------------
	elseif (opcode == 40) then	//RET
		local newIP = self:Pop()
		if (newIP) then
			self.IP = newIP
		end
		WriteBack = false
	elseif (opcode == 41) then	//IRET
		local newIP = self:Pop()
		if (newIP) then
			self.IP = newIP
		end
		WriteBack = false
	elseif (opcode == 42) then	//STI
		self.IF = true
		WriteBack = false
	elseif (opcode == 43) then	//CLI
		self.IF = false
		WriteBack = false
	elseif (opcode == 44) then	//STP
		self.PF = true
		WriteBack = false
	elseif (opcode == 45) then	//CLP
		self.PF = false
		WriteBack = false
	elseif (opcode == 46) then	//STD
		//self.Debug = true
		WriteBack = false
	elseif (opcode == 47) then	//RETF
		local newIP = self:Pop()
		local newCS = self:Pop()
		if (newIP) && (newCS) then
			self.IP = newIP
			self.CS = newCS
		end
		WriteBack = false
	elseif (opcode == 48) then	//RCMPR
		self.EAX = self.CMPR
		WriteBack = false
	elseif (opcode == 49) then	//TMR
		self.EAX = self.TMR
		WriteBack = false
	//------------------------------------------------------------
	elseif (opcode == 50) then	//AND
		if (params[1] > 0) && (params[2] > 0) then
			result = 1
		else
			result = 0
		end
	elseif (opcode == 51) then	//OR
		if (params[1] > 0) || (params[2] > 0) then
			result = 1
		else
			result = 0
		end
	elseif (opcode == 52) then	//XOR
		if ((params[1] > 0) && (params[2] <= 0)) ||
		   ((params[1] <= 0) && (params[2] > 0)) then
			result = 1
		else
			result = 0
		end
	elseif (opcode == 53) then	//FSIN
		result = math.sin(params[2])
	elseif (opcode == 54) then	//FCOS
		result = math.cos(params[2])
	elseif (opcode == 55) then	//FTAN
		result = math.tan(params[2])
	elseif (opcode == 56) then	//FASIN
		result = math.asin(params[2])
	elseif (opcode == 57) then	//FACOS
		result = math.acos(params[2])
	elseif (opcode == 58) then	//FATAN
		result = math.atan(params[2])
	elseif (opcode == 59) then	//MOD
		result = math.fmod(params[1],params[2])
	//------------------------------------------------------------
	elseif (opcode == 60) then	//BIT
		local temp = params[1]
		for i = 0,params[2]-1 do
			temp = math.floor(temp / 10)
		end
		self.CMPR = math.fmod(temp,10)
		WriteBack = false
	elseif (opcode == 61) then	//SBIT
		local temp = params[1]
		local temp2 = 0
		local temp3 = 1
		for i = 0,7 do
			if (i == params[2]) then
				temp2 = temp2 + temp3*1
			else
				temp2 = temp2 + temp3*math.fmod(temp,10)
			end
			temp = math.floor(temp / 10)
			temp3 = temp3*10
		end
		result = temp2
	elseif (opcode == 62) then	//CBIT
		local temp = params[1]
		local temp2 = 0
		local temp3 = 1
		for i = 0,7 do
			if (i == params[2]) then
				temp2 = temp2 + temp3*0
			else
				temp2 = temp2 + temp3*math.fmod(temp,10)
			end
			temp = math.floor(temp / 10)
			temp3 = temp3*10
		end
		result = temp2
	elseif (opcode == 69) then	//JMPF
		self.CS = params[2]
		self.IP = params[1]
		WriteBack = false
	//------------------------------------------------------------
	elseif (opcode == 71) then	//CNE
		if (self.CMPR ~= 0) then
			if self:Push(self.IP) then
				self.IP = params[1]
			end
		end
		WriteBack = false
	elseif (opcode == 72) then	//CJMP
		if self:Push(self.IP) then
			self.IP = params[1]
		end
		WriteBack = false
	elseif (opcode == 73) then	//CG
		if (self.CMPR > 0) then
			if self:Push(self.IP) then
				self.IP = params[1]
			end
		end
		WriteBack = false
	elseif (opcode == 74) then	//CGE
		if (self.CMPR >= 0) then
			if self:Push(self.IP) then
				self.IP = params[1]
			end
		end
		WriteBack = false
	elseif (opcode == 75) then	//CL
		if (self.CMPR < 0) then
			if self:Push(self.IP) then
				self.IP = params[1]
			end
		end
		WriteBack = false
	elseif (opcode == 76) then	//CLE
		if (self.CMPR <= 0) then
			if self:Push(self.IP) then
				self.IP = params[1]
			end
		end
		WriteBack = false
	elseif (opcode == 77) then	//CE
		if (self.CMPR == 0) then
			if self:Push(self.IP) then
				self.IP = params[1]
			end
		end
		WriteBack = false
	elseif (opcode == 78) then	//MCOPY
		for i = 1,params[1] do
			local val
			val = self:ReadCell(self.ESI+segment1)
			if (val == nil) then return end
			if (self:WriteCell(self.EDI+segment2,val) == false) then return end
			self.EDI = self.EDI + 1
			self.ESI = self.ESI + 1
		end
		WriteBack = false
	elseif (opcode == 79) then	//MXCHG
		for i = 1,params[1] do
			local val
			val1 = self:ReadCell(self.ESI+segment1)
			val2 = self:ReadCell(self.EDI+segment2)
			if (val1 == nil) || (val2 == nil) then return end
			if (self:WriteCell(self.EDI+segment2,val1) == false) || (self:WriteCell(self.ESI+segment1,val2) == false) then return end
			self.EDI = self.EDI + 1
			self.ESI = self.ESI + 1
		end
		WriteBack = false
	//------------------------------------------------------------
	elseif (opcode == 80) then	//FPWR
		result = params[1]^params[2]
	elseif (opcode == 81) then	//XCHG
		local val1 = params[2]
		local val2 = params[1]

		result = val1
		if (drm2 == 1) then self.EAX = val2
		elseif (drm2 == 2) then	self.EBX = val2
		elseif (drm2 == 3) then	self.ECX = val2
		elseif (drm2 == 4) then	self.EDX = val2
		elseif (drm2 == 5) then	self.ESI = val2
		elseif (drm2 == 6) then	self.EDI = val2
		elseif (drm2 == 7) then	self.ESP = val2
		elseif (drm2 == 8) then	self.EBP = val2
		elseif (drm2 == 9)  then self:Interrupt(13)
		elseif (drm2 == 10) then self.SS = val2
		elseif (drm2 == 11) then self.DS = val2
		elseif (drm2 == 12) then self.ES = val2
		elseif (drm2 == 13) then self.GS = val2
		elseif (drm2 == 14) then self.FS = val2
		elseif (drm2 >= 17) && (drm2 <= 25) then
			self:WriteCell(disp2+segment2,val2)
		elseif (drm2 >= 1000) && (drm2 <= 2024) then
			self:WritePort(drm2-1000,val2)
		end
	elseif (opcode == 82) then	//FLOG
		result = math.log(params[2])
	elseif (opcode == 83) then	//FLOG10
		result = math.log10(params[2])
	elseif (opcode == 84) then	//IN
		result = self:ReadPort(params[2])
	elseif (opcode == 85) then	//OUT
		self:WritePort(params[1],params[2])
		WriteBack = false
	elseif (opcode == 86) then	//FABS
		result = math.abs(params[2])
	elseif (opcode == 87) then	//FSGN
		if (params[2] > 0) then
			result = 1
		elseif (params[2] < 0) then
			result = -1
		else
			result = 0
		end
	elseif (opcode == 88) then	//FEXP
		result = math.exp(params[2])
	elseif (opcode == 89) then	//CALLF
		if self:Push(self.CS) && self:Push(self.IP)  then
			self.IP = params[1]
			self.CS = params[2]
		end
		WriteBack = false
	//------------------------------------------------------------
	elseif (opcode == 90) then 	//FPI
		result = 3.141592653589793
	elseif (opcode == 91) then 	//FE
		result = 2.718281828459045
	elseif (opcode == 92) then 	//INT
		self:Interrupt(tonumber(params[1]))
		WriteBack = false
	elseif (opcode == 93) then 	//TPG
		local tadd = params[1]*128
		self.CMPR = 0
		while (tadd < params[1]*128+128) do
			local val = self:ReadCell(tadd)
			if (val == nil) then
				self.CMPR = tadd
				tadd = params[1]*128+128
			end
			tadd = tadd + 1
		end
		WriteBack = false
	elseif (opcode == 94) then 	//FCEIL
		result = math.ceil(params[1])
	elseif (opcode == 95) then 	//ERPG
		if (params[1] >= 0) && (params[1] < 512) then
			local tadd = params[1]*128
			while (tadd < params[1]*128+128) do
				self.ROMMemory[tadd] = 0
				tadd = tadd + 1
			end
		else
			self:Interrupt(12)
		end
		WriteBack = false
	elseif (opcode == 96) then 	//WRPG
		if (params[1] >= 0) && (params[1] < 512) then
			local tadd = params[1]*128
			while (tadd < params[1]*128+128) do
				self.ROMMemory[tadd] = self.Memory[tadd]
				tadd = tadd + 1
			end
		else
			self:Interrupt(12)
		end
		WriteBack = false
	elseif (opcode == 97) then 	//RDPG
		if (params[1] >= 0) && (params[1] < 512) then
			local tadd = params[1]*128
			while (tadd < params[1]*128+128) do
				self.Memory[tadd] = self.ROMMemory[tadd]
				tadd = tadd + 1
			end
		else
			self:Interrupt(12)
		end
		WriteBack = false
	elseif (opcode == 98) then	//TIMER
		result = self.TIMER
	elseif (opcode == 99) then	//LIDTR
		self.IDTR = params[1]
		WriteBack = false
	//------------------------------------------------------------
	elseif (opcode == 101) then	//JNER
		if (self.CMPR ~= 0) then
			self.IP = self.IP + params[1]
		end
		WriteBack = false
	elseif (opcode == 102) then	//JMPR
		self.IP = self.IP + params[1]
		WriteBack = false
	elseif (opcode == 103) then	//JGR
		if (self.CMPR > 0) then
			self.IP = self.IP + params[1]
		end
		WriteBack = false
	elseif (opcode == 104) then	//JGER
		if (self.CMPR >= 0) then
			self.IP = self.IP + params[1]
		end
		WriteBack = false
	elseif (opcode == 105) then	//JLR
		if (self.CMPR < 0) then
			self.IP = self.IP + params[1]
		end
		WriteBack = false
	elseif (opcode == 106) then	//JLER
		if (self.CMPR <= 0) then
			self.IP = self.IP + params[1]
		end
		WriteBack = false
	elseif (opcode == 107) then	//JER
		if (self.CMPR == 0) then
			self.IP = self.IP + params[1]
		end
		WriteBack = false
	//------------------------------------------------------------
	elseif (opcode == 110) then	//NMIRET
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

		WriteBack = false
	//------------------------------------------------------------
	else
		self:Interrupt(4)
	end

	if (self.INTR) then
		self.INTR = false
		return
	end

	// ------------------------------------------------ //
	//| OPCODES END HERE                               |//
	// ------------------------------------------------ //

	if (self:OpcodeParamCount( opcode ) > 0) && (drm1 ~= 0) && (WriteBack) && (self.Clk == 1) then
		if (drm1 == 1) then self.EAX = result
		elseif (drm1 == 2) then self.EBX = result
		elseif (drm1 == 3) then self.ECX = result
		elseif (drm1 == 4) then	self.EDX = result
		elseif (drm1 == 5) then	self.ESI = result
		elseif (drm1 == 6) then	self.EDI = result
		elseif (drm1 == 7) then	self.ESP = result
		elseif (drm1 == 8) then	self.EBP = result
		elseif (drm1 == 9)  then self:Interrupt(13)
		elseif (drm1 == 10) then self.SS = result
		elseif (drm1 == 11) then self.DS = result
		elseif (drm1 == 12) then self.ES = result
		elseif (drm1 == 13) then self.GS = result
		elseif (drm1 == 14) then self.FS = result
		elseif (drm1 >= 17) && (drm1 <= 25) then
			self:WriteCell(disp1+segment1,result)
		elseif (drm1 >= 1000) && (drm1 <= 2024) then
			self:WritePort(drm1-1000,result)
		end
	end

	if (self.INTR) then
		self.INTR = false
	end
end

function ENT:Use()
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	local timeout = self.ThinkTime*5
	while (timeout > 0) && (self.Clk >= 1.0) do
		self:Execute( )
		timeout = timeout - 1
	end
	self.Entity:NextThink(CurTime()+0.05)
end

function ENT:TriggerInput(iname, value)
	if (iname == "Clk") then
		self.Clk = value
		self.InputClk = value
		self.PrevTime = CurTime()
	elseif (iname == "Frequency") then
		if (!SinglePlayer() && (value > 20000)) then 
			self.ThinkTime = 200 
			return
		end
		if (value ~= 0) then
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
				Interrupt(math.floor(value));
			end
		end
	end
end
