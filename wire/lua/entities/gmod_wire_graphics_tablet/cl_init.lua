--Wire graphics tablet  by greenarrow
--http://gmodreviews.googlepages.com/
--http://forums.facepunchstudios.com/greenarrow
--There may be a few bits of code from the wire panel here and there as i used it as a starting point.
--Credit to whoever created the first wire screen, from which all others seem to use the lagacy clientside drawing code (this one included)

include('shared.lua')
CreateClientConVar( "wire_graphics_tablet_xval", 1, true, true )
CreateClientConVar( "wire_graphics_tablet_yval", 1, true, true ) 

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_BOTH

function ENT:Initialize()
	self.lastX = 0
	self.lastY = 0
end

function ENT:Draw()
	self.Entity:DrawModel()
	--night-eagle screen drawing code:
	local OF = 0
	local OU = 0
	local OR = 0
	local Res = 0.1
	local RatioX = 1
	
	if self.Entity:GetModel() == "models/props_lab/monitor01b.mdl" then
		OF = 6.53
		OU = 0
		OR = 0
		Res = 0.05
	elseif self.Entity:GetModel() == "models/kobilica/wiremonitorsmall.mdl" then
		OF = 0.2
		OU = 4.5
		OR = -0.85
		Res = 0.045
	elseif self.Entity:GetModel() == "models/kobilica/wiremonitorbig.mdl" then
		OF = 0.3
		OU = 11.8
		OR = -2.35
		Res = 0.12
	elseif self.Entity:GetModel() == "models/props/cs_office/computer_monitor.mdl" then
		OF = 3.25
		OU = 15.85
		OR = -2.2
		Res = 0.085
		RatioX = 0.75
	elseif self.Entity:GetModel() == "models/props/cs_office/TV_plasma.mdl" then
		OF = 6.1
		OU = 17.05
		OR = -5.99
		Res = 0.175
		RatioX = 0.57
	end
		
	local ang = self.Entity:GetAngles()
	local rot = Vector(-90,90,0)
	ang:RotateAroundAxis(ang:Right(), 	rot.x)
	ang:RotateAroundAxis(ang:Up(), 		rot.y)
	ang:RotateAroundAxis(ang:Forward(), rot.z)
	
	local pos = self.Entity:GetPos() + (self.Entity:GetForward() * OF) + (self.Entity:GetUp() * OU) + (self.Entity:GetRight() * OR)
	
	cam.Start3D2D(pos,ang,Res)
		local x = -112
		local y = -104
		local w = 296
		local h = 292
	
		local x1 = -5.535
		local x2 = 3.5
		local y1 = 5.091
		local y2 = -4.1
		
		local ox = 5
		local oy = 5
		
		local pos
		local cx
		local cy
		local posfix_x
		local posfix_y
		
		local trace = {}
		trace.start = LocalPlayer():GetShootPos()
		trace.endpos = LocalPlayer():GetAimVector() * 64 + trace.start
		trace.filter = LocalPlayer()
		local trace = util.TraceLine(trace)
		pos = self.Entity:WorldToLocal(trace.HitPos)
			
		posfix_x = math.abs(OR)
		posfix_y = math.abs(OU)
	
		cx = (((pos.y + OR)/math.abs(posfix_x)) - x1) / (math.abs(x1) + math.abs(x2))
		cy = 1 - (((pos.z - OU) + y1)) / (math.abs(y1) + math.abs(y2))
		if trace.Entity == self.Entity and cx >= 0 and cy >= 0 and cx <= 1 and cy <= 1 then
			if (math.abs(pos.x - OF) < 1.0) then
				surface.SetDrawColor(255,255,255,255)
				surface.SetTexture(surface.GetTextureID("gui/arrow"))
				surface.DrawTexturedRectRotated((x+(w*cx*.621)+ox)/RatioX,y+(h*cy*.621)+oy,16,16,45)
			end
			if (self.lastX ~= cx) then
				LocalPlayer():ConCommand("wire_graphics_tablet_xval "..tostring(cx).."\n")
				self.lastX = cx
			end
			if (self.lastY ~= cy) then
				LocalPlayer():ConCommand("wire_graphics_tablet_yval "..tostring(cy).."\n")
				self.lastY = cy
			end
		end
	cam.End3D2D()
	Wire_Render(self.Entity)
end

function ENT:IsTranslucent()
	return true
end
