-- a variable inside a single if-branch is discarded, even though that type should be forced for any consecutive assignments

AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')
include('core/init.lua')

ENT.OverlayDelay = 0
ENT.WireDebugName = "Expression 2"

function tablekeys(tbl)
	l = {}
	for k,v in pairs(tbl) do
		l[#l + 1] = k
	end
	return l
end

function tablevalues(tbl)
	l = {}
	for k,v in pairs(tbl) do
		l[#l + 1] = v
	end
	return l
end

function ENT:Initialize()
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	
	self.Inputs = WireLib.CreateInputs(self.Entity, {})
	self.Outputs = WireLib.CreateOutputs(self.Entity, {})
	
	self:SetOverlayText("Expression 2\n(none)")
	self:SetColor(255, 0, 0, 255)
end

function ENT:OnRestore()
	self:Setup(self.original)
	/*
	local buffer = self._buffer
	
	local status, result = PreProcessor:Execute(buffer)
	if(!status) then self:Error(result) end
	local directives = result[1]
	self.buffer = result[2]
	
	self.inports = directives.inputs
	self.outports = directives.outputs
	self.persists = directives.persist
	
	local status, result = Tokenizer:Execute(buffer)
	if(!status) then self:Error(result) end
	local tokens = result
	
	local status, result = Parser:Execute(tokens)
	if(!status) then self:Error(result) end
	local tree, dvars = result[1], result[2]
	
	local status, result = Compiler:Execute(tree, inports[3], outports[3], persists[3], dvars)
	if(!status) then self:Error(result) end
	local script, dvars = result[1], result[2]
	
	self.script = script*/
end

function ENT:Execute()
	self.script[1](self.context, self.script)
	
	self:TriggerOutputs()
	
	for k,v in pairs(self.inports[3]) do
		if self.context.vclk[k] then
			if wire_expression_types[self.Inputs[k].Type][3] then
				self.context.vars[k] = wire_expression_types[self.Inputs[k].Type][3](self.context, self.Inputs[k].Value)
			else
				self.context.vars[k] = self.Inputs[k].Value
			end
		end
	end
	
	self.context.vclk = {}
end

function ENT:OnRemove( )
	exp2FindOnRemove(self.Entity)
	if(self.script) then
		for i,callback in ipairs(wire_expression_callbacks['destruct']) do
			callback(self.context)
		end
	end
end

function ENT:Error(message)
	self:SetOverlayText("Expression 2\n(script error)")
	self:SetColor(255, 0, 0, 255)
	
	error(message, 0)
end

function ENT:Setup(buffer, restore)
	self.original = buffer
	if self.script then
		for i,callback in ipairs(wire_expression_callbacks['destruct']) do
			callback(self.context)
		end
	end
	
	local status, result = PreProcessor:Execute(buffer)
	if(!status) then self:Error(result) end
	local directives = result[1]
	self.buffer = result[2]
	
	self.name = directives.name
	if directives.name == "" then self.name = "generic" end
	self.inports = directives.inputs
	self.outports = directives.outputs
	self.persists = directives.persist
	
	local status, result = Tokenizer:Execute(self.buffer)
	if(!status) then self:Error(result) end
	local tokens = result
	
	local status, result = Parser:Execute(tokens)
	if(!status) then self:Error(result) end
	local tree, dvars = result[1], result[2]
	
	local status, result = Compiler:Execute(tree, self.inports[3], self.outports[3], self.persists[3], dvars)
	if(!status) then self:Error(result) end
	local script, dvars = result[1], result[2]
	
	self:SetOverlayText("Expression 2\n" .. self.name)
	self:SetColor(255, 255, 255, 255)
	
	self.Inputs = WireLib.AdjustSpecialInputs(self.Entity, self.inports[1], self.inports[2])
	self.Outputs = WireLib.AdjustSpecialOutputs(self.Entity, self.outports[1], self.outports[2])
	
	self.script = script
	
	self.context = {}
	self.context.vars = {}
	self.context.vclk = {}
	self.context.data = {}
	self.context.entity = self
	self.context.player = self.player
	
	self._original = string.Replace(string.Replace(self.original,"\"","£"),"\n","€")
	self._buffer = buffer
	
	self._name = self.name
	self._inputs = { {}, {} }
	self._outputs = { {}, {} }
	self._vars = self.context.vars

	if exp2Discoveries == nil then exp2Discoveries = {} end
	exp2Discoveries[self.Entity:EntIndex()]=nil
	
	for k,v in pairs(self.inports[3]) do
		self._inputs[1][#self._inputs[1] + 1] = k
		self._inputs[2][#self._inputs[2] + 1] = v
		self.context.vars[k] = wire_expression_types[v][2]
	end
	
	for k,v in pairs(self.outports[3]) do
		self._outputs[1][#self._outputs[1] + 1] = k
		self._outputs[2][#self._outputs[2] + 1] = v
		self.context.vars[k] = wire_expression_types[v][2]
	end
	
	for k,v in pairs(self.persists[3]) do
		self.context.vars[k] = wire_expression_types[v][2]
	end
	
	for k,v in pairs(self.Inputs) do
		if wire_expression_types[v.Type][3] then
			self.context.vars[k] = wire_expression_types[v.Type][3](self.context, v.Value)
		else
			self.context.vars[k] = v.Value
		end
	end
	
	for k,v in pairs(dvars) do
		self.context.vars["$" .. k] = self.context.vars[k]
	end
		
	for i,callback in ipairs(wire_expression_callbacks['construct']) do
		callback(self.context)
	end
	
	if !restore then self:Execute() end
end

function ENT:TriggerInput(key, value)
	if key and self.inports[3][key] then
		t = self.inports[3][key]
		
		self.context.vars["$" .. key] = self.context.vars[key]
		if wire_expression_types[t][3] then
			self.context.vars[key] = wire_expression_types[t][3](self.context, value)
		else
			self.context.vars[key] = value
		end
		
		self.context.triggerinput = key		
		self:Execute()
		self.context.triggerinput = nil
	end
end

function ENT:TriggerOutputs()
	for key,t in pairs(self.outports[3]) do
		if self.context.vclk[key] then
			if wire_expression_types[t][4] then
				WireLib.TriggerOutput(self.Entity, key, wire_expression_types[t][4](self.context, self.context.vars[key]))
			else
				WireLib.TriggerOutput(self.Entity, key, self.context.vars[key]) 
			end
		end
	end
end

// BEGIN DECODER

local hex = {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'}
local tbl = {}

for byte=1,255 do
	tbl[hex[(byte - byte % 16) / 16 + 1] .. hex[byte % 16 + 1]] = string.char(byte)
end

function decode(encoded)
	local str = ""
	local length = encoded:len()
	
	local offset = 1
	
	for i=1,length do
		if encoded:sub(i,i) == "#" then
			if offset < i then str = str .. encoded:sub(offset, i - 1) end
			str = str .. tbl[encoded:sub(i + 1, i + 2)]
			i = i + 2
			offset = i + 1
		end
	end
	
	str = str .. encoded:sub(offset, length)
	
	return str;
end

// END DECODER

function ENT:SendCode(pl)
	local chunksize = 200
	if(!self.original || !pl) then return end
	local code = self.original
	local chunks = math.ceil(code:len() / chunksize)
	umsg.Start("wire_expression2_download", pl)
	umsg.Short(chunks)
	umsg.String(self.name)
	umsg.End()
	
	for i=0,chunks do
		umsg.Start("wire_expression2_download", pl)
		umsg.Short(i)
		umsg.String(code:sub(i * chunksize + 1, (i + 1) * chunksize))
		umsg.End()
	end
end

local buffer = {}

function ENT:Prepare(player)
	local ID = player:UserID()
	buffer[ID] = {}
	buffer[ID].ent = self
end

local function concommand_upload_begin(player, command, args)
	local ID = player:UserID()
	buffer[ID].text = ""
	buffer[ID].len = tonumber(args[1])
	buffer[ID].chunk = 0
	buffer[ID].chunks = tonumber(args[2])
	buffer[ID].ent:SetOverlayText("Expression 2\n(transferring)")
	buffer[ID].ent:SetColor(0, 255, 0, 255)
end

local function concommand_upload_data(player, command, args)
	local ID = player:UserID()
	buffer[ID].text = buffer[ID].text .. args[1]
	buffer[ID].chunk = buffer[ID].chunk + 1
	
	local percent = math.Round((buffer[ID].chunk / buffer[ID].chunks) * 100)
end

local function concommand_upload_end(player, command, args)
	local ID = player:UserID()
	if(decode(buffer[ID].text):len() != buffer[ID].len) then
		buffer[ID].ent:SetOverlayText("Expression 2\n(transfer error)")
		buffer[ID].ent:SetColor(255, 0, 0, 255)
	else
		buffer[ID].ent:Setup(decode(buffer[ID].text))
		buffer[ID].ent.player = player
	end
	buffer[ID] = nil
end

concommand.Add("wire_expression_upload_begin", concommand_upload_begin)
concommand.Add("wire_expression_upload_data", concommand_upload_data)
concommand.Add("wire_expression_upload_end", concommand_upload_end)
