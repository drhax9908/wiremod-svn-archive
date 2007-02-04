
-- phenex: Start radio mod.
local radio_channels = {}
local radio_sets = {}

function Radio_Register( o )
	table.insert( radio_sets, o )
end

function Radio_Transmit( ch, v )
	radio_channels[ch] = v

	for i, o in ipairs( radio_sets ) do
	    if (not o.Entity:IsValid()) then
	        table.remove(radio_sets, i)
	    elseif (o.Channel == ch) then
			o:ReceiveRadio(v)
		end
	end
end

function Radio_Receive( ch )
	return radio_channels[ch] or 0
end

local radio_twowaycounter = 0

function Radio_GetTwoWayID()
	radio_twowaycounter = radio_twowaycounter + 1
	return radio_twowaycounter
end

-- phenex: End radio mod.
