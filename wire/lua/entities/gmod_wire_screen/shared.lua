ENT.Type 			= "anim"
ENT.Base 			= "base_wire_entity"

ENT.PrintName		= ""
ENT.Author			= ""
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

local Limit = .05
local LastTimeA = 0
local LastTimeB = 0

function ENT:SetDisplayA( float )
	if (CurTime() > LastTimeA + Limit) then
		if (self.Floor) then
			self.Entity:SetNetworkedBeamFloat( 1, math.floor(float), true )
		else
			self.Entity:SetNetworkedBeamFloat( 1, math.floor(float * 1000)/ 1000, true )
		end
		LastTimeA = CurTime()
	end
end

function ENT:SetDisplayB( float )
	if (CurTime() > LastTimeB + Limit) then
		if (self.Floor) then
			self.Entity:SetNetworkedBeamFloat( 2, math.floor(float), true )
		else
			self.Entity:SetNetworkedBeamFloat( 2, math.floor(float * 1000)/ 1000, true )
		end
		LastTimeB = CurTime()
	end
end

function ENT:GetDisplayA( )
	return self.Entity:GetNetworkedBeamFloat( 1 )
end

function ENT:GetDisplayB( )
	return self.Entity:GetNetworkedBeamFloat( 2 )
end

// Extra stuff for Wire Screen (TheApathetic)
function ENT:SetSingleValue(singlevalue)
	self.Entity:SetNetworkedBool("SingleValue",singlevalue)

	// Change inputs if necessary
	if (singlevalue) then
		Wire_AdjustInputs(self.Entity, {"A"})
	else
		Wire_AdjustInputs(self.Entity, {"A","B"})
	end
end

function ENT:GetSingleValue()
	return self.Entity:GetNetworkedBool("SingleValue")
end

function ENT:SetSingleBigFont(singlebigfont)
	self.Entity:SetNetworkedBool("SingleBigFont",singlebigfont)
end

function ENT:GetSingleBigFont()
	return self.Entity:GetNetworkedBool("SingleBigFont")
end

function ENT:SetTextA(text)
	self.Entity:SetNetworkedString("TextA",text)
end

function ENT:GetTextA()
	return self.Entity:GetNetworkedString("TextA")
end

function ENT:SetTextB(text)
	self.Entity:SetNetworkedString("TextB",text)
end

function ENT:GetTextB()
	return self.Entity:GetNetworkedString("TextB")
end

//LeftAlign (TAD2020)
function ENT:SetLeftAlign(leftalign)
	self.Entity:SetNetworkedBool("LeftAlign",leftalign)
end

function ENT:GetLeftAlign()
	return self.Entity:GetNetworkedBool("LeftAlign")
end

//Floor (TAD2020)
function ENT:SetFloor(Floor)
	self.Entity:SetNetworkedBool("Floor",Floor)
end

function ENT:GetFloor()
	return self.Entity:GetNetworkedBool("Floor")
end
