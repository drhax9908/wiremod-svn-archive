
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Radio"

local MODEL = Model( "models/props_lab/binderblue.mdl" )

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self, { "Channel"})
	self.Outputs = Wire_CreateOutputs(self, { "ERRORS!!!" })
	
	self.Channel = 1
	self.Transmitting = 0
	
	Radio_Register(self)
end

function ENT:Setup(channel,values,secure)
	channel = math.floor(tonumber(channel) or 0)
	self.Channel = channel
	self.Secure = secure
	self.Old = false
	if (tonumber(values) == nil) then
		values = 4
		self.Old = true
	else
		values = math.Round(values)
		if (values > 20) then
			values = 20
		end
		if (values < 1) then
			values = 1
		end
	end
	self.Values = values
	local onames = {}
	if (self.Old == false) then
		for i = 1,self.Values do
			onames[i] = tostring(i) //without tostring() you kill the debugger.
		end
	else
		onames = {"A","B","C","D"}
	end
	
	Wire_AdjustOutputs(self,onames)
	table.insert(onames,"Channel")
	Wire_AdjustInputs(self,onames)
	
	self:ReceiveRadio(Radio_Receive(self,self.Channel))
end

function ENT:TriggerInput(iname, value)
	if (iname == "Channel") then
	    	Radio_TuneOut(self,self.Channel)
	    	self.Channel = math.floor(value)
	   	self:ReceiveRadio(Radio_Receive(self,self.Channel))
		for k,v in pairs(self.Inputs) do	
			if k != "Channel" then self:Transmit( self.Channel, k, v.Value ) end
		end
	elseif (iname != nil && value != nil) then
		self.Inputs[iname].Value = value
		self:Transmit(self.Channel,iname,value)
	end
	self:ShowOutput()
end

function ENT:ReadCell(Address)
	if (Address >= 0) && (Address < self.Values) then
		if (self.Outputs[tostring(Address+1)] != nil) then
//			Msg("Reading output "..Address.." = "..(self.Outputs[tostring(Address+1)].Value or 0).."\n")
			return self.Outputs[tostring(Address+1)].Value or 0
		else
//			Msg("Reading 0..\n")
			return 0
		end
	else
		return nil
	end
end

function ENT:WriteCell(Address, value)
	if (Address >= 0) && (Address < self.Values) then
		self:Transmit(self.Channel, tostring(Address+1), value)
		return true
	else
		return false
	end
end

function ENT:Transmit(channel,k,v)
	Radio_Transmit(self,self.Channel,k,v)
end

function ENT:ReceiveRadio(values)
	if (values == nil) then return end
	local i = 1
	for k,o in pairs(values) do
		Wire_TriggerOutput(self,k,o)
		//print("RADIO "..k.." = "..o)
		if (i >= self.Values) then 
//			if (self.Outputs != nil) then 
//				PrintTable(self.Outputs)
//			end
			self:ShowOutput() 
			return 
		end
		i = i + 1
	end
	self:ShowOutput()
end
function ENT:SReceiveRadio(k,v)
	if (k == nil || v == nil) then return end
	Wire_TriggerOutput(self,k,v)
	self:ShowOutput()
end
function ENT:ShowOutput()
	if (self.Old == true) then
		self:SetOverlayText( "(Channel " .. self.Channel .. ") Transmit A: " .. (self.Inputs.A.Value or 0) .. " B: " .. (self.Inputs.B.Value or 0) ..  " C: " .. (self.Inputs.C.Value or 0) ..  " D: " .. (self.Inputs.D.Value or 0) .. "\nReceive A: " .. (self.Outputs.A.Value or 0) .. " B: " .. (self.Outputs.B.Value or 0) ..  " C: " .. (self.Outputs.C.Value or 0) ..  " D: " .. (self.Outputs.D.Value or 0) )
	else
		local overlay = "(Channel " .. self.Channel .. ") Transmit"
		for i=1,self.Values do
			if (k!= "Channel") then if (self.Outputs[tostring(i)] != nil) then overlay = overlay .. " " .. (tostring(i) or "Error") .. ":" .. math.Round((self.Inputs[tostring(i)].Value or 0)*1000)/1000 end end
		end
		overlay = overlay .. "\nReceive"
		for i=1,self.Values do
			if (self.Outputs[tostring(i)] != nil) then overlay = overlay .. " " .. (tostring(i) or "Error") .. ":" .. math.Round((self.Outputs[tostring(i)].Value or 0)*1000)/1000 end
		end
		if (self.Secure == true) then overlay = overlay .. "\nSecured" end
		self:SetOverlayText( overlay )
	end
end

function ENT:OnRestore()
    self.BaseClass.OnRestore(self)

	Radio_Register(self)
end

function ENT:OnRemove()
	if (!self.Channel) then return end
        Radio_TuneOut(self,self.Channel)
end
