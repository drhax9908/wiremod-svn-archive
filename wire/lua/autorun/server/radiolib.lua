
-- phenex: Start radio mod.
local radio_channels = {}
local radio_sets = {}

function Radio_Register( o )
	table.insert( radio_sets, o )
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

function Radio_Receive(ent ,ch )
	if (ent.Secure == true) then
		if (radio_channels[ent.pl:SteamID()] == nil) then return {} end
		if (type(radio_channels[ent.pl:SteamID()][ch]) == "table") then
			return radio_channels[ent.pl:SteamID()][ch] //Nothing fancy needed :P
		end
	else
		if (type(radio_channels[ch]) == "table") then
			return radio_channels[ch] //Nothing fancy needed :P
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