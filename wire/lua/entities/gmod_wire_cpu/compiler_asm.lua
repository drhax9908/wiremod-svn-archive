function ENT:InitializeRegisterNames()
	self.RegisterName = {}
	self.RegisterName["eax"] = 0
	self.RegisterName["ebx"] = 1
	self.RegisterName["ecx"] = 2
	self.RegisterName["edx"] = 3
	self.RegisterName["esi"] = 4
	self.RegisterName["edi"] = 5
	self.RegisterName["esp"] = 6
	self.RegisterName["ebp"] = 7

	self.RegisterName["cs"] = 8
	self.RegisterName["ss"] = 9
	self.RegisterName["ds"] = 10
	self.RegisterName["es"] = 11
	self.RegisterName["gs"] = 12
	self.RegisterName["fs"] = 13
	self.RegisterName["ks"] = 14
	self.RegisterName["ls"] = 15

	for i=0,1023 do
		self.RegisterName["port"..i] = 1000+i
	end

	self.SegmentName = {}
	self.SegmentName["eax"] = -10
	self.SegmentName["ebx"] = -11
	self.SegmentName["ecx"] = -12
	self.SegmentName["edx"] = -13
	self.SegmentName["esi"] = -14
	self.SegmentName["edi"] = -15
	self.SegmentName["esp"] = -16
	self.SegmentName["ebp"] = -17

	self.SegmentName["cs"] = -2
	self.SegmentName["ss"] = -3
	self.SegmentName["ds"] = -4
	self.SegmentName["es"] = -5
	self.SegmentName["gs"] = -6
	self.SegmentName["fs"] = -7
	self.SegmentName["ks"] = -8
	self.SegmentName["ls"] = -9

	self.GeneralRegister = {}
	self.GeneralRegister["eax"] = true
	self.GeneralRegister["ebx"] = true
	self.GeneralRegister["ecx"] = true
	self.GeneralRegister["edx"] = true
	self.GeneralRegister["esi"] = true
	self.GeneralRegister["edi"] = true
	self.GeneralRegister["esp"] = true
	self.GeneralRegister["ebp"] = true
end

function ENT:Message(msg)
	self.Player:PrintMessage(HUD_PRINTCONSOLE,"-> "..msg)
	self.Player:ConCommand("wire_cpu_editor_addlog \""..msg.."\"")
end

function ENT:Error(msg)
	if (self.CurrentFile == "") then
		self.Player:PrintMessage(HUD_PRINTCONSOLE,"-> Error at line "..self.Line..": "..msg)
	else
		self.Player:PrintMessage(HUD_PRINTCONSOLE,"-> "..self.CurrentFile..": Error at line "..(self.Line-self.FileStartLine)..": "..msg)
	end

//	self.Player:ConCommand("wire_cpu_editor_addlog \"".."-> Error at line "..self.Line..": "..msg.."\"") FIXME
	self.FatalError = true
end

function ENT:_whitespace()
	while ((string.sub(self.CurrentLine,1,1) == " ") ||
	       (string.sub(self.CurrentLine,1,1) == "	")) do
		self.CurrentLine = string.sub(self.CurrentLine,2,9999)
	end
end

function ENT:_need(char)
	if (string.sub(self.CurrentLine,1,1) ~= char) then
		return false
	else
		self.CurrentLine = string.sub(self.CurrentLine,2,9999)
		return true
	end
end

function ENT:_char()
	local char = string.sub(self.CurrentLine,1,1)
	self.CurrentLine = string.sub(self.CurrentLine,2,9999)
	return char
end

function ENT:_peek()
	return string.sub(self.CurrentLine,2,2)
end

function ENT:_getc()
	return string.sub(self.CurrentLine,1,1)
end

function ENT:_lcheck(keyword)
	if (keyword == "") then
		self:_need("@")
		return self:_keyword()
	else
		return keyword
	end		
end

function ENT:_getstring(sepchar)
	local str = ""
	self:_whitespace()
	while ((self.CurrentLine ~= "") && (self:_getc() ~= sepchar) && (self:_getc() ~= ")")) do //fixme isalphanum
		str = str .. _char()
	end
	return string.lower(str)
end

function ENT:_word()
	local word = ""
	while ((self.CurrentLine ~= "") &&
	      (string.sub(self.CurrentLine,1,1) ~= " ") && 
	      (string.sub(self.CurrentLine,1,1) ~= "(") &&
	      (string.sub(self.CurrentLine,1,1) ~= ")") &&
	      (string.sub(self.CurrentLine,1,1) ~= ";") &&
	      (string.sub(self.CurrentLine,1,1) ~= "#") &&
	      (string.sub(self.CurrentLine,1,1) ~= ":") &&
	      (string.sub(self.CurrentLine,1,1) ~= "@") &&
	      (string.sub(self.CurrentLine,1,1) ~= ",") &&
	      (string.sub(self.CurrentLine,1,1) ~= "'") &&
	      (string.sub(self.CurrentLine,1,1) ~= "\"") &&
	      (string.sub(self.CurrentLine,1,1) ~= "!") &&
	      (string.sub(self.CurrentLine,1,1) ~= "$") && 
	      (string.sub(self.CurrentLine,1,1) ~= "%") &&
	      (string.sub(self.CurrentLine,1,1) ~= "^") &&
	      (string.sub(self.CurrentLine,1,1) ~= "&") &&
	      (string.sub(self.CurrentLine,1,1) ~= "*") &&
	      (string.sub(self.CurrentLine,1,1) ~= "	")) do //FIXME: isalphanum
		word = word .. string.sub(self.CurrentLine,1,1)
		self.CurrentLine = string.sub(self.CurrentLine,2,9999)
	end
	return word
end


function ENT:_keyword()
	return string.lower(self:_word())
end

function ENT:Compiler_Stage0(pl)
	self.Player = pl

	self.FatalError = false
	self.Compiling = false
	self.MakeDump = false

	self.PrecompileData = {}
	self.DebugLines = {}
	self.DebugData = {}

	self.Dump = ""

	self.LocalVarRange = 128
	self.ReturnVariable = "eax"
end

function ENT:Compiler_Stage1()
	self.WIP = 0
	self.OffsetWIP = 0
	self.Labels = {}
	self.FunctionParams = {}
	self.FirstPass = true

	self.LastKeyword = ""
	self.Dump = ""
	self.CurrentFunction = nil

	self.CurrentFile = ""
	self.FileStartLine = 0

	self:SetLabel("programsize",0)
end

function ENT:Compiler_Stage2()
	self:SetLabel("programsize",self.WIP)

	self.WIP = 0
	self.OffsetWIP = 0
	self.FirstPass = false

	self.LastKeyword = ""
	self.Dump = ""
	self.CurrentFunction = nil

	self.CurrentFile = ""
	self.FileStartLine = 0
end

function ENT:ParseProgram_ASM(programtext,programline)
	self.CurrentLine = programtext
	self.Line = programline

	local comment = string.find(self.CurrentLine,"//")
	if (comment) then self.CurrentLine = string.sub(self.CurrentLine,1,comment-1) end

	self:Compile()
end

function ENT:GenerateASM(code)
	local templine = self.CurrentLine
	self.CurrentLine = code
	self:GenerateCode()	
	self.CurrentLine = templine
end

function ENT:ParseOpcodeParameter(keyword)
	local result = {}

	if (keyword == "") then //#EAX
		if (self:_need("#")) then
			keyword = self:_lcheck(self:_keyword())
			if (self.RegisterName[keyword]) then //#EAX
				if (self.GeneralRegister[keyword]) then
					result.RM = 17+self.RegisterName[keyword]
				else
					self:Error("Expected general register for memory reference, got '"..keyword.."' instead!")
				end
			else
				if ((self.FunctionParams[keyword]) && (self.Labels[self.CurrentFunction.Name].Param[keyword])) then //#functparam
					result.RM = 49
					result.Byte = self.CurrentFunction.ArgCount - self.Labels[self.CurrentFunction.Name].Param[keyword].Arg + 2
				else
					result.RM = 25
					result.Byte = self:GetValidValue(keyword) //#123
				end
			end
		else
			self:Error("Expected '#' for memory reference")
		end
	else
		if (self:_need(":")) then //Segment prefix
			if (self:_need("#")) then //EAX:#EBX
				if (self.RegisterName[keyword]) then //EAX:#EBX
					local register = self:_lcheck(self:_keyword())
					if (self.RegisterName[register]) then
						if (self.GeneralRegister[register]) then
							result.RM = 17+self.RegisterName[register]
							result.Segment = self.SegmentName[keyword]
						else
							self:Error("Expected general register for parameter with offset")
						end
					else
						result.RM = 25
						result.Byte = self:GetValidValue(register) //EAX:#123
						result.Segment = self.SegmentName[keyword]
					end
				else
					local register = self:_keyword()
					if (self.RegisterName[register]) then //123:#EBX
						if (self.GeneralRegister[register]) then
							result.RM = 34+self.RegisterName[register]
							result.Byte = self:GetValidValue(keyword)
						else
							self:Error("Expected general register name parameter with offset")
						end
					else
						self:Error("Expected register name for parameter with offset, got '"..keyword.."' instead!")
					end
				end
			else //EAX:EBX
				if (self.RegisterName[keyword]) then //EAX:EBX
					local register = self:_keyword()
					if (self.RegisterName[register]) then
						if (self.GeneralRegister[register]) then
							result.RM = 26+self.RegisterName[register]
							result.Segment = self.SegmentName[keyword]
						else
							self:Error("Expected general register for parameter with offset")
						end
					else
						self:Error("Expected register name for parameter with offset, got '"..keyword.."' instead!")
					end
				else
					local register = self:_keyword()
					if (self.RegisterName[register]) then //123:#EBX
						if (self.GeneralRegister[register]) then
							result.RM = 42+self.RegisterName[register]
							result.Byte = self:GetValidValue(keyword)
						else
							self:Error("Expected general register name parameter with offset")
						end
					else
						self:Error("Expected register name for parameter with offset, got '"..keyword.."' instead!")
					end
				end
			end
		else //No segment prefix, no memory reference
			if (self.RegisterName[keyword]) then //EAX
				result.RM = self.RegisterName[keyword]+1
			else
				if ((self.FunctionParams[keyword]) && (self.Labels[self.CurrentFunction.Name].Param[keyword])) then //functparam
					result.RM = 49
					result.Byte = self.CurrentFunction.ArgCount - self.Labels[self.CurrentFunction.Name].Param[keyword].Arg + 2
				else
					result.RM = 0
					result.Byte = self:GetValidValue(keyword) //123
				end
			end
		end
	end

	return result
end

function ENT:GenerateCode(keyword)
	//#EBX< >,< >EAX:#EBX< >
	local dRM1 = {}
	local dRM2 = {}
	if (keyword == nil) then
	 	self:_whitespace()
		keyword = self:_keyword()
		self:_whitespace()
	end

	if (self.OpcodeCount[self.DecodeOpcode[keyword]] > 0) then
		dRM1 = self:ParseOpcodeParameter(self:_lcheck(self:_keyword()))
		if (self.FatalError) then return end
	end
	if (self.OpcodeCount[self.DecodeOpcode[keyword]] > 1) then
		self:_whitespace()
		if (not self:_need(",")) then
			self:Error("Expected second operand for opcode '"..keyword.."'!")
		end
		self:_whitespace()
		dRM2 = self:ParseOpcodeParameter(self:_lcheck(self:_keyword()))
		if (self.FatalError) then return end
	end

	local XEIP = self.WIP
	local RM = 0
	local Opcode = self.DecodeOpcode[keyword]

	if (dRM1.RM) then RM = RM + dRM1.RM end
	if (dRM2.RM) then RM = RM + dRM2.RM*10000 end
	if (dRM1.Segment) then Opcode = Opcode + 1000 end
	if (dRM2.Segment) then Opcode = Opcode + 10000 end

	self:Write(Opcode)
	self:Write(RM)

	if (dRM1.Segment) then self:Write(dRM1.Segment) end
	if (dRM2.Segment) then self:Write(dRM2.Segment) end

	if (dRM1.Byte) then self:Write(dRM1.Byte) end
	if (dRM2.Byte) then self:Write(dRM2.Byte) end

	if (self.FirstPass == false) then
		self:Precompile(XEIP)
	end
end

function ENT:Compile()
	if (self.Debug) && (not self.FirstPass) then
		self.DebugLines[self.Line] = "["..self.Line.."]"..self.CurrentLine
		self.DebugData[self.WIP] = self.Line
	end
	self.Dump = self.Dump.."["..self.WIP.."]["..self.Line.."]"..self.CurrentLine.."\n"

	while (self.FatalError == false) && (self.CurrentLine ~= "") do
		//< >MOV< >
		if (self.WIP < 0) then
			self:Error("Write pointer out of range")
		end

	 	self:_whitespace()
		local word = self:_word()
		local keyword = string.lower(word)
		self:_whitespace()

		if (keyword == "") then return end

		if (self.DecodeOpcode[keyword]) then
			self:GenerateCode(keyword)
		elseif (keyword == "db") then
			local ParsingString = false
			while (self.FatalError == false) && (self.CurrentLine ~= "") && (not self:_need(";")) do	
				if (self:_need("'")) then
					if (ParsingString == true) then
						if (self:_peek() == "'") then
							self:_char()
							self:Write(string.byte("'"))
						else
							ParsingString = false
							self:_whitespace()
							self:_need(",")
							self:_whitespace()
						end
					else
						ParsingString = true					
					end
				end
				if (ParsingString == false) then
					if (self:_need("$")) then //Offset...
						local value = self:_lcheck(self:_keyword())
						self:Write(self.WIP+self:GetValidValue(value))
					else
						local value = self:_lcheck(self:_keyword())
						self:Write(self:GetValidValue(value))
					end
					self:_whitespace()
					self:_need(",")
					self:_whitespace()
				else
					local char = self:_char()
					self:Write(string.byte(char))
				end
			end
		elseif (keyword == "alloc") then
			local aword = self:_keyword()
			self:_whitespace()
			if (self:_need(",")) then
				if (aword == "") then
					self.Error("Missing first parameter for 'alloc' macro!")
					return
				end

				local bword = self:_lcheck(self:_keyword())
				self:_whitespace()
				if (self:_need(",")) then
					local cword = self:_lcheck(self:_keyword())

					if (bword == "") then
						self.Error("Missing second parameter for 'alloc' macro!")
						return
					end

					if (cword ~= "") then
						local size = 0
						local value = 0

						size = self:GetAlwaysValidValue(bword)
						value = self:GetValidValue(cword)

						for i=0,size-1 do
							self:Write(value)
						end
					else
						self:Error("Missing third parameter for 'alloc' macro!")
					end
				else
					if (bword ~= "") then //alloc mylabel,123;
						self:AddLabel(aword)
						self:Write(self:GetValidValue(bword))
					else
						self:Error("Missing second parameter for 'alloc' macro!")
					end
				end
			else
				if (aword ~= "") then //alloc mylabel;
					if (tonumber(aword)) then
						for i=0,aword-1 do
							self:Write(0)
						end
					else
						self:AddLabel(aword)
						self:Write(0)
					end
				else //alloc;
					self:Write(0)
				end
			end
		elseif (keyword == "define") then
			local definename = self:_keyword()
			self:_whitespace()
			if (self:_need(",")) then
				local definevalue = self:_lcheck(self:_keyword())
				if (self.FirstPass) then
					if (self.Labels[definename]) then
						self:Error("Label '"..definename.."' already exists (previously defined at line "..self.Labels[definename].DefineLine..")")
					else
						self.Labels[definename] = {}
						self.Labels[definename].WIP = self:GetValidValue(definevalue)
						self.Labels[definename].DefineLine = self.Line
					end
				end
			else
				self:Error("Error in 'define' macro syntax: missing second parameter (define value)")
			end
		elseif (keyword == "float") || (keyword == "scalar") || (keyword == "vector1f") then
			local name = self:_keyword()
			AddLabel(name)
			if (self:need(",")) then
				local x = self:_keyword()
				self:Write(self:GetValidValue(x))
			else
				self:Write(0)
			end
		elseif (keyword == "vector2f") || (keyword == "uv") || (keyword == "vector") then
			local name = self:_keyword()
			AddLabel(name)
			if (self:need(",")) then
				local x = self:_keyword()
				self:Write(self:GetValidValue(x))
				if (self:_need(",")) then
					local y = self:_keyword()
					self:Write(self:GetValidValue(y))
				else
					self:Write(0)
				end
			else
				self:Write(0)
				self:Write(0)
			end
		elseif (keyword == "vector3f") then
			local name = self:_keyword()
			AddLabel(name)
			if (self:need(",")) then
				local x = self:_keyword()
				self:Write(self:GetValidValue(x))
				if (self:_need(",")) then
					local y = self:_keyword()
					self:Write(self:GetValidValue(y))
					if (self:_need(",")) then
						local z = self:_keyword()
						self:Write(self:GetValidValue(z))
					else
						self:Write(0)
					end
				else
					self:Write(0)
					self:Write(0)
				end
			else
				self:Write(0)
				self:Write(0)
				self:Write(0)
			end
		elseif (keyword == "vector4f") || (keyword == "color") then
			local name = self:_keyword()
			AddLabel(name)
			if (self:need(",")) then
				local x = self:_keyword()
				self:Write(self:GetValidValue(x))
				if (self:_need(",")) then
					local y = self:_keyword()
					self:Write(self:GetValidValue(y))
					if (self:_need(",")) then
						local z = self:_keyword()
						self:Write(self:GetValidValue(z))
						if (self:_need(",")) then
							local w = self:_keyword()
							self:Write(self:GetValidValue(w))
						else
							self:Write(0)
						end
					else
						self:Write(0)
						self:Write(0)
					end
				else
					self:Write(0)
					self:Write(0)
					self:Write(0)
				end
			else
				self:Write(0)
				self:Write(0)
				self:Write(0)
				self:Write(0)
			end
		elseif (keyword == "code") then
			self:AddLabel("codestart")
			if (not self.FirstPass) && (not self.Labels["datastart"]) then
				self:Error("No matching 'data' macro was found!")
			end
		elseif (keyword == "data") then
			self:AddLabel("datastart")
			if (not self.FirstPass) && (not self.Labels["codestart"]) then
				self:Error("No matching 'code' macro was found!")
			end

			self:Write(self:GetValidValue("codestart"))
		elseif (keyword == "org") then
			local value = self:_lcheck(self:_keyword())
			self.WIP = self:GetValidValue(value)
		elseif (keyword == "offset") then
			local value = self:_lcheck(self:_keyword())
			self.OffsetWIP = self:GetValidValue(value)
		elseif (keyword == "wipe_locals") then
			self:WipeLocals()
		elseif (keyword == "wipe_labels") then
			self:WipeLabels()
		elseif (keyword == "setvar") then
			local varname = self:_keyword()
			if (varname ~= "") then
				self:_whitespace()
				if (self:_need(",")) then
					local varvalue = self:_keyword()
					if (varvalue ~= "") then
						//Set compiler variables
						if (varname == "localrange") then
							if tonumber(varvalue) then self.LocalVarRange = tonumber(varvalue) end
						end
						if (varname == "returnregister") then
							if self.GeneralRegister[varvalue] then self.ReturnVariable = varvalue end
						end
					else
						self:Error("Missing variable value for 'setvar' macro")
					end
				end
			else
				self:Error("Missing variable name for 'setvar' macro")
			end
		elseif (keyword == "asmfile") then
			local filename  = self:_getstring(";")

			self.CurrentFile = filename
			self.FileStartLine = self.Line
		elseif (keyword == "asmend") then
			self.CurrentFile = ""
		elseif (keyword == "function") then
			if (self.CurrentFunction) then
				self:Error("Can't have function inside function!")
			end

			local fname = self:_keyword()
			local argscnt = 0

			self:AddLabel(fname)
			self:GenerateASM("push ebp")
			self:GenerateASM("mov ebp,1:esp")

			if (self:_need("(")) then
				local argument = self:_getstring(",")
				while (argument ~= "") do
					self:AddFunctionArgument(fname,argument,argscnt)

					argscnt = argscnt + 1
					if (self:_need(",")) then
						argument = self:_getstring(",")
					else
						argument = ""
					end
				end
			end		

			self.CurrentFunction = {}
			self.CurrentFunction.ArgCount = argscnt
			self.CurrentFunction.Name = fname
		elseif (keyword == "return") then
			local retval = self:_getstring(";")
			if (retval ~= "") then
				if (retval ~= "eax") then
					self:GenerateASM("mov "..self.ReturnVariable..","..retval)
				end
			end
			self:GenerateASM("ret")
		elseif (keyword == "end") then
			if (not self.CurrentFunction) then
				self:Error("END must be inside function")
			end

			if (self.LastKeyword ~= "return") then
				self:GenerateASM("ret")
			end
			self.CurrentFunction = nil
		elseif (keyword == "getarg") then
			if (not self.CurrentFunction) then
				self:Error("GETARG must be inside function")
			end
			
			if (self:_need("(")) then
				local where = self:_getstring(",")
				self:_need(",")
				local argno = self:GetValidValue(self:_keyword())
				self:GenerateASM("mov "..where..","..(self.CurrentFunction.ArgCount - argno + 2))
			else
				self:Error("GETARG: syntax error")
			end
		elseif (self:_need("(")) then //High-level function call
			//Function call
			local address = self:GetValidValue(keyword)
			local argscnt = 0
			
			local argument = self:_getstring(",")
			while (argument ~= "") do
				self:GenerateASM("push "..argument)

				argscnt = argscnt + 1
				if (self:_need(",")) then
					argument = self:_getstring(",")
				else
					argument = ""
				end
			end

			self:GenerateASM("mov ecx,"..argscnt)
			self:GenerateASM("call "..address)
			if (argscnt ~= 0) then
				self:GenerateASM("mov esp,ebp:-"..argscnt)
			end

			if (not self:_need(")")) then
				self:Error("Error in function call syntax")
			end
		else //Label
			local locvar = false
			local globvar = false

			if (self:_need("@")) then locvar = true elseif
			   (self:_need("$")) then globvar = true end

			if (self:_need(":")) then
				if (locvar == true) then
					self:AddLocalLabel(keyword)
				elseif (globvar == true) then
					self:AddGlobalLabel(keyword)
				else
					self:AddLabel(keyword)
				end
			else
				if (keyword ~= "") then
					local peek = self:_peek()
					if (peek == ";") then
						self:Error("Invalid label definition or unknown keyword '"..keyword.."' (expecting ':' rather than ';')")
					else
						self:Error("Unknown keyword '"..keyword.."'")
					end
				else
					self:Error("Unexpected character")
				end
			end
		end

		self.LastKeyword = keyword

		self:_whitespace()
		self:_need(";")
	end
end

function ENT:GetLabel(labelname)
	local foundlabel = nil
	for labelk,labelv in pairs(self.Labels) do
		if (labelk == labelname)/* and 
		  ((labelv.Local == false) or 
		  ((labelv.Local) and (math.abs(WIP - labelv.WIP) < LocalVarRange)))*/ then
			foundlabel = labelv
			return foundlabel
			//fixme: stop
		end
	end
	return foundlabel
end

function ENT:GetValidValue(labelname)
	if (labelname == "") then return 0 end
	if (tonumber(labelname)) then
		return tonumber(labelname)
	else
		local foundlabel = self:GetLabel(labelname)

		if (foundlabel) then
			return foundlabel.WIP+self.OffsetWIP
		else
			if (not self.FirstPass) then
				self:Error("Expected number or a valid label")
			end
			return 0
		end
	end
end

function ENT:GetAlwaysValidValue(labelname)
	if (labelname == "") then return 0 end
	if (tonumber(labelname)) then
		return tonumber(labelname)
	else
		local foundlabel = self:GetLabel(labelname)

		if (foundlabel) then
			return foundlabel.WIP+self.OffsetWIP
		else
			self:Error("Expected number or a valid label, defined BEFORE this line")
			return 0
		end
	end
end

function ENT:SetLabel(labelname,value)
	if (self.Labels[labelname]) then
		self.Labels[labelname].WIP = value
	else
		self.Labels[labelname] = {}
		self.Labels[labelname].WIP = self.WIP
		self.Labels[labelname].DefineLine = self.Line
	end
end

function ENT:AddLabel(labelname)
	if (self.FirstPass) then
		if (self:GetLabel(labelname)) then
			self:Error("Label '"..labelname.."' already exists (previously defined at line "..self.Labels[labelname].DefineLine..")")
		else
			self.Labels[labelname] = {}
			self.Labels[labelname].WIP = self.WIP
			self.Labels[labelname].DefineLine = self.Line
		end
	else
		if (self.Labels[labelname]) then
			if (self.Labels[labelname].WIP ~= self.WIP) then
				self.Labels[labelname].WIP = self.WIP
				self:Error("Label pointer changed between stages - report this to Black Phoenix!")
			end
		end
	end
end

function ENT:AddFunctionArgument(functionname,labelname,argno)
	if (self.FirstPass) then
		if (!self:GetLabel(functionname)) then
			self:Error("Internal error - report to black phoenix! (code AF8828Z8A)")
		end

		if (self.Labels[functionname].Param[labelname]) then
			self:Error("Function parameter '"..labelname.."' already exists)")
		else
			if (not self.Labels[functionname].Param) then
				self.Labels[functionname].Param = {}
			end
			self.Labels[functionname].Param[labelname] = {}
			self.Labels[functionname].Param[labelname].Arg = argno
			self.FunctionParams[labelname] = true
		end
	end
end

function ENT:AddLocalLabel(labelname)
	if (self.FirstPass) then
		if (self:GetLabel(labelname)) then
			self:Error("Label '"..labelname.."' already exists (previously defined at line "..self.Labels[labelname].DefineLine..")")
		else
			self.Labels[labelname] = {}
			self.Labels[labelname].WIP = self.WIP
			self.Labels[labelname].DefineLine = self.Line
			self.Labels[labelname].Local = true
		end
	else
		if (self.Labels[labelname]) then
			if (self.Labels[labelname].WIP ~= self.WIP) then
				self.Labels[labelname].WIP = self.WIP
				self:Error("Label pointer changed between stages - report this to Black Phoenix!")
			end
		end
	end
end

function ENT:AddGlobalLabel(labelname)
	if (self.FirstPass) then
		if (self:GetLabel(labelname)) then
			self:Error("Label '"..labelname.."' already exists (previously defined at line "..self.Labels[labelname].DefineLine..")")
		else
			self.Labels[labelname] = {}
			self.Labels[labelname].WIP = self.WIP
			self.Labels[labelname].DefineLine = self.Line
			self.Labels[labelname].Global = true
		end
	else
		if (self.Labels[labelname]) then
			if (self.Labels[labelname].WIP ~= self.WIP) then
				self.Labels[labelname].WIP = self.WIP
				self:Error("Label pointer changed between stages - report this to Black Phoenix!")
			end
		end
	end
end

function ENT:WipeLocals()
	for labelk,labelv in pairs(self.Labels) do
		if (labelv.Local) then
			self.Labels[labelk] = nil
		end
	end
end

function ENT:WipeLabels()
	for labelk,labelv in pairs(self.Labels) do
		if (not labelv.Global) then
			self.Labels[labelk] = nil
		end
	end
end