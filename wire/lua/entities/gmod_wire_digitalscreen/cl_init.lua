
include('shared.lua')

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_BOTH

function ENT:Initialize()

	surface.CreateFont( "coolvetica", 80, 400, false, false, "screen_font" ) 

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
	ang:RotateAroundAxis(ang:Forward(), 	rot.z)
	
	local pos = self.Entity:GetPos() + (self.Entity:GetForward() * OF) + (self.Entity:GetUp() * OU) + (self.Entity:GetRight() * OR)
	
	cam.Start3D2D(pos,ang,Res)
		
		local x = -112
		local y = -104
		local w = 296
		local h = 292
		
		
		surface.SetDrawColor(0,0,0,255)
		surface.DrawRect(x/RatioX,y,(x+w)/RatioX,y+h)
		
		//local PW = math.ceil((w / self:GetPixelsW( )) / 2)
		//local PH = math.ceil((h / self:GetPixelsH( )) / 2)

		
		for ty = 0, 31 do
			for tx = 0, 31 do
				local a = tx + ty*32
				local c = self.Entity:GetNetworkedFloat( "DispData"..a )
				surface.SetDrawColor(c,c,c,255)
				surface.DrawRect(x/RatioX + tx*6/RatioX,y + ty*6/RatioX,6/RatioX,6/RatioX)
			end
		end
		
	cam.End3D2D()
	
	Wire_Render(self.Entity)
end

function ENT:IsTranslucent()
	return true
end
