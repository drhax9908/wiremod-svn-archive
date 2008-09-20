AddCSLuaFile( "autorun/client/cl_wirelib.lua" )
AddCSLuaFile( "autorun/client/cl_gpulib.lua" )

WireLib = {}

-- Compatibility Global
WireAddon = 1

if file.Exists("../lua/wire/.svn/entries") then
	WireVersion = tonumber( string.Explode( "\n", file.Read( "../lua/wire/.svn/entries" ) )[ 4 ] ) --get svn revision, stolen from ULX
else
	WireVersion = 0	--change this value to the current revision number when making a general release
end
local function initplayer(ply)
	umsg.Start( "wire_initplayer", ply )
		umsg.Short( WireVersion or 0 )
	umsg.End()
end
hook.Add( "PlayerInitialSpawn", "WirePlayerInitSpawn", initplayer )


WireLib.Version = WireVersion

-- extra table functions

local orig_table = table

-- Compacts an array by rejecting entries according to cb.
function table.Compact(tbl, cb, n)
	n = n or table.getn(tbl)
	local cpos = 1
	for i = 1, n do
	    if cb(tbl[i]) then
	    	tbl[cpos] = tbl[i]
	    	cpos = cpos + 1
		end
	end
	
	local new_n = cpos-1
	while (cpos <= n) do
	    tbl[cpos] = nil
	    cpos = cpos + 1
	end
end

function table.MakeSortedKeys(tbl) -- I don't even know if I need this one.
	local result = {}
	
	for k,_ in pairs(tbl) do table.insert(result, k) end
	table.sort(result)

	return result
end


-- end extra table functions


local Inputs = {}
local Outputs = {}
local CurLink = {}
local PathQueue = {}

local function Wire_ResetTriggerLimit(idx, output)
	if (output) then
	    output.TriggerLimit = 4
	end
end

local function UpdateWires()
    table.foreach(Outputs, Wire_ResetTriggerLimit)
end

hook.Add("Think", "WireLib_Think", UpdateWires)


function Wire_CreateInputs(ent, names)
	local inputs = {}
	for n,v in pairs(names) do
		local input = {
			Entity = ent,
			Name = v,
			Value = 0,
			Type = "NORMAL",
			Material = "tripmine_laser",
			Color = Color(255, 255, 255, 255),
			Width = 1,
			Num = n,
			}
		
		local idx = 1
		while (Inputs[idx]) do
		    idx = idx+1
		end
		input.Idx = idx
		
		inputs[v] = input
		Inputs[idx] = input
	end
	
	Wire_SetPathNames(ent, names)

	return inputs
end


function Wire_CreateOutputs(ent, names, desc)
	local outputs = {}
	for n,v in pairs(names) do
		local output = {
			Entity = ent,
			Name = v,
			Value = 0,
			Type = "NORMAL",
			Connected = {},
			TriggerLimit = 8,
			Num = n,
			}
		
		if (desc) and (desc[n]) then
			output.Desc = desc[n]
		end
		
		local idx = 1
		while (Outputs[idx]) do
		    idx = idx+1
		end
		output.Idx = idx
		
		outputs[v] = output
		Outputs[idx] = output
	end

	return outputs
end


function Wire_AdjustInputs(ent, names)
    local inputs = ent.Inputs
	for n,v in pairs(names) do
	    if (inputs[v]) then
			inputs[v].Keep = true
			inputs[v].Num = n
	    else
			local input = {
				Entity = ent,
				Name = v,
				Value = 0,
				Type = "NORMAL",
				Material = "tripmine_laser",
				Color = Color(255, 255, 255, 255),
				Width = 1,
				Keep = true,
				Num = n,
			}

			local idx = 1
			while (Inputs[idx]) do
			    idx = idx+1
			end
			input.Idx = idx

			inputs[v] = input
			Inputs[idx] = input
		end
	end

	for k,v in pairs(inputs) do
	    if (v.Keep) then
	        v.Keep = nil
	    else
	        Wire_Link_Clear(ent, k)

			inputs[k] = nil
	    end
	end

	Wire_SetPathNames(ent, names)
end


function Wire_AdjustOutputs(ent, names, desc)
    local outputs = ent.Outputs
	for n,v in pairs(names) do
	    if (outputs[v]) then
			outputs[v].Keep = true
			outputs[v].Num = n
			if (desc) and (desc[n]) then
				outputs[v].Desc = desc[n]
			end
	    else
			local output = {
				Keep = true,
				Name = v,
				Value = 0,
				Type = "NORMAL",
				Connected = {},
				TriggerLimit = 8,
				Num = n,
			}
			
			if (desc) and (desc[n]) then
				output.Desc = desc[n]
			end
			
			local idx = 1
			while (Outputs[idx]) do
			    idx = idx+1
			end
			output.Idx = idx
			
			outputs[v] = output
			Outputs[idx] = output
		end
	end

	for k,v in pairs(outputs) do
	    if (v.Keep) then
	        v.Keep = nil
	    else
			-- fix by Syranide: unlinks wires of removed outputs
			for i,v in ipairs(outputs[k].Connected) do
				if (v.Entity:IsValid()) then
					Wire_Link_Clear(v.Entity, v.Name)
				end
			end
			outputs[k] = nil
	    end
	end
	
	ent.Outputs = outputs -- Just to be sure
end


-- and array of data types
WireLib.DT = {
	NORMAL = {},	-- Numbers
	VECTOR = {},
	ANGLE = {},
	COLOR = {},
	ENTITY = {},
	STRING = {},
	TABLE = {},
	BIDIRTABLE = {},
	ANY = {},
	HOVERDATAPORT = {},
}
WireLib.DT.NORMAL.Zero			= 0
WireLib.DT.VECTOR.Zero			= Vector(0,0,0)
WireLib.DT.ANGLE.Zero			= Angle(0,0,0)
WireLib.DT.COLOR.Zero			= Color(0,0,0,0)
WireLib.DT.ENTITY.Zero			= NULL
WireLib.DT.STRING.Zero			= ""
WireLib.DT.TABLE.Zero			= {}
WireLib.DT.BIDIRTABLE.Zero		= {}
WireLib.DT.BIDIRTABLE.BiDir		= true
WireLib.DT.ANY.Zero				= 0
WireLib.DT.HOVERDATAPORT.Zero	= 0

function WireLib.CreateSpecialInputs(ent, names, types, desc)
	types = types or {}
	desc = desc or {}
	local inputs = {}
	for n,v in pairs(names) do
		local input = {
			Entity = ent,
			Name = v,
			Desc = desc[n],
			Type = types[n] or "NORMAL",
			Value = WireLib.DT[ (types[n] or "NORMAL") ].Zero,
			Material = "tripmine_laser",
			Color = Color(255, 255, 255, 255),
			Width = 1,
			Num = n,
		}
		
		local idx = 1
		while (Inputs[idx]) do
		    idx = idx+1
		end
		input.Idx = idx
		
		inputs[v] = input
		Inputs[idx] = input
	end
	
	WireLib.SetPathNames(ent, names)

	return inputs
end


function WireLib.CreateSpecialOutputs(ent, names, types, desc)
	types = types or {}
	desc = desc or {}
	local outputs = {}
	for n,v in pairs(names) do
		local output = {
			Entity = ent,
			Name = v,
			Desc = desc[n],
			Type = types[n] or "NORMAL",
			Value = WireLib.DT[ (types[n] or "NORMAL") ].Zero,
			Connected = {},
			TriggerLimit = 8,
			Num = n,
		}
		
		local idx = 1
		while (Outputs[idx]) do
		    idx = idx+1
		end
		output.Idx = idx
		
		outputs[v] = output
		Outputs[idx] = output
	end

	return outputs
end



function WireLib.AdjustSpecialInputs(ent, names, types, desc)
    types = types or {}
	desc = desc or {}
	local inputs = ent.Inputs
	for n,v in pairs(names) do
	    if (inputs[v]) then
			inputs[v].Keep = true
			inputs[v].Num = n
			inputs[v].Desc = desc[n]
			inputs[v].Type = types[n] or "NORMAL"
	    else
			local input = {
				Entity = ent,
				Name = v,
				Desc = desc[n],
				Type = types[n] or "NORMAL",
				Value = WireLib.DT[ (types[n] or "NORMAL") ].Zero,
				Material = "tripmine_laser",
				Color = Color(255, 255, 255, 255),
				Width = 1,
				Keep = true,
				Num = n,
			}
			
			local idx = 1
			while (Inputs[idx]) do
			    idx = idx+1
			end
			input.Idx = idx
			
			inputs[v] = input
			Inputs[idx] = input
		end
	end

	for k,v in pairs(inputs) do
	    if (v.Keep) then
	        v.Keep = nil
	    else
	        Wire_Link_Clear(ent, k)

			inputs[k] = nil
	    end
	end

	WireLib.SetPathNames(ent, names)
	
	return inputs
end


function WireLib.AdjustSpecialOutputs(ent, names, types, desc)
    types = types or {}
	desc = desc or {}
	local outputs = ent.Outputs
	for n,v in pairs(names) do
	    if (outputs[v]) then
			outputs[v].Keep = true
			outputs[v].Num = n			
			outputs[v].Desc = desc[n]
			outputs[v].Type = types[n] or "NORMAL"
	    else
			local output = {
				Keep = true,
				Name = v,
				Desc = desc[n],
				Type = types[n] or "NORMAL",
				Value = WireLib.DT[ (types[n] or "NORMAL") ].Zero,
				Connected = {},
				TriggerLimit = 8,
				Num = n,
			}
			
			local idx = 1
			while (Outputs[idx]) do
			    idx = idx+1
			end
			output.Idx = idx
			
			outputs[v] = output
			Outputs[idx] = output
		end
	end

	for k,v in pairs(outputs) do
	    if (v.Keep) then
	        v.Keep = nil
	    else
			-- fix by Syranide: unlinks wires of removed outputs
			for i,v in ipairs(outputs[k].Connected) do
				if (v.Entity:IsValid()) then
					Wire_Link_Clear(v.Entity, v.Name)
				end
			end
			outputs[k] = nil
	    end
	end
	
	ent.Outputs = outputs -- Just to be sure
	
	return outputs
end


function WireLib.RetypeInputs(ent, iname, itype, desc)
	local inputs = ent.Inputs
	if (!inputs[iname]) or (!itype) then return end
	inputs[iname].Desc = desc
	inputs[iname].Type = itype
	inputs[iname].Value = WireLib.DT[itype].Zero
end


function WireLib.RetypeOutputs(ent, oname, otype, desc)
	local outputs = ent.Outputs
	if (!outputs[oname]) or (!otype) then return end
	outputs[oname].Desc = desc
	outputs[oname].Type = otype
	outputs[oname].Value = WireLib.DT[otype].Zero
end


-- force_outputs is only needed for existing components to allow them to be updated
function Wire_Restored(ent, force_outputs)
    local inputs = ent.Inputs
    if (inputs) then
		for name,input in pairs(inputs) do
			if (not input.Material) then  -- Must be an old save
			    input.Name = name
				
				if (input.Ropes) then
				    for _,rope in pairs(input.Ropes) do
						rope:Remove()
					end
					input.Ropes = nil
				end
			end
			
			input.Entity = ent
			input.Type = input.Type or "NORMAL"
			input.Material = input.Material or "cable/blue_elec"
		    input.Color = input.Color or Color(255, 255, 255, 255)
		    input.Width = input.Width or 2
			input.StartPos = input.StartPos or Vector(0, 0, 0)
			if (input.Src) and (not input.Path) then
			    input.Path = { { Entity = input.Src, Pos = Vector(0, 0, 0) } }
			end
			
			local idx = 1
			while (Inputs[idx]) do
			    idx = idx+1
			end
			input.Idx = idx

			Inputs[idx] = input
		end
	end

    local outputs = ent.Outputs
    if (outputs) then
		for _,output in pairs(outputs) do
			output.Entity = ent
			output.Type = output.Type or "NORMAL"
			
			local idx = 1
			while (Outputs[idx]) do
			    idx = idx+1
			end
			output.Idx = idx

			Outputs[idx] = output
		end
	elseif (force_outputs) then
	    ent.Outputs = Wire_CreateOutputs(ent, force_outputs)
	end
end


function Wire_Remove(ent)
    local inputs = ent.Inputs
    if (inputs) then
		for _,input in pairs(inputs) do
			if (input.Src) and (input.Src:IsValid()) then
			    local output = input.Src.Outputs[input.SrcId]
			    if (output) then
				    for k,v in ipairs(output.Connected) do
				        if (v.Entity == dst) and (v.Name == dstid) then
				            table.remove(output.Connected, k)
				            break
				        end
				    end
				end
			end

			Inputs[input.Idx] = nil
		end
	end

    local outputs = ent.Outputs
    if (outputs) then
		for _,output in pairs(outputs) do
		    for _,v in ipairs(output.Connected) do
		        if (v.Entity:IsValid()) then
		           	v.Entity.Inputs[v.Name].Value = 0

					if (v.Entity.TriggerInput) then
						v.Entity:TriggerInput(dstid, 0)
					end
					-- disable for beamlib
			        Wire_Link_Clear(v.Entity, v.Name)
				end
		    end

			Outputs[output.Idx] = nil
		end
	end
end


local function Wire_Link(dst, dstid, src, srcid, path)
	if (not dst) or (not dst.Inputs) or (not dst.Inputs[dstid]) then
	    Msg("Wire_link: Invalid destination!\n")
		return
	end
	if (not src) or (not src.Outputs) or (not src.Outputs[srcid]) then
	    Msg("Wire_link: Invalid source!\n")
		return
	end

	local input = dst.Inputs[dstid]
	local output = src.Outputs[srcid]

	if (input.Src) and (input.Src:IsValid()) then
	    if (input.Src.Outputs) then
		    local oldOutput = input.Src.Outputs[input.SrcId]
		    if (oldOutput) then
			    for k,v in ipairs(oldOutput.Connected) do
			        if (v.Entity == dst) and (v.Name == dstid) then
			            table.remove(oldOutput.Connected, k)
			        end
			    end
			end
		end
	end

	input.Src = src
	input.SrcId = srcid
	input.Path = path
	
	table.insert(output.Connected, { Entity = dst, Name = dstid })
	
	if dst.OnInputWireLink then
		-- ENT:OnInputWireLink(iName, iType, oEnt, oName, oType)
		dst:OnInputWireLink(dstid, input.Type, src, srcid, output.Type)
	end
	
	if src.OnOutputWireLink then
		-- ENT:OnOutputWireLink(oName, oType, iEnt, iName, iType)
		src:OnOutputWireLink(srcid, output.Type, dst, dstid, input.Type)
	end
	
	dst.Inputs[dstid].Value = output.Value
	if (dst.TriggerInput) then
		dst:TriggerInput(dstid, output.Value)
	end
end


function Wire_TriggerOutput(ent, oname, value, iter)
	if (not ent) or (not ent:IsValid()) or (not ent.Outputs) or (not ent.Outputs[oname]) then return end

    local output = ent.Outputs[oname]
    if (output) and (value ~= output.Value) then
        if (output.TriggerLimit <= 0) then return end
        output.TriggerLimit = output.TriggerLimit - 1
        
		output.Value = value

		if (iter) then
	        for _,dst in ipairs(output.Connected) do
	            if (dst.Entity:IsValid()) then
	                iter:Add(dst.Entity, dst.Name, value)
	            end
			end
			return
		end

		iter = Wire_CreateOutputIterator()

        for _,dst in ipairs(output.Connected) do
            if (dst.Entity:IsValid()) then
                local input = dst.Entity.Inputs[dst.Name]
                
            	input.Value = value
	            if (dst.Entity.TriggerInput) then
	        		dst.Entity:TriggerInput(dst.Name, value, iter)
				end
			end
        end
        
        iter:Process()
    end
end
	
local function Wire_Unlink(ent, iname)
	local input = ent.Inputs[iname]
	if (input) then
		if (input.Src) and (input.Src:IsValid()) then
		    local output = input.Src.Outputs[input.SrcId]
		    if (output) then
			    for k,v in ipairs(output.Connected) do
			        if (v.Entity == ent) and (v.Name == iname) then
			            table.remove(output.Connected, k)
			        end
			    end
				-- untested
				if input.Src.OnOutputWireLink then
					-- ENT:OnOutputWireLink(oName, oType, iEnt, iName, iType)
					input.Src:OnOutputWireLink(input.SrcId, input.Src.Outputs[input.SrcId].Type, ent, iname, input.Type)
				end
			end
			-- untested
			if ent.OnInputWireUnlink then
				-- ENT:OnInputWireUnlink(iName, iType, oEnt, oName, oType)
				ent:OnInputWireUnlink(iname, input.Type, input.Src, input.SrcId, input.Src.Outputs[input.SrcId].Type)
			end
		end

	    input.Value = 0
		if (ent.TriggerInput) then
			ent:TriggerInput(iname, WireLib.DT[input.Type].Zero)
		end

	    input.Src = nil
		input.SrcId = nil
	end
end

function Wire_Link_Start(idx, ent, pos, iname, material, color, width)
    if (not ent) or (not ent:IsValid()) or (not ent.Inputs) or (not ent.Inputs[iname]) then return end

	local input = ent.Inputs[iname]

	CurLink[idx] = {
		Dst = ent,
		DstId = iname,
		Path = {},
		OldPath = input.Path,
		}
	
	CurLink[idx].OldPath				= CurLink[idx].OldPath or {}
	CurLink[idx].OldPath[0]				= {}
	CurLink[idx].OldPath[0].pos			= input.StartPos
	CurLink[idx].OldPath[0].material	= input.Material
	CurLink[idx].OldPath[0].color		= input.Color
	CurLink[idx].OldPath[0].width		= input.Width
	
	local net_name = "wp_" .. iname
	ent:SetNetworkedBeamInt(net_name, 0)
	ent:SetNetworkedBeamVector(net_name .. "_start", pos)
	ent:SetNetworkedBeamString(net_name .. "_mat", material)
	ent:SetNetworkedBeamVector(net_name .. "_col", Vector(color.r, color.g, color.b))
	ent:SetNetworkedBeamFloat(net_name .. "_width", width)
	
	--RDbeamlib.StartWireBeam( ent, iname, pos, material, color, width )
	
	input.StartPos = pos
	input.Material = material
	input.Color = color
	input.Width = width

	return true
end


function Wire_Link_Node(idx, ent, pos)
    if (not CurLink[idx]) or (not CurLink[idx].Dst) then return end
	if (!ent:IsValid()) then return end -- its the world, give up
	
	local net_name = "wp_" .. CurLink[idx].DstId
	local node_idx = CurLink[idx].Dst:GetNetworkedBeamInt(net_name)+1
	CurLink[idx].Dst:SetNetworkedBeamEntity(net_name .. "_" .. node_idx .. "_ent", ent)
	CurLink[idx].Dst:SetNetworkedBeamVector(net_name .. "_" .. node_idx .. "_pos", pos)
	CurLink[idx].Dst:SetNetworkedBeamInt(net_name, node_idx)
	
	--RDbeamlib.AddWireBeamNode( CurLink[idx].Dst, CurLink[idx].DstId, ent, pos )
	
	table.insert(CurLink[idx].Path, { Entity = ent, Pos = pos })
end


function Wire_Link_End(idx, ent, pos, oname, pl)
    if (not CurLink[idx]) or (not CurLink[idx].Dst) or (not ent.Outputs) then return end
	
	if (CurLink[idx].Dst:GetClass() == "gmod_wire_sensor") and (ent:GetClass() != "gmod_wire_target_finder") then
		Msg("Wire_link: Beacon Sensor can only be wired to a Target Finder!\n")
		if pl then
			pl:SendLua( "GAMEMODE:AddNotify('Beacon Sensor can only be wired to a Target Finder!', NOTIFY_GENERIC, 7);" )
		end
		Wire_Link_Cancel(idx)
		return
	end
	
	local input = CurLink[idx].Dst.Inputs[CurLink[idx].DstId]
	local output = ent.Outputs[oname] or {}
	--Msg("input type= " .. input.Type .. "  output type= " .. (output.Type or "NIL") .. "\n")	-- I bet that was getting anoying (TAD2020)
	output.Type = output.Type or "NORMAL"
	if (input.Type != output.Type) and (input.Type != "ANY") and (output.Type != "ANY") then
		local txt = "Data Type Mismatch! Input takes "..input.Type.." and Output gives "..output.Type
		Msg(txt.."\n")
		if pl then
			pl:SendLua( "GAMEMODE:AddNotify('"..txt.."', NOTIFY_GENERIC, 7);" )
		end
		Wire_Link_Cancel(idx)
		return
	end
	
	local net_name = "wp_" .. CurLink[idx].DstId
	local node_idx = CurLink[idx].Dst:GetNetworkedBeamInt(net_name)+1
	CurLink[idx].Dst:SetNetworkedBeamEntity(net_name .. "_" .. node_idx .. "_ent", ent)
	CurLink[idx].Dst:SetNetworkedBeamVector(net_name .. "_" .. node_idx .. "_pos", pos)
	CurLink[idx].Dst:SetNetworkedBeamInt(net_name, node_idx)
	
	--RDbeamlib.AddWireBeamNode( CurLink[idx].Dst, CurLink[idx].DstId, ent, pos )
	
	table.insert(CurLink[idx].Path, { Entity = ent, Pos = pos })

	Wire_Link(CurLink[idx].Dst, CurLink[idx].DstId, ent, oname, CurLink[idx].Path)
	
	if (WireLib.DT[input.Type].BiDir) then
		Wire_Link(ent, oname, CurLink[idx].Dst, CurLink[idx].DstId, {})
	end
	
	CurLink[idx] = nil
end


function Wire_Link_Cancel(idx)
    if (not CurLink[idx]) or (not CurLink[idx].Dst) then return end
	
	--local orig = CurLink[idx].OldPath[0]
	--RDbeamlib.StartWireBeam( CurLink[idx].Dst, CurLink[idx].DstId, orig.pos, orig.material, orig.color, orig.width )
	
	local path_len = 0
	if (CurLink[idx].OldPath) then path_len = table.getn(CurLink[idx].OldPath) end
	
	local net_name = "wp_" .. CurLink[idx].DstId
	for i=1,path_len do
		CurLink[idx].Dst:SetNetworkedBeamEntity(net_name .. "_" .. i, CurLink[idx].OldPath[i].Entity)
		CurLink[idx].Dst:SetNetworkedBeamVector(net_name .. "_" .. i, CurLink[idx].OldPath[i].Pos)
		--RDbeamlib.AddWireBeamNode( CurLink[idx].Dst, CurLink[idx].DstId, CurLink[idx].OldPath[i].Entity, CurLink[idx].OldPath[i].Pos )
	end
	CurLink[idx].Dst:SetNetworkedBeamInt(net_name, path_len)
	
	CurLink[idx] = nil
end


function Wire_Link_Clear(ent, iname)
	local net_name = "wp_" .. iname
	ent:SetNetworkedBeamInt(net_name, 0)
	--RDbeamlib.ClearWireBeam( ent, iname )
	
	Wire_Unlink(ent, iname)
end

function Wire_SetPathNames(ent, names)
	for k,v in pairs(names) do
		ent:SetNetworkedBeamString("wpn_" .. k, v)
	end
	ent:SetNetworkedBeamInt("wpn_count", table.getn(names))
end


function Wire_CreateOutputIterator()
	local iter = {
		Queue = {}
	}
	
	function iter:Add(ent, iname, value)
		table.insert(self.Queue, { Entity = ent, IName = iname, Value = value })
	end
	
	function iter:Process()
	    if (self.Processing) then return end
	    self.Processing = true
	    
	    while (table.getn(self.Queue) > 0) do
	        local next = self.Queue[1]
	        table.remove(self.Queue, 1)
	        
	        next.Entity.Inputs[next.IName].Value = next.Value
	        if (next.Entity.TriggerInput) then
				next.Entity:TriggerInput(next.IName, next.Value, self)
			end
	    end
	    
	    self.Processing = nil
	end
	
	return iter
end


function Wire_AfterPasteMods(ply, Ent, DupeInfo)
	-- this does nothing for now, we need the blank function to get the duplicator to copy the WireDupeInfo into the pasted ent
end
duplicator.RegisterEntityModifier( "WireDupeInfo", Wire_AfterPasteMods )


-- used for welding wired stuff, if trace is worl, the ent is not welded and is froze instead
function WireLib.Weld(ent, traceEntity, tracePhysicsBone, DOR, collision, AllowWorldWeld)
	if (!ent or !traceEntity or traceEntity:IsNPC() or traceEntity:IsPlayer()) then return end
	local const
	if ( traceEntity:IsValid() ) or ( traceEntity:IsWorld() and AllowWorldWeld ) then
		const = constraint.Weld( ent, traceEntity, 0, tracePhysicsBone, 0, (not collision), DOR )
		-- Don't disable collision if it's not attached to anything
		if (!collision) then
			ent:GetPhysicsObject():EnableCollisions( false )
			ent.nocollide = true
		end
	else
		ent:GetPhysicsObject():EnableMotion( false )
	end
	return const
end


function WireLib.BuildDupeInfo( Ent )
	if (not Ent.Inputs) then return end
	
	local info = { Wires = {} }
	for k,input in pairs(Ent.Inputs) do
		if (input.Src) and (input.Src:IsValid()) then
		    info.Wires[k] = {
				StartPos = input.StartPos,
				Material = input.Material,
				Color = input.Color,
				Width = input.Width,
				Src = input.Src:EntIndex(),
				SrcId = input.SrcId,
				SrcPos = Vector(0, 0, 0),
			}
			
			if (input.Path) then
				info.Wires[k].Path = {}
				
			    for _,v in ipairs(input.Path) do
			        if (v.Entity) and (v.Entity:IsValid()) then
			        	table.insert(info.Wires[k].Path, { Entity = v.Entity:EntIndex(), Pos = v.Pos })
					end
			    end
			    
			    local n = table.getn(info.Wires[k].Path)
			    if (n > 0) and (info.Wires[k].Path[n].Entity == info.Wires[k].Src) then
			        info.Wires[k].SrcPos = info.Wires[k].Path[n].Pos
			        table.remove(info.Wires[k].Path, n)
			    end
			end
		end
	end
	
	return info
end

function WireLib.ApplyDupeInfo( ply, ent, info, GetEntByID )
	if (info.Wires) then
		for k,input in pairs(info.Wires) do
		    
			Wire_Link_Start(ply:UniqueID(), ent, input.StartPos, k, input.Material, input.Color, input.Width)
		    
			if (input.Path) then
				for _,v in ipairs(input.Path) do
					
					local ent2 = GetEntByID(v.Entity)
					if (!ent2) or (!ent2:IsValid()) then
						local EntityList = GetEntByID("EntityList")
						if (!EntityList) or (!EntityList[v.Entity]) then
							ent2 = ents.GetByIndex(v.Entity)
						end
					end
					if (ent2) or (ent2:IsValid()) then
						Wire_Link_Node(ply:UniqueID(), ent2, v.Pos)
					else
						Msg("ApplyDupeInfo: Error, Could not find the entity for wire path\n")
					end
				end
			end
			
			local ent2 = GetEntByID(input.Src)
			if (!ent2) or (!ent2:IsValid()) then
				local EntityList = GetEntByID("EntityList")
				if (!EntityList) or (!EntityList[input.Src]) then
					ent2 = ents.GetByIndex(input.Src)
				end
			end
			if (ent2) or (ent2:IsValid()) then
				Wire_Link_End(ply:UniqueID(), ent2, input.SrcPos, input.SrcId)
			else
				Msg("ApplyDupeInfo: Error, Could not find the output entity\n")
			end
		end
	end
end



WireLib.CreateInputs			= Wire_CreateInputs
WireLib.CreateOutputs			= Wire_CreateOutputs
WireLib.AdjustInputs			= Wire_AdjustInputs
WireLib.AdjustOutputs			= Wire_AdjustOutputs
WireLib.Restored				= Wire_Restored
WireLib.Remove					= Wire_Remove
WireLib.TriggerOutput			= Wire_TriggerOutput
WireLib.Link_Start				= Wire_Link_Start
WireLib.Link_Node				= Wire_Link_Node
WireLib.Link_End				= Wire_Link_End
WireLib.Link_Cancel				= Wire_Link_Cancel
WireLib.Link_Clear				= Wire_Link_Clear
WireLib.SetPathNames			= Wire_SetPathNames
WireLib.CreateOutputIterator	= Wire_CreateOutputIterator
WireLib.AfterPasteMods			= Wire_AfterPasteMods
Wire_BuildDupeInfo				= WireLib.BuildDupeInfo
Wire_ApplyDupeInfo				= WireLib.ApplyDupeInfo

--backwards logic: set enable to false to show show values on gates instead
Wire_EnableGateInputValues = true
local function WireEnableInputValues(pl, cmd, args)
	if ( args[1] ) and ( ( pl:IsAdmin() ) or ( pl:IsSuperAdmin( )() ) ) then
		if args[1] == "1" or args[1] == 1 then 
			Wire_EnableGateInputValues = true
		elseif args[1] == "0" or args[1] == 0 then
			Wire_EnableGateInputValues = false
		else
			pl:PrintMessage(HUD_PRINTCONSOLE, "Only takes 0 or 1")
		end
	end
	pl:PrintMessage(HUD_PRINTCONSOLE, "\nWire_EnableGateInputValues = "..tostring(Wire_EnableGateInputValues).."\n")
end
concommand.Add( "Wire_EnableGateInputValues", WireEnableInputValues )

Wire_FastOverlayTextUpdate = false
local function WireFastOverlayTextUpdate(pl, cmd, args)
	if ( args[1] ) and ( ( pl:IsAdmin() ) or ( pl:IsSuperAdmin( )() ) ) then
		if args[1] == "1" or args[1] == 1 then 
			Wire_FastOverlayTextUpdate = true
		elseif args[1] == "0" or args[1] == 0 then
			Wire_FastOverlayTextUpdate = false
		else
			pl:PrintMessage(HUD_PRINTCONSOLE, "Only takes 0 or 1")
		end
	end
	pl:PrintMessage(HUD_PRINTCONSOLE, "\nWire_FastOverlayTextUpdate = "..tostring(Wire_FastOverlayTextUpdate).."\n")
end
concommand.Add( "Wire_FastOverlayTextUpdate", WireFastOverlayTextUpdate )

Wire_SlowerOverlayTextUpdate = false
local function WireSlowerOverlayTextUpdate(pl, cmd, args)
	if ( args[1] ) and ( ( pl:IsAdmin() ) or ( pl:IsSuperAdmin( )() ) ) then
		if args[1] == "1" or args[1] == 1 then 
			Wire_SlowerOverlayTextUpdate = true
		elseif args[1] == "0" or args[1] == 0 then
			Wire_SlowerOverlayTextUpdate = false
		else
			pl:PrintMessage(HUD_PRINTCONSOLE, "Only takes 0 or 1")
		end
	end
	pl:PrintMessage(HUD_PRINTCONSOLE, "\nWire_SlowerOverlayTextUpdate = "..tostring(Wire_SlowerOverlayTextUpdate).."\n")
end
concommand.Add( "Wire_SlowerOverlayTextUpdate", WireSlowerOverlayTextUpdate )

Wire_DisableOverlayTextUpdate = false
local function WireDisableOverlayTextUpdate(pl, cmd, args)
	if ( args[1] ) and ( ( pl:IsAdmin() ) or ( pl:IsSuperAdmin( )() ) ) then
		if args[1] == "1" or args[1] == 1 then 
			Wire_DisableOverlayTextUpdate = true
		elseif args[1] == "0" or args[1] == 0 then
			Wire_DisableOverlayTextUpdate = false
		else
			pl:PrintMessage(HUD_PRINTCONSOLE, "Only takes 0 or 1")
		end
	end
	pl:PrintMessage(HUD_PRINTCONSOLE, "\nWire_DisableOverlayTextUpdate = "..tostring(Wire_DisableOverlayTextUpdate).."\n")
end
concommand.Add( "Wire_DisableOverlayTextUpdate", WireDisableOverlayTextUpdate )

Wire_ForceDelayOverlayTextUpdate = false
local function WireForceDelayOverlayTextUpdate(pl, cmd, args)
	if ( args[1] ) and ( ( pl:IsAdmin() ) or ( pl:IsSuperAdmin( )() ) ) then
		if args[1] == "1" or args[1] == 1 then 
			Wire_ForceDelayOverlayTextUpdate = true
		elseif args[1] == "0" or args[1] == 0 then
			Wire_ForceDelayOverlayTextUpdate = false
		else
			pl:PrintMessage(HUD_PRINTCONSOLE, "Only takes 0 or 1")
		end
	end
	pl:PrintMessage(HUD_PRINTCONSOLE, "\nWire_ForceDelayOverlayTextUpdate = "..tostring(Wire_ForceDelayOverlayTextUpdate).."\n")
end
concommand.Add( "Wire_ForceDelayOverlayTextUpdate", WireForceDelayOverlayTextUpdate )


--[[Wire_UseOldGateOutputLables = false
local function WireUseOldGateOutputLables(pl, cmd, args)
	if ( args[1] ) and ( ( pl:IsAdmin() ) or ( pl:IsSuperAdmin( )() ) ) then
		if args[1] == "1" or args[1] == 1 then 
			Wire_UseOldGateOutputLables = true
		elseif args[1] == "0" or args[1] == 0 then
			Wire_UseOldGateOutputLables = false
		else
			pl:PrintMessage(HUD_PRINTCONSOLE, "Only takes 0 or 1")
		end
	end
	pl:PrintMessage(HUD_PRINTCONSOLE, "\nWire_UseOldGateOutputLables = "..tostring(Wire_UseOldGateOutputLables).."\n")
end
concommand.Add( "Wire_UseOldGateOutputLables", WireUseOldGateOutputLables )]]


local function PrintWireVersion(pl,cmd,args)
	if (WireVersion) then
		pl:SendLua("Msg(\"===============================\n===  Wire  "..WireVersion.."   Installed  ===\n===============================\n\")")
	end
end
concommand.Add( "Wire_PrintVersion", PrintWireVersion )

if (WireVersion) then
	Msg("===============================\n===  Wire  "..WireVersion.."   Installed  ===\n===============================\n")
end


-- add wiresvn tag

-- add wiresvn_rev tag (doesn't work like it should)
--RunConsoleCommand("sv_tags", (GetConVarString("sv_tags") or "")..",wiresvn"..WireVersion)

-- this still doesn't quiet work like it looks like it should, must be some issues with setting sv_tags (long tags, similar tags might be ignored/removed while duplicates might get though)
local tags = string.Explode(",",(GetConVarString("sv_tags") or ""))
for i,tag in ipairs(tags) do
	if tag:find("wiresvn") then table.remove(tags,i) end
end
table.insert(tags, "wiresvn")
table.sort(tags)
RunConsoleCommand("sv_tags", table.concat(tags, ","))
