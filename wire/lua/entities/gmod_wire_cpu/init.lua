AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "CPU"

function ENT:Initialize()
	
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "Frequency", "Clk", "Reset", "ReadAddr", "WriteAddr", "Data", "WriteClk", "Port0", "Port1", "Port2", "Port3", "Port4", "Port5", "Port6", "Port7"})
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Error", "Data", "Port0", "Port1", "Port2", "Port3", "Port4", "Port5", "Port6", "Port7"}) 

	self.Memory = {}

	for i = 0, 65535 do
		self.Memory[i] = 0
	end

	self.IP = 0
	self.WIP = 0

	self.Ports = {0, 0, 0, 0, 0, 0, 0, 0}

	self.Clk = 0

	self.EAX = 0
	self.EBX = 0
	self.ECX = 0
	self.EDX = 0

	self.ESI = 0
	self.EDI = 0
	self.ESP = 65535
	self.EBP = 0
	
	self.CMPR = 0

	self.WriteAddr = 0
	self.WriteData = 0

	self.HaltPort = -1
	
	//=================================
	self.FatalError = false
	self.Labels = {}
	//=================================

	self.ThinkTime = 10

	Wire_TriggerOutput(self.Entity, "Error", 0.0)
end

function ENT:Write( value )
	self.Memory[self.WIP] = value
	self.WIP = self.WIP + 1
	
	//Msg("-> ZyeliosASM: Wrote "..value.." at ["..self.WIP.."]\n")
end

function ENT:Read( )
	self.IP = self.IP + 1
	return self.Memory[self.IP - 1]
end







function ENT:DecodeOpcode( opcode )
	//------------------------------------------------------------
	if (opcode == "jne") || (opcode == "jnz") then		//JNE X   : IP = X, IF CMPR ~= 0
		return 1
	elseif (opcode == "jmp") then	//JMP X  : IP = X
		return 2
	elseif (opcode == "jg") || (opcode == "jnle") then	//JG X 	 : IP = X, IF CMPR > 0
		return 3
	elseif (opcode == "jge") || (opcode == "jnl") then	//JGE X  : IP = X, IF CMPR >= 0
		return 4
	elseif (opcode == "jl") || (opcode == "jnge") then	//JL X 	 : IP = X, IF CMPR < 0
		return 5
	elseif (opcode == "jle") || (opcode == "jng") then	//JLE X  : IP = X, IF CMPR <= 0
		return 6
	elseif (opcode == "je") || (opcode == "jz") then	//JE X   : IP = X, IF CMPR = 0
		return 7
	elseif (opcode == "cpuid") then	//CPUID X : EAX -> CPUID[X]
		return 8
	elseif (opcode == "push") then	//PUSH X : X -> STACK
		return 9
	//------------------------------------------------------------
	elseif (opcode == "add") then	//ADD X,Y : X = X + Y
		return 10
	elseif (opcode == "sub") then	//SUB X,Y : X = X - Y
		return 11
	elseif (opcode == "mul") then	//MUL X,Y : X = X * Y
		return 12
	elseif (opcode == "div") then	//DIV X,Y : X = X / Y
		return 13
	elseif (opcode == "mov") then	//MOV X,Y : X = Y
		return 14
	elseif (opcode == "cmp") then	//CMP X,Y : CMPR = X - Y
		return 15
	elseif (opcode == "rd") then	//RD X,Y : X = MEMORY[Y]
		return 16
	elseif (opcode == "wd") then	//WD X,Y : MEMORY[X] = Y
		return 17
	elseif (opcode == "min") then	//MIN X,Y : MIN(X,Y)
		return 18
	elseif (opcode == "max") then	//MAX X,Y : MAX(X,Y)
		return 19
	//------------------------------------------------------------
	elseif (opcode == "inc") then	//INC X  : X = X + 1
		return 20
	elseif (opcode == "dec") then	//DEC X  : X = X - 1
		return 21
	elseif (opcode == "neg") then	//NEG X  : X = -X
		return 22
	elseif (opcode == "rand") then	//RAND X : X = Random(0..1)
		return 23
	//------------------------------------------------------------
	elseif (opcode == "pop") then 	//POP X : X <- STACK
		return 30
	elseif (opcode == "call") then	//CALL X : IP -> STACK; IP = X
		return 31
	elseif (opcode == "not") then	//NOT X : X = not X
		return 32
	elseif (opcode == "int") then	//INT X : X = FLOOR(X)
		return 33
	elseif (opcode == "rnd") then	//RND X : X = ROUND(X)
		return 34
	elseif (opcode == "frac") then	//FRAX X : X = X - FLOOR(X)
		return 35
	elseif (opcode == "finv") then	//FINV X : X = 1 / X
		return 36
	elseif (opcode == "halt") then	//HALT X : HALT UNTIL PORT[X]
		return 37
	//------------------------------------------------------------
	elseif (opcode == "ret") then	//RET : IP <- STACK
		return 40
	//------------------------------------------------------------
	elseif (opcode == "and") then	//AND X,Y : X = X AND Y
		return 50
	elseif (opcode == "or") then	//OR X,Y : X = X OR Y
		return 51
	elseif (opcode == "xor") then	//XOR X,Y : X = X XOR Y
		return 52
	elseif (opcode == "fsin") then	//FSIN X,Y : X = SIN Y
		return 53
	elseif (opcode == "fcos") then	//FCOS X,Y : X = COS Y
		return 54
	elseif (opcode == "ftan") then	//FTAN X,Y : X = TAN Y
		return 55
	elseif (opcode == "fasin") then	//FASIN X,Y : X = ASIN Y
		return 56
	elseif (opcode == "facos") then	//FACOS X,Y : X = ACOS Y
		return 57
	elseif (opcode == "fatan") then	//FATAN X,Y : X = ATAN Y
		return 58
	end
	return -1
end

function ENT:OpcodeParamCount( opcode )
	if (opcode >= 1) && (opcode <= 9) then
		return 1
	elseif (opcode >= 10) && (opcode <= 19) then	
		return 2
	elseif (opcode >= 20) && (opcode <= 29) then
		return 1
	elseif (opcode >= 30) && (opcode <= 39) then
		return 1
	elseif (opcode >= 40) && (opcode <= 49) then
		return 0
	elseif (opcode >= 50) && (opcode <= 59) then
		return 2
	end
	return 0
end

//ERROR VALUES TABLE
//Value | Error
//--------------------------------------------
//0.0	| No error
//2.0	| End of program execution
//3.0	| Division by zero
//4.0	| Unknown opcode
//5.0	| Internal error
//6.0	| Stack error
//--------------------------------------------
//
//CPUID
//Value | EAX
//--------------------------------------------
//0	| CPU Version
//1	| RAM Size
//--------------------------------------------

function ENT:Execute( )
	if (self.HaltPort ~= -1) then
		return
	end
	
	local opcode = self:Read( )
	local rm = self:Read( )
	local params = {0, 0}
	local result = 0

	local disp1,disp2 = 0

	local drm2 = math.floor(rm / 100)
	local drm1 = rm - drm2*100


	if (self:OpcodeParamCount( opcode ) > 0) then
		if (drm1 == 0) then
			params[1] = self:Read( )
		elseif (drm1 == 1) then
			params[1] = self.EAX
		elseif (drm1 == 2) then
			params[1] = self.EBX
		elseif (drm1 == 3) then
			params[1] = self.ECX
		elseif (drm1 == 4) then
			params[1] = self.EDX
		elseif (drm1 == 5) then
			params[1] = self.ESI
		elseif (drm1 == 6) then
			params[1] = self.EDI
		elseif (drm1 == 7) then
			params[1] = self.ESP
		elseif (drm1 == 8) then
			params[1] = self.EBP
		elseif (drm1 >= 9) && (drm1 <= 16) then
			params[1] = self.Ports[drm1-9]
		elseif (drm1 == 17) then
			disp1 = math.floor(self.EAX)
		elseif (drm1 == 18) then
			disp1 = math.floor(self.EBX)
		elseif (drm1 == 19) then
			disp1 = math.floor(self.ECX)
		elseif (drm1 == 20) then
			disp1 = math.floor(self.EDX)
		elseif (drm1 == 21) then
			disp1 = math.floor(self.ESI)
		elseif (drm1 == 22) then
			disp1 = math.floor(self.EDI)
		elseif (drm1 == 23) then
			disp1 = math.floor(self.ESP)
		elseif (drm1 == 24) then
			disp1 = math.floor(self.EBP)
		elseif (drm1 == 25) then
			disp1 = math.floor(self:Read( ))
		end
		if (drm1 >= 17) && (drm1 <= 25) then
			if (disp1 >= 0) && (disp1 <= 65535) then
				params[1] = self.Memory[disp1]
			end
		end
	end
	if (self:OpcodeParamCount( opcode ) > 1) then
		if (drm2 == 0) then
			params[2] = self:Read( )
		elseif (drm2 == 1) then
			params[2] = self.EAX
		elseif (drm2 == 2) then
			params[2] = self.EBX
		elseif (drm2 == 3) then
			params[2] = self.ECX
		elseif (drm2 == 4) then
			params[2] = self.EDX
		elseif (drm2 == 5) then
			params[2] = self.ESI
		elseif (drm2 == 6) then
			params[2] = self.EDI
		elseif (drm2 == 7) then
			params[2] = self.ESP
		elseif (drm2 == 8) then
			params[2] = self.EBP
		elseif (drm2 >= 9) && (drm2 <= 16) then
			params[2] = self.Ports[drm2-9]
		elseif (drm2 == 17) then
			disp2 = math.floor(self.EAX)
		elseif (drm2 == 18) then
			disp2 = math.floor(self.EBX)
		elseif (drm2 == 19) then
			disp2 = math.floor(self.ECX)
		elseif (drm2 == 20) then
			disp2 = math.floor(self.EDX)
		elseif (drm2 == 21) then
			disp2 = math.floor(self.ESI)
		elseif (drm2 == 22) then
			disp2 = math.floor(self.EDI)
		elseif (drm2 == 23) then
			disp2 = math.floor(self.ESP)
		elseif (drm2 == 24) then
			disp2 = math.floor(self.EBP)
		elseif (drm2 == 25) then
			disp2 = math.floor(self:Read( ))
		end
		if (drm2 >= 17) && (drm2 <= 25) then
			if (disp2 >= 0) && (disp2 <= 65535) then
				params[2] = self.Memory[disp2]
			end
		end
	end

	local WriteBack = true
	
	// ------------------------------------------------ //
	//| OPCODES COME HERE:                             |//
	// ------------------------------------------------ //
	if (opcode == 0) then
		Wire_TriggerOutput(self.Entity, "Error", 2.0)
		self.Clk = 0
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
			self.EAX = 150		//= 1.50
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
		self.Memory[ESP] = params[1]
		ESP = ESP - 1
		if (ESP < 16384) then
			Wire_TriggerOutput(self.Entity, "Error", 6.0)
			self.Clk = 0
		end
		WriteBack = false
	//------------------------------------------------------------
	elseif (opcode == 10) then	//ADD
		result = params[1] + params[2]
	elseif (opcode == 11) then	//SUB
		result = params[1] - params[2]
	elseif (opcode == 12) then	//MUL
		result = params[1] * params[2]
	elseif (opcode == 13) then	//DIV
		if (math.abs(params[2]) < 0.0001) then
			Wire_TriggerOutput(self.Entity, "Error", 3.0)
			self.Clk = 0
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
		if (params[2] < params[1]) then
			result = params[2]
		else
			result = params[1]
		end
	elseif (opcode == 19) then	//MAX
		if (params[2] > params[1]) then
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
	//------------------------------------------------------------
	elseif (opcode == 30) then	//POP
		self.ESP = self.ESP + 1
		if (self.ESP > 65535) then
			Wire_TriggerOutput(self.Entity, "Error", 6.0)
			self.Clk = 0
		else
			result = self.Memory[self.ESP]
		end
		WriteBack = false
	elseif (opcode == 31) then	//CALL
		self.Memory[self.ESP] = self.IP
		self.ESP = self.ESP - 1
		if (self.ESP < 16384) then
			Wire_TriggerOutput(self.Entity, "Error", 6.0)
			self.Clk = 0
		else
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
		if (math.abs(params[1]) < 0.0001) then
			Wire_TriggerOutput(self.Entity, "Error", 3.0)
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
	elseif (opcode == 38) then
		Wire_TriggerOutput(self.Entity, "Error", 5632663.0)
	//------------------------------------------------------------
	elseif (opcode == 40) then	//RET
		self.ESP = self.ESP + 1
		if (self.ESP > 65535) then
			Wire_TriggerOutput(self.Entity, "Error", 6.0)
			self.Clk = 0
		else
			self.IP = self.Memory[self.ESP]
		end
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
	//------------------------------------------------------------
	else
		Wire_TriggerOutput(self.Entity, "Error", 4.0)
		self.Clk = 0
	end

	// ------------------------------------------------ //
	//| OPCODES END HERE                               |//
	// ------------------------------------------------ //

	if (self:OpcodeParamCount( opcode ) > 0) && (drm1 ~= 0) && (WriteBack) && (self.Clk == 1) then
		if (drm1 == 1) then
			self.EAX = result
		elseif (drm1 == 2) then
			self.EBX = result
		elseif (drm1 == 3) then
			self.ECX = result
		elseif (drm1 == 4) then
			self.EDX = result
		elseif (drm1 == 5) then
			self.ESI = result
		elseif (drm1 == 6) then
			self.EDI = result
		elseif (drm1 == 7) then
			self.ESP = result
		elseif (drm1 == 8) then
			self.EBP = result
		elseif (drm1 >= 9) && (drm1 <= 16) then
			local port = drm1 - 9
			Wire_TriggerOutput(self.Entity, "Port"..port, result)
		elseif (drm1 >= 17) && (drm1 <= 25) then
			self.Memory[disp1] = result
		end
	end
end



function ENT:Digit( prefix )
	return (prefix == "0") || (prefix == "1") || (prefix == "2") || (prefix == "3") ||
	       (prefix == "4") || (prefix == "5") || (prefix == "6") || (prefix == "7") ||
	       (prefix == "8") || (prefix == "9") || (prefix == ".")
end

function ENT:ValidNumber( line )
	if (line) then
		return self:Digit(string.sub(line,1,1))
	else
		return false;
	end
end

function ENT:Compile( pl, line, linenumber, firstpass )
	local opcodetable = string.Explode(" ", line or { } )
	local dopcode = 0
	local nextparams = false
	local nextvariable = false
	local nextorg = false
	local nextdefine = false
	local nextalloc = false
	local nextdb = false
	local programsize = 0
	for _,opcode in pairs(opcodetable) do
		opcode = string.Trim(opcode)
		if (nextdefine) then
			local deftable = string.Explode(",", opcode )
			if (table.Count(deftable) == 2) then
				if (not self.Labels[deftable[1]]) then
					if (self:ValidNumber(opcode)) then
						self.Labels[deftable[1]] = deftable[2]
					else
						pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E270) at line "..linenumber..": Attempt to define a non-number\n")
						return false
					end
				else
					if (firstpass) then
						pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E236) at line "..linenumber..": Define "..deftable[1].." already exists\n")
						return false
					end
				end
			else
				pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E335) at line "..linenumber..": Invalid number of parameters in DEFINE macro\n")
				return false	
			end
		elseif (nextdb) then
			local dbtable = string.Explode(",", opcode )
			for _,dbvalue in pairs(dbtable) do
				if self:ValidNumber(dbvalue) then
					self:Write(dbvalue)
				else
					pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E450) at line "..linenumber..": Invalid parameter in DB macro\n")
					return false
				end
			end
		elseif (nextorg) then
			if self:ValidNumber(opcode) then
				self.WIP = opcode
			else
				pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E333) at line "..linenumber..": Invalid parameter in ORG macro\n")
				return false
			end
		elseif (nextalloc) then
			local alloctable = string.Explode(",", opcode )
			if (table.Count(alloctable) == 0) then
				pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Allocated new variable ".."0".." ["..self.WIP.."]\n")
				self:Write( 0 )
			end
			if (table.Count(alloctable) == 1) then
				alloctable[1] = string.Trim(alloctable[1])
				local prefix = string.sub(alloctable[1],1,1)
				if self:ValidNumber(alloctable[1]) then
					pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Allocated new array ".."0["..alloctable[1].."] ["..self.WIP.."]\n")
					for i = 1, alloctable[1] do
						self:Write( 0 )
					end
				else
					if (not self.Labels[alloctable[1]]) then
						self.Labels[alloctable[1]] = self.WIP
						pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Allocated new variable "..alloctable[1].." ["..self.WIP.."]\n")
						self:Write( 0 )
					else
						if (firstpass) then
							pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E231) at line "..linenumber..": Variable "..opcode.." already exists\n")
							return false
						else
							self:Write( 0 )
						end
					end
				end
			end
			if (table.Count(alloctable) == 2) then
				alloctable[1] = string.Trim(alloctable[1])
				alloctable[2] = string.Trim(alloctable[2])
				if (not self.Labels[alloctable[1]]) then
					self.Labels[alloctable[1]] = self.WIP
					pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Allocated new array "..alloctable[1].."["..alloctable[2].."] ["..self.WIP.."]\n")
					for i = 1, alloctable[2] do
						self:Write( 0 )
					end
				else
					if (firstpass) then
						pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E231) at line "..linenumber..": Variable "..opcode.." already exists\n")
						return false
					else
						for i = 1, alloctable[2] do
							self:Write( 0 )
						end
					end
				end
			end
			if (table.Count(alloctable) == 3) then
				alloctable[1] = string.Trim(alloctable[1])
				alloctable[2] = string.Trim(alloctable[2])
				alloctable[3] = string.Trim(alloctable[3])
				if (not self.Labels[alloctable[1]]) then
					self.Labels[alloctable[1]] = self.WIP
					pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Allocated new array "..alloctable[1].."["..alloctable[2].."] ["..self.WIP.."]\n")
					for i = 1, alloctable[2] do
						self:Write( alloctable[3] )
					end
				else
					if (firstpass) then
						pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E231) at line "..linenumber..": Variable "..opcode.." already exists\n")
						return false
					else
						for i = 1, alloctable[2] do
							self:Write( alloctable[3] )
						end
					end
				end
			end
			nextalloc = false
		elseif (nextparams) then
			local paramtable = string.Explode(",", opcode or {"none","none"} )
			local drm1 = 0
			local drm2 = 0
			local disp1,disp2 = 0

			if (table.Count(paramtable) ~= self:OpcodeParamCount( dopcode )) then
				pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E245) at line "..linenumber..": wrong number of parameters for opcode\n")
				return false
			end
			paramtable[1] = string.Trim(paramtable[1])
			
			if (paramtable[1] == "eax") then
				drm1 = 1
			elseif (paramtable[1] == "ebx")	then
				drm1 = 2
			elseif (paramtable[1] == "ecx")	then				
				drm1 = 3
			elseif (paramtable[1] == "edx")	then				
				drm1 = 4
			elseif (paramtable[1] == "esi")	then				
				drm1 = 5
			elseif (paramtable[1] == "edi")	then				
				drm1 = 6
			elseif (paramtable[1] == "esp")	then				
				drm1 = 7
			elseif (paramtable[1] == "ebp")	then				
				drm1 = 8
			elseif (paramtable[1] == "port0") then				
				drm1 = 9
			elseif (paramtable[1] == "port1") then				
				drm1 = 10
			elseif (paramtable[1] == "port2") then				
				drm1 = 11
			elseif (paramtable[1] == "port3") then				
				drm1 = 12
			elseif (paramtable[1] == "port4") then				
				drm1 = 13
			elseif (paramtable[1] == "port5") then				
				drm1 = 14
			elseif (paramtable[1] == "port6") then				
				drm1 = 15
			elseif (paramtable[1] == "port7") then				
				drm1 = 16
			else
				local prefix = string.sub(paramtable[1],1,1)
				local postprefix = string.sub(paramtable[1],2)
				if (prefix ~= "#") && (not self:ValidNumber(paramtable[1])) then
					if (self.Labels[paramtable[1]..":"]) then
						paramtable[1] = self.Labels[paramtable[1]..":"]
					else	
						if (not firstpass) then
							pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E232) at line "..linenumber..": No such label: "..paramtable[1].."!\n")
							return false
						end
					end
				end
				if (prefix == "#") then
					if (postprefix == "eax") then
						drm1 = 17
					elseif (postprefix == "ebx") then
						drm1 = 18
					elseif (postprefix == "ecx") then
						drm1 = 19
					elseif (postprefix == "edx") then
						drm1 = 20
					elseif (postprefix == "esi") then
						drm1 = 21
					elseif (postprefix == "edi") then
						drm1 = 22
					elseif (postprefix == "esp") then
						drm1 = 23
					elseif (postprefix == "edp") then
						drm1 = 24
					elseif (self.Labels[postprefix..":"]) then
						drm1 = 25
						disp1 = self.Labels[postprefix..":"]
					elseif (self.Labels[postprefix]) then
						drm1 = 25
						disp1 = self.Labels[postprefix]
					else
						if (postprefix) then
							if (not self.ValidNumber(postprefix)) then
								if (not firstpass) then
									pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E232) at line "..linenumber..": No such variable: "..postprefix.."!\n")
									return false
								end
							end
							drm1 = 25
							disp1 = postprefix
						else
							pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E490) at line "..linenumber..": Wrong memory reference syntax!\n")
						end
					end
				end
			end

			if (self:OpcodeParamCount( dopcode ) > 1) && (paramtable[2] ~= "none") then
				paramtable[2] = string.Trim(paramtable[2])

				if (paramtable[2] == "eax") then
					drm2 = 1
				elseif (paramtable[2] == "ebx") then				
					drm2 = 2
				elseif (paramtable[2] == "ecx") then				
					drm2 = 3
				elseif (paramtable[2] == "edx") then				
					drm2 = 4	
				elseif (paramtable[2] == "esi") then				
					drm2 = 5
				elseif (paramtable[2] == "edi") then				
					drm2 = 6
				elseif (paramtable[2] == "esp") then		
					drm2 = 7
				elseif (paramtable[2] == "ebp") then				
					drm2 = 8
				elseif (paramtable[2] == "port0") then				
					drm2 = 9
				elseif (paramtable[2] == "port1") then				
					drm2 = 10
				elseif (paramtable[2] == "port2") then				
					drm2 = 11
				elseif (paramtable[2] == "port3") then				
					drm2 = 12
				elseif (paramtable[2] == "port4") then				
					drm2 = 13
				elseif (paramtable[2] == "port5") then				
					drm2 = 14
				elseif (paramtable[2] == "port6") then				
					drm2 = 15
				elseif (paramtable[2] == "port7") then				
					drm2 = 16
				else
					local prefix = string.sub(paramtable[2],1,1)
					local postprefix = string.sub(paramtable[2],2)
					if (prefix ~= "#") && (not self:ValidNumber(paramtable[2])) then
						if (self.Labels[paramtable[2]..":"]) then
							paramtable[2] = self.Labels[paramtable[2]..":"]
						else	
							if (not firstpass) then
								pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E232) at line "..linenumber..": No such label: "..paramtable[2].."!\n")
								return false
							end
						end
					end
					if (prefix == "#") then
						if (postprefix == "eax") then
							drm2 = 17
						elseif (postprefix == "ebx") then
							drm2 = 18
						elseif (postprefix == "ecx") then
							drm2 = 19
						elseif (postprefix == "edx") then
							drm2 = 20
						elseif (postprefix == "esi") then
							drm2 = 21
						elseif (postprefix == "edi") then
							drm2 = 22
						elseif (postprefix == "esp") then
							drm2 = 23
						elseif (postprefix == "edp") then
							drm2 = 24
						elseif (self.Labels[postprefix..":"]) then
							drm2 = 25
							disp2 = self.Labels[postprefix..":"]
						elseif (self.Labels[postprefix]) then
							drm2 = 25
							disp2 = self.Labels[postprefix]
						else
							if (postprefix) then
								if (not self.ValidNumber(postprefix)) then
									if (not firstpass) then
										pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E231) at line "..linenumber..": No such variable: "..postprefix.."!\n")
										return false
									end
								end
								drm2 = 25
								disp2 = postprefix
							else
								pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E490) at line "..linenumber..": Wrong memory reference syntax!\n")
							end
						end
					end	
				end
			end
			local rm = drm1 + drm2*100
			self:Write( dopcode )
			self:Write( rm )
			programsize = programsize + 2
			
			if (drm1 == 0) then
				self:Write( paramtable[1] )
				programsize = programsize + 1
			end
			if (self:OpcodeParamCount( dopcode ) > 1) && (drm2 == 0) then
				self:Write( paramtable[2] )
				programsize = programsize + 1
			end
			if (drm1 == 25) then
				self:Write( disp1 )
			end
			if (drm2 == 25) then
				self:Write( disp2 )
			end

			nextparams = false
		else
			if ( opcode == "alloc" ) then
				nextalloc = true
			elseif (opcode == "db") then
				nextdb = true
			elseif ( opcode == "org" ) then
				nextorg = true
			elseif ( opcode == "define" ) then
				nextdefine = true
			elseif ( opcode == "code" ) then
				self.WIP = 0
				self.Labels["codestart"] = 0
			elseif ( opcode == "data" ) then
				self.WIP = 8196
				self.Labels["datastart"] = 8196
			else
				dopcode = self:DecodeOpcode( opcode )
				if (dopcode ~= -1) then
					if (self:OpcodeParamCount( dopcode ) > 0) then
						nextparams = true
					else
						self:Write( dopcode )
						self:Write( 0 )
						programsize = programsize + 2
					end				
				else
					local lastsymbol = string.sub(opcode,-1,-1)
					if (lastsymbol == ":") then
						if (not self.Labels[opcode]) then
							self.Labels[opcode] = self.WIP
							pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Added label "..opcode.."["..self.WIP.."]\n")
						else
							if (firstpass) then
								pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E200) at line "..linenumber..": Label "..opcode.." already exists\n")
								return false
							end
						end
					else
						if (opcode ~= "") && (opcode ~= " ") then
							pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E500) at line "..linenumber..": unknown opcode: "..opcode.."\n")
							return false
						end
					end
				end
			end
		end
	end
	return true
end

function ENT:ParseProgram( pl, programtext, parsedline, firstpass )
	if (self.FatalError) then
		return false
	end
	
	//local programtext2 = string.gsub(programtext,"/*(.-)*/")
	//Msg("!!: "..programtext2.."\n")
	//local programtext2 = string.Implode(" ",tablenolines)
	
	local comment = string.find(programtext,"//")

	local programtext2 = programtext

	if (comment) then
		programtext2 = string.sub(programtext,1,comment-1)
	end

	local linestable = string.Explode(";", programtext2 or { } )
	local linenumber = 0
	for _,line in pairs(linestable) do
		linenumber = linenumber + 1
		if (not self:Compile( pl, string.lower(line), parsedline, firstpass )) then
			self.FatalError = true
			self.Memory[0] = 0	//FIXME
		end
	end	
end

function ENT:Use()
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	local timeout = self.ThinkTime
	while (timeout > 0) && (self.Clk >= 1.0) do
		self:Execute( )
		timeout = timeout - 1
	end
	self.Entity:NextThink(CurTime()+0.01)
end

function ENT:TriggerInput(iname, value)
	if (iname == "Clk") then
		self.Clk = value
		if (value >= 1.0) then
			Wire_TriggerOutput(self.Entity, "Error", 0.0)
		end
	elseif (iname == "Frequency") then
		if (value ~= 0) then
			self.ThinkTime = value/100
		end
	elseif (iname == "Reset") then
		if (value >= 1.0) then
			self.IP = 0
		
			self.EAX = 0
			self.EBX = 0
			self.ECX = 0
			self.EDX = 0

			self.ESI = 0
			self.EDI = 0
			self.ESP = 65535
			self.EBP = 0

			Wire_TriggerOutput(self.Entity, "Error", 0.0)
		end		
	elseif (iname == "Port0") then
		if (self.HaltPort == 0) then
			self.HaltPort = -1
		end
		self.Ports[0] = value
	elseif (iname == "Port1") then
		if (self.HaltPort == 1) then
			self.HaltPort = -1
		end
		self.Ports[1] = value
	elseif (iname == "Port2") then
		if (self.HaltPort == 2) then
			self.HaltPort = -1
		end
		self.Ports[2] = value
	elseif (iname == "Port3") then
		if (self.HaltPort == 3) then
			self.HaltPort = -1
		end
		self.Ports[3] = value
	elseif (iname == "Port4") then
		if (self.HaltPort == 4) then
			self.HaltPort = -1
		end
		self.Ports[4] = value
	elseif (iname == "Port5") then
		if (self.HaltPort == 5) then
			self.HaltPort = -1
		end
		self.Ports[5] = value
	elseif (iname == "Port6") then
		if (self.HaltPort == 6) then
			self.HaltPort = -1
		end
		self.Ports[6] = value
	elseif (iname == "Port7") then
		if (self.HaltPort == 7) then
			self.HaltPort = -1
		end
		self.Ports[7] = value
	elseif (iname == "ReadAddr") then
		if (value >= 0.0) and (value <= 65535.0) then
			Wire_TriggerOutput(self.Entity, "Data", self.Memory[math.floor(value)])
		end
	elseif (iname == "WriteAddr") then
		self.WriteAddr = math.floor(value)
	elseif (iname == "Data") then
		self.WriteData = value
	elseif (iname == "WriteClk") then
		if (value >= 1.0) then
			self.Memory[self.WriteAddr] = self.WriteData
		end
	end
end
