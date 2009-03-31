
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "CD Ray"


function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self.Entity, {"Write","Read","Value"})
	self.Outputs = Wire_CreateOutputs(self.Entity, {"Data","Sector","LocalSector","Track","Stack","Address"})

	self.Command = {}
	self.Command[0]  = 0 //[W] Write ray on
	self.Command[1]  = 0 //[W] Read ray on
	self.Command[2]  = 0 //[R] Current sector (global)
	self.Command[3]  = 0 //[R] Current sector (on track)
	self.Command[4]  = 0 //[R] Current track
	self.Command[5]  = 0 //[R] Current stack
	self.Command[6]  = 0 //[R] Current address (global)
	self.Command[7]  = 0 //[R] Current address (in current stack)

	self.Command[8]  = 0 //[W] Write buffer ready
	self.Command[9]  = 0 //[W] Continious write

//	self.Command[10] = 0 //[R] Read buffer ready
//	self.Command[11] = 0 //[R] Wait for address enabled
//	self.Command[12] = 0 //[R] Target read address (on stack)

	self.Command[16] = 0 //[R] Disk sectors (total)
	self.Command[17] = 0 //[R] Disk tracks (total)
	self.Command[18] = 0 //[R] First track number
	self.Command[19] = 0 //[R] Bytes per block
	self.Command[20] = 0 //[R] Disk size (per stack)
	self.Command[21] = 0 //[R] Disk volume (bytes total)

	self.WriteBuffer = {}
	self.PrevDiskEnt = nil

	self:SetBeamRange(64)
	self:ShowOutput()
end

function ENT:ReadCell(Address)
	if (Address >= 0) && (Address < 32) then
		if (self.Command[Address]) then
			return self.Command[Address]
		else
			return 0
		end
	end
	if (Address >= 512) && (Address < 1024) then
		if (self.WriteBuffer[Address-512]) then
			return self.WriteBuffer[Address-512]
		else
			return 0
		end
	end
	return nil
end

function ENT:WriteCell(Address, value)
	if (Address >= 0) && (Address < 32) then
		self.Command[Address] = value
		return true
	end
	if (Address >= 512) && (Address < 1024) then
		self.WriteBuffer[Address-512] = value
		return true
	end
	return false
end

function ENT:Setup(Range,DefaultZero)
	self.DefaultZero = DefaultZero
	self:SetBeamRange(Range)
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:TriggerInput(iname, value)
	if (iname == "Write") then
		self.Command[0] = value
		if (value ~= 0) then
			self.Entity:NextThink(CurTime()+0.01)
		end
	elseif (iname == "Read") then
		self.Command[1] = value
		if (value ~= 0) then
			self.Entity:NextThink(CurTime()+0.01)
		end
	elseif (iname == "Value") then
		self.Command[8] = 1
		self.Command[9] = 1
		self.WriteBuffer[0] = value
	end
end

function ENT:Think()
	if ((self.Command[0] ~= 0) or (self.Command[1] ~= 0)) then
		local vStart = self.Entity:GetPos()
		local vForward = self.Entity:GetUp()
		
	    	local trace = {}
			trace.start = vStart
			trace.endpos = vStart + (vForward * self:GetBeamRange())
			trace.filter = { self.Entity }
		local trace = util.TraceLine( trace ) 
		
		if (self.Command[0] == 1) then //write ray (blue)
			if (Color(self.Entity:GetColor()) != Color(0,0,255,255)) then
				self.Entity:SetColor(0, 0, 255, 255)
			end
		else //read ray (red)
			if (Color(self.Entity:GetColor()) != Color(255,0,0,255)) then
				self.Entity:SetColor(255, 0, 0, 255)
			end
		end

		if ((trace.Entity) and 
		    (trace.Entity:IsValid()) and 
		    (trace.Entity:GetClass() == "gmod_wire_cd_disk")) then
			local pos = trace.HitPos
			local disk = trace.Entity
			local lpos = disk:WorldToLocal(pos)

			local r = (lpos.x^2+lpos.y^2)^0.5 //radius
			local a = math.fmod(3.1415926+math.atan2(lpos.x,lpos.y),3.1415926*2) //angle
			local h = lpos.z-disk.StackStartHeight //stack 

			local track = math.floor(r / disk.Precision)
			local sector = math.floor(a*(track*disk.Precision))
			local stack = math.floor(h/disk.Precision)

			if (self.PrevDiskEnt ~= disk) then
				self.PrevDiskEnt = disk

				self.Command[16] = disk.DiskSectors //[R] Disk sectors (total)
				self.Command[17] = disk.DiskTracks //[R] Disk tracks (total)
				self.Command[18] = disk.FirstTrack //[R] First track number
				self.Command[19] = disk.BytesPerBlock //[R] Bytes per block
				self.Command[20] = disk.DiskSize //[R] Disk size (per stack)
				self.Command[21] = disk.DiskVolume //[R] Disk volume (total amount of sectors in all stacks)
			end

			if ((track >= disk.FirstTrack) and (stack >= 0) and (sector >= 0) and
			    (track < disk.DiskTracks) and
			    (stack < disk.DiskStacks)) then

				self.Command[2]  = disk.DiskSectors*stack+disk.TrackSectors[track]+sector //[R] Current sector (global)
				self.Command[3]  = sector //[R] Current sector (on track)
				self.Command[4]  = track //[R] Current track
				self.Command[5]  = stack //[R] Current stack
				self.Command[6]  = self.Command[2]*disk.BytesPerBlock //[R] Current address (global)
				self.Command[7]  = (disk.TrackSectors[track]+sector)*disk.BytesPerBlock //[R] Current address (in current stack)

				if (self.Command[0] ~= 0) then //write ray
					if (self.Command[8] ~= 0) then
						disk.DiskMemory[{s=sector,t=track,st=stack}] = self.WriteBuffer
						if (self.Command[9] == 0) then
							self.Command[8] = 0
						end
					end
				else //read ray
					if (disk.DiskMemory[{s=sector,t=track,st=stack}]) then
						self.WriteBuffer = disk.DiskMemory[{s=sector,t=track,st=stack}]
					else 
						self.WriteBuffer = {}
						self.WriteBuffer[0] = 0
					end
				end
			else
				self.Command[2]  = 0
				self.Command[3]  = 0
				self.Command[4]  = 0
				self.Command[5]  = 0
				self.Command[6]  = 0
				self.Command[7]  = 0
			end
		end

		//Update output
		Wire_TriggerOutput(self.Entity, "Data", 	self.WriteBuffer[0])
		Wire_TriggerOutput(self.Entity, "Sector", 	self.Command[2])
		Wire_TriggerOutput(self.Entity, "LocalSector",	self.Command[3])
		Wire_TriggerOutput(self.Entity, "Track", 	self.Command[4])
		Wire_TriggerOutput(self.Entity, "Stack", 	self.Command[5])
		Wire_TriggerOutput(self.Entity, "Address", 	self.Command[2])

		//Read more
		self.Entity:NextThink(CurTime()+0.01)
		return
	end
	if (Color(self.Entity:GetColor()) != Color(255,255,255,255)) then
		self.Entity:SetColor(255, 255, 255, 255)
	end
	self.Entity:NextThink(CurTime()+0.25)
end

function ENT:ShowOutput()
	self:SetOverlayText("CD Ray")
end

function ENT:OnRestore()
	Wire_Restored(self.Entity)
end

function ENT:RecieveValue(output,value)
	self.Activated = true
	self.ActivateTime = CurTime()
	Wire_TriggerOutput(self.Entity,output,value)
end