local WIRE_SCROLL_SPEED = 0.5
local WIRE_BLINKS_PER_SECOND = 2
local CurPathEnt = {}
local Wire_DisableWireRender = 2 --bug with mode 0 and gmod2007beta

function Wire_Render(ent)
	if (not ent:IsValid()) then return end
	if (Wire_DisableWireRender == 1) then return end
	
	if (Wire_DisableWireRender == 0) then
		local path_count = ent:GetNetworkedBeamInt("wpn_count") or 0
		if (path_count <= 0) then return end

		local w,f = math.modf(CurTime()*WIRE_BLINKS_PER_SECOND)
	    local blink = nil
	    if (f < 0.5) then
			blink = ent:GetNetworkedBeamString("BlinkWire")
		end
		
		for i = 1,path_count do
		    local path_name = ent:GetNetworkedBeamString("wpn_" .. i)
		    if (blink ~= path_name) then
		        local net_name = "wp_"..path_name
			    local len = ent:GetNetworkedBeamInt(net_name) or 0
				
				if (len > 0) then
				    local start = ent:GetNetworkedBeamVector(net_name .. "_start")
				    if (ent:IsValid()) then start = ent:LocalToWorld(start) end
				    local color_v = ent:GetNetworkedBeamVector(net_name .. "_col")
				    local color = Color(color_v.x, color_v.y, color_v.z, 255)
				    local width = ent:GetNetworkedBeamFloat(net_name .. "_width")

				    local scroll = CurTime()*WIRE_SCROLL_SPEED
				    
					render.SetMaterial(Material(ent:GetNetworkedBeamString(net_name .. "_mat")))
					render.StartBeam(len+1)
					render.AddBeam(start, width, scroll, color)

					for j=1,len do
					    local node_ent = ent:GetNetworkedBeamEntity(net_name .. "_" .. j .. "_ent")
					    local endpos = ent:GetNetworkedBeamVector(net_name .. "_" .. j .. "_pos")
						if (node_ent:IsValid()) then
							endpos = node_ent:LocalToWorld(endpos)

						    scroll = scroll+(endpos-start):Length()/10

							render.AddBeam(endpos, width, scroll, color)

							start = endpos
						end
					end
					render.EndBeam()
				end
			end
		end
		
		ent:SetRenderBoundsWS(bbmin, bbmax, Vector()*6)
	else
		local p = ent.ppp
		if p == nil then p = {next = -100} end
		
		if p.next < CurTime() then
			p.next = CurTime() + 0.25
			p.paths = {}
			
			local path_count = ent:GetNetworkedBeamInt("wpn_count") or 0
			if (path_count <= 0) then return end

			local w,f = math.modf(CurTime()*WIRE_BLINKS_PER_SECOND)
		    local blink = nil
		    if (f < 0.2) then
				blink = ent:GetNetworkedBeamString("BlinkWire")
			end
			
			for i = 1,path_count do
				local x = {}
			    local path_name = ent:GetNetworkedBeamString("wpn_" .. i)
				x.path_name = path_name
			    //if (blink ~= path_name) then
			        local net_name = "wp_"..path_name
				    local len = ent:GetNetworkedBeamInt(net_name) or 0
					
					if (len > 0) then
						
					    local start = ent:GetNetworkedBeamVector(net_name .. "_start")
						x.startx = start
					    if (ent:IsValid()) then start = ent:LocalToWorld(start) end
					    local color_v = ent:GetNetworkedBeamVector(net_name .. "_col")
					    local color = Color(color_v.x, color_v.y, color_v.z, 255)
					    local width = ent:GetNetworkedBeamFloat(net_name .. "_width")

					    local scroll = CurTime()*WIRE_SCROLL_SPEED
					    
						x.material = Material(ent:GetNetworkedBeamString(net_name .. "_mat"))
						x.startbeam = len + 1
						x.start = start
						x.width = width
						x.scroll = scroll
						x.color = color
						x.beams = {}
						
						for j=1,len do
							local v = {}
						    local node_ent = ent:GetNetworkedBeamEntity(net_name .. "_" .. j .. "_ent")
						    local endpos = ent:GetNetworkedBeamVector(net_name .. "_" .. j .. "_pos")
							v.node_ent = node_ent
							v.node_endpos = endpos
							if (node_ent:IsValid()) then
								endpos = node_ent:LocalToWorld(endpos)
								
							    scroll = scroll+(endpos-start):Length()/10
								
								v.endpos = endpos
								v.width = width
								v.scroll = scroll
								v.color = color
								table.insert(x.beams, v)
								
								start = endpos
							end
						end
						
						table.insert(p.paths, x)
						
					end
				//end
			end
			
			ent.ppp = p
		end
		
		for _,k in ipairs(p.paths) do
			if (ent:GetNetworkedBeamString("BlinkWire") ~= k.path_name || math.fmod(CurTime()*WIRE_BLINKS_PER_SECOND, 1) > 0.5) then
				k.scroll = CurTime()*WIRE_SCROLL_SPEED
				k.start = ent:LocalToWorld(k.startx)
				render.SetMaterial(k.material)
				render.StartBeam(k.startbeam)
				render.AddBeam(k.start, k.width, k.scroll, k.color)
				
				for _,v in ipairs(k.beams) do
					if (v.node_ent:IsValid()) then
						local endpos = v.node_ent:LocalToWorld(v.node_endpos)
						local scroll = k.scroll+(endpos-k.start):Length()/10
					
						render.AddBeam(endpos, v.width, scroll, v.color)
					end
				end
			
				render.EndBeam()
			end
		end
		
	end
end


local function Wire_GetWireRenderBounds(ent)
    if (not ent:IsValid()) then return end

    local paths = ent.WirePaths
	local bbmin = ent:OBBMins()
	local bbmax = ent:OBBMaxs()

	local path_count = ent:GetNetworkedBeamInt("wpn_count") or 0
	if (path_count > 0) then
		for i = 1,path_count do
		    local path_name = ent:GetNetworkedBeamString("wpn_" .. i)
	        local net_name = "wp_"..path_name
		    local len = ent:GetNetworkedBeamInt(net_name) or 0

			if (len > 0) then
				for j=1,len do
				    local node_ent = ent:GetNetworkedBeamEntity(net_name .. "_" .. j .. "_ent")
				    local nodepos = ent:GetNetworkedBeamVector(net_name .. "_" .. j .. "_pos")
					if (node_ent:IsValid()) then
						nodepos = ent:WorldToLocal(node_ent:LocalToWorld(nodepos))
						
						if (nodepos.x < bbmin.x) then bbmin.x = nodepos.x end
						if (nodepos.y < bbmin.y) then bbmin.y = nodepos.y end
						if (nodepos.z < bbmin.z) then bbmin.z = nodepos.z end
						if (nodepos.x > bbmax.x) then bbmax.x = nodepos.x end
						if (nodepos.y > bbmax.y) then bbmax.y = nodepos.y end
						if (nodepos.z > bbmax.z) then bbmax.z = nodepos.z end
					end
				end
			end
		end
	end
	
	if (ent.ExtraRBoxPoints) then
		for _,point_l in ipairs( ent.ExtraRBoxPoints ) do
			local point = point_l
			if (point.x < bbmin.x) then bbmin.x = point.x end
			if (point.y < bbmin.y) then bbmin.y = point.y end
			if (point.z < bbmin.z) then bbmin.z = point.z end
			if (point.x > bbmax.x) then bbmax.x = point.x end
			if (point.y > bbmax.y) then bbmax.y = point.y end
			if (point.z > bbmax.z) then bbmax.z = point.z end
		end
	end

	return bbmin, bbmax
end


function Wire_UpdateRenderBounds(ent)
	local bbmin, bbmax = Wire_GetWireRenderBounds(ent)
	ent:SetRenderBounds(bbmin, bbmax)
end

local function WireDisableRender(pl, cmd, args)
	if args[1] then
		Wire_DisableWireRender = tonumber(args[1])
	end
	Msg("\nWire DisableWireRender/WireRenderMode = "..tostring(Wire_DisableWireRender).."\n")
end
concommand.Add( "cl_Wire_DisableWireRender", WireDisableRender )
concommand.Add( "cl_Wire_SetWireRenderMode", WireDisableRender )


function Wire_DrawTracerBeam( ent, beam_num, hilight, beam_length )
	local beam_length = beam_length or ent:GetBeamLength(beam_num)
	if (beam_length > 0) then
		
		local x, y = 0, 0
		if (ent.GetSkewX and ent.GetSkewY) then
			x, y = ent:GetSkewX(beam_num), ent:GetSkewY(beam_num)
		end
		
		local start, ang = ent:GetPos(), ent:GetAngles()
		
		if (ent.ls != start or ent.la != ang or ent.ll != beam_length or ent.lx != x or ent.ly != y) then
			ent.ls, ent.la = start, ang
			
			if (ent.ll != beam_length or ent.lx != x or ent.ly != y) then
				ent.ll, ent.lx, ent.ly = beam_length, x, y
				
				if (x == 0 and y == 0) then
					ent.endpos = start + (ent:GetUp() * beam_length)
				else
					local skew = Vector(x, y, 1)
					skew = skew*(beam_length/skew:Length())
					local beam_x = ent:GetRight()*skew.x
					local beam_y = ent:GetForward()*skew.y
					local beam_z = ent:GetUp()*skew.z
					ent.endpos = start + beam_x + beam_y + beam_z
				end
				ent.ExtraRBoxPoints = ent.ExtraRBoxPoints or {}
				ent.ExtraRBoxPoints[beam_num] = ent:WorldToLocal(ent.endpos)
			else
				ent.endpos = ent:LocalToWorld(ent.ExtraRBoxPoints[beam_num])
			end
		end
		
		local trace = {}
		trace.start = start
		trace.endpos = ent.endpos
		trace.filter = { ent }
		if (ent:GetNetworkedBool("TraceWater")) then trace.mask = MASK_ALL end
		trace = util.TraceLine(trace)
		
		render.SetMaterial(Material("tripmine_laser"))
		render.DrawBeam(start, trace.HitPos, 6, 0, 10, Color(ent:GetColor()))
		if (hilight) then
			render.SetMaterial(Material("Models/effects/comball_tape"))
			render.DrawBeam(start, trace.HitPos, 6, 0, 10, Color(255,255,255,255))
		end
	end
end


local function initplayer(um)
	WireVersion = um:ReadShort()
	Msg("===============================\n===  Wire  "..WireVersion.."   Installed  ===\n===============================\n")
end
usermessage.Hook( "wire_initplayer", initplayer )