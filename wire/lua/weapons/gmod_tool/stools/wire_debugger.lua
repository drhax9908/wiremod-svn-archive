
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

	ply_idx = self:GetOwner():UniqueID()
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

	ply_idx = self:GetOwner():UniqueID()
    Components[ply_idx] = Components[ply_idx] or {}

	for k,cmp in ipairs(Components[ply_idx]) do
	    if (cmp == trace.Entity) then
	        table.remove(Components[ply_idx], k)
	        return true
	    end
	end
end


function TOOL:Reload(trace)
	Components[self:GetOwner():UniqueID()] = {}
end


if (SERVER) then

	local dbg_line_cache = {}
	local dbg_line_time = {}

	function DebuggerThink()
	    for i,cmps in pairs(Components) do
	        local ply = player.GetByUniqueID(i)

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
			        	dbginfo = dbginfo .. k .. ":" .. math.Round(input.Value*1000)/1000 .. " "
		            end
		        end

		        if (cmp.Outputs) then
			        dbginfo = dbginfo .. "OUT "
		            for _,k in ipairs(table.MakeSortedKeys(cmp.Outputs)) do
		                local output = cmp.Outputs[k]
			        	dbginfo = dbginfo .. k .. ":" .. math.Round(output.Value*1000)/1000 .. " "
		            end
		        end

		        if (not cmp.Inputs) and (not cmp.Outputs) then
		            dbginfo = dbginfo .. "No info"
		        end

                dbg_line_cache[i] = dbg_line_cache[i] or {}
                dbg_line_time[i] = dbg_line_time[i] or {}
		        if (dbg_line_cache[i][l] ~= dbginfo) then
		            if (not dbg_line_time[i][l]) or (CurTime() > dbg_line_time[i][l]) then
				        umsg.Start("WireDbgLine", ply)
							umsg.Short(l)
							umsg.String(dbginfo)
						umsg.End()
						dbg_line_cache[i][l] = dbginfo
						dbg_line_time[i][l] = CurTime() + 0.2
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
				text = dbg_lines[i],
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
	    dbg_lines[i] = um:ReadString()
	end
	usermessage.Hook("WireDbgLine", Debugger_Msg_Line)

end


function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_debugger_name", Description = "#Tool_wire_debugger_desc" })
end
