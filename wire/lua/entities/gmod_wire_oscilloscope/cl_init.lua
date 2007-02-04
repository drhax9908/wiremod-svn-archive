
include('shared.lua')

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_BOTH

function ENT:Initialize()
end

function ENT:Draw()
	self.Entity:DrawModel()

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
		
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(x/RatioX, y, (x+w)/RatioX, y+h)

		local nodes = self:GetNodeList()
		for i=1,39 do
		    local i_next = i+1
		    
			local nx1 = (nodes[i].X+1)*w*0.25+x
			local ny1 = (nodes[i].Y+1)*h*0.25+y
			local nx2 = (nodes[i_next].X+1)*w*0.25+x
			local ny2 = (nodes[i_next].Y+1)*h*0.25+y
			
			local b = math.max(0, math.min(i*i*0.16, 255))
			surface.SetDrawColor(b, b, b, 255)
			surface.DrawLine(nx1/RatioX, ny1, nx2/RatioX, ny2)
		end
		
	cam.End3D2D()
	
	Wire_Render(self.Entity)
end

function ENT:IsTranslucent()
	return true
end
