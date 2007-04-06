local WIRE_SCROLL_SPEED = 0.5
local WIRE_BLINKS_PER_SECOND = 2
local CurPathEnt = {}
local Wire_DisableWireRender = 0

function Wire_Render(ent)
    if (not ent:IsValid()) then return end
	if (Wire_DisableWireRender > 0) then return end
	
	local path_count = ent:GetNetworkedBeamInt("wpn_count") or 0
	if (path_count <= 0) then return end

	local w,f = math.modf(CurTime()*WIRE_BLINKS_PER_SECOND)
    local blink = nil
    if (f < 0.5) then
		blink = ent:GetNetworkedBeamString("BlinkWire")
	end

    local bbmin = ent:GetPos()+Vector(-8, -8, -8)
    local bbmax = ent:GetPos()+Vector(8, 8, 8)

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

						if (endpos.x < bbmin.x) then bbmin.x = endpos.x end
						if (endpos.y < bbmin.y) then bbmin.y = endpos.y end
						if (endpos.z < bbmin.z) then bbmin.z = endpos.z end
						if (endpos.x > bbmax.x) then bbmax.x = endpos.x end
						if (endpos.y > bbmax.y) then bbmax.y = endpos.y end
						if (endpos.z > bbmax.z) then bbmax.z = endpos.z end
					end
				end
				render.EndBeam()
			end
		end
	end
	
	ent:SetRenderBoundsWS(bbmin, bbmax, Vector()*6)
end


local function Wire_GetWireRenderBoundsWS(ent)
    if (not ent:IsValid()) then return end

    local paths = ent.WirePaths
    local bbmin = ent:GetPos()+Vector(-8, -8, -8)
    local bbmax = ent:GetPos()+Vector(8, 8, 8)

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
						nodepos = node_ent:LocalToWorld(nodepos)

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

	return bbmin, bbmax
end


function Wire_UpdateRenderBounds(ent)
	local bbmin, bbmax = Wire_GetWireRenderBoundsWS(ent)
	ent:SetRenderBoundsWS(bbmin, bbmax, Vector()*6)
end

local function WireDisableRender(pl, cmd, args)
	if not args[1] then return end
	Wire_DisableWireRender = tonumber(args[1])
end
concommand.Add( "Wire_DisableWireRender", WireDisableRender )
