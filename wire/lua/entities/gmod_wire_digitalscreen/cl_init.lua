
include('shared.lua')

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_BOTH

function ENT:Initialize()

	surface.CreateFont( "coolvetica", 80, 400, false, false, "screen_font" ) 

	self.Memory1 = {}
	self.Memory2 = {}

	for i = 0, 2047 do
		self.Memory1[i] = 0
	end
	for i = 0, 2047 do
		self.Memory2[i] = 0
	end

	self.LastClk = 0
	
end

function DigitalScreen_DataMessage( um )
	local ent = ents.GetByIndex( um:ReadLong() )
	local clk = um:ReadLong()
	local address = um:ReadLong()
	local value = um:ReadFloat()
	if (ent) && (ent.Memory1) && (ent.Memory2) then
		if (clk == 1) then
			ent.Memory1[address] = value //Vis mem
			ent.Memory2[address] = value //Invis mem
		else
			ent.Memory2[address] = value //Invis mem
		end

		//2039 - Hardware Clear Row (Writing clears row)
		//2040 - Hardware Clear Column (Writing clears column)
		//2041 - Hardware Clear Screen

		if (address == 2039) then
			for i = 0, 31 do
				ent.Memory1[value*30+i] = 0
				ent.Memory2[value*30+i] = 0
			end
		end
		if (address == 2040) then
			for i = 0, 31 do
				ent.Memory1[i*30+value] = 0
				ent.Memory2[i*30+value] = 0
			end
		end
		if (address == 2041) then
			for i = 0, 32*32-1 do 
				ent.Memory1[i] = value
				ent.Memory2[i] = value
			end
		end

		if (ent.LastClk ~= clk) then
			ent.LastClk = clk //swap the memory if clock changes
			ent.Memory1 = table.Copy(ent.Memory2)

			//ent.Memory1,ent.Memory2 = ent.Memory2,ent.Memory1
			//local temp = table.Copy(ent.Memory1)
			//ent.Memory1 = table.Copy(ent.Memory2)
			//ent.Memory2 = table.Copy(temp)			
		end

	end
end
usermessage.Hook("digitalscreen_datamessage", DigitalScreen_DataMessage) 

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

		//local ratio = 192/w;
		
		for ty = 0, 31 do
			for tx = 0, 31 do
				local a = tx + ty*32
				local c = self.Memory1[a]
				surface.SetDrawColor(c,c,c,255)
				surface.DrawRect(x/RatioX + tx*6/RatioX,y + ty*6,6/RatioX,6)
			end
		end
		
	cam.End3D2D()
	
	Wire_Render(self.Entity)
end

function ENT:IsTranslucent()
	return true
end
