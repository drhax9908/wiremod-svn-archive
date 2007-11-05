
-- phenex: Start radio mod.
local radio_channels = {}
local radio_sets = {}

function Radio_Register( o )
	table.insert( radio_sets, o )
end

function Radio_Transmit( ch, A,B,C,D )
	radio_channels[ch] = {}
	radio_channels[ch]['A'] = A
	radio_channels[ch]['B'] = B
	radio_channels[ch]['C'] = C
	radio_channels[ch]['D'] = D

	for i, o in ipairs( radio_sets ) do
	    if (not IsEntity(o.Entity)) then
	        table.remove(radio_sets, i)
	    elseif (o.Channel == ch) then
			o:ReceiveRadio(A,B,C,D)
		end
	end
end

function Radio_Receive( ch )
	if (type(radio_channels[ch]) == "table") then
		return radio_channels[ch]['A'] or 0,radio_channels[ch]['B'] or 0,radio_channels[ch]['C'] or 0, radio_channels[ch]['D'] or 0
	end
	return 0,0,0,0
end

local radio_twowaycounter = 0

function Radio_GetTwoWayID()
	radio_twowaycounter = radio_twowaycounter + 1
	return radio_twowaycounter
end

-- phenex: End radio mod.
//Modified by High6 (To support 4 values)