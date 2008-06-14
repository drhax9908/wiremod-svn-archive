local TextReceivers = {}
local securetext = nil
local returntext = false

function Add_TextReceiver( r )
	table.insert( TextReceivers, r )
end

function TextReceiver_Received(pl,text,toall)
	securetext = nil
	for i, o in ipairs( TextReceivers ) do
	    if (not IsEntity(o.Entity)) then
	        table.remove(TextReceivers, i)
	    else
			local temptext = o:TextReceived(pl,text)
			if (securetext == nil && temptext != nil) then
				securetext = temptext
			end
		end
	end
	if (securetext != nil) then return securetext end
end

hook.Add("PlayerSay","TextReceiverSay",TextReceiver_Received)
