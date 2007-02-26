ENT.Type 			= "anim"
ENT.Base 			= "base_wire_entity"

ENT.PrintName		= ""
ENT.Author			= ""
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

function ENT:SetDisplayA( float )
	self.Entity:SetNetworkedFloat( "DisA", float )
end

function ENT:SetDisplayB( float )
	self.Entity:SetNetworkedFloat( "DisB", float )
end

function ENT:GetDisplayA( )
	return self.Entity:GetNetworkedFloat( "DisA" )
end

function ENT:GetDisplayB( )
	return self.Entity:GetNetworkedFloat( "DisB" )
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