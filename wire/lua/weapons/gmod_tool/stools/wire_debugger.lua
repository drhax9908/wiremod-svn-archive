TOOL.Category		= "Wire - Tools"
TOOL.Name			= "Debugger"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_debugger_name", "Debugging Tool" )
    language.Add( "Tool_wire_debugger_desc", "Shows selected components info on the HUD." )
    language.Add( "Tool_wire_debugger_0", "Primary: Add component to HUD\nSecondary: Remove component from HUD\nReload: Clear HUD" )
end

local Components = {}

function TOOL:LeftClick(trace)
	if (not trace.Entity:IsValid()) then return end
	if (CLIENT) then return true end

	local dbgname = trace.Entity.WireDebugName
	if (not dbgname) then return end

	ply_idx = self:GetOwner()
    Components[ply_idx] = Components[ply_idx] or {}

	for k,cmp in ipairs(Components[ply_idx]) do
	    if (cmp == trace.Entity) then return end
	end
	
	table.insert(Components[ply_idx], trace.Entity)
	
	return true
end


function TOOL:RightClick(trace)
	if (not trace.Entity:IsValid()) then return end
	if (CLIENT) then return true end

	local dbgname = trace.Entity.WireDebugName
	if (not dbgname) then return end

	ply_idx = self:GetOwner()
    Components[ply_idx] = Components[ply_idx] or {}

	for k,cmp in ipairs(Components[ply_idx]) do
	    if (cmp == trace.Entity) then
	        table.remove(Components[ply_idx], k)
	        return true
	    end
	end
end


function TOOL:Reload(trace)
	if (CLIENT) then return end
	Components[self:GetOwner()] = {}
end


if (SERVER) then
	
	local dbg_line_cache = {}
	local dbg_line_time = {}
	
	function DebuggerThink()
	    for ply,cmps in pairs(Components) do
			
			if ( !ply ) or ( !ply:IsValid() ) or ( !ply:IsPlayer() ) then --player has left
				
				Components[ply] = nil
				
			else
				
		    	table.Compact(cmps, function(cmp) return cmp:IsValid() end)
				
		        umsg.Start("WireDbgLineCount", ply)
					umsg.Short(table.getn(cmps))
				umsg.End()
				
			    for l,cmp in ipairs(cmps) do
				    local dbginfo = cmp.WireDebugName .. " - "
					
			        if (cmp.Inputs) then
				        dbginfo = dbginfo .. "IN "
			            for _,k in ipairs(table.MakeSortedKeys(cmp.Inputs)) do
			                local input = cmp.Inputs[k]
							if (type(input.Value) == "number") then
								dbginfo = dbginfo .. k .. ":" .. math.Round(input.Value*1000)/1000 .. " "
							elseif (type(input.Value) == "Vector") then
								dbginfo = dbginfo .. k .. ":(" .. math.Round(input.Value.x*10)/10 .. "," .. math.Round(input.Value.y*10)/10 .. "," .. math.Round(input.Value.z*10)/10 .. ") "
							end
			            end
			        end
					
			        if (cmp.Outputs) then
				        dbginfo = dbginfo .. "OUT "
			            for _,k in ipairs(table.MakeSortedKeys(cmp.Outputs)) do
			                local output = cmp.Outputs[k]
							if (type(output.Value) == "number") then
								dbginfo = dbginfo .. k .. ":" .. math.Round(output.Value*1000)/1000 .. " "
							elseif (type(output.Value) == "Vector") then
								dbginfo = dbginfo .. k .. ":(" .. math.Round(output.Value.x*10)/10 .. "," .. math.Round(output.Value.y*10)/10 .. "," .. math.Round(output.Value.z*10)/10 .. ") "
							end
			            end
			        end
					
			        if (not cmp.Inputs) and (not cmp.Outputs) then
			            dbginfo = dbginfo .. "No info"
			        end
					
	                dbg_line_cache[ply] = dbg_line_cache[ply] or {}
	                dbg_line_time[ply] = dbg_line_time[ply] or {}
			        if (dbg_line_cache[ply][l] ~= dbginfo) then
			            if (not dbg_line_time[ply][l]) or (CurTime() > dbg_line_time[ply][l]) then
					        umsg.Start("WireDbgLine", ply)
								umsg.Short(l)
								umsg.String(dbginfo)
							umsg.End()
							dbg_line_cache[ply][l] = dbginfo
							dbg_line_time[ply][l] = CurTime() + 0.2
						end
					end
			    end
				
			end
			
		end
	end
	hook.Add("Think", "DebuggerThink", DebuggerThink)
	
end


if (CLIENT) then

	local dbg_line_count = 0
	local dbg_lines = {}

	function DebuggerDrawHUD()
	    local dbginfo = ""
	    if (dbg_line_count <= 0) then return end
	    
	    draw.RoundedBox(8, 22, ScrH()/2-8, 300+16, dbg_line_count*14+16, Color(50, 50, 50, 128))
	    
	    for i = 1,dbg_line_count do
			draw.Text{
				text = dbg_lines[i] or "",
				font = "Default",
				pos = { 30, ScrH()/2+(i-1)*14 }
				}
		end
	end
	hook.Add("HUDPaint", "DebuggerDrawHUD", DebuggerDrawHUD)

	function Debugger_Msg_LineCount(um)
	    dbg_line_count = um:ReadShort()
	end
	usermessage.Hook("WireDbgLineCount", Debugger_Msg_LineCount)

	function Debugger_Msg_Line(um)
	    local i = um:ReadShort()
	    dbg_lines[i] = um:ReadString() or ""
	end
	usermessage.Hook("WireDbgLine", Debugger_Msg_Line)

end


function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_debugger_name", Description = "#Tool_wire_debugger_desc" })
end
