
ENT.Type 				= "anim"
ENT.Base 				= "base_wire_entity"
ENT.PrintName				= "Wire FX Emitter"
ENT.Author				= "Team garry / ZeikJT"
ENT.Contact				= ""
ENT.Purpose				= ""
ENT.Instructions		= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

/*---------------------------------------------------------
   Effect
---------------------------------------------------------*/
function ENT:SetEffect( value )
	if value!=self.datanstuff.effect then
		self.Entity:SetNWInt( "Effect", value )
		self.datanstuff.effect = value
	end
end
function ENT:GetEffect()
	return self.Entity:GetNWInt( "Effect" )
end

/*---------------------------------------------------------
   Delay
---------------------------------------------------------*/
function ENT:SetDelay( f )
	if f!=self.datanstuff.delay then
		self.Entity:SetNWFloat( "Delay", f )
		self.datanstuff.delay=f
	end
end
function ENT:GetDelay()
	return self.Entity:GetNWFloat( "Delay" )
end

/*---------------------------------------------------------
   Position
---------------------------------------------------------*/
function ENT:SetFXPos( pos )
	if pos!=self.datanstuff.pos then
		self.Entity:SetNWVector( "FXPos", pos )
		self.datanstuff.pos = pos
	end
end
function ENT:GetFXPos()
	return self.Entity:GetNWVector( "FXPos" )
end

/*---------------------------------------------------------
   Position
---------------------------------------------------------*/
function ENT:SetFXDir( dir )
	if dir!=self.datanstuff.dir then
		self.Entity:SetNWVector( "FXDir", dir:GetNormal() )
		self.datanstuff.dir = dir
	end
end
function ENT:GetFXDir()
	return self.Entity:GetNWVector( "FXDir" )
end

/*---------------------------------------------------------
   On
---------------------------------------------------------*/
function ENT:SetOn( b )
	if b!=self.datanstuff.on then
		self.Entity:SetNWInt( "On", b )
		self.datanstuff.on = b
	end
end
function ENT:GetOn()
	return self.Entity:GetNWInt( "On" )
end



/*---------------------------------------------------------
   Effect registration
---------------------------------------------------------*/

ENT.Effects				= {}
ENT.fxcount = 0

ComboBox_Wire_FX_Emitter_Options = {}

function ENT:AddEffect( name, func, nicename )
	self.fxcount = self.fxcount+1
		// Maintain a global reference for these effects
	ComboBox_Wire_FX_Emitter_Options[name] = self.fxcount
	if CLIENT then
		self.Effects[self.fxcount] = func
		language.Add( "wire_fx_emitter_"..name, nicename )
	end
end

/*---------------------------------------------------------
   Modular effect adding.. stuff
---------------------------------------------------------*/

include( "fx_default.lua" )
