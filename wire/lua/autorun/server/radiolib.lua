
-- phenex: Start radio mod.
local radio_channels = {}
local radio_sets = {}
local radio_num = {}

function Radio_Register( o )
	table.insert( radio_sets, o )
end

function Radio_TuneIn(ent,ch)
	if (ent.Secure == true) then
		if (radio_channels[ent.pl:SteamID()] == nil) then
			radio_num[ent.pl:SteamID()] = {}
		end
		radio_num[ent.pl:SteamID()][ch] = (radio_num[ent.pl:SteamID()][ch] or 0) + 1
	else
		radio_num[ch] = (radio_num[ch] or 0) + 1
	end
end

function Radio_TuneOut(ent,ch)
	if (ent.Secure == true) then
		if (radio_channels[ent.pl:SteamID()] == nil) then
			radio_channels[ent.pl:SteamID()] = {}
		end
		radio_num[ent.pl:SteamID()][ch] = (radio_num[ent.pl:SteamID()][ch] or 0) - 1
		if ((radio_num[ent.pl:SteamID()][ch] or 0) == 0) then
			radio_channels[ent.pl:SteamID()][ch] = {}
		end
	else
		radio_num[ch] = (radio_num[ch] or 1) - 1
		if (radio_num[ch] == 0) then
//			Msg("  Clear radio channels "..ch.."\n")
			radio_channels[ch] = {}
		end
	end

	for i, o in ipairs( radio_sets ) do
	    if (not IsEntity(o.Entity)) then
	        table.remove(radio_sets, i)
	    elseif (o.Channel == ch && o.Entity:EntIndex() != ent:EntIndex()) then
		if (radio_channels[ch] == null) then
			radio_channels[ch] = {}
		end

		local retable  = radio_channels[ch]
		for i=1,20 do if (!radio_channels[ch][tostring(i)]) then retable[tostring(i)] = 0 end end

//		Msg("Tune out: notifying a radio on channel "..ch.."\n")

		o:ReceiveRadio(retable)
	    end
	end
end

function Radio_Transmit(ent,ch,k,v)
	if (ent.Secure == true) then
		if (radio_channels[ent.pl:SteamID()] == nil) then radio_channels[ent.pl:SteamID()]  = {} end
		if (radio_channels[ent.pl:SteamID()][ch] == nil) then radio_channels[ent.pl:SteamID()][ch] = {} end
		radio_channels[ent.pl:SteamID()][ch][k] = v
	else
		if (radio_channels[ch] == nil) then radio_channels[ch] = {} end
		radio_channels[ch][k] = v
	end

	for i, o in ipairs( radio_sets ) do
	    if (not IsEntity(o.Entity)) then
	        table.remove(radio_sets, i)
	    elseif (o.Channel == ch && o.Entity:EntIndex() != ent:EntIndex()) then
			if (o.Secure == true && ent.Secure == true) then
				if (o.pl:EntIndex() == ent.pl:EntIndex()) then
					o:SReceiveRadio(k,v)
				end
			elseif (o.Secure == false && ent.Secure == false) then
				o:SReceiveRadio(k,v)
			end
		end
	end
end

function Radio_ChannelOccupied(ent,ch)
	if (ent.Secure == true) then
		if (radio_channels[ent.pl:SteamID()] == nil) then
			radio_num[ent.pl:SteamID()] = {}
		end
		if ((radio_num[ent.pl:SteamID()][ch] or 0) ~= 0) then
			return true
		end
	else
//		print("is occupied "..ch.." = "..radio_num[ch] or 0)
		if ((radio_num[ch] or 0) ~= 0) then
			return true
		end
	end
	return false
end

function Radio_Receive(ent, ch)
	if (ent.Secure == true) then
		if (radio_channels[ent.pl:SteamID()] == nil) then return {} end
		if (type(radio_channels[ent.pl:SteamID()][ch]) == "table") then
			local retable = radio_channels[ent.pl:SteamID()][ch]
			for i=1,20 do if (!radio_channels[ent.pl:SteamID()][ch][tostring(i)]) then retable[tostring(i)] = 0 end end
			return retable //Nothing fancy needed :P
		else
			local retable = {}
			for i=1,20 do retable[tostring(i)] = 0 end			
			return retable
		end
	else
		if (type(radio_channels[ch]) == "table") then
			local retable = radio_channels[ch]
			for i=1,20 do if (!radio_channels[ch][tostring(i)]) then retable[tostring(i)] = 0 end end

			return retable //Nothing fancy needed :P
		else
			local retable = {}
			for i=1,20 do retable[tostring(i)] = 0 end			
			return retable
		end
	end
	return {}
end

local radio_twowaycounter = 0

function Radio_GetTwoWayID()
	radio_twowaycounter = radio_twowaycounter + 1
	return radio_twowaycounter
end

-- phenex: End radio mod.
//Modified by High6 (To support 4 values)
//Rebuilt by high6 to allow defined amount of values/secure lines