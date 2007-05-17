function ENT:DecodeOpcode( opcode )
	//------------------------------------------------------------
	if (opcode == "jne") || (opcode == "jnz") then		//JNE X   : IP = X, IF CMPR ~= 0
		return 1
	elseif (opcode == "jmp") then				//JMP X  : IP = X
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
	elseif (opcode == "loop") then 	//LOOP X : IF ECX ~= 0 THEN JUMP X //2.00
		return 24
	elseif (opcode == "loopa") then //LOOP X : IF EAX ~= 0 THEN JUMP X //2.00
		return 25
	elseif (opcode == "loopb") then //LOOP X : IF EBX ~= 0 THEN JUMP X //2.00
		return 26
	elseif (opcode == "loopd") then //LOOP X : IF EDX ~= 0 THEN JUMP X //2.00
		return 27		
	elseif (opcode == "spg") then	//SRD X : PAGE(X) = READ ONLY	   //2.00
		return 28  
	elseif (opcode == "cpg") then	//CRD X : PAGE(X) = READ AND WRITE //2.00
		return 29
	//------------------------------------------------------------
	elseif (opcode == "pop") then 	//POP X : X <- STACK
		return 30
	elseif (opcode == "call") then	//CALL X : IP -> STACK; IP = X
		return 31
	elseif (opcode == "not") then	//NOT X : X = not X
		return 32
	elseif (opcode == "fint") then	//FINT X : X = FLOOR(X)
		return 33
	elseif (opcode == "frnd") then	//FRND X : X = ROUND(X)
		return 34
	elseif (opcode == "ffrac") then	//FFRAC X : X = X - FLOOR(X)
		return 35
	elseif (opcode == "finv") then	//FINV X : X = 1 / X
		return 36
	elseif (opcode == "halt") then	//HALT X : HALT UNTIL PORT[X]
		return 37
	elseif (opcode == "fshl") then	//FSHL X : X = X * 2		//2.00
		return 38
	elseif (opcode == "fshr") then	//FSHR X : X = X / 2		//2.00
		return 39
	//------------------------------------------------------------
	elseif (opcode == "ret") then	//RET : IP <- STACK
		return 40
	elseif (opcode == "iret") then	//IRET : IP <- STACK 		//2.00
		return 41
	elseif (opcode == "sti") then	//STI : IF = TRUE		//2.00
		return 42
	elseif (opcode == "cli") then	//CLI : IF = FALSE		//2.00
		return 43
	elseif (opcode == "stp") then	//STP : PF = TRUE		//2.00
		return 44
	elseif (opcode == "clp") then	//CLP : PF = FALSE		//2.00
		return 45
//	elseif (opcode == "") then	//RESERVED			//2.00
//		return 46
	elseif (opcode == "RETF") then	//RETF : IP,CS <- STACK		//2.00
		return 47
//	elseif (opcode == "") then	//RESERVED			//2.00
//		return 48
//	elseif (opcode == "") then	//RESERVED			//2.00
//		return 49
	//------------------------------------------------------------
	elseif (opcode == "and") then	//FAND X,Y : X = X AND Y
		return 50
	elseif (opcode == "or") then	//FOR X,Y : X = X OR Y
		return 51
	elseif (opcode == "xor") then	//FXOR X,Y : X = X XOR Y
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
	elseif (opcode == "mod") then	//MOD X,Y : X = X MOD Y		//2.00
		return 59
	//------------------------------------------------------------
	elseif (opcode == "bit") then	//BIT X,Y : CMPR = BIT(X,Y)	//2.00
		return 60
	elseif (opcode == "sbit") then	//SBIT X,Y : BIT(X,Y) = 1	//2.00
		return 61
	elseif (opcode == "cbit") then	//CBIT X,Y : BIT(X,Y) = 0	//2.00
		return 62
	elseif (opcode == "tbit") then	//TBIT X,Y : BIT(X,Y) = ~BIT(X,Y)//2.00
		return 63
	elseif (opcode == "band") then	//AND X,Y : X = X AND Y		//2.00
		return 64
	elseif (opcode == "bor") then	//OR X,Y : X = X OR Y		//2.00
		return 65
	elseif (opcode == "bxor") then	//XOR X,Y : X = X XOR Y		//2.00
		return 66
	elseif (opcode == "bshl") then	//SHL X,Y : X = X SHL Y		//2.00
		return 67
	elseif (opcode == "bshr") then	//SHR X,Y : X = X SHR Y		//2.00
		return 68
	elseif (opcode == "jmpf") then	//JMPF X,Y : CS = Y; IP = X	//2.00
		return 69
	//------------------------------------------------------------
	elseif (opcode == "cne") || (opcode == "cnz") then	//CNE X  : CALL(X), IF CMPR ~= 0 //2.00
		return 71
	elseif (opcode == "cg") || (opcode == "cnle") then	//CG X 	 : CALL(X), IF CMPR > 0	 //2.00
		return 73
	elseif (opcode == "cge") || (opcode == "cnl") then	//CGE X  : CALL(X), IF CMPR >= 0 //2.00
		return 74
	elseif (opcode == "cl") || (opcode == "cnge") then	//CL X 	 : CALL(X), IF CMPR < 0	 //2.00
		return 75
	elseif (opcode == "cle") || (opcode == "cng") then	//CLE X  : CALL(X), IF CMPR <= 0 //2.00
		return 76
	elseif (opcode == "ce") || (opcode == "cz") then	//CE X   : CALL(X), IF CMPR = 0	 //2.00
		return 77
	elseif (opcode == "mcopy") then	//MCOPY X : X BYTES(ESI) -> EDI	//2.00
		return 78
	elseif (opcode == "mxchg") then	//MXCHG X : X BYTES(ESI) <> EDI	//2.00
		return 79
	//------------------------------------------------------------
	elseif (opcode == "fpwr") then	//FPWR X,Y : X = X ^ Y		//2.00
		return 80
	elseif (opcode == "xchg") then	//XCHG X,Y : X,Y = Y,X		//2.00
		return 81
	elseif (opcode == "flog") then	//FLOG X,Y : X = LOG(Y)		//2.00
		return 82
	elseif (opcode == "flog10") then//FLOG10 X,Y : X = LOG10(Y)	//2.00
		return 83
	elseif (opcode == "in") then	//IN X,Y : X = PORT[Y]		//2.00
		return 84
	elseif (opcode == "out") then	//OUT X,Y : PORT[X] = Y		//2.00
		return 85
	elseif (opcode == "fabs") then	//FABS X,Y : X = ABS(Y)		//2.00
		return 86
	elseif (opcode == "fsgn") then	//FSGN X,Y : X = SIGN(Y)	//2.00
		return 87
	elseif (opcode == "fexp") then	//FEXP X,Y : X = EXP(Y)		//2.00
		return 88
	elseif (opcode == "callf") then //CALLF X,Y : CS = Y; CALL(X)	//2.00
		return 89
	//------------------------------------------------------------
	elseif (opcode == "fpi") then	//FPI X : X = PI		//2.00
		return 90
	elseif (opcode == "fe")	then 	//FE X : X = E			//2.00
		return 91
	elseif (opcode == "int") then	//INT X : INTERRUPT(X)		//2.00
		return 92
	elseif (opcode == "tpg") then	//TPG X : CMPR = TEST(PAGE(X))*	//2.00
		return 93
	elseif (opcode == "fceil") then	//FCEIL X : X = CEIL(X)		//2.00
		return 94
	elseif (opcode == "erpg") then	//ERPG X : ERASE ROM PAGE(X)	//2.00
		return 95
	elseif (opcode == "wrpg") then	//WRPG X : WRITE ROM PAGE(X)	//2.00
		return 96
	elseif (opcode == "rdpg") then	//RDPG X : READ ROM PAGE(X)	//2.00
		return 97
	elseif (opcode == "timer") then	//TIMER X : X = TIMER		//2.00
		return 98
	elseif (opcode == "lidtr") then //LIDTR X : IDTR = X		//2.00
		return 99
	//------------------------------------------------------------
	elseif (opcode == "jner") || (opcode == "jnzr") then	//JNE X   : IP = IP+X, IF CMPR ~= 0	//2.00
		return 101
	elseif (opcode == "jmpr") then				//JMP X  : IP = IP+X			//2.00
		return 102
	elseif (opcode == "jgr") || (opcode == "jnler") then	//JG X 	 : IP = IP+X, IF CMPR > 0	//2.00
		return 103
	elseif (opcode == "jger") || (opcode == "jnlr") then	//JGE X  : IP = IP+X, IF CMPR >= 0	//2.00
		return 104
	elseif (opcode == "jlr") || (opcode == "jnger") then	//JL X 	 : IP = IP+X, IF CMPR < 0	//2.00
		return 105
	elseif (opcode == "jler") || (opcode == "jngr") then	//JLE X  : IP = IP+X, IF CMPR <= 0	//2.00
		return 106
	elseif (opcode == "jer") || (opcode == "jzr") then	//JE X   : IP = IP+X, IF CMPR = 0	//2.00
		return 107
	//------------------------------------------------------------
	elseif (opcode == "nmiret") then //NMIRET X : NMIRESTORE;	//2.00
		return 110
	end
	return -1
end

function ENT:OpcodeParamCount( opcode )
	if ((opcode >= 1) && (opcode <= 9)) || (opcode == 69) then
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
	elseif (opcode >= 60) && (opcode <= 68) then
		return 2
	elseif (opcode >= 70) && (opcode <= 79) then
		return 1
	elseif (opcode >= 80) && (opcode <= 89) then
		return 2
	elseif (opcode >= 90) && (opcode <= 99) then
		return 1
	elseif (opcode >= 100) && (opcode <= 109) then
		return 1
	elseif (opcode >= 110) && (opcode <= 119) then
		return 0
	end
	return 0
end


function ENT:Digit( prefix )
	return (prefix == "0") || (prefix == "1") || (prefix == "2") || (prefix == "3") ||
	       (prefix == "4") || (prefix == "5") || (prefix == "6") || (prefix == "7") ||
	       (prefix == "8") || (prefix == "9") || (prefix == ".") || (prefix == "-") ||
	       (prefix == "+")
end

function ENT:ValidNumber( line )
	if (line) then
		return self:Digit(string.sub(line,1,1))
	else
		return false;
	end
end

function ENT:Explode(seperator ,str)
	local tble={}
	ll=0

	local prevll = 1

	str = string.Trim(str)

	while true do
		l = string.find(str,seperator,ll+1,true)
		if l~=nil then
			local leftstr = string.Left(str,l)
			local rightstr = string.Right(str,string.len(str)-l)
			local cleft = 0
			local cright = 0

			for i = 1, string.len(leftstr) do									
				if (string.sub(leftstr,i,i) == "'") then
					cleft = cleft + 1
				end
			end
			for i = 1, string.len(rightstr) do									
				if (string.sub(rightstr,i,i) == "'") then
					cright = cright + 1
				end
			end

			if (cleft % 2 == 0) && (cright % 2 == 0) then
				table.insert(tble, string.sub(str,ll,l-1))
				prevll = ll+l+1
			end
			ll=l+1
		else
			table.insert(tble, string.sub(str,math.min(prevll,ll)))
			break
		end
	end
	return tble
end

function ENT:Lowercase(str)

	local j = 1
	local rstr = ""

	while (j <= string.len(str)) do
		local leftstr = string.Left(str,j)
		local rightstr = string.Right(str,string.len(str)-j)
		local cleft = 0
		local cright = 0

		for i = 1, string.len(leftstr) do									
			if (string.sub(leftstr,i,i) == "'") then
				cleft = cleft + 1
			end
		end
		for i = 1, string.len(rightstr) do									
			if (string.sub(rightstr,i,i) == "'") then
				cright = cright + 1
			end
		end

		if (cleft % 2 == 0) && (cright % 2 == 0) then
			rstr = rstr..string.lower(string.sub(leftstr,j,j))
		else
			rstr = rstr..string.sub(leftstr,j,j)
		end
		j = j + 1
	end
	return rstr
end

function ENT:RemoveFuckingSpaces(str)
	
end

function ENT:Compile_ASM( pl, line, linenumber, firstpass )
	local opcodetable = self:Explode(" ", line or { } )
	local dopcode = 0
	local nextparams = false
	local nextvariable = false
	local nextorg = false
	local nextdefine = false
	local nextalloc = false
	local nextdb = false
	local programsize = 0
	if (self.MakeDump) && (string.Trim(line) ~= "") && (not firstpass) then
		self.Dump = self.Dump.."["..linenumber.."]"..self.WIP.." = "..line.."\n"
	end
	for _,opcode in pairs(opcodetable) do
		opcode = string.Trim(opcode)
		if (nextdefine) then
			local deftable = self:Explode(",", opcode )
			if (table.Count(deftable) == 2) then
				if (not self.Labels[deftable[1]]) then
					if (self:ValidNumber(deftable[2])) then
						self.Labels[deftable[1]] = deftable[2]
						//-pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Added define "..deftable[1].."["..deftable[2].."]\n")
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
//			Msg("db explode:"..opcode..";\n")
			local dbtable = self:Explode(",", opcode )
//			PrintTable(dbtable)
//			Msg("db start\n")
//			for _,dbvalue in pairs(dbtable) do
			for i=0,table.Count(dbtable) do
				local dbvalue = dbtable[i]
				if (dbvalue) && (dbvalue ~= "") then
					dbvalue = string.Trim(dbvalue)
//					Msg("dbvalue:"..dbvalue..";\n")
					if self:ValidNumber(dbvalue) then
						self:Write(dbvalue)
					else
						if (string.sub(dbvalue,1,1) == "'") && (string.sub(dbvalue,-1,-1) == "'") then
							local string = string.sub(dbvalue,2,-2)
							for i = 1, string.len(string) do									
								self:Write(string.byte(string,i))
							end
						else
							if (self.Labels[dbvalue]) then
								self:Write(self.Labels[dbvalue])
							elseif (self.Labels[dbvalue..":"]) then
								self:Write(self.Labels[dbvalue..":"])
							else
								if (not firstpass) then
									pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E450) at line "..linenumber..": Invalid parameter in DB macro\n")
									return false
								end
								//self:Write(0)
							end
						end
					end
				end
			end
		elseif (nextorg) then
			if self:ValidNumber(opcode) then
				self.WIP = tonumber(opcode)
			else
				pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E333) at line "..linenumber..": Invalid parameter in ORG macro\n")
				return false
			end
		elseif (nextalloc) then
			local alloctable = string.Explode(",", opcode )
			if (table.Count(alloctable) == 0) then
				//-pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Allocated new variable ".."0".." ["..self.WIP.."]\n")
				self:Write( 0 )
			end
			if (table.Count(alloctable) == 1) then
				alloctable[1] = string.Trim(alloctable[1])
				local prefix = string.sub(alloctable[1],1,1)
				if self:ValidNumber(alloctable[1]) then
					//-pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Allocated variable ".."["..alloctable[1].."] ["..self.WIP.."]\n")
					for i = 0,alloctable[1]-1 do
						self:Write( 0 )
					end
				else
					if (not self.Labels[alloctable[1]]) then
						self.Labels[alloctable[1]] = self.WIP
						//-pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Allocated new variable "..alloctable[1].." ["..self.WIP.."]\n")
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
					//-pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Allocated new variable "..alloctable[1].."["..alloctable[2].."] ["..self.WIP.."]\n")
					self:Write( alloctable[2] )
				else
					if (firstpass) then
						pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E231) at line "..linenumber..": Variable "..opcode.." already exists\n")
						return false
					else
						self:Write( alloctable[2] )
					end
				end
			end
			if (table.Count(alloctable) == 3) then
				alloctable[1] = string.Trim(alloctable[1])
				alloctable[2] = string.Trim(alloctable[2])
				alloctable[3] = string.Trim(alloctable[3])
				if (not self.Labels[alloctable[1]]) then
					self.Labels[alloctable[1]] = self.WIP
					//-pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Allocated new array "..alloctable[1].."["..alloctable[2].."] ["..self.WIP.."]\n")
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
			local segment1 = -1
			local segment2 = -1

			if (table.Count(paramtable) ~= self:OpcodeParamCount( dopcode )) then
				pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E245) at line "..linenumber..": wrong number of parameters for opcode\n")
				pl:PrintMessage(HUD_PRINTCONSOLE,"-> Code: ["..linenumber.."]"..self.WIP.." = "..line.."\n")
				return false
			end
			paramtable[1] = string.Trim(paramtable[1])
			
			if (self:ValidNumber(paramtable[1])) then
				drm1 = 0
			elseif (paramtable[1] == "eax") then drm1 = 1
			elseif (paramtable[1] == "ebx")	then drm1 = 2
			elseif (paramtable[1] == "ecx")	then drm1 = 3
			elseif (paramtable[1] == "edx")	then drm1 = 4
			elseif (paramtable[1] == "esi")	then drm1 = 5
			elseif (paramtable[1] == "edi")	then drm1 = 6
			elseif (paramtable[1] == "esp")	then drm1 = 7
			elseif (paramtable[1] == "ebp")	then drm1 = 8
			elseif (paramtable[1] == "cs")	then drm1 = 9
			elseif (paramtable[1] == "ss")	then drm1 = 10
			elseif (paramtable[1] == "ds")	then drm1 = 11
			elseif (paramtable[1] == "es")	then drm1 = 12
			elseif (paramtable[1] == "gs")	then drm1 = 13
			elseif (paramtable[1] == "fs")	then drm1 = 14
			elseif (string.sub(paramtable[1],1,4) == "port") then				
				drm1 = 1000+string.sub(paramtable[1],5)
			else
				local prefix = string.find(paramtable[1],"#")
				local postprefix = paramtable[1]
				if (prefix) then
					postprefix = string.sub(paramtable[1],2)
				end
				local segmentprefix2 = string.find(paramtable[1],":")
				if (segmentprefix2) then
					local segmentprefix = string.sub(paramtable[1],1,segmentprefix2-1)
					if (not self:ValidNumber(segmentprefix)) then
						if (segmentprefix == "cs") then
							segment1 = -2
						elseif (segmentprefix == "ss") then
							segment1 = -3
						elseif (segmentprefix == "ds") then
							segment1 = -4
						elseif (segmentprefix == "es") then
							segment1 = -5
						elseif (segmentprefix == "gs") then
							segment1 = -6
						elseif (segmentprefix == "fs") then
							segment1 = -7
						end
					else
						segment1 = segmentprefix
					end
					prefix = string.find(paramtable[1],"#",segmentprefix2)
					if (prefix) then
						postprefix = string.sub(paramtable[1],prefix+1)
					else
						postprefix = string.sub(paramtable[1],segmentprefix2)
					end
				end
				if (prefix == nil) && (not self:ValidNumber(paramtable[1])) then
					if (self.Labels[postprefix..":"]) then
						paramtable[1] = self.Labels[postprefix..":"]
					elseif (self.Labels[postprefix]) then
						paramtable[1] = self.Labels[postprefix]
					else	
						if (not firstpass) then
							pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E235) at line "..linenumber..": No such label: "..postprefix.."!\n")
							return false
						end
					end
				end
				if (prefix ~= nil) then
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
					elseif (postprefix == "ebp") then
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
									pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E236) at line "..linenumber..": No such variable: "..postprefix.."!\n") //I'm teh pirate yarr!
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

				if (self:ValidNumber(paramtable[2])) then
					drm2 = 0
				elseif (paramtable[2] == "eax") then drm2 = 1
				elseif (paramtable[2] == "ebx")	then drm2 = 2
				elseif (paramtable[2] == "ecx")	then drm2 = 3
				elseif (paramtable[2] == "edx")	then drm2 = 4
				elseif (paramtable[2] == "esi")	then drm2 = 5
				elseif (paramtable[2] == "edi")	then drm2 = 6
				elseif (paramtable[2] == "esp")	then drm2 = 7
				elseif (paramtable[2] == "ebp")	then drm2 = 8
				elseif (paramtable[2] == "cs")	then drm2 = 9
				elseif (paramtable[2] == "ss")	then drm2 = 10
				elseif (paramtable[2] == "ds")	then drm2 = 11
				elseif (paramtable[2] == "es")	then drm2 = 12
				elseif (paramtable[2] == "gs")	then drm2 = 13
				elseif (paramtable[2] == "fs")	then drm2 = 14
				elseif (string.sub(paramtable[2],1,4) == "port") then				
					drm2 = 1000+string.sub(paramtable[2],5)
				else
					local prefix = string.find(paramtable[2],"#")
					local postprefix = paramtable[2]
					if (prefix) then
						postprefix = string.sub(paramtable[2],2)
					end
					local segmentprefix2 = string.find(paramtable[2],":")
					if (segmentprefix2) then
						local segmentprefix = string.sub(paramtable[2],1,segmentprefix2-1)
						if (not self:ValidNumber(segmentprefix)) then
							if (segmentprefix == "cs") then
								segment2 = -2
							elseif (segmentprefix == "ss") then
								segment2 = -3
							elseif (segmentprefix == "ds") then
								segment2 = -4
							elseif (segmentprefix == "es") then
								segment2 = -5
							elseif (segmentprefix == "gs") then
								segment2 = -6
							elseif (segmentprefix == "fs") then
								segment2 = -7
							end
						else
							segment2 = segmentprefix
						end
						prefix = string.find(paramtable[2],"#",segmentprefix2)
						if (prefix) then
							postprefix = string.sub(paramtable[2],prefix+1)
						else
							postprefix = string.sub(paramtable[2],segmentprefix2)
						end
					end
					if (prefix == nil) && (not self:ValidNumber(paramtable[2])) then
						if (self.Labels[postprefix..":"]) then
							paramtable[2] = self.Labels[postprefix..":"]
						elseif (self.Labels[postprefix]) then
							paramtable[2] = self.Labels[postprefix]
						else	
							if (not firstpass) then
								pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E232) at line "..linenumber..": No such label: "..postprefix.."!\n")
								return false
							end
						end
					end
					if (prefix ~= nil) then
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
						elseif (postprefix == "ebp") then
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
			local rm = drm1 + drm2*10000
			local sopcode = dopcode
			if (segment1 ~= -1) then
				dopcode = dopcode + 1000
			end
			if (segment2 ~= -1) then
				dopcode = dopcode + 10000
			end
			self:Write( dopcode )
			self:Write( rm )
			programsize = programsize + 2
			if (segment1 ~= -1) then
				self:Write( segment1 )
			end
			if (segment2 ~= -1) then
				self:Write( segment2 )
			end

			if (drm1 == 0) then
				self:Write( paramtable[1] )
				programsize = programsize + 1
			end
			if (drm1 == 25) then
				self:Write( disp1 )
			end
			if (self:OpcodeParamCount( sopcode ) > 1) && (drm2 == 0) then
				self:Write( paramtable[2] )
				programsize = programsize + 1
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
				if (self.Labels["codestart"]) then
					if (firstpass) then
						pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E600) at line "..linenumber..": CODESTART label exists - cant use CODE macro\n")
						return false
					end
				end
				self.Labels["codestart"] = self.WIP
			elseif ( opcode == "data" ) then
				if (self.Labels["datastart"]) then
					if (firstpass) then
						pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E601) at line "..linenumber..": DATASTART label exists - cant use DATA macro\n")
						return false
					end
				end
				self.Labels["datastart"] = self.WIP
				self:Write(2)
				self:Write(0)
				if (self.Labels["codestart"]) then
					self:Write(self.Labels["codestart"])
				else
					self:Write(0)
					if (not firstpass) then
						pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Error (E602) at line "..linenumber..": No CODE macro, cant use DATA macro\n")
						return false
					end
				end
				
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
							//-pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Added label "..opcode.."["..self.WIP.."]\n")
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

function ENT:ParseProgram_ASM( pl, programtext, parsedline, firstpass )
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
		if (not self:Compile_ASM( pl, self:Lowercase(line), parsedline, firstpass )) then
			self.FatalError = true
			self.Memory[0] = 0	//FIXME
		end
	end	
end
