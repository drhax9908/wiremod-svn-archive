--Wire text screen by greenarrow
--http://gmodreviews.googlepages.com/
--http://forums.facepunchstudios.com/greenarrow
--There are a few bits of code from wire digital screen here and there, mainly just
--the values to correctly format cam3d2d for the screen, and a few standard things in the stool.

include('shared.lua')
ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_BOTH

function umScreenConfig(um)
	local ent = um:ReadEntity()
	ent.chrPerLine = um:ReadShort()
	ent.textJust = um:ReadShort()
	ent.tRed = um:ReadShort()
	ent.tGreen = um:ReadShort()
	ent.tBlue = um:ReadShort()
	ent.activeC = um:ReadBool()
end
usermessage.Hook("umsgScreenConfig", umScreenConfig) 

function ENT:Initialize()
	local fontSize = 380
	surface.CreateFont( "coolvetica", fontSize, 400, false, false, "font1" )
	surface.CreateFont( "coolvetica", fontSize / 2, 400, false, false, "font2" )
	surface.CreateFont( "coolvetica", fontSize / 3, 400, false, false, "font3" )
	surface.CreateFont( "coolvetica", fontSize / 4, 400, false, false, "font4" )
	surface.CreateFont( "coolvetica", fontSize / 5, 400, false, false, "font5" )
	surface.CreateFont( "coolvetica", fontSize / 6, 400, false, false, "font6" )
	surface.CreateFont( "coolvetica", fontSize / 7, 400, false, false, "font7" )
	surface.CreateFont( "coolvetica", fontSize / 8, 400, false, false, "font8" )
	surface.CreateFont( "coolvetica", fontSize / 9, 400, false, false, "font9" )
	surface.CreateFont( "coolvetica", fontSize / 10, 400, false, false, "font10" )
	surface.CreateFont( "coolvetica", fontSize / 11, 400, false, false, "font11" )
	surface.CreateFont( "coolvetica", fontSize / 12, 400, false, false, "font12" )
	surface.CreateFont( "coolvetica", fontSize / 13, 400, false, false, "font13" )
	surface.CreateFont( "coolvetica", fontSize / 14, 400, false, false, "font14" )
	surface.CreateFont( "coolvetica", fontSize / 15, 400, false, false, "font15" )
	self.activeI = true
end

function ENT:Draw()
	self.Entity:DrawModel()
	if (!self.activeC || !self.activeI) then return true end
	local OF = 0.3
	local OU = 11.8
	local OR = -2.35
	local Res = 0.12
	local RatioX = 1
	
	local ang = self.Entity:GetAngles()
	local rot = Vector(-90,90,0)
	ang:RotateAroundAxis(ang:Right(), rot.x)
	ang:RotateAroundAxis(ang:Up(), rot.y)
	ang:RotateAroundAxis(ang:Forward(), rot.z)
	local pos = self.Entity:GetPos() + (self.Entity:GetForward() * OF) + (self.Entity:GetUp() * OU) + (self.Entity:GetRight() * OR)
	
	cam.Start3D2D(pos,ang,Res)
		local x = -112
		local y = -104
		local w = 296
		local h = 292
			
		surface.SetDrawColor(0,0,0,255)
		surface.DrawRect(x/RatioX,y,(x+w)/RatioX,y+h)
		
		local justOffset = (w / 3) + (self.textJust * (w / 3.5))
		local lineText = self:GetLine(0)
		draw.DrawText(lineText, "font"..tostring(self.chrPerLine), (x + justOffset - 92) / RatioX, y + 2, Color(self.tRed, self.tGreen, self.tBlue, 255), self.textJust)

	cam.End3D2D()
	Wire_Render(self.Entity)
end

function ENT:IsTranslucent()
	return true
end
