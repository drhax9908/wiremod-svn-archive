ENT.Type 			= "anim"
ENT.Base 			= "base_wire_entity"

ENT.PrintName		= ""
ENT.Author			= ""
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

function ENT:AddMonitor(model,tof,tou,tor,trs,x1,x2,y1,y2)
	self.Monitor[model] = {}
	self.Monitor[model].OF = tof
	self.Monitor[model].OU = tou
	self.Monitor[model].OR = tor
	self.Monitor[model].RS = trs
	self.Monitor[model].RatioX = (y1-y2)/(x2-x1)

	self.Monitor[model].x1 = x1
	self.Monitor[model].x2 = x2
	self.Monitor[model].y1 = y1
	self.Monitor[model].y2 = y2

	self.Monitor[model].z = tof
end

function ENT:InitMonitorModels()
	//Offset front, offset up, offset right, resolution/scale        OF     OU     OR    SCALE  RATIO (X/Y)
	self:AddMonitor("models/props_lab/monitor01b.mdl",		6.4,  0.45,  1.00, 0.018, -5.535, 3.5, 5.091, -4.1)
	self:AddMonitor("models/kobilica/wiremonitorsmall.mdl",		0.3, 5.0, 0.0, 0.0175, -4.4, 4.5, 9.5, 0.6)
	self:AddMonitor("models/props/cs_office/computer_monitor.mdl",	3.7, 16.7, 2.4, 0.031, -10.5, 10.5, 24.7, 8.6)
	self:AddMonitor("models/kobilica/wiremonitorbig.mdl",		0.2, 13,  0.0, 0.045, -11.5, 11.6, 24.5, 1.6)
	self:AddMonitor("models/blacknecro/tv_plasma_4_3.mdl",		0.1, -0.5, 6.5, 0.082, -27.87, 27.87, 20.93, -20.93)
	self:AddMonitor("models/props/cs_office/TV_plasma.mdl",		6.1, 18.93, 11.0, 0.065, -28.5, 28.5, 36, 2)
	self:AddMonitor("models/props/cs_assault/Billboard.mdl",	1, 0, 52, 0.23, -110.512, 110.512, 57.647, -57.647)

	self:AddMonitor("models/blacknecro/ledboard60.mdl",		6.1, 18.5, 11.0, 0.065, -60, 60, -60, 60)

	//1:1 monitor
	//16:9 plasma 

end