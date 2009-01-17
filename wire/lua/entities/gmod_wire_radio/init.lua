
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
	self.ValuesTable = {}
	
	Radio_Register(self)
	Radio_TuneIn(self,self.Channel)
end

function ENT:Setup(channel,values,secure)
	channel = math.floor(tonumber(channel) or 0)
	Radio_TuneOut(self,self.Channel)
	self.Channel = channel
	Radio_TuneIn(self,self.Channel)
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

	self.ValuesTable = {}
	for i=1,values do
		self.ValuesTable[i] = 0
	end
	
	Wire_AdjustOutputs(self,onames)
	table.insert(onames,"Channel")
	Wire_AdjustInputs(self,onames)
	
//	print("radio setup to channel "..self.Channel)
	self:ReceiveRadio(Radio_Receive(self,self.Channel))
end

function ENT:TriggerInput(iname, value)
	if (iname == "Channel") then
	    	Radio_TuneOut(self,self.Channel)
	    	self.Channel = math.floor(value)

//		print("STARTING SWITCH TO "..value.." here are the values BEFORE SWITCH:")
//		PrintTable(self.ValuesTable)

		if (Radio_ChannelOccupied(self,self.Channel)) then
		   	self:ReceiveRadio(Radio_Receive(self,self.Channel))
		end

//		print("Switched to channel "..value.." here are the values:")
//		PrintTable(self.ValuesTable)

		if (not Radio_ChannelOccupied(self,self.Channel)) then
//			print("Sending values")
			for j=1,20 do
				if (self.ValuesTable[j]) then
					Wire_TriggerOutput(self,tostring(j),self.ValuesTable[j])
//					Msg(j.." << "..self.ValuesTable[j].."\n")
					self:Transmit(self.Channel, tostring(j), self.ValuesTable[j])
				end
			end
		end

		Radio_TuneIn(self,value)
	elseif (iname != nil && value != nil) then
		self.ValuesTable[tonumber(iname)] = value
		self.Inputs[iname].Value = value
		self:Transmit(self.Channel,iname,value)
	end
	self:ShowOutput()
end

function ENT:ReadCell(Address)
//	print("==================== read "..Address.." (chan "..self.Channel..")")
//	print(self.ValuesTable[Address+1])
//	PrintTable(self.ValuesTable)
	if (Address >= 0) && (Address < self.Values) then
		return self.ValuesTable[Address+1]
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
	self.ValuesTable[tonumber(k)] = v
end

function ENT:ReceiveRadio(values) //FIXME: horrible code, needs cleanup. it's only a temp fix...
	if (values == nil) then return end
//	print("recieve radio:")
	//for k,o in pairs(values) do
	for j=1,20 do
		if (values[tostring(j)]) then
			Wire_TriggerOutput(self,tostring(j),values[tostring(j)])
			self.ValuesTable[j] = values[tostring(j)]
//			Msg(j.." = "..values[tostring(j)].."\n")
		end
	end
	self:ShowOutput()
end
function ENT:SReceiveRadio(k,v)
	if (k == nil || v == nil) then return end
	Wire_TriggerOutput(self,k,v)
	self.ValuesTable[tonumber(k)] = v
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
