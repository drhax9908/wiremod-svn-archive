
include('shared.lua')

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_BOTH

function ENT:Initialize()

	surface.CreateFont( "lucida console", 30, 400, true, false, "console_font" ) 

	self.Memory1 = {}
	self.Memory2 = {}

	for i = 0, 2048 do
		self.Memory1[i] = 0
	end

	for i = 0, 2048 do
		self.Memory2[i] = 0
	end

	self.LastClk = 0

	self.PrevTime = CurTime()
	self.IntTimer = 0
	
end

function ConsoleScreen_DataMessage( um )
	local ent = ents.GetByIndex( um:ReadLong() )
	local clk = um:ReadLong()
	local address = um:ReadLong()
	local value = um:ReadFloat()
	if (ent) && (ent.Memory1) && (ent.Memory2) then
		if (clk == 1) && (address <= 2000) then
			ent.Memory1[address] = value //Vis mem
			ent.Memory2[address] = value //Invis mem
		else
			ent.Memory2[address] = value //Invis mem
		end

		//2040 - Hardware Clear Row (Writing clears row)
		//2041 - Hardware Clear Column (Writing clears column)
		//2042 - Hardware Clear Screen

		if (address == 2040) then
			for i = 0, 29 do
				ent.Memory1[value*30+i] = 0
				ent.Memory2[value*30+i] = 0
			end
		end
		if (address == 2041) then
			for i = 0, 17 do
				ent.Memory1[i*30+value] = 0
				ent.Memory2[i*30+value] = 0
			end
		end
		if (address == 2042) then
			for i = 0, 18*30*2 do 
				ent.Memory1[i] = 0
				ent.Memory2[i] = 0
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
usermessage.Hook("consolescreen_datamessage", ConsoleScreen_DataMessage) 

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
		Res = 0.02
	elseif self.Entity:GetModel() == "models/kobilica/wiremonitorsmall.mdl" then
		OF = 0.2
		OU = 4.5
		OR = -0.85
		Res = 0.019
	elseif self.Entity:GetModel() == "models/kobilica/wiremonitorbig.mdl" then
		OF = 0.3
		OU = 11.8
		OR = -2.35
		Res = 0.051
	elseif self.Entity:GetModel() == "models/props/cs_office/computer_monitor.mdl" then
		OF = 3.25
		OU = 15.85
		OR = -2.2
		Res = 0.0364
		RatioX = 0.75
	elseif self.Entity:GetModel() == "models/props/cs_office/TV_plasma.mdl" then
		OF = 6.1
		OU = 17.05
		OR = -5.99
		Res = 0.075
		RatioX = 0.57
	end
	
	local ang = self.Entity:GetAngles()
	local rot = Vector(-90,90,0)
	ang:RotateAroundAxis(ang:Right(), 	rot.x)
	ang:RotateAroundAxis(ang:Up(), 		rot.y)
	ang:RotateAroundAxis(ang:Forward(), 	rot.z)
	
	local pos = self.Entity:GetPos() + (self.Entity:GetForward() * OF) + (self.Entity:GetUp() * OU) + (self.Entity:GetRight() * OR)
	
	cam.Start3D2D(pos,ang,Res)
		
		local x = -254
		local y = -247
		local w = 676
		local h = 692

		local ch = self.Memory1[2043]

		local hb = 24*math.fmod(ch,10)
		local hg = 24*math.fmod(math.floor(ch / 10),10)
		local hr = 24*math.fmod(math.floor(ch / 100),10)
		surface.SetDrawColor(hr,hg,hb,255)
		surface.DrawRect(x/RatioX,y,(x+w)/RatioX,y+h)

		//local ratio = 192/w;
		
		for ty = 0, 17 do
			for tx = 0, 29 do
				local a = tx + ty*30
				local c1 = self.Memory1[2*a]
				local c2 = self.Memory1[2*a+1]
				local cback = math.floor(c2 / 1000)
				local cfrnt = c2 - math.floor(c2 / 1000)*1000

				local fb = 24*math.fmod(cfrnt,10)
				local fg = 24*math.fmod(math.floor(cfrnt / 10),10)
				local fr = 24*math.fmod(math.floor(cfrnt / 100),10)
				local bb = 24*math.fmod(cback,10)
				local bg = 24*math.fmod(math.floor(cback / 10),10)
				local br = 24*math.fmod(math.floor(cback / 100),10)

				if (c1 > 255) then c1 = 0 end

				if (cback ~= 0) then
					surface.SetDrawColor(br,bg,bb,255)
					surface.DrawRect((x+tx*14)/RatioX,y+ty*24,14/RatioX+2,24+2)
				end
				if (c1 ~= 0) && (cfrnt ~= 0) then
					draw.DrawText(string.char(c1),"console_font",(8+x+tx*14)/RatioX,y+ty*24,Color(fr,fg,fb,255),1)
				end
			end
		end

		//2040 - Hardware Clear Row (Writing clears row)
		//2041 - Hardware Clear Column (Writing clears column)
		//2042 - Hardware Clear Screen
		//2043 - Hardware Background Color (000)
		//2044 - Cursor Blink Rate (0.50)
		//2045 - Cursor Size (0.25)
		//2046 - Cursor Address
		//2047 - Cursor Enabled
		//2048 - Clk

		if (self.Memory1[2047] >= 1) then
			local DeltaTime = CurTime()-(self.PrevTime or CurTime())
			self.PrevTime = (self.PrevTime or CurTime())+DeltaTime
			self.IntTimer = self.IntTimer + DeltaTime

			local Rate = self.Memory1[2044]

			if (self.IntTimer <= Rate) then
				local a = math.floor(self.Memory1[2046] / 2)

				local tx = a - math.floor(a / 30)*30
				local ty = math.floor(a / 30)
	
				local c = self.Memory1[2*a+1]
				local cback = 999-math.floor(c / 1000)
				local bb = 24*math.fmod(cback,10)
				local bg = 24*math.fmod(math.floor(cback / 10),10)
				local br = 24*math.fmod(math.floor(cback / 100),10)
	
				surface.SetDrawColor(br,bg,bb,255)
				surface.DrawRect((x+tx*14)/RatioX,y+ty*24+24*(1-self.Memory1[2045]),14/RatioX,24*self.Memory1[2045])
			end
			if (self.IntTimer >= Rate*2) then
				self.IntTimer = 0
			end
		end
		
	cam.End3D2D()
	
	Wire_Render(self.Entity)
end

function ENT:IsTranslucent()
	return true
end
