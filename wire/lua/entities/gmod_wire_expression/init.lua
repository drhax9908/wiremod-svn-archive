
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')
include('parser.lua')

ENT.Delta = 0.001
ENT.OverlayDelay = 0
ENT.WireDebugName = "Expression"

if !WireModPacket then
	WireModPacket = {}
	WireModPacketIndex = 0
end

function ENT:Initialize()
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	self.Entity:SetCollisionGroup(COLLISION_GROUP_WORLD)
	
	self.Xinputs =  {}
	self.Xoutputs = {}
	self.Xlocals =  {}
	
	self.deltavars = {}
	self.inputvars = {}
	self.triggvars = {}
	self.variables = {}
	
	self.Inputs = Wire_CreateInputs(self.Entity, {})
	self.Outputs = Wire_CreateOutputs(self.Entity, {})
end

function ENT:Use()
end

function ENT:Think()
	--self:Update()
end

function ENT:TriggerInput(key, value)
	if key then
		self.deltavars[key] = self.inputvars[key]
		self.inputvars[key] = value
		self.triggvars[key] = true
		self:Update()
		--self.Entity:NextThink(CurTime()+0.001)
	end
end

function ENT:Update()
	for _,key in pairs(self.Xinputs) do
		self.variables[key] = self.inputvars[key]
	end
	
	local tbl = self.instructions
	self["_"..tbl[1]](self,tbl)
	self.triggvars = {}
	
	for _,key in ipairs(self.Xoutputs) do
		Wire_TriggerOutput(self.Entity, key, self.variables[key]) --major overhead, add lazy updates?
	end
end

function ENT:Reset()
	for _,key in ipairs(self.Xlocals)  do self.variables[key] = 0 self.deltavars[key] = 0 end
	for _,key in ipairs(self.Xoutputs) do self.variables[key] = 0 self.deltavars[key] = 0  end
	self:Update()
end

function ENT:Setup(name, parser)
	local inputs =  parser:GetInputs()
	local outputs = parser:GetOutputs()
	local locals =  parser:GetLocals()
	
	local inputvars = {}
	local deltavars = {}
	local triggvars = {}
	local variables = {}
	
	for _,key in ipairs(inputs) do
		if !self.inputvars[key] then
			inputvars[key] = 0
			deltavars[key] = 0
		else
			inputvars[key] = self.inputvars[key]
			deltavars[key] = self.deltavars[key]
		end
	end
	
	for _,key in ipairs(outputs) do
		if !self.variables[key] then
			variables[key] = 0
			deltavars[key] = 0
		else
			variables[key] = self.variables[key]
			deltavars[key] = self.deltavars[key]
		end
	end
	
	for _,key in ipairs(locals) do
		if !self.variables[key] then
			variables[key] = 0
			deltavars[key] = 0
		else
			variables[key] = self.variables[key]
			deltavars[key] = self.deltavars[key]
		end
	end
	
	self.inputvars = inputvars
	self.deltavars = deltavars
	self.triggvars = triggvars
	self.variables = variables
	
	self.Xinputs =  inputs
	self.Xoutputs = outputs
	self.Xlocals =  locals
	
	self.instructions = parser:GetInstructions()
	
	Wire_AdjustInputs(self.Entity, inputs)
	Wire_AdjustOutputs(self.Entity, outputs)

	if name == "" then name = "generic" end
	self:SetOverlayText("Expression (" .. name .. ")")
	
	self:Update()
	return true
end

--function ENT:Compile(tbl)
--	if type(tbl) == "table" then
--		tbl[1] = self["_" .. tbl[1]]
--		for i=2,#tbl do tbl[i] = self:Compile(tbl[i]) end
--	end
--	return tbl
--end

function ENT:_end(tbl)  return -1 end

function ENT:_num(tbl)  return tbl[2] end
function ENT:_var(tbl)  return self.variables[tbl[2]] end
function ENT:_dlt(tbl)  return self.variables[tbl[2]] - self.deltavars[tbl[2]] end
function ENT:_trg(tbl)  if self.triggvars[tbl[2]] then return 1 else return 0 end end

function ENT:_seq(tbl)  if self["_"..tbl[2][1]](self,tbl[2]) == -1 then return -1 elseif self["_"..tbl[3][1]](self,tbl[3]) == -1 then return -1 end end

function ENT:_fun(tbl)  local prm = self["_"..tbl[3][1]](self,tbl[3]) local fun = self["_"..tbl[2].."_"..#prm] if !fun and #prm > 0 then fun = self["_"..tbl[2].."_x"] end if !fun then return -1 end return fun(self,unpack(prm)) end
function ENT:_prm(tbl)  local prm = self["_"..tbl[2][1]](self,tbl[2]) table.insert(prm, self["_"..tbl[3][1]](self,tbl[3])) return prm end
function ENT:_nil(tbl)  return {} end

function ENT:_imp(tbl)  if math.abs(self["_"..tbl[2][1]](self,tbl[2])) >= self.Delta then     if self["_"..tbl[3][1]](self,tbl[3]) == -1 then return -1 end end end
function ENT:_cnd(tbl)  if math.abs(self["_"..tbl[2][1]](self,tbl[2])) >= self.Delta then return self["_"..tbl[3][1]](self,tbl[3]) else return self["_"..tbl[4][1]](self,tbl[4]) end end

function ENT:_and(tbl)  if math.abs(self["_"..tbl[2][1]](self,tbl[2])) >= self.Delta and math.abs(self["_"..tbl[3][1]](self,tbl[3])) >= self.Delta then return 1 else return 0 end end
function ENT:_or(tbl)   if math.abs(self["_"..tbl[2][1]](self,tbl[2])) >= self.Delta or  math.abs(self["_"..tbl[3][1]](self,tbl[3])) >= self.Delta then return 1 else return 0 end end

function ENT:_ass(tbl)  self.triggvars[tbl[2][2]] = true self.deltavars[tbl[2][2]] = self.variables[tbl[2][2]] self.variables[tbl[2][2]] =                             self["_"..tbl[3][1]](self,tbl[3]) return self.variables[tbl[2][2]] end
function ENT:_aadd(tbl) self.triggvars[tbl[2][2]] = true self.deltavars[tbl[2][2]] = self.variables[tbl[2][2]] self.variables[tbl[2][2]] = self.variables[tbl[2][2]] + self["_"..tbl[3][1]](self,tbl[3]) return self.variables[tbl[2][2]] end
function ENT:_asub(tbl) self.triggvars[tbl[2][2]] = true self.deltavars[tbl[2][2]] = self.variables[tbl[2][2]] self.variables[tbl[2][2]] = self.variables[tbl[2][2]] - self["_"..tbl[3][1]](self,tbl[3]) return self.variables[tbl[2][2]] end
function ENT:_amul(tbl) self.triggvars[tbl[2][2]] = true self.deltavars[tbl[2][2]] = self.variables[tbl[2][2]] self.variables[tbl[2][2]] = self.variables[tbl[2][2]] * self["_"..tbl[3][1]](self,tbl[3]) return self.variables[tbl[2][2]] end
function ENT:_adiv(tbl) self.triggvars[tbl[2][2]] = true self.deltavars[tbl[2][2]] = self.variables[tbl[2][2]] self.variables[tbl[2][2]] = self.variables[tbl[2][2]] / self["_"..tbl[3][1]](self,tbl[3]) return self.variables[tbl[2][2]] end
function ENT:_amod(tbl) self.triggvars[tbl[2][2]] = true self.deltavars[tbl[2][2]] = self.variables[tbl[2][2]] self.variables[tbl[2][2]] = self.variables[tbl[2][2]] % self["_"..tbl[3][1]](self,tbl[3]) return self.variables[tbl[2][2]] end
function ENT:_aexp(tbl) self.triggvars[tbl[2][2]] = true self.deltavars[tbl[2][2]] = self.variables[tbl[2][2]] self.variables[tbl[2][2]] = self.variables[tbl[2][2]] ^ self["_"..tbl[3][1]](self,tbl[3]) return self.variables[tbl[2][2]] end

function ENT:_eq(tbl)   if math.abs(self["_"..tbl[2][1]](self,tbl[2]) - self["_"..tbl[3][1]](self,tbl[3])) < self.Delta  then return 1 else return 0 end end
function ENT:_neq(tbl)  if math.abs(self["_"..tbl[2][1]](self,tbl[2]) - self["_"..tbl[3][1]](self,tbl[3])) >= self.Delta then return 1 else return 0 end end

function ENT:_gth(tbl)  if self["_"..tbl[2][1]](self,tbl[2]) - self["_"..tbl[3][1]](self,tbl[3]) >= self.Delta  then return 1 else return 0 end end
function ENT:_lth(tbl)  if self["_"..tbl[2][1]](self,tbl[2]) - self["_"..tbl[3][1]](self,tbl[3]) <= -self.Delta then return 1 else return 0 end end
function ENT:_geq(tbl)  if self["_"..tbl[2][1]](self,tbl[2]) - self["_"..tbl[3][1]](self,tbl[3]) > -self.Delta  then return 1 else return 0 end end
function ENT:_leq(tbl)  if self["_"..tbl[2][1]](self,tbl[2]) - self["_"..tbl[3][1]](self,tbl[3]) < self.Delta   then return 1 else return 0 end end

function ENT:_neg(tbl)  return                                   - self["_"..tbl[2][1]](self,tbl[2]) end
function ENT:_add(tbl)  return self["_"..tbl[2][1]](self,tbl[2]) + self["_"..tbl[3][1]](self,tbl[3]) end
function ENT:_sub(tbl)  return self["_"..tbl[2][1]](self,tbl[2]) - self["_"..tbl[3][1]](self,tbl[3]) end
function ENT:_mul(tbl)  return self["_"..tbl[2][1]](self,tbl[2]) * self["_"..tbl[3][1]](self,tbl[3]) end
function ENT:_div(tbl)  return self["_"..tbl[2][1]](self,tbl[2]) / self["_"..tbl[3][1]](self,tbl[3]) end
function ENT:_mod(tbl)  return self["_"..tbl[2][1]](self,tbl[2]) % self["_"..tbl[3][1]](self,tbl[3]) end
function ENT:_exp(tbl)  return self["_"..tbl[2][1]](self,tbl[2]) ^ self["_"..tbl[3][1]](self,tbl[3]) end

function ENT:_not(tbl)  if math.abs(self["_"..tbl[2][1]](self,tbl[2])) < self.Delta then return 1 else return 0 end end

ENT._abs_1 =     function (self, n) return math.abs(n) end
ENT._ceil_1 =    function (self, n) return math.ceil(n) end
ENT._exp_1 =     function (self, n) return math.exp(n) end
ENT._floor_1 =   function (self, n) return math.floor(n) end
ENT._log_1 =     function (self, n) return math.log(n) end
ENT._log10_1 =   function (self, n) return math.log10(n) end
ENT._sqrt_1 =    function (self, n) return math.sqrt(n) end
ENT._random_2 =  function (self, l, u) return math.random() * (u - l) end

ENT._max_x =     function (self, ...) return math.max(...) end
ENT._min_x =     function (self, ...) return math.min(...) end

ENT._deg_1 =     function (self, r) return math.deg(r) end
ENT._rad_1 =     function (self, d) return math.rad(d) end
ENT._pi_0 =      function (self)    return math.pi end

ENT._acosr_1 =   function (self, x) return math.acos(x) end
ENT._asinr_1 =   function (self, x) return math.asin(x) end
ENT._atan2r_2 =  function (self, x, y) return math.atan2(x, y) end
ENT._atanr_1 =   function (self, x) return math.atan(x) end
ENT._coshr_1 =   function (self, r) return math.cosh(r) end
ENT._cosr_1 =    function (self, r) return math.cos(r) end
ENT._sinr_1 =    function (self, r) return math.sin(r) end
ENT._sinhr_1 =   function (self, r) return math.sinh(r) end
ENT._tanr_1 =    function (self, r) return math.tan(r) end
ENT._tanhr_1 =   function (self, r) return math.tanh(r) end

ENT._acos_1 =    function (self, x) return math.deg(math.acos(x)) end
ENT._asin_1 =    function (self, x) return math.deg(math.asin(x)) end
ENT._atan2_2 =   function (self, x, y) return math.deg(math.atan2(x, y)) end
ENT._atan_1 =    function (self, x) return math.deg(math.atan(x)) end
ENT._cosh_1 =    function (self, d) return math.cosh(math.rad(d)) end
ENT._cos_1 =     function (self, d) return math.cos(math.rad(d)) end
ENT._sin_1 =     function (self, d) return math.sin(math.rad(d)) end
ENT._sinh_1 =    function (self, d) return math.sinh(math.rad(d)) end
ENT._tan_1 =     function (self, d) return math.tan(math.rad(d)) end
ENT._tanh_1 =    function (self, d) return math.tanh(math.rad(d)) end

ENT._angnorm_1 = function (self, d) return (d + 180) % 360 - 180 end
--ENT._angdiff_2 = function (self, a, b) return (a - b + 180) % 360 - 180 end
ENT._angnormr_1 = function (self, d) return (d + math.pi) % (math.pi * 2) - math.pi end
--ENT._angdiffr_2 = function (self, a, b) return (a - b + math.pi) % (math.pi * 2) - math.pi end
ENT._clamp_3 =   function (self, v, l, u) if v < l then return l elseif v > u then return u else return v end end

ENT._send_x =    function (self, ...) WireModPacketIndex = WireModPacketIndex % 64 + 1 WireModPacket[WireModPacketIndex] = {...} return WireModPacketIndex end
ENT._recv_2 =    function (self, id, p) if WireModPacket[id] and WireModPacket[id][p] then return WireModPacket[id][p] else return -1 end end
