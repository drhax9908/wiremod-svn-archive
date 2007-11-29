AddCSLuaFile( "cl_init.lua" )

AddCSLuaFile( "shared.lua" )


include('shared.lua')


ENT.WireDebugName = "Ranger"


local MODEL = Model("models/jaanus/wiretool/wiretool_range.mdl")


function ENT:Initialize()

	self.Entity:SetModel( MODEL )

	self.Entity:PhysicsInit( SOLID_VPHYSICS )

	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )

	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Entity:StartMotionController()


	self.Inputs = Wire_CreateInputs(self.Entity, { "X", "Y", "SelectValue"})

	self.Outputs = Wire_CreateOutputs(self.Entity, { "Dist" })
	
	self.HiRes = False

end

function
 
ENT:Setup( max_range, default_zero, show_beam, ignore_world, trace_water, out_dist, out_pos, out_vel, out_ang, out_col, out_val, out_sid, out_uid, out_eid, hiRes )

	self.MaxRange = max_range

	self.DefaultZero = default_zero
	self.PrevOutput = nil

	self.ShowBeam = show_beam

	self.IgnoreWorld = ignore_world

	self.Inputs.SelectValue.Value = 0

	if (show_beam) then

		self:SetBeamLength(math.min(self.MaxRange, 2000))

	else

		self:SetBeamLength(0)

	end

	
	if (trace_water) then

		self.Entity:SetNetworkedInt("TraceWater", 1)

	else

		self.Entity:SetNetworkedInt("TraceWater", 0)

	end

	

	local onames = {}

	if (out_dist) then

	    table.insert(onames, "Dist")

	end

	if (out_pos) then

	    table.insert(onames, "Pos X")

	    table.insert(onames, "Pos Y")

	    table.insert(onames, "Pos Z")

	end

	if (out_vel) then

	    table.insert(onames, "Vel X")

	    table.insert(onames, "Vel Y")

	    table.insert(onames, "Vel Z")

	end

	if (out_ang) then

	    table.insert(onames, "Ang Pitch")

	    table.insert(onames, "Ang Yaw")

	    table.insert(onames, "Ang Roll")

	end

	if (out_col) then

	    table.insert(onames, "Col R")

	    table.insert(onames, "Col G")

	    table.insert(onames, "Col B")

	    table.insert(onames, "Col A")

	end

	if (out_val) then

	    table.insert(onames, "Val")

	    table.insert(onames, "ValSize")

	end

	if (out_sid) then

		table.insert(onames, "SteamID")

	end

	if (out_uid) then

		table.insert(onames, "UniqueID")

	end

	if (out_eid) then

		table.insert(onames, "EntID")

	end


	Wire_AdjustOutputs(self.Entity, onames)


	self:TriggerOutput(0, Vector(0, 0, 0), Vector(0, 0, 0), Angle(0, 0, 0), Color(255, 255, 255, 255))

    self.HiRes = hiRes

	self:ShowOutput()
end

function
 
ENT:Output()

	return self.Value

end

function
 
ENT:TriggerInput(iname, value)

	if (iname == "X") then

		self:SetSkewX(self.Inputs.X.Value or 0)

	elseif (iname == "Y") then

		self:SetSkewY(self.Inputs.Y.Value or 0)

	end

end

function
 
ENT:Think()

	self.BaseClass.Think(self)


	local skew = Vector(self:GetSkewX(), self:GetSkewY(), 1)

	skew = skew*(self.MaxRange/skew:Length())

	local beam_x = self.Entity:GetRight()*skew.x

	local beam_y = self.Entity:GetForward()*skew.y

	local beam_z = self.Entity:GetUp()*skew.z


	local trace = {}

	trace.start = self.Entity:GetPos() + self.Entity:GetUp()*self.Entity:OBBMaxs().z

	trace.endpos = trace.start + beam_x + beam_y + beam_z

	trace.filter = { self.Entity }

	if (self.Entity:GetNetworkedInt("TraceWater") == 1) then trace.mask = MASK_ALL end


	local trace = util.TraceLine(trace)


	local dist = 0

	local pos = Vector(0, 0, 0)

	local vel = Vector(0, 0, 0)

	local ang = Angle(0, 0, 0)

	local col = Color(255, 255, 255, 255)

	local eid = 0
	local sid = 0

	local uid = 0

	local val = {}

	if (trace.Hit) then

		dist = trace.Fraction*self.MaxRange

		pos = trace.HitPos
		if (trace.Entity:IsValid()) then

			vel = trace.Entity:GetVelocity()

			ang = trace.Entity:GetAngles()

			col = Color(trace.Entity:GetColor())

			eid = trace.Entity:EntIndex()

			
if (trace.Entity:IsPlayer()) then

				sid = string.Explode(":", trace.Entity:SteamID())

				if (table.getn(sid) == 3) then
 
					sid = tonumber(sid[2] .. sid[3]) or -1

				else

					sid = -1

				end

				uid = tonumber(trace.Entity:UniqueID()) or -1

			end

			

			if (trace.Entity.Outputs) then

				local i = 0

				for k,v in pairs(trace.Entity.Outputs) do

					if (v.Value != nil) then

						val[i] = v.Value

						i = i + 1

					end

				end

			end

		elseif(self.IgnoreWorld) then

			if (self.DefaultZero) then

			    dist = 0

			else

				dist = self.MaxRange

			end

		end

	else

		if (not self.DefaultZero) then

			dist = self.MaxRange

		end

	end

	

	self:TriggerOutput(dist, pos, vel, ang, col, val, sid, uid, eid)

	self:ShowOutput()

	
    if(self.HiRes == True)then
	   self.Entity:NextThink(CurTime()+0.01)
	else
	   self.Entity:NextThink(CurTime()+0.04)
	end

	return true

end

function
 
ENT:ShowOutput()

	local txt = "Max Range: " .. self.MaxRange

	

	if (self.Outputs["Dist"]) then

		txt = txt .. "\nRange = " .. math.Round(self.Outputs["Dist"].Value*1000)/1000

	end

	if (self.Outputs["Pos X"]) then

		txt = txt .. "\nPosition = "
			.. math.Round(self.Outputs["Pos X"].Value*1000)/1000 .. ", "
			.. math.Round(self.Outputs["Pos Y"].Value*1000)/1000 .. ", "
			.. math.Round(self.Outputs["Pos Z"].Value*1000)/1000

	end

	if (self.Outputs["Vel X"]) then

		txt = txt .. "\nVelocity = "
			.. math.Round(self.Outputs["Vel X"].Value*1000)/1000 .. ", "
			.. math.Round(self.Outputs["Vel Y"].Value*1000)/1000 .. ", "
			.. math.Round(self.Outputs["Vel Z"].Value*1000)/1000

	end

	if (self.Outputs["Ang Pitch"]) then

		txt = txt .. "\nAngles = "
			.. math.Round(self.Outputs["Ang Pitch"].Value*1000)/1000 .. ", "
			.. math.Round(self.Outputs["Ang Yaw"].Value*1000)/1000 .. ", "
			.. math.Round(self.Outputs["Ang Roll"].Value*1000)/1000

	end

	if (self.Outputs["Col R"]) then

		txt = txt .. "\nColor = "
			.. math.Round(self.Outputs["Col R"].Value*1000)/1000 .. ", "
			.. math.Round(self.Outputs["Col G"].Value*1000)/1000 .. ", "
			.. math.Round(self.Outputs["Col B"].Value*1000)/1000 .. ", "
			.. math.Round(self.Outputs["Col A"].Value*1000)/1000

	end

	if (self.Outputs["Val"]) then

	
		txt = txt .. "\nValue = " .. math.Round((self.Outputs["Val"].Value)*1000)/1000 .. " ValSize = " .. self.Outputs["ValSize"].Value

	end

	if (self.Outputs["SteamID"]) then

	
		txt = txt .. "\nSteamID = " .. (self.Outputs["SteamID"].Value or 0)

	end

	if (self.Outputs["UniqueID"]) then

	
		txt = txt .. "\nUniqueID = " .. (self.Outputs["UniqueID"].Value or 0)

	end

	if (self.Outputs["EntID"]) then

	
		txt = txt .. "\nEntID = " .. (self.Outputs["EntID"].Value or 0)

	end


	self:SetOverlayText(txt)

end

function
 
ENT:TriggerOutput(dist, pos, vel, ang, col, val,sid,uid,eid)

    Wire_TriggerOutput(self.Entity, "Dist", dist)

    Wire_TriggerOutput(self.Entity, "Pos X", pos.x)

    Wire_TriggerOutput(self.Entity, "Pos Y", pos.y)

    Wire_TriggerOutput(self.Entity, "Pos Z", pos.z)

    Wire_TriggerOutput(self.Entity, "Vel X", vel.x)

    Wire_TriggerOutput(self.Entity, "Vel Y", vel.y)

    Wire_TriggerOutput(self.Entity, "Vel Z", vel.z)

    Wire_TriggerOutput(self.Entity, "Ang Pitch", ang.p)

    Wire_TriggerOutput(self.Entity, "Ang Yaw", ang.y)

    Wire_TriggerOutput(self.Entity, "Ang Roll", ang.r)

    Wire_TriggerOutput(self.Entity, "Col R", col.r)
 
    Wire_TriggerOutput(self.Entity, "Col G", col.g)

    Wire_TriggerOutput(self.Entity, "Col B", col.b)

    Wire_TriggerOutput(self.Entity, "Col A", col.a)

    Wire_TriggerOutput(self.Entity, "SteamID", sid)

    Wire_TriggerOutput(self.Entity, "UniqueID", uid)

    Wire_TriggerOutput(self.Entity, "EntID", eid)

    if (val != nil && table.getn(val) > 0 && self.Inputs.SelectValue.Value < table.Count(val)) then

	Wire_TriggerOutput(self.Entity, "Val", val[self.Inputs.SelectValue.Value])

	Wire_TriggerOutput(self.Entity,"ValSize",table.Count(val))

    else

	Wire_TriggerOutput(self.Entity, "Val", 0)

	Wire_TriggerOutput(self.Entity,"ValSize",0)

    end

end
