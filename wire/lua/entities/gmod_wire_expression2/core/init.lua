AddCSLuaFile('init.lua')

/******************************************************************************\
  Expression 2 for Garry's Mod
  Andreas "Syranide" Svensson, me@syranide.com
\******************************************************************************/

// ADD FUNCTIONS FOR COLOR CONVERSION!
// ADD CONSOLE SUPPORT

/*
n = numeric
v = vector
s = string
t = table
e = entity
x = non-basic extensions prefix
*/

delta = 0.0000001000000

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/

wire_expression_callbacks = {}
wire_expression_callbacks['construct'] = {}
wire_expression_callbacks['destruct'] = {}
wire_expression_callbacks['preexecute'] = {}
wire_expression_callbacks['postexecute'] = {}

wire_expression_types = {}
wire_expression_types2 = {}
local funcs = {}
funclist = {}

function registerType(name, id, def, incb, outcb)
	wire_expression_types[string.upper(name)] = {id, def, incb, outcb}
	wire_expression_types2[id] = {string.upper(name), def, incb, outcb}
	if SERVER then
		if WireLib.DT[string.upper(name)] == nil then
			WireLib.DT[string.upper(name)] = {}
			WireLib.DT[string.upper(name)].Zero = def
		end
	end
end


function registerCallback(event, callback)
	wire_expression_callbacks[event][#wire_expression_callbacks[event] + 1] = callback
end

function registerCallback(event, callback)
	wire_expression_callbacks[event][#wire_expression_callbacks[event] + 1] = callback
end

function registerOperator(name, pars, rets, func)
	funcs["op:" .. name .. "(" .. pars .. ")"] = { "op:" .. name .. "(" .. pars .. ")", rets, func }
end

function registerFunction(name, pars, rets, func)
	funcs[name .. "(" .. pars .. ")"] = { name .. "(" .. pars .. ")", rets, func }
	funclist[name] = true
end

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/

/******************************************************************************\
  Helpers
\******************************************************************************/

local function stringlimit(text, length)
	if string.len(text) <= length then
		return text
	else
		return string.sub(text, 1, length) .. "..."
	end
end

/******************************************************************************\
  PreProcessor
\******************************************************************************/

PreProcessor = {}

function PreProcessor:Execute(...)
	self.__index = self
	self = setmetatable({}, self)
	
	return pcall(PreProcessor.Process, self, ...)
end

function PreProcessor:Error(message)
	error(message .. " at line " .. self.readline .. ", char " .. 1, 0)
end

function PreProcessor:Process(buffer, params)
	lines = string.Explode("\n", buffer)
	
	local directives = {
		name = nil,
		inputs = { {}, {}, {} },
		outputs = { {}, {}, {} },
		persist = { {}, {}, {} },
		delta = { {}, {}, {} },
	}
	
	local incode = false
	local directive, value
	
	for i,line in ipairs(lines) do
		self.readline = i
		line = string.TrimRight(line)
		
		local comment = string.find(line, "#", 1, true)
		if comment then
			if comment == 1 then
				line = ""
			else
				line = string.sub(line, 1, comment - 1)
			end
			
			lines[i] = line
		end
		
		if string.sub(line, 1, 1) == "@" then
			local position = string.find(line, " ", 2, true)
			
			if position then
				directive = string.sub(line, 2, position - 1)
				value = string.Trim(string.sub(line, position + 1))
			else 
				directive = string.sub(line, 2)
				value = ""
			end
			
			if directive != string.lower(directive) then
				self:Error("Directive (@" .. stringlimit(directive, 10) .. ") must be lowercase")
			elseif incode then
				self:Error("Directive (@" .. stringlimit(directive, 10) .. ") must appear before code")
			end
			
			lines[i] = ""
			
			if directive == "name" then
				if directives.name == nil then
					directives.name = value
				else
					self:Error("Directive (@name) must not be specified twice")
				end
			elseif directive == "inputs" then
				local retval = self:ParsePorts(value)
				
				for i,key in ipairs(retval[1]) do
					if directives.inputs[3][key] then
						self:Error("Directive (@input) contains multiple definitions of the same variable")
					else
						local index = #directives.inputs[1] + 1
						directives.inputs[1][index] = key
						directives.inputs[2][index] = retval[2][i]
						directives.inputs[3][key] = retval[2][i]
					end
				end
			elseif directive == "outputs" then
				local retval = self:ParsePorts(value)
				
				for i,key in ipairs(retval[1]) do
					if directives.outputs[3][key] then
						self:Error("Directive (@output) contains multiple definitions of the same variable")
					else
						local index = #directives.outputs[1] + 1
						directives.outputs[1][index] = key
						directives.outputs[2][index] = retval[2][i]
						directives.outputs[3][key] = retval[2][i]
					end
				end
			elseif directive == "persist" then
				local retval = self:ParsePorts(value)
				
				for i,key in ipairs(retval[1]) do
					if directives.persist[3][key] then
						self:Error("Directive (@persist) contains multiple definitions of the same variable")
					else
						local index = #directives.persist[1] + 1
						directives.persist[1][index] = key
						directives.persist[2][index] = retval[2][i]
						directives.persist[3][key] = retval[2][i]
					end
				end
			else
				self:Error("Unknown directive found (@" .. stringlimit(directive, 10) .. ")")
			end
		elseif line != "" then
			incode = true
		end
	end
	
	if !directives.name then directives.name = "" end
	
	return { directives, string.Implode("\n", lines) }
end


function PreProcessor:ParsePorts(ports)
	local vals = {}
	local names = {}
	local types = {}
	local keys = {}
	local tp = "NORMAL"
	ports = string.Explode(" ", string.Trim(ports))
	
	for _,key in ipairs(ports) do
		key = string.Trim(key)
		if key ~= "" then
			character = string.sub(key, 1, 1)
			charvalue = string.byte(character)
			if charvalue >= 65 and charvalue <= 90 or character == "_" then
				for i=2,string.len(key) do
					character = string.sub(key, i, i)
					charvalue = string.byte(character)
					if character and charvalue >= 65 and charvalue <= 90 or charvalue >= 97 and charvalue <= 122 or character >= "0" and character <= "9" or character == "_" then
					elseif character == ":" then
						tp = string.sub(key, i + 1, string.len(key))
						key = string.sub(key, 1, i - 1)
						
						if tp != string.lower(tp) then
							self:Error("Variable type (" .. stringlimit(tp, 10) .. ") must be lowercase")
						elseif !wire_expression_types[string.upper(tp)] then
							self:Error("Unknown variable type (" .. stringlimit(tp, 10) .. ") specified for variable (" .. stringlimit(key, 10) .. ")")
						end
						break
					else
						self:Error("Variable declaration (" .. stringlimit(key, 10) .. ") contains invalid characters")
					end
				end
			else
				self:Error("Variable declaration (" .. stringlimit(key, 10) .. ") contains invalid characters")
			end
			
			if keys[key] then
				self:Error("Variable (" .. stringlimit(key, 10) .. ") is already declared") -- this should be removed
			else
				names[#names + 1] = key
				types[#types + 1] = string.upper(tp)
				keys[key] = string.upper(tp)
				tp = "NORMAL"
				--table.insert(vals, key)
			end
		end
	end
	
	return { names, types }
end


/******************************************************************************\
  Tokenizer
\******************************************************************************/

Tokenizer = {}

function Tokenizer:Execute(...)
	self.__index = self
	self = setmetatable({}, self)
	
	return pcall(Tokenizer.Process, self, ...)
end

function Tokenizer:Error(message)
	error(message .. " at line " .. self.tokenline .. ", char " .. self.tokenchar, 0)
end

function Tokenizer:Process(buffer, params)
	self.buffer = buffer
	self.length = string.len(buffer)
	self.position = 0
	
	self:SkipCharacter()
	
	local tokens = {}
	local tokenname, tokendata, tokenspace
	
	while self.character do
		tokenspace = false
		
		while self.character == " " or self.character == "\t" or
		      self.character == "\n" or self.character == "\r"
		do
			self:SkipCharacter()
			tokenspace = true
		end
		
		if !self.character then break end
		
		self.tokenline = self.readline
		self.tokenchar = self.readchar
		self.tokendata = ""
		
		tokenname, tokendata = self:NextSymbol()
		
		if tokenname == nil then
			tokenname, tokendata = self:NextOperator()
			
			if tokenname == nil then
				self:Error("Unknown character found (" .. self.character .. ")")
			end
		end
		
		tokens[#tokens + 1] = { tokenname, tokendata, tokenspace, self.tokenline, self.tokenchar }
	end
	
	return tokens
end

/******************************************************************************/

function Tokenizer:SkipCharacter()
	if self.position < self.length then
		if self.position > 0 then
			if self.character == "\n" then
				self.readline = self.readline + 1
				self.readchar = 1
			else
				self.readchar = self.readchar + 1
			end
		else
			self.readline = 1
			self.readchar = 1
		end
	
		self.position   = self.position + 1
		self.character  = string.sub(self.buffer, self.position, self.position)
	else
		self.character = nil
	end
end

function Tokenizer:NextCharacter()
	self.tokendata = self.tokendata .. self.character
	self:SkipCharacter()
end

function Tokenizer:NextSymbol()
	if self.character >= "0" and self.character <= "9" then
		local formaterror = false
		
		if self.character == "0" then
			self:NextCharacter()
			if self.character and self.character >= "0" and self.character <= "9" then
				formaterror = true
			end
		else
			self:NextCharacter()
		end
		
		while self.character and self.character >= "0" and self.character <= "9" do self:NextCharacter() end
		
		if self.character and self.character == "." then
			self:NextCharacter()
			if !(self.character and self.character >= "0" and self.character <= "9") then
				formaterror = true
			else
				self:NextCharacter()
				while self.character and self.character >= "0" and self.character <= "9" do self:NextCharacter() end
			end
		end
		
		if self.character and (self.character >= "a" and self.character <= "z" or self.character >= "A" and self.character <= "Z" or self.character == "_") then
			self:NextCharacter()
			formaterror = true
		end
		
		if formaterror then
			self:Error("Invalid number format (" .. stringlimit(self.tokendata, 10) .. ")")
		end
		
		tokenname = "num"
	elseif self.character >= "a" and self.character <= "z" then
		self:NextCharacter()
		while self.character and (self.character >= "a" and self.character <= "z" or self.character >= "A" and self.character <= "Z" or
		                          self.character >= "0" and self.character <= "9" or self.character == "_") do self:NextCharacter() end
		
		if(self.tokendata == "if") then
			tokenname = "if"
		elseif(self.tokendata == "elseif") then
			tokenname = "eif"
		elseif(self.tokendata == "else") then
			tokenname = "els"
		else
			tokenname = "fun"
		end
	elseif self.character >= "A" and self.character <= "Z" then
		self:NextCharacter()
		while self.character and (self.character >= "a" and self.character <= "z" or self.character >= "A" and self.character <= "Z" or
		                          self.character >= "0" and self.character <= "9" or self.character == "_") do self:NextCharacter() end
		
		tokenname = "var"
	elseif self.character == "\"" then
		self:SkipCharacter()
		while self.character != "\"" do
			if self.character == "\\" then self:SkipCharacter() end
			
			if self.character == "\n" or !self.character then
				self:Error("Unterminated string (\"" .. stringlimit(self.tokendata, 10) .. ")") 
			end
			
			self:NextCharacter()
		end
		self:SkipCharacter()
		
		tokenname = "str"
	else
		return
	end
	
	return tokenname, self.tokendata
end


// TODO: rewrite this!
local optable = {
	["+"] = {"add", {["="] = {"aadd"}, ["+"] = {"inc"}}},
	["-"] = {"sub", {["="] = {"asub"}, ["-"] = {"dec"}}},
	["*"] = {"mul", {["="] = {"amul"}}},
	["/"] = {"div", {["="] = {"adiv"}}},
	["%"] = {"mod"},
	["^"] = {"exp"},
	
	["="] = {"ass", {["="] = {"eq"}}},
	["!"] = {"not", {["="] = {"neq"}}},
	[">"] = {"gth", {["="] = {"geq"}}},
	["<"] = {"lth", {["="] = {"leq"}}},
	
	["&"] = {"and"},
	["|"] = {"or"},
	
	["?"] = {"qsm"},
	[":"] = {"col"},
	[","] = {"com"},
	
	["("] = {"lpa"},
	[")"] = {"rpa"},
	["{"] = {"lcb"},
	["}"] = {"rcb"},

	["$"] = {"dlt"},
	["~"] = {"trg"},
}

// TODO: rewrite this!
function Tokenizer:NextOperator()
	local op = optable

	if op[self.character] then
		while true do
			op = op[self.character]
			self:NextCharacter()
			
			if self.character then
				if op[2] then
					
					if op[2][self.character] then
						op = op[2]
					else
						self.tokendata = self.buffer
						return op[1], self.tokendata
					end
				else
					self.tokendata = self.buffer
					return op[1], self.tokendata
				end
			else
				if op[1] then
					self.tokendata = self.buffer
					return op[1], self.tokendata
				else
					return
				end
			end
		end
	else
		return
	end
end

/******************************************************************************\
  Parser
\******************************************************************************/
/*

Root
 1 : q1

seQuencing
 1 : ""
 2 : "s1 q1", "s1, q2"
 
Statement
 1 : if(e1) { q1 } i1
 2 : var++, var--
 3 : var += e1, var -= e1, var *= e1, var /= e1
 4 : var = s4
 5 : e1

If
 1 : elseif(e1) { q1 } i1
 2 : else { q1 }

Expression
 1 : var = e1, var += e1, var -= e1, var *= e1, var /= e1 [ERROR]
 2 : e3 ? e1 : e1
 3 : e3 | e4
 4 : e4 & e5
 5 : e5 == e6, e5 != e6
 6 : e6 < e7, e6 > e7, e6 <= e7, e6 >= e7
 7 : e7 + e8, e7 - e8
 8 : e8 * e9, e8 / e9, e8 % e9
 9 : e9 ^ e10
10 : -e11, !e11
11 : e11:fun([e1, ...]), [e11.sub] [IMPLEMENT TABLE INDEX!]
12 : (e1), fun([e1, ...])
13 : string, num, ~var, $var
14 : var++, var-- [ERROR]
15 : var

*/
/******************************************************************************/

Parser = {}

function Parser:Execute(...)
	self.__index = self
	self = setmetatable({}, self)
	
	return pcall(Parser.Process, self, ...)
end

function Parser:Error(message, token)
	if token then
		error(message .. " at line " .. token[4] .. ", char " .. token[5], 0)
	else
		error(message .. " at line " .. self.token[4] .. ", char " .. self.token[5], 0)
	end
end

function Parser:Process(tokens, params)
	self.tokens = tokens
	
	self.index = 0
	self.count = #tokens
	self.delta = {}
	
	self:NextToken()
	local tree = self:Root()
	
	return { tree, self.delta }
end

/******************************************************************************/

function Parser:GetToken()
	return self.token
end

function Parser:GetTokenData()
	return self.token[2]
end

function Parser:GetTokenTrace()
	return {self.token[4], self.token[5]}
end


function Parser:Instruction(trace, name, ...)
	return {name, trace, ...} //
end


function Parser:HasTokens()
	return self.readtoken != nil
end

function Parser:NextToken()
	if self.index <= self.count then
		if self.index > 0 then
			self.token = self.readtoken
		else
			self.token = {"", "", false, 1, 1}
		end
		
		self.index = self.index + 1
		self.readtoken = self.tokens[self.index]
	else
		self.readtoken = nil
	end
end

function Parser:TrackBack()
    self.index = self.index - 2
	self:NextToken()
end


function Parser:AcceptRoamingToken(name)
	local token = self.readtoken
	if !token or token[1] != name then return false end
	
	self:NextToken()
	return true
end

function Parser:AcceptTailingToken(name)
	local token = self.readtoken
	if !token or token[3] then return false end
	
	return self:AcceptRoamingToken(name)
end

function Parser:AcceptLeadingToken(name)
	local token = self.tokens[self.index + 1]
	if !token or token[3] then return false end
	
	return self:AcceptRoamingToken(name)
end


function Parser:RecurseLeft(func, tbl)
	local expr = func(self)
	local hit = true
	
	while hit do
		hit = false
		for i=1,#tbl do
			if self:AcceptRoamingToken(tbl[i]) then
				local trace = self:GetTokenTrace()
				
				hit = true
				expr = self:Instruction(trace, tbl[i], expr, func(self))
				break
			end
		end
	end
	
	return expr
end

/******************************************************************************/

function Parser:Root()
	return self:Stmts()
end


function Parser:Stmts()
	local trace = self:GetTokenTrace()
	local stmts = self:Instruction(trace, "seq")

	if !self:HasTokens() then return stmts end
	
	while true do
		if self:AcceptRoamingToken("com") then
			self:Error("Statement separator (,) must not appear multiple times")
		end
		
		stmts[#stmts + 1] = self:Stmt1()
		
		if !self:HasTokens() then break end
		
		if !self:AcceptRoamingToken("com") then
			if self.readtoken[3] == false then
				self:Error("Statements must be separated by comma (,) or whitespace")
			end
		end
	end
	
	return stmts
end


function Parser:Stmt1()
	if self:AcceptRoamingToken("if") then
		local trace = self:GetTokenTrace()
		return self:Instruction(trace, "if", self:IfCond(), self:IfBlock(), self:IfElseIf())
	end
	
	return self:Stmt2()
end

function Parser:Stmt2()
	if self:AcceptRoamingToken("var") then
		local trace = self:GetTokenTrace()
		local var = self:GetTokenData()
		
		if self:AcceptTailingToken("inc") then
			return self:Instruction(trace, "inc", var)
		elseif self:AcceptRoamingToken("inc") then
			self:Error("Increment operator (++) must not be preceded by whitespace")
		end
		
		if self:AcceptTailingToken("dec") then
			return self:Instruction(trace, "dec", var)
		elseif self:AcceptRoamingToken("dec") then
			self:Error("Decrement operator (--) must not be preceded by whitespace")
		end
		
		self:TrackBack()
	end
	
	return self:Stmt3()
end

function Parser:Stmt3()
	if self:AcceptRoamingToken("var") then
		local trace = self:GetTokenTrace()
		local var = self:GetTokenData()
		
		if self:AcceptRoamingToken("aadd") then
			return self:Instruction(trace, "ass", var, self:Instruction(trace, "add", self:Instruction(trace, "var", var), self:Expr1()))
		elseif self:AcceptRoamingToken("asub") then
			return self:Instruction(trace, "ass", var, self:Instruction(trace, "sub", self:Instruction(trace, "var", var), self:Expr1()))
		elseif self:AcceptRoamingToken("amul") then
			return self:Instruction(trace, "ass", var, self:Instruction(trace, "mul", self:Instruction(trace, "var", var), self:Expr1()))
		elseif self:AcceptRoamingToken("adiv") then
			return self:Instruction(trace, "ass", var, self:Instruction(trace, "div", self:Instruction(trace, "var", var), self:Expr1()))
		end
		
		self:TrackBack()
	end
	
	return self:Stmt4()
end

function Parser:Stmt4()
	if self:AcceptRoamingToken("var") then
		local trace = self:GetTokenTrace()
		local var = self:GetTokenData()
		
		if self:AcceptRoamingToken("ass") then
			return self:Instruction(trace, "ass", var, self:Stmt4())
		end
		
		self:TrackBack()
	end
	
	return self:Stmt5()
end

function Parser:Stmt5()
	return self:Expr1()
end


function Parser:IfElseIf()
	if self:AcceptRoamingToken("eif") then
		local trace = self:GetTokenTrace()
		return self:Instruction(trace, "if", self:IfCond(), self:IfBlock(), self:IfElseIf())
	end
	
	return self:IfElse()
end

function Parser:IfElse()
	if self:AcceptRoamingToken("els") then
		return self:IfBlock()
	end
	
	local trace = self:GetTokenTrace()
	return self:Instruction(trace, "seq")
end

function Parser:IfCond()
	if !self:AcceptRoamingToken("lpa") then
		self:Error("Left parenthesis (() must appear before if-statement condition")
	end
	
	local expr = self:Expr1()
	
	if !self:AcceptRoamingToken("rpa") then
		self:Error("Right parenthesis ()) missing, to close if-statement condition")
	end
	
	return expr
end


function Parser:IfBlock()
	local trace = self:GetTokenTrace()
	local stmts = self:Instruction(trace, "seq")
	
	if !self:AcceptRoamingToken("lcb") then
		self:Error("Left curly bracket ({) must appear after if-statement condition")
	end
	
	local token = self:GetToken()
	
	if self:AcceptRoamingToken("rcb") then
		return stmts
	end
	
	if self:HasTokens() then
		while true do
			if self:AcceptRoamingToken("com") then
				self:Error("Statement separator (,) must not appear multiple times")
			elseif self:AcceptRoamingToken("rcb") then
				self:Error("Statement separator (,) must be suceeded by statement")
			end
			
			stmts[#stmts + 1] = self:Stmt1()
			
			if self:AcceptRoamingToken("rcb") then
				return stmts
			end
			
			if !self:AcceptRoamingToken("com") then
				if !self:HasTokens() then break end
			
				if self.readtoken[3] == false then
					self:Error("Statements must be separated by comma (,) or whitespace")
				end
			end
		end
	end
	
	self:Error("Right curly bracket (}) missing, to close if-statement block", token)
end


function Parser:Expr1()
	self.exprtoken = self:GetToken()

	if self:AcceptRoamingToken("var") then
		if self:AcceptRoamingToken("ass") then
			self:Error("Assignment operator (=) must not be part of equation")
		end
		
		if self:AcceptRoamingToken("aadd") then
			self:Error("Additive assignment operator (+=) must not be part of equation")
		elseif self:AcceptRoamingToken("asub") then
			self:Error("Subtractive assignment operator (-=) must not be part of equation")
		elseif self:AcceptRoamingToken("amul") then
			self:Error("Multiplicative assignment operator (*=) must not be part of equation")
		elseif self:AcceptRoamingToken("adiv") then
			self:Error("Divisive assignment operator (/=) must not be part of equation")
		end
		
		self:TrackBack()
	end

	return self:Expr2()
end

function Parser:Expr2()
	local expr = self:Expr3()
	
	if self:AcceptRoamingToken("qsm") then
		local trace = self:GetTokenTrace()
		local exprtrue = self:Expr1()
		
		if !self:AcceptRoamingToken("col") then -- perhaps we want to make sure there is space around this (method bug)
			self:Error("Conditional operator (:) must appear after expression to complete conditional", token)
		end
		
		return self:Instruction(trace, "cnd", expr, exprtrue, self:Expr1())
	end
	
	return expr
end

function Parser:Expr3()
	return self:RecurseLeft(self.Expr4, {"or"})
end

function Parser:Expr4()
	return self:RecurseLeft(self.Expr5, {"and"})
end

function Parser:Expr5()
	return self:RecurseLeft(self.Expr6, {"eq", "neq"})
end

function Parser:Expr6()
	return self:RecurseLeft(self.Expr7, {"gth", "lth", "geq", "leq"})
end

function Parser:Expr7()
	return self:RecurseLeft(self.Expr8, {"add", "sub"})
end

function Parser:Expr8()
	return self:RecurseLeft(self.Expr9, {"mul", "div", "mod"})
end

function Parser:Expr9()
	return self:RecurseLeft(self.Expr10, {"exp"})
end

function Parser:Expr10()
	if self:AcceptLeadingToken("sub") then
		local trace = self:GetTokenTrace()
		return self:Instruction(trace, "neg", self:Expr11())
	elseif self:AcceptRoamingToken("sub") then
		self:Error("Negation operator (-) must not be succeeded by whitespace")
	end
	
	if self:AcceptLeadingToken("not") then
		local trace = self:GetTokenTrace()
		return self:Instruction(trace, "not", self:Expr11())
	elseif self:AcceptRoamingToken("not") then
		self:Error("Logical not operator (-) must not be succeeded by whitespace")
	end
	
	return self:Expr11()
end

function Parser:Expr11()
	local expr = self:Expr12()

	while true do
		if self:AcceptTailingToken("col") then
			if !self:AcceptTailingToken("fun") then
				if self:AcceptRoamingToken("fun") then
					self:Error("Method operator (:) must not be preceded by whitespace")
				else
					self:Error("Method operator (:) must be followed by method name")
				end
			end
			
			local trace = self:GetTokenTrace()
			local fun = self:GetTokenData()
			
			if !self:AcceptTailingToken("lpa") then
				if self:AcceptRoamingToken("lpa") then
					self:Error("Left parenthesis (() must not be preceded by whitespace")
				else
					self:Error("Left parenthesis (() must appear after method name")
				end
			end
			
			local token = self:GetToken()
			
			if self:AcceptRoamingToken("rpa") then
				expr = self:Instruction(trace, "mto", fun, expr, {})
			else
				local exprs = {self:Expr1()}
				
				while self:AcceptRoamingToken("com") do
					exprs[#exprs + 1] = self:Expr1()
				end
				
				if !self:AcceptRoamingToken("rpa") then
					self:Error("Right parenthesis ()) missing, to close method argument list", token)
				end
				
				expr = self:Instruction(trace, "mto", fun, expr, exprs)
			end
		--elseif self:AcceptRoamingToken("col") then
		--	self:Error("Method operator (:) must not be preceded by whitespace")
		else
			break
		end
	end
	
	return expr
end

function Parser:Expr12()
	if self:AcceptRoamingToken("lpa") then
		local token = self:GetToken()
	
		local expr = self:Expr1()
		
		if !self:AcceptRoamingToken("rpa") then
			self:Error("Right parenthesis ()) missing, to close grouped equation", token)
		end
		
		return expr
	end
	
	if self:AcceptRoamingToken("fun") then
		local trace = self:GetTokenTrace()
		local fun = self:GetTokenData()
		
		if !self:AcceptTailingToken("lpa") then
			if self:AcceptRoamingToken("lpa") then
				self:Error("Left parenthesis (() must not be preceded by whitespace")
			else
				self:Error("Left parenthesis (() must appear after function name, variables must start with uppercase letter,")
			end
		end
		
		local token = self:GetToken()
		
		if self:AcceptRoamingToken("rpa") then
			return self:Instruction(trace, "fun", fun, {})
		else
			local exprs = {self:Expr1()}
			while self:AcceptRoamingToken("com") do
				exprs[#exprs + 1] = self:Expr1()
			end
			
			if !self:AcceptRoamingToken("rpa") then
				self:Error("Right parenthesis ()) missing, to close function argument list", token)
			end
			
			return self:Instruction(trace, "fun", fun, exprs)
		end
	end
	
	return self:Expr13()
end

function Parser:Expr13()
	if self:AcceptRoamingToken("num") then
		local trace = self:GetTokenTrace()
		local num = self:GetTokenData()
		return self:Instruction(trace, "num", tonumber(num))
	end
	
	if self:AcceptRoamingToken("str") then
		local trace = self:GetTokenTrace()
		local str = self:GetTokenData()
		return self:Instruction(trace, "str", str)
	end
	
	if self:AcceptRoamingToken("trg") then
		local trace = self:GetTokenTrace()
	
		if !self:AcceptTailingToken("var") then
			if self:AcceptRoamingToken("var") then
				self:Error("Triggered operator (~) must not be succeeded by whitespace")
			else
				self:Error("Triggered operator (~) must be preceded by variable")
			end
		end
		
		local var = self:GetTokenData()
		return self:Instruction(trace, "trg", var)
	end
	
	if self:AcceptRoamingToken("dlt") then
		local trace = self:GetTokenTrace()
	
		if !self:AcceptTailingToken("var") then
			if self:AcceptRoamingToken("var") then
				self:Error("Delta operator ($) must not be succeeded by whitespace")
			else
				self:Error("Delta operator ($) must be preceded by variable")
			end
		end
		
		local var = self:GetTokenData()
		self.delta[var] = true
		
		return self:Instruction(trace, "dlt", var)
	end
	
	return self:Expr14()
end

function Parser:Expr14()
	if self:AcceptRoamingToken("var") then
		if self:AcceptTailingToken("inc") then
			self:Error("Increment operator (++) must not be part of equation")
		elseif self:AcceptRoamingToken("inc") then
			self:Error("Increment operator (++) must not be preceded by whitespace")
		end
		
		if self:AcceptTailingToken("dec") then
			self:Error("Decrement operator (--) must not be part of equation")
		elseif self:AcceptRoamingToken("dec") then
			self:Error("Decrement operator (--) must not be preceded by whitespace")
		end
		
		self:TrackBack()
	end
	
	return self:Expr15()
end

function Parser:Expr15()
	if self:AcceptRoamingToken("var") then
		local trace = self:GetTokenTrace()
		local var = self:GetTokenData()
		return self:Instruction(trace, "var", var)
	end
	
	return self:ExprError()
end

function Parser:ExprError()
	if self:HasTokens() then
		if self:AcceptRoamingToken("add") then
			self:Error("Addition operator (+) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("sub") then -- can't occur
			self:Error("Subtraction operator (-) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("mul") then
			self:Error("Multiplication operator (*) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("div") then
			self:Error("Division operator (/) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("mod") then
			self:Error("Modulo operator (%) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("exp") then
			self:Error("Exponentiation operator (%) must be preceded by equation or value")
		
		elseif self:AcceptRoamingToken("ass") then
			self:Error("Assignment operator (=) must be preceded by variable")
		elseif self:AcceptRoamingToken("aadd") then
			self:Error("Additive assignment operator (+=) must be preceded by variable")
		elseif self:AcceptRoamingToken("asub") then
			self:Error("Subtractive assignment operator (-=) must be preceded by variable")
		elseif self:AcceptRoamingToken("amul") then
			self:Error("Multiplicative assignment operator (*=) must be preceded by variable")
		elseif self:AcceptRoamingToken("adiv") then
			self:Error("Divisive assignment operator (/=) must be preceded by variable")
		
		elseif self:AcceptRoamingToken("and") then
			self:Error("Logical and operator (&) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("or") then
			self:Error("Logical or operator (|) must be preceded by equation or value")
		
		elseif self:AcceptRoamingToken("eq") then
			self:Error("Equality operator (==) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("neq") then
			self:Error("Inequality operator (!=) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("gth") then
			self:Error("Greater than or equal to operator (>=) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("lth") then
			self:Error("Less than or equal to operator (<=) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("geq") then
			self:Error("Greater than operator (>) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("leq") then
			self:Error("Less than operator (<) must be preceded by equation or value")
		
		elseif self:AcceptRoamingToken("inc") then
			self:Error("Increment operator (++) must be preceded by variable")
		elseif self:AcceptRoamingToken("dec") then
			self:Error("Decrement operator (--) must be preceded by variable")
			
		elseif self:AcceptRoamingToken("lpa") then
			self:Error("Right parenthesis ()) without matching left parenthesis")
		elseif self:AcceptRoamingToken("lcb") then
			self:Error("Left curly bracket ({) must be part of an if-statement block")
		elseif self:AcceptRoamingToken("rcb") then
			self:Error("Right curly bracket (}) without matching left curly bracket")
			
		elseif self:AcceptRoamingToken("col") then
			self:Error("Method operator (:) must not be preceded by whitespace")
			
		elseif self:AcceptRoamingToken("if") then
			self:Error("If keyword (if) must not appear inside an equation")
		elseif self:AcceptRoamingToken("eif") then
			self:Error("Else-if keyword (elseif) must be part of an if-statement")
		elseif self:AcceptRoamingToken("els") then
			self:Error("Else keyword (else) must be part of an if-statement")
			
		else
			self:Error("Unexpected token found (" .. self.readtoken[1] .. "), please report this to me@syranide.com")
		end
	else
		self:Error("Further input required at end of code, incomplete expression", self.exprtoken)
	end
end

/******************************************************************************\
  Extensions
\******************************************************************************/

local Extensions = {
	types = {},
	callbacks = {},
}

function Extensions:registerType(name, id, default, inputcallback, outputcallback)
	if name != string.lower(name) then
		error("TODO")
	end
	
	self.types[string.upper(name)] = {id, default, inputcallback, outputcallback}
	
	if SERVER then
		if WireLib.DT[string.upper(name)] == nil then
			WireLib.DT[string.upper(name)] = {}
			WireLib.DT[string.upper(name)].Zero = default
		end
	end
end

function Extensions:registerCallback(event, callback)
	self.callbacks[event][#self.callbacks[event] + 1] = callback
end

function Extensions:registerCallback(event, callback)
	self.callbacks[event][#self.callbacks[event] + 1] = callback
end

function Extensions:registerOperator(name, pars, rets, func)
	funcs["op:" .. name .. "(" .. pars .. ")"] = { "op:" .. name .. "(" .. pars .. ")", rets, func }
end

function Extensions:registerFunction(name, pars, rets, func)
	funcs[name .. "(" .. pars .. ")"] = { name .. "(" .. pars .. ")", rets, func }
end

/******************************************************************************\
  Compiler
\******************************************************************************/

Compiler = {}

function Compiler:Execute(...)
	self.__index = self
	self = setmetatable({}, self)
	
	return pcall(Compiler.Process, self, ...)
end

function Compiler:Error(message, instr)
	error(message .. " at line " .. instr[2][1] .. ", char " .. instr[2][2], 0)
end

function Compiler:Process(root, inputs, outputs, persist, delta, params)
	self.context = {}

	self:PushContext()
	
	self.dvars = {}
	self.vars = {}
	
	for name,v in pairs(inputs) do
		self.vars[name] = v
		self:SetVariableType(name, wire_expression_types[v][1])
	end
	for name,v in pairs(outputs) do
		self.vars[name] = v
		self:SetVariableType(name, wire_expression_types[v][1])
	end
	for name,v in pairs(persist) do
		self.vars[name] = v
		self:SetVariableType(name, wire_expression_types[v][1])
	end
	for name,v in pairs(delta) do
		self.dvars[name] = v
	end
	
	self:PushContext()
	
	local script = Compiler["Instr" .. string.upper(root[1])](self, root)
	
	local ctx = self:PopContext()
	
	return { script, self.dvars }
end

/******************************************************************************/

function Compiler:EvaluateStatement(args, index)
	local name = string.upper(args[index + 2][1])
	local ex, tp = Compiler["Instr" .. name](self, args[index + 2])
	return ex, tp
end

function Compiler:Evaluate(args, index)
	local ex, tp = self:EvaluateStatement(args, index)

	if tp == "" then
		self:Error("No return value (void), statement cannot part of expression,", args)
	end
	
	return ex, tp
end


function Compiler:GetOperator(instr, name, tps)
	pars = string.Implode("", tps)
	local a = funcs["op:" .. name .. "(" .. pars .. ")"]
	if !a then
		self:Error("No operator (" .. name .. ") that accepts ["..pars.."]", instr)
		return
	end
	return { a[3], a[2], a[1] }
end

function Compiler:GetFunction(instr, name, tps)
	pars = string.Implode("", tps)
	local a = funcs[name .. "(" .. pars .. ")"]
	if !a then
		self:Error("No functions (" .. name .. ") that accepts ["..pars.."]", instr)
		return
	end
	return { a[3], a[2], a[1] }
end

function Compiler:GetMethod(instr, name, tp, tps)
	pars = tp .. ":" .. string.Implode("", tps)
	local a = funcs[name .. "(" .. pars .. ")"]
	if !a then
		self:Error("No functions (" .. name .. ") that accepts ["..pars.."]", instr)
		return
	end
	return { a[3], a[2], a[1] }
end

function Compiler:PushContext()
	self.context[#self.context + 1] = {}
end

function Compiler:PopContext()
	local context = self.context[#self.context]
	self.context[#self.context] = nil
	return context
end

function Compiler:MergeContext(cx1, cx2)
	local vr1 = {}
	local vr2 = {}

	for name,tp in pairs(cx1) do
		if cx2[name] and cx2[name] != tp then
			error("ERROR, TYPE MISMATCH!\n", 0)
		end
	end
	
	for name,tp in pairs(cx1) do
		self:SetVariableType(name, tp)
		if !cx2[name] then vr2[name] = tp end
	end
	
	for name,tp in pairs(cx2) do
		self:SetVariableType(name, tp)
		if !cx1[name] then vr1[name] = tp end
	end
	
	return vr1, vr2
end


function Compiler:SetVariableType(name, tp)
	for i=#self.context,1,-1 do
		if self.context[i][name] then
			if self.context[i][name] != tp then error("ERROR OVERLOADING VARIABLE TYPE [" .. name .. "]", 0) end
			return
		end
	end
	
	self.context[#self.context][name] = tp
end

function Compiler:GetVariableType(instr, name)
	for i=1,#self.context do
		if self.context[i][name] then return self.context[i][name] end
	end

	self:Error("Variable (" .. stringlimit(name, 10) .. ") does not exist", instr)
	return nil
end

/******************************************************************************/

function Compiler:InstrSEQ(args)
	local stmts = {self:GetOperator(args, "seq", {})[1]}
	
	for i=1,#args-2 do
		stmts[#stmts + 1] = self:EvaluateStatement(args, i)
	end
	
	return stmts
end


function Compiler:InstrIF(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	
	self:PushContext()
	local st1 = self:EvaluateStatement(args, 2)
	local cx1 = self:PopContext()
	
	self:PushContext()
	local st2 = self:EvaluateStatement(args, 3)
	local cx2 = self:PopContext()
	
	local vr1, vr2 = self:MergeContext(cx1, cx2)
	
	for name,tp in pairs(vr1) do
		st1[#st1 + 1] = { self:GetOperator(args, "ass", {tp})[1], name, { self:GetOperator(args, "dat", {})[1], wire_expression_types2[tp][2] } }
	end
	
	for name,tp in pairs(vr2) do
		st2[#st2 + 1] = { self:GetOperator(args, "ass", {tp})[1], name, { self:GetOperator(args, "dat", {})[1], wire_expression_types2[tp][2] } }
	end
	
	local rtis = self:GetOperator(args, "is", {tp1})
	local rtif = self:GetOperator(args, "if", {rtis[2]})
	return { rtif[1], { rtis[1], ex1 }, st1, st2 }
end

function Compiler:InstrCND(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local ex3, tp3 = self:Evaluate(args, 3)
	
	local rtis     = self:GetOperator(args, "is", {tp1})
	local rtif     = self:GetOperator(args, "cnd", {rtis[2]})
	
	if tp2 != tp3 then
		self:Error("CONDITIONAL GIVEN TWO DIFFERENT TYPES!", args)
	end
	
	return { rtif[1], { rtis[1], ex1 }, ex2, ex3 }, tp2
end


function Compiler:InstrFUN(args)
	local exprs = {false}
	
	local tps = {}
	for i=1,#args[4] do
		local ex, tp = self:Evaluate(args[4], i - 2)
		tps[#tps + 1] = tp
		exprs[#exprs + 1] = ex
	end
	
	local rt = self:GetFunction(args, args[3], tps)
	exprs[1] = rt[1]
	
	return exprs, rt[2]
end

function Compiler:InstrMTO(args)
	local exprs = {false}
	
	local tps = {}
	
	local ex, tp = self:Evaluate(args, 2)
	exprs[#exprs + 1] = ex
	
	for i=1,#args[5] do
		local ex, tp = self:Evaluate(args[5], i - 2)
		tps[#tps + 1] = tp
		exprs[#exprs + 1] = ex
	end
	
	local rt = self:GetMethod(args, args[3], tp, tps)
	exprs[1] = rt[1]
	
	return exprs, rt[2]
end

function Compiler:InstrASS(args)
	local op     = args[3]
	local ex, tp = self:Evaluate(args, 2)
	local rt     = self:GetOperator(args, "ass", {tp})
	
	self:SetVariableType(op, tp)
	
	if self.dvars[op] then
		local stmts = {self:GetOperator(args, "seq", {})[1]}
		stmts[2] = {self:GetOperator(args, "ass", {tp})[1], "$" .. op, {self:GetOperator(args, "var", {})[1], op}}
		stmts[3] = {rt[1], op, ex}
		return stmts, tp
	else
		return {rt[1], op, ex}, tp
	end
end

function Compiler:InstrINC(args)
	local op = args[3]
	local tp = self:GetVariableType(args, op)
	local rt = self:GetOperator(args, "inc", {tp})
	
	if self.dvars[op] then
		local stmts = {self:GetOperator(args, "seq", {})[1]}
		stmts[2] = {self:GetOperator(args, "ass", {tp})[1], "$" .. op, {self:GetOperator(args, "var", {})[1], op}}
		stmts[3] = {rt[1], op}
		return stmts
	else
		return {rt[1], op}
	end
end

function Compiler:InstrDEC(args)
	local op = args[3]
	local tp = self:GetVariableType(args, op)
	local rt = self:GetOperator(args, "dec", {tp})
	
	if self.dvars[op] then
		local stmts = {self:GetOperator(args, "seq", {})[1]}
		stmts[2] = {self:GetOperator(args, "ass", {tp})[1], "$" .. op, {self:GetOperator(args, "var", {})[1], op}}
		stmts[3] = {rt[1], op}
		return stmts
	else
		return {rt[1], op}
	end
end


function Compiler:InstrNEG(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local rt       = self:GetOperator(args, "neg", {tp1})
	return { rt[1], ex1 }, rt[2]
end

function Compiler:InstrADD(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local rt       = self:GetOperator(args, "add", {tp1, tp2})
	return { rt[1], ex1, ex2 }, rt[2]
end

function Compiler:InstrSUB(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local rt       = self:GetOperator(args, "sub", {tp1, tp2})
	return { rt[1], ex1, ex2 }, rt[2]
end

function Compiler:InstrMUL(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local rt       = self:GetOperator(args, "mul", {tp1, tp2})
	return {rt[1], ex1, ex2}, rt[2]
end

function Compiler:InstrDIV(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local rt       = self:GetOperator(args, "div", {tp1, tp2})
	return {rt[1], ex1, ex2}, rt[2]
end

function Compiler:InstrMOD(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local rt       = self:GetOperator(args, "mod", {tp1, tp2})
	return {rt[1], ex1, ex2}, rt[2]
end

function Compiler:InstrEXP(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local rt       = self:GetOperator(args, "exp", {tp1, tp2})
	return {rt[1], ex1, ex2}, rt[2]
end


function Compiler:InstrNOT(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local rt1is    = self:GetOperator(args, "is", {tp1})
	local rt       = self:GetOperator(args, "not", {rt1is[2]})
	return { rt[1], { rt1is[1], ex1 } }, rt[2]
end

function Compiler:InstrAND(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local rt1is    = self:GetOperator(args, "is", {tp1})
	local rt2is    = self:GetOperator(args, "is", {tp2})
	local rt       = self:GetOperator(args, "and", {rt1is[2], rt2is[2]})
	return { rt[1], { rt1is[1], ex1 }, { rt2is[1], ex2 } }, rt[2]
end

function Compiler:InstrOR(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local rt1is    = self:GetOperator(args, "is", {tp1})
	local rt2is    = self:GetOperator(args, "is", {tp2})
	local rt       = self:GetOperator(args, "or", {rt1is[2], rt2is[2]})
	return { rt[1], { rt1is[1], ex1 }, { rt2is[1], ex2 } }, rt[2]
end


function Compiler:InstrEQ(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local rt       = self:GetOperator(args, "eq", {tp1, tp2})
	return { rt[1], ex1, ex2 }, rt[2]
end

function Compiler:InstrNEQ(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local rt       = self:GetOperator(args, "neq", {tp1, tp2})
	return { rt[1], ex1, ex2 }, rt[2]
end

function Compiler:InstrGEQ(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local rt       = self:GetOperator(args, "geq", {tp1, tp2})
	return { rt[1], ex1, ex2 }, rt[2]
end

function Compiler:InstrLEQ(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local rt       = self:GetOperator(args, "leq", {tp1, tp2})
	return { rt[1], ex1, ex2 }, rt[2]
end

function Compiler:InstrGTH(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local rt       = self:GetOperator(args, "gth", {tp1, tp2})
	return { rt[1], ex1, ex2 }, rt[2]
end

function Compiler:InstrLTH(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local rt       = self:GetOperator(args, "lth", {tp1, tp2})
	return { rt[1], ex1, ex2 }, rt[2]
end


function Compiler:InstrTRG(args)
	local op = args[3]
	local tp = self:GetVariableType(args, op)
	local rt = self:GetOperator(args, "trg", {})
	return {rt[1], op}, rt[2]
end

function Compiler:InstrDLT(args)
	local op = args[3]
	local tp = self:GetVariableType(args, op)
	if !self.vars[op] then
		self:Error("Delta operator ($" .. stringlimit(op, 10) .. ") cannot be used on temporary variable", args)
	end
	self.dvars[op] = true
	local rt = self:GetOperator(args, "dlt", {tp})
	return {rt[1], op}, rt[2]
end


function Compiler:InstrNUM(args)
	local rt = self:GetOperator(args, "dat", {})
	return {rt[1], args[3]}, "n"
end

function Compiler:InstrSTR(args)
	local rt = self:GetOperator(args, "dat", {})
	return {rt[1], args[3]}, "s"
end

function Compiler:InstrVAR(args)
	local op = args[3]
	local tp = self:GetVariableType(args, op)
	local rt = self:GetOperator(args, "var", {})
	return {rt[1], op}, tp
end

/******************************************************************************\
  Loading extensions (temporary)
\******************************************************************************/

// TODO: matrices as well, they seem fairly cheap? any use though?

include("core.lua");
include("array.lua");
include("number.lua");
include("vector.lua");
include("string.lua");
include("angle.lua");
include("entity.lua");
include("player.lua");
include("table.lua");
include("timer.lua");
include("selfaware.lua");
include("unitconv.lua");
include("wirelink.lua");
include("console.lua");
include("find.lua");
include("custom.lua");
//include("quaternion.lua");

local list = file.FindInLua("entities/gmod_wire_expression2/core/custom/*.lua")
for _, file in pairs(list) do 
	include("custom/" .. file)
	AddCSLuaFile("custom/" .. file)
end