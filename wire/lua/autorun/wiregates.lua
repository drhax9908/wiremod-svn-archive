AddCSLuaFile( "autorun/wiregates.lua" )

//***********************************************************
//		Gate Action Functions Module
//			define all gate actions here
//	TODO: loader function to grab external gate action defines
//***********************************************************
GateActions = {}




//***********************************************************
//		Arithmetic Gates
//***********************************************************
GateActions["increment"] = {
	group = "Arithmetic",
	name = "Increment",
	inputs = { "A", "Clk" },
	output = function(gate, A, Clk)
		local clk = ( Clk > 0 )
		if ( gate.PrevValue ~=  clk ) then
			gate.PrevValue = clk
			if ( clk ) then
				if ( gate.Memory == nil ) then
					gate.Memory = A
				else
					gate.Memory = gate.Memory + 1
				end
			end
		end
		return gate.Memory
	end,
	label = function(Out, A)
		return "(" .. A .. " + LastNum)++ = " .. Out
	end
}

GateActions["identity"] = {
	group = "Arithmetic",
	name = "Identity (No change)",
	inputs = { "A" },
	output = function(gate, A)
	    return A
	end,
	label = function(Out, A)
	    return A.." = "..Out
	end
}

GateActions["negate"] = {
	group = "Arithmetic",
	name = "Negate",
	inputs = { "A" },
	output = function(gate, A)
	    return -A
	end,
	label = function(Out, A)
	    return "-"..A.." = "..Out
	end
}

GateActions["inverse"] = {
	group = "Arithmetic",
	name = "Inverse",
	inputs = { "A" },
	output = function(gate, A)
		if (A) and (math.abs(A) >= 0.0001) then return 1/A end
	    return 0
	end,
	label = function(Out, A)
	    return "1/"..A.." = "..Out
	end
}

GateActions["sqrt"] = {
	group = "Arithmetic",
	name = "Square Root",
	inputs = { "A" },
	output = function(gate, A)
	    return math.sqrt(math.abs(A)) // Negatives are possible, use absolute value
	end,
	label = function(Out, A)
		/*if ( A < 0 ) then
			return "sqrt("..A..") = i"..Out // Display as imaginary if A is negative
		else*/
			return "sqrt("..A..") = "..Out
		//end
	end
}

GateActions["log"] = {
	group = "Arithmetic",
	name = "Log",
	inputs = { "A" },
	output = function(gate, A)
	    return math.log(A)
	end,
	label = function(Out, A)
	    return "log("..A..") = "..Out
	end
}

GateActions["log10"] = {
	group = "Arithmetic",
	name = "Log 10",
	inputs = { "A" },
	output = function(gate, A)
	    return math.log10(A)
	end,
	label = function(Out, A)
	    return "log10("..A..") = "..Out
	end
}

GateActions["abs"] = {
	group = "Arithmetic",
	name = "Absolute",
	inputs = { "A" },
	output = function(gate, A)
	    return math.abs(A)
	end,
	label = function(Out, A)
	    return "abs("..A..") = "..Out
	end
}

GateActions["sgn"] = {
	group = "Arithmetic",
	name = "Sign (-1,0,1)",
	inputs = { "A" },
	output = function(gate, A)
	    if (A > 0) then return 1 end
	    if (A < 0) then return -1 end
	    return 0
	end,
	label = function(Out, A)
	    return "sgn("..A..") = "..Out
	end
}

GateActions["floor"] = {
	group = "Arithmetic",
	name = "Floor (Round down)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.floor(A)
	end,
	label = function(Out, A)
	    return "floor("..A..") = "..Out
	end
}

GateActions["round"] = {
	group = "Arithmetic",
	name = "Round",
	inputs = { "A" },
	output = function(gate, A)
	    return math.Round(A)
	end,
	label = function(Out, A)
	    return "round("..A..") = "..Out
	end
}

GateActions["ceil"] = {
	group = "Arithmetic",
	name = "Ceiling (Round up)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.ceil(A)
	end,
	label = function(Out, A)
	    return "ceil("..A..") = "..Out
	end
}

GateActions["+"] = {
	group = "Arithmetic",
	name = "Add",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
	    local result = 0
	    for k,v in ipairs(arg) do
		    if (v) then result = result+v end
		end
	    return result
	end,
	label = function(Out, ...)
	    local txt = ""
	    for k,v in ipairs(arg) do
		    if (v) then txt = txt..v.." + " end
		end
	    return string.sub(txt, 1, -4).." = "..Out
	end
}

GateActions["-"] = {
	group = "Arithmetic",
	name = "Subtract",
	inputs = { "A", "B" },
	colors = { Color(255, 0, 0, 255), Color(0, 0, 255, 255) },
	output = function(gate, A, B)
	    return A-B
	end,
	label = function(Out, A, B)
	    return A.." - "..B.." = "..Out
	end
}

GateActions["*"] = {
	group = "Arithmetic",
	name = "Multiply",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
	    local result = 1
	    for k,v in ipairs(arg) do
		    if (v) then result = result*v end
		end
	    return result
	end,
	label = function(Out, ...)
	    local txt = ""
	    for k,v in ipairs(arg) do
		    if (v) then txt = txt..v.." * " end
		end
	    return string.sub(txt, 1, -4).." = "..Out
	end
}

GateActions["/"] = {
	group = "Arithmetic",
	name = "Divide",
	inputs = { "A", "B" },
	output = function(gate, A, B)
	    if (math.abs(B) < 0.0001) then return 0 end
	    return A/B
	end,
	label = function(Out, A, B)
	    return A.." / "..B.." = "..Out
	end
}

GateActions["%"] = {
	group = "Arithmetic",
	name = "Modulus",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		if ( B == 0 ) then return 0 end
		return math.fmod(A,B)
	end,
	label = function(Out, A, B)
		return A.." % "..B.." = "..Out
	end
}

GateActions["rand"] = {
	group = "Arithmetic",
	name = "Random",
	inputs = { "A", "B" },
	timed = true,
	output = function(gate, A, B)
	    return math.random()*(B-A)+A
	end,
	label = function(Out, A, B)
	    return "random("..A.." - "..B..") = "..Out
	end
}

GateActions["PI"] = {
	group = "Arithmetic",
	name = "PI",
	inputs = { },
	output = function(gate)
		return math.pi
	end,
	label = function(Out)
		return "PI = "..Out
	end
}

GateActions["exp"] = {
	group = "Arithmetic",
	name = "Exp",
	inputs = { "A" },
	output = function(gate, A)
	    return math.exp(A)
	end,
	label = function(Out, A)
	    return "exp("..A..") = "..Out
	end
}

GateActions["pow"] = {
    group = "Arithmetic",
    name = "Exponential Powers",
    inputs = { "A", "B" },
    output = function(gate, A, B)
        return math.pow(A, B)
    end,
    label = function(Out, A, B)
        return "pow("..A..", "..B..") = "..Out
    end
}

GateActions["and/add"] = {
	group = "Arithmetic",
	name = "And/Add",
	inputs = { "A", "B"},
	output = function(gate, A, B)
		if ((A) and (A <= 0)) or ((B) and (B <= 0)) then return 0 end
		return A+B
	end,
	label = function(Out, A, B)
		return A.." and/and "..B.." = "..Out
	end
}

GateActions["Percent"] = {
	group = "Arithmetic",
	name = "Percent",
	inputs = { "Value", "Max" },
	compact_inputs = 2,
	output = function(gate, Value, Max)
		if (math.abs(Max) < 0.0001) then return 0 end
	    return Value / Max * 100
	end,
	label = function(Out, Value, Max)
	    return Value.." / "..Max.." * 100 = "..Out.."%"
	end
}

GateActions["Delta"] = {
    group = "Arithmetic",
    name = "Delta",
    inputs = { "A" },
    output = function(gate, A)
        gate.PrevValue = gate.PrevValue or 0
        local delta = A - gate.PrevValue
        gate.PrevValue = A
        return delta
    end,
    reset = function(gate)
        gate.PrevValue = 0
    end,
    label = function(Out, A)
        return "Delta("..A..") "
    end
} 

GateActions["Delta360"] = {
    group = "Arithmetic",
    name = "Delta (Rectified)",
    inputs = { "A" },
    output = function(gate, A)
        gate.PrevValue = gate.PrevValue or 0
        local delta = A - gate.PrevValue
        gate.PrevValue = A
        return ( math.fmod( (math.fmod( delta, 360 ) + 540 ), 360 ) - 180 )
    end,
    reset = function(gate)
        gate.PrevValue = 0
    end,
    label = function(Out, A)
        return "Delta("..A..") "
    end
}

GateActions["increment/decrement"] = {
	group = "Arithmetic",
	name = "Increment/Decrement",
	inputs = { "A", "Increment", "Decrement" },
	output = function(gate, A, Increment, Decrement)
		local increment = ( Increment > 0 )
		local decrement = ( Decrement > 0 )
		
		if ( gate.PrevValue ~=  increment ) then
			gate.PrevValue = increment
			if ( increment ) then
				gate.Memory = (gate.Memory or 0) + A
			end
		end
		
		if ( gate.PrevValue ~=  decrement ) then
			gate.PrevValue = decrement
			if ( decrement ) then
				gate.Memory = (gate.Memory or 0) - A
			end
		end
		
		return gate.Memory
	end,
	label = function(Out, A)
		return "(" .. A .. " +/- LastNum) = " .. Out
	end
}




//***********************************************************
//		Comparison Gates
//***********************************************************
GateActions["="] = {
	group = "Comparison",
	name = "Equal",
	inputs = { "A", "B" },
	output = function(gate, A, B)
	    if (math.abs(A-B) < 0.001) then return 1 end
	    return 0
	end,
	label = function(Out, A, B)
	    return A.." == "..B.." = "..Out
	end
}

GateActions["!="] = {
	group = "Comparison",
	name = "Not Equal",
	inputs = { "A", "B" },
	output = function(gate, A, B)
	    if (math.abs(A-B) < 0.001) then return 0 end
	    return 1
	end,
	label = function(Out, A, B)
	    return A.." ~= "..B.." = "..Out
	end
}

GateActions["<"] = {
	group = "Comparison",
	name = "Less Than",
	inputs = { "A", "B" },
	output = function(gate, A, B)
	    if (A < B) then return 1 end
	    return 0
	end,
	label = function(Out, A, B)
	    return A.." < "..B.." = "..Out
	end
}

GateActions[">"] = {
	group = "Comparison",
	name = "Greater Than",
	inputs = { "A", "B" },
	output = function(gate, A, B)
	    if (A > B) then return 1 end
	    return 0
	end,
	label = function(Out, A, B)
	    return A.." > "..B.." = "..Out
	end
}

GateActions["<="] = {
	group = "Comparison",
	name = "Less or Equal",
	inputs = { "A", "B" },
	output = function(gate, A, B)
	    if (A <= B) then return 1 end
	    return 0
	end,
	label = function(Out, A, B)
	    return A.." <= "..B.." = "..Out
	end
}

GateActions[">="] = {
	group = "Comparison",
	name = "Greater or Equal",
	inputs = { "A", "B" },
	output = function(gate, A, B)
	    if (A >= B) then return 1 end
	    return 0
	end,
	label = function(Out, A, B)
	    return A.." >= "..B.." = "..Out
	end
}

GateActions["inrangei"] = {
	group = "Comparison",
	name = "Is In Range (Inclusive)",
	inputs = { "Min", "Max", "Value" },
	output = function(gate, Min, Max, Value)
	    if (Max < Min) then
		local temp = Max
		Max = Min
		Min = temp
	    end
	    if ((Value >= Min) && (Value <= Max)) then return 1 end
	    return 0
	end,
	label = function(Out, Min, Max, Value)
	    return Min.." <= "..Value.." <= "..Max.." = "..Out
	end
}

GateActions["inrangee"] = {
	group = "Comparison",
	name = "Is In Range (Exclusive)",
	inputs = { "Min", "Max", "Value" },
	output = function(gate, Min, Max, Value)
	    if (Max < Min) then
		local temp = Max
		Max = Min
		Min = temp
	    end
	    if ((Value > Min) && (Value < Max)) then return 1 end
	    return 0
	end,
	label = function(Out, Min, Max, Value)
	    return Min.." < "..Value.." < "..Max.." = "..Out
	end
}




//***********************************************************
//		Logic Gates
//***********************************************************
GateActions["not"] = {
	group = "Logic",
	name = "Not (Invert)",
	inputs = { "A" },
	output = function(gate, A)
	    if (A > 0) then return 0 end
	    return 1
	end,
	label = function(Out, A)
	    return "not "..A.." = "..Out
	end
}

GateActions["and"] = {
	group = "Logic",
	name = "And (All)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
	    for k,v in ipairs(arg) do
		    if (v) and (v <= 0) then return 0 end
		end
	    return 1
	end,
	label = function(Out, ...)
	    local txt = ""
	    for k,v in ipairs(arg) do
		    if (v) then txt = txt..v.." and " end
		end
	    return string.sub(txt, 1, -6).." = "..Out
	end
}

GateActions["or"] = {
	group = "Logic",
	name = "Or (Any)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
	    for k,v in ipairs(arg) do
		    if (v) and (v > 0) then return 1 end
		end
	    return 0
	end,
	label = function(Out, ...)
	    local txt = ""
	    for k,v in ipairs(arg) do
		    if (v) then txt = txt..v.." or " end
		end
	    return string.sub(txt, 1, -5).." = "..Out
	end
}

GateActions["xor"] = {
	group = "Logic",
	name = "Exclusive Or (Odd)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
		local result = 0
	    for k,v in ipairs(arg) do
		    if (v) and (v > 0) then result = (1-result) end
		end
	    return result
	end,
	label = function(Out, ...)
	    local txt = ""
	    for k,v in ipairs(arg) do
		    if (v) then txt = txt..v.." xor " end
		end
	    return string.sub(txt, 1, -6).." = "..Out
	end
}

GateActions["nand"] = {
	group = "Logic",
	name = "Not And (Not All)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
	    for k,v in ipairs(arg) do
		    if (v) and (v <= 0) then return 1 end
		end
	    return 0
	end,
	label = function(Out, ...)
	    local txt = ""
	    for k,v in ipairs(arg) do
		    if (v) then txt = txt..v.." nand " end
		end
	    return string.sub(txt, 1, -7).." = "..Out
	end
}

GateActions["nor"] = {
	group = "Logic",
	name = "Not Or (None)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
	    for k,v in ipairs(arg) do
		    if (v) and (v > 0) then return 0 end
		end
	    return 1
	end,
	label = function(Out, ...)
	    local txt = ""
	    for k,v in ipairs(arg) do
		    if (v) then txt = txt..v.." nor " end
		end
	    return string.sub(txt, 1, -6).." = "..Out
	end
}

GateActions["xnor"] = {
	group = "Logic",
	name = "Exclusive Not Or (Even)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
		local result = 1
	    for k,v in ipairs(arg) do
		    if (v) and (v > 0) then result = (1-result) end
		end
	    return result
	end,
	label = function(Out, ...)
	    local txt = ""
	    for k,v in ipairs(arg) do
		    if (v) then txt = txt..v.." xnor " end
		end
	    return string.sub(txt, 1, -7).." = "..Out
	end
}




//***********************************************************
//		Memory Gates
//***********************************************************
GateActions["latch"] = {
	group = "Memory",
	name = "Latch (Edge triggered)",
	inputs = { "Data", "Clk" },
	output = function(gate, Data, Clk)
		local clk = (Clk > 0)
		if (gate.PrevValue ~= clk) then
			gate.PrevValue = clk
		    if (clk) then
		        gate.LatchStore = Data
		    end
		end
	    return gate.LatchStore or 0
	end,
	reset = function(gate)
	    gate.LatchStore = 0
	    gate.PrevValue = nil
	end,
	label = function(Out, Data, Clk)
	    return "Latch Data:"..Data.."  Clock:"..Clk.." = "..Out
	end
}

GateActions["dlatch"] = {
	group = "Memory",
	name = "D-Latch",
	inputs = { "Data", "Clk" },
	output = function(gate, Data, Clk)
	    if (Clk > 0) then
			gate.LatchStore = Data
		end
	    return gate.LatchStore or 0
	end,
	reset = function(gate)
	    gate.LatchStore = 0
	end,
	label = function(Out, Data, Clk)
	    return "D-Latch Data:"..Data.."  Clock:"..Clk.." = "..Out
	end
}

GateActions["srlatch"] = {
    group = "Memory",
    name = "SR-Latch",
    inputs = { "S", "R" },
    output = function(gate, S, R)
        if (S > 0) and (R <= 0) then
            gate.LatchStore = 1
        elseif (S <= 0) and (R > 0) then
            gate.LatchStore = 0
        end
        return gate.LatchStore
    end,
    reset = function(gate)
        gate.LatchStore = 0
    end,
    label = function(Out, S, R)
        return "S:"..S.." R:"..R.." == "..Out
    end
}

GateActions["toggle"] = {
    group = "Memory",
    name = "Toggle (Edge triggered)",
    inputs = { "Clk", "OnValue", "OffValue" },
    output = function(gate, Clk, OnValue, OffValue)
        local clk = (Clk > 0)
        if (gate.PrevValue ~= clk) then
            gate.PrevValue = clk
            if (clk) then
                gate.LatchStore = (not gate.LatchStore)
            end
        end
        
        if (gate.LatchStore) then return OnValue end
        return OffValue
    end,
    reset = function(gate)
        gate.LatchStore = 0
        gate.PrevValue = nil
    end,
    label = function(Out, Clk, OnValue, OffValue)
        return "Off:"..OffValue.."  On:"..OnValue.."  Clock:"..Clk.." = "..Out
    end
}

GateActions["wom4"] = {
	group = "Memory",
	name = "Write Only Memory(4 store)",
	inputs = { "Clk", "AddrWrite", "Data" },
	output = function( gate, Clk, AddrWrite, Data )
		AddrWrite = math.floor(tonumber(AddrWrite))
		if ( Clk > 0 ) then
			if ( AddrWrite >= 0 ) and ( AddrWrite < 4 ) then
				gate.LatchStore[AddrWrite] = Data
			end
		end
		return 0
	end,
	reset = function( gate )
		gate.LatchStore = {}
		for i = 0, 3 do
			gate.LatchStore[i] = 0
		end
	end,
	label = function()
		return "Write Only Memory - 4 store"
    end
}

GateActions["ram8"] = {
    group = "Memory",
    name = "RAM(8 store)",
    inputs = { "Clk", "AddrRead", "AddrWrite", "Data" },
    output = function(gate, Clk, AddrRead, AddrWrite, Data )
        AddrRead = math.floor(tonumber(AddrRead))
        AddrWrite = math.floor(tonumber(AddrWrite))
        if (Clk > 0) then
            if (AddrWrite >= 0) and (AddrWrite < 8) then
                gate.LatchStore[AddrWrite] = Data
            end
        end
        
		if (AddrRead < 0) or (AddrRead >= 8) then return 0 end
		
        return gate.LatchStore[AddrRead] or 0
    end,
    reset = function(gate)
        gate.LatchStore = {}
        for i = 0, 7 do
            gate.LatchStore[i] = 0
        end
    end,
    label = function(Out, Clk, AddrRead, AddrWrite, Data)
	    return "WriteAddr:"..AddrWrite.."  Data:"..Data.."  Clock:"..Clk..
    	    "\nReadAddr:"..AddrRead.." = "..Out
    end
}

GateActions["ram64"] = {
    group = "Memory",
    name = "RAM(64 store)",
    inputs = { "Clk", "AddrRead", "AddrWrite", "Data" },
    output = function(gate, Clk, AddrRead, AddrWrite, Data )
        AddrRead = math.floor(tonumber(AddrRead))
        AddrWrite = math.floor(tonumber(AddrWrite))
        if (Clk > 0) then
            if (AddrWrite < 64) then
                    gate.LatchStore[AddrWrite] = Data
            end
        end
        return gate.LatchStore[AddrRead] or 0
    end,
    reset = function(gate)
        gate.LatchStore = {}
        for i = 0,63 do
            gate.LatchStore[i] = 0
        end
    end,
    label = function(Out, Clk, AddrRead, AddrWrite, Data)
        return "WriteAddr:"..AddrWrite.."  Data:"..Data.."  Clock:"..Clk..
        	"\nReadAddr:"..AddrRead.." = "..Out
    end
}

GateActions["ram32k"] = {
    group = "Memory",
    name = "RAM(32kb)",
    inputs = { "Clk", "AddrRead", "AddrWrite", "Data" },
    output = function(gate, Clk, AddrRead, AddrWrite, Data )
        AddrRead = math.floor(tonumber(AddrRead))
        AddrWrite = math.floor(tonumber(AddrWrite))
        if (Clk > 0) then
            if (AddrWrite < 32768) then
                    gate.LatchStore[AddrWrite] = Data
            end
        end
        return gate.LatchStore[AddrRead] or 0
    end,
    reset = function(gate)
        gate.LatchStore = {}
        for i = 0,32767 do
            gate.LatchStore[i] = 0
        end
    end,
    label = function(Out, Clk, AddrRead, AddrWrite, Data)
        return "WriteAddr:"..AddrWrite.."  Data:"..Data.."  Clock:"..Clk..
        	"\nReadAddr:"..AddrRead.." = "..Out
    end
}

GateActions["ram128k"] = {
    group = "Memory",
    name = "RAM(128kb)",
    inputs = { "Clk", "AddrRead", "AddrWrite", "Data" },
    output = function(gate, Clk, AddrRead, AddrWrite, Data )
        AddrRead = math.floor(tonumber(AddrRead))
        AddrWrite = math.floor(tonumber(AddrWrite))
        if (Clk > 0) then
            if (AddrWrite < 32768) then
                    gate.LatchStore[AddrWrite] = Data
            end
        end
        return gate.LatchStore[AddrRead] or 0
    end,
    reset = function(gate)
        gate.LatchStore = {}
        for i = 0,32767 do
            gate.LatchStore[i] = 0
        end
    end,
    label = function(Out, Clk, AddrRead, AddrWrite, Data)
        return "WriteAddr:"..AddrWrite.."  Data:"..Data.."  Clock:"..Clk..
        	"\nReadAddr:"..AddrRead.." = "..Out
    end
}

GateActions["ram64x64"] = {
    group = "Memory",
    name = "RAM(64x64 store)",
    inputs = { "Clk", "AddrReadX", "AddrReadY", "AddrWriteX", "AddrWriteY", "Data" },
    output = function(gate, Clk, AddrReadX, AddrReadY, AddrWriteX, AddrWriteY, Data )
        AddrReadX = math.floor(tonumber(AddrReadX))
        AddrReadY = math.floor(tonumber(AddrReadY))
        AddrWriteX = math.floor(tonumber(AddrWriteX))
        AddrWriteY = math.floor(tonumber(AddrWriteY))
        if (Clk > 0) then
            if (AddrWriteX >= 0) and (AddrWriteX < 64) or (AddrWriteY >= 0) and (AddrWriteY < 64) then
				gate.LatchStore[AddrWriteX + AddrWriteY*64] = Data
            end
        end
        
        if (AddrReadX < 0) or (AddrReadX >= 64) or (AddrReadY < 0) or (AddrReadY >= 64) then
            return 0
        end
        
        return gate.LatchStore[AddrReadX + AddrReadY*64] or 0
    end,
    reset = function(gate)
        gate.LatchStore = {}
        for i = 0,4095 do
            gate.LatchStore[i] = 0
        end
    end,
    label = function(Out, Clk, AddrReadX, AddrReadY, AddrWriteX, AddrWriteY, Data)
        return "WriteAddr:"..AddrWriteX..", "..AddrWriteY.."  Data:"..Data.."  Clock:"..Clk..
        "\nReadAddr:"..AddrReadX..", "..AddrReadY.." = "..Out
    end
}

GateActions["udcounter"] = {
	group = "Memory",
	name = "Up/Down Counter",
	inputs = { "Increment", "Decrement", "Clk", "Reset"},
	output = function(gate, Inc, Dec, Clk, Reset)
		local lInc = (Inc > 0)
		local lDec = (Dec > 0)
		local lClk = (Clk > 0)
		local lReset = (Reset > 0)
		if ((gate.PrevInc ~= lInc || gate.PrevDec ~= lDec || gate.PrevClk ~= lClk) && gate.lClk) then
			if (lInc) and (!lDec) and (!lReset) then
				gate.countStore = gate.countStore + 1
			elseif (!lInc) and (lDec) and (!lReset) then
				gate.countStore = gate.countStore - 1
			end
			gate.PrevInc = lInc
			gate.PrevDec = lDec
			gate.PrevClk = lClk
		end
		if (lReset) then
			gate.countStore = 0
		end
		return gate.countStore
	end,
	label = function(Out, Inc, Dec, Clk, Reset)
		return "Increment:"..Inc.." Decrement:"..Dec.." Clk:"..Clk.." Reset:"..Reset.." = "..Out
	end
}

GateActions["togglewhile"] = {
	group = "Memory",
	name = "Toggle While(Edge triggered)",
	inputs = { "Clk", "OnValue", "OffValue", "While" },
	output = function(gate, Clk, OnValue, OffValue, While)
		local clk = (Clk > 0)
		
		if (While <= 0) then
			clk = false
			gate.LatchStore = false
		end
		
		if (gate.PrevValue ~= clk) then
			gate.PrevValue = clk
			if (clk) then
				gate.LatchStore = (not gate.LatchStore)
			end
		end
		
		if (gate.LatchStore) then return OnValue end
		return OffValue
    end,
	reset = function(gate)
		gate.LatchStore = 0
		gate.PrevValue = nil
	end,
	label = function(Out, Clk, OnValue, OffValue, While)
		return "Off:"..OffValue.."  On:"..OnValue.."  Clock:"..Clk.."  While:"..While.." = "..Out
	end
}




//***********************************************************
//		Selection Gates
//***********************************************************
GateActions["min"] = {
	group = "Selection",
	name = "Minimum (Smallest)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
	    return math.min(unpack(arg))
	end,
	label = function(Out, ...)
	    local txt = "min("
	    for k,v in ipairs(arg) do
		    if (v) then txt = txt..v..", " end
		end
	    return string.sub(txt, 1, -3)..") = "..Out
	end
}

GateActions["max"] = {
	group = "Selection",
	name = "Maximum (Largest)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
	    return math.max(unpack(arg))
	end,
	label = function(Out, ...)
	    local txt = "max("
	    for k,v in ipairs(arg) do
		    if (v) then txt = txt..v..", " end
		end
	    return string.sub(txt, 1, -3)..") = "..Out
	end
}

GateActions["minmax"] = {
    group = "Selection",
    name = "Value Range",
    inputs = { "Min", "Max", "Value" },
    output = function(gate, Min, Max, Value)
        local temp = Min
        if Min > Max then
          Min = Max
          Max = temp
        end
        if Value < Min then return Min end
        if Value > Max then return Max end
        return Value
    end,
    label = function(Out, Min, Max, Value)
        local temp = Min
        if Min > Max then
          Min = Max
          Max = temp
        end
        return "Min: "..Min.."  Max: "..Max.."  Value: "..Value.." = "..Out
    end
}

GateActions["if"] = {
	group = "Selection",
	name = "If Then Else",
	inputs = { "A", "B", "C" },
	output = function(gate, A, B, C)
	    if (A) and (A > 0) then return B end
	    return C
	end,
	label = function(Out, A, B, C)
	    return "if "..A.." then "..B.." else "..C.." = "..Out
	end
}

GateActions["select"] = {
	group = "Selection",
	name = "Select (Choice)",
	inputs = { "Choice", "A", "B", "C", "D", "E", "F", "G", "H" },
	output = function(gate, Choice, ...)
		local idx = math.floor(Choice)
	    if (idx > 0) and (idx <= 8) then
			return arg[idx]
		end
	    
		return 0
	end,
	label = function(Out, Choice)
	    return "Select Choice:"..Choice.." Out:"..Out
	end
}

GateActions["router"] = {
	group = "Selection",
	name = "Router",
	inputs = { "Path", "Data" },
	outputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	output = function(gate, Path, Data)
	    local result = { 0, 0, 0, 0, 0, 0, 0, 0 }

		local idx = math.floor(Path)
	    if (idx > 0) and (idx <= 8) then
			result[idx] = Data
		end
	    
	    return unpack(result)
	end,
	label = function(Out, Path, Data)
	    return "Router Path:"..Path.." Data:"..Data
	end
}

local SegmentInfo = {
	None = { 0, 0, 0, 0, 0, 0, 0 },
	[0] = { 1, 1, 1, 1, 1, 1, 0 },
	[1] = { 0, 1, 1, 0, 0, 0, 0 },
	[2] = { 1, 1, 0, 1, 1, 0, 1 },
	[3] = { 1, 1, 1, 1, 0, 0, 1 },
	[4] = { 0, 1, 1, 0, 0, 1, 1 },
	[5] = { 1, 0, 1, 1, 0, 1, 1 },
	[6] = { 1, 0, 1, 1, 1, 1, 1 },
	[7] = { 1, 1, 1, 0, 0, 0, 0 },
	[8] = { 1, 1, 1, 1, 1, 1, 1 },
	[9] = { 1, 1, 1, 1, 0, 1, 1 },
}

GateActions["7seg"] = {
	group = "Selection",
	name = "7 Segment Decoder",
	inputs = { "A", "Clear" },
	outputs = { "A", "B", "C", "D", "E", "F", "G" },
	output = function(gate, A, Clear)
	    if (Clear > 0) then return unpack(SegmentInfo.None) end

		local idx = math.fmod(math.abs(math.floor(A)), 10)
	    return unpack(SegmentInfo[idx]) -- same as: return SegmentInfo[idx][1], SegmentInfo[idx][2], ...
	end,
	label = function(Out, A)
	    return "7-Seg In:" .. A .. " Out:" .. Out.A .. Out.B .. Out.C .. Out.D .. Out.E .. Out.F .. Out.G
	end
}

GateActions["timedec"] = {
	group = "Selection",
	name = "Time/Date decoder",
	inputs = { "Time", "Date" },
	outputs = { "Hours","Minutes","Seconds","Year","Day" },
	output = function(gate, Time, Date)
	    return math.floor(Time / 3600),math.floor(Time / 60) % 60,math.floor(Time) % 60,math.floor(Date / 366),math.floor(Date) % 366
	end,
	label = function(Out, A)
	    return "Date decoder"
	end
}


//***********************************************************
//		Time Gates
//***********************************************************
GateActions["accumulator"] = {
	group = "Time",
	name = "Accumulator",
	inputs = { "A", "Hold", "Reset" },
	timed = true,
	output = function(gate, A, Hold, Reset)
	    local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
	    gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
	    if (Reset > 0) then
	        gate.Accum = 0
		elseif (Hold <= 0) then
		    gate.Accum = gate.Accum+A*DeltaTime
		end
		return gate.Accum or 0
	end,
	reset = function(gate)
	    gate.PrevTime = CurTime()
	    gate.Accum = 0
	end,
	label = function(Out, A, Hold, Reset)
	    return "A:"..A.." Hold:"..Hold.." Reset:"..Reset.." = "..Out
	end
}

GateActions["smoother"] = {
	group = "Time",
	name = "Smoother",
	inputs = { "A", "Rate" },
	timed = true,
	output = function(gate, A, Rate)
	    local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
	    gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
	    local Delta = A-gate.Accum
	    if (Delta > 0) then
	        gate.Accum = gate.Accum+math.min(Delta, Rate*DeltaTime)
	    elseif (Delta < 0) then
	        gate.Accum = gate.Accum+math.max(Delta, -Rate*DeltaTime)
	    end
		return gate.Accum or 0
	end,
	reset = function(gate)
	    gate.PrevTime = CurTime()
	    gate.Accum = 0
	end,
	label = function(Out, A, Rate)
	    return "A:"..A.." Rate:"..Rate.." = "..Out
	end
}

GateActions["timer"] = {
	group = "Time",
	name = "Timer",
	inputs = { "Run", "Reset" },
	timed = true,
	output = function(gate, Run, Reset)
	    local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
	    gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if ( Reset > 0 ) then
			gate.Accum = 0
		elseif ( Run > 0 ) then
			gate.Accum = gate.Accum+DeltaTime
		end
		return gate.Accum or 0
	end,
	reset = function(gate)
	    gate.PrevTime = CurTime()
	    gate.Accum = 0
	end,
	label = function(Out, Run, Reset)
	    return "Run:"..Run.." Reset:"..Reset.." = "..Out
	end
}

GateActions["ostime"] = {
	group = "Time",
	name = "OS Time",
	inputs = { },
	timed = true,
	output = function(gate)
	    return os.date("%H")*3600+os.date("%M")*60+os.date("%S")
	end,
	label = function(Out)
	    return "OS Time = "..Out
	end
}

GateActions["osdate"] = {
	group = "Time",
	name = "OS Date",
	inputs = { },
	timed = true,
	output = function(gate)
	    return os.date("%Y")*366+os.date("%j")
	end,
	label = function(Out)
	    return "OS Date = "..Out
	end
}

GateActions["pulser"] = {
	group = "Time",
	name = "Pulser",
	inputs = { "Run", "Reset", "TickTime" },
	timed = true,
	output = function(gate, Run, Reset, TickTime)
	    local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
	    gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if ( Reset > 0 ) then
			gate.Accum = 0
		elseif ( Run > 0 ) then
			gate.Accum = gate.Accum+DeltaTime
			if (gate.Accum >= TickTime) then
				gate.Accum = gate.Accum - TickTime
				return 1
			end
		end
		return 0
	end,
	reset = function(gate)
	    gate.PrevTime = CurTime()
	    gate.Accum = 0
	end,
	label = function(Out, Run, Reset, TickTime)
	    return "Run:"..Run.." Reset:"..Reset.."TickTime:"..TickTime.." = "..Out
	end
}

GateActions["squarepulse"] = {
	group = "Time",
	name = "Square Pulse",
	inputs = { "Run", "Reset", "PulseTime", "GapTime" },
	timed = true,
	output = function(gate, Run, Reset, PulseTime, GapTime)
	    local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
	    gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if ( Reset > 0 ) then
			gate.Accum = 0
		elseif ( Run > 0 ) then
			gate.Accum = gate.Accum+DeltaTime
			if (gate.Accum >= GapTime) then
				return 1
			end
			if (gate.Accum >= PulseTime + GapTime) then
				gate.Accum = gate.Accum - PulseTime - GapTime
			end
		end
		return 0
	end,
	reset = function(gate)
	    gate.PrevTime = CurTime()
	    gate.Accum = 0
	end,
	label = function(Out, Run, Reset, PulseTime, GapTime)
	    return "Run:"..Run.." Reset:"..Reset.." PulseTime:"..PulseTime.." GapTime:"..GapTime.." = "..Out
	end
}

GateActions["derive"] = {
	group = "Time",
	name = "Derivative",
	inputs = {"A"},
	timed = false,
	output = function(gate, A)
		local t = CurTime()
		local dT = t - gate.LastT
		gate.LastT = t
		local dA = A - gate.LastA
		gate.LastA = A
		if (dT != 0) then
			return dA/dT
		else
			return 0;
		end
	end,
	reset = function(gate)
		gate.LastT = CurTime()
		gate.LastA = 0
	end,
	label = function(Out, A)
		return "d/dt["..A.."] = "..Out
	end
}

GateActions["delay"] = {
	group = "Time",
	name = "Delay",
	inputs = { "Clk", "Delay", "Hold", "Reset" },
	outputs = { "Out", "TimeElapsed" },
	timed = true,
	output = function(gate, Clk, Delay, Hold, Reset)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		local out = 0
		
		if ( Reset > 0 ) then
			gate.Stage = 0
			gate.Accum = 0
		end
		
		if ( gate.Stage == 1 ) then
			if ( gate.Accum >= Delay ) then
				gate.Stage = 2
				gate.Accum = 0
				out = 1
			else
				gate.Accum = gate.Accum+DeltaTime
			end
		elseif ( gate.Stage == 2 ) then
			if ( gate.Accum >= Hold ) then
				gate.Stage = 0
				gate.Accum = 0
				out = 0
			else
				out = 1
				gate.Accum = gate.Accum+DeltaTime
			end
		else
			if ( Clk > 0 ) then
				gate.Stage = 1
				gate.Accum = 0
			end
		end
		
		return out, gate.Accum
	end,
	reset = function(gate)
	    gate.PrevTime = CurTime()
	    gate.Accum = 0
		gate.Stage = 0
	end,
	label = function(Out, Clk, Delay, Hold, Reset)
	    return "Clk: "..Clk.." Delay: "..Delay..
		"\nHold: "..Hold.." Reset: "..Reset..
		"\nTime Elapsed: "..Out.TimeElapsed.." = "..Out.Out
	end
}

GateActions["Definite Integral"] = {
	group = "Time",
	name = "Integral",
	inputs = { "A", "Points" },
	timed = true,
	output = function(gate, A, Points)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if(Points<=0) then
			Points=2
			data = {}
		end
		data = data or {}
		integral=A*DeltaTime
		if (index == nil) then
			index=1
		else
			index=(index+1)%Points
		end
		data[index]=integral
		i=0
		totalintegral=0
		while (i<Points) do
			whichIndex=(index-i)
			whichIndex=whichIndex%Points
			whichIndex=whichIndex+1
			totalintegral=totalintegral+(data[whichIndex] or 0)
			i=i+1
		end
	return totalintegral or 0
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		data = {}
	end,
	label = function(Out, A, Points)
		return "A: "..A.."   Points: "..Points.."   Output: "..Out
	end,
}
 
GateActions["Derivative"] = {
	group = "Time",
	name = "Derivative",
	inputs = { "A" },
	timed = true,
	output = function(gate, A)
		prev5Delta= (prev4Delta or .04)
		prev4Delta= (prev3Delta or .04)
		prev3Delta= (prev2Delta or .04)
		prev2Delta= (prevDelta or .04)
		prevDelta = (DeltaT or .04)
		-- begin block: set up DeltaValue time
		prevTime=currentTime
		currentTime=CurTime()
		if (prevTime==currentTime) then
			DeltaT=.04
		else
			DeltaT=currentTime-(prevTime or 0)
		end
		prev6Value=(prev5Value or A)
		prev5Value=(prev4Value or A)
		prev5Slope=(prev5Value-prev6Value)/prev5Delta
		prev4Value=(prev3Value or A)
		prev4Slope=(prev4Value-prev5Value)/prev4Delta
		prev3Value=(prev2Value or A)
		prev3Slope=(prev3Value-prev4Value)/prev3Delta
		prev2Value=(prevValue or A)
		prev2Slope=(prev2Value-prev3Value)/prev2Delta
		prevValue=(currentValue or A)
		prevSlope=(prevValue-prev2Value)/prevDelta
		currentValue=A
		currentSlope=(prevValue-currentValue)/DeltaT
		averageSlope=((currentSlope+prevSlope+prev2Slope+prev3Slope+prev4Slope+prev5Slope)/6)
		return averageSlope
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		data = {}
	end,
	label = function(Out, A)
		return "Input: "..currentValue.."   Previous: "..prevValue.."   Derivative: "..Out
	end,
}
 
GateActions["Indefinite Integral"] = {
	group = "Time",
	name = "Indefinite Integral",
	inputs = { "A", "Reset" },
	timed = true,
	output = function(gate, A, Reset)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if(Reset != 0) then
			totalintegral=0
		end
		integral=A*DeltaTime
		totalintegral = (totalintegral or 0) + integral
		if (totalintegral > 100000) then
			totalintegral = 100000
		end
		if (totalintegral < -100000) then
			totalintegral = -100000
		end
		return totalintegral or 0
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		data = {}
	end,
	label = function(Out, A, Reset)
		return "A: "..A.."  Reset: "..Reset.."   Output: "..Out
	end,
}
 
GateActions["Average Derivative"] = {
	group = "Time",
	name = "Average Derivative",
	inputs = { "A", "Window" },
	timed = true,
	output = function(gate, A, Window)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if(Window<=0) then
			Window=2
			data = {}
		end
		data = data or {}
		prevA=currentA or A
		currentA=A
		derivative=(currentA-prevA)/DeltaTime
		if (index == nil) then
			index=1
		else
			index=(index+1)%Window
		end
		data[index]=derivative
		i=0
		sum=0
		while (i<Window) do
			whichIndex=(index-i)
			whichIndex=whichIndex%Window
			whichIndex=whichIndex+1
			sum=sum+(data[whichIndex] or 0)
			i=i+1
		end
		averageDerivative=(sum/Window)
	return averageDerivative or 0
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		data = {}
	end,
	label = function(Out, A, Window)
		return "A: "..A.."   Window: "..Window.."   Output: "..Out
	end,
} 


GateActions["monostable"] = {
	group = "Time",
	name = "Monostable Timer",
	inputs = { "Run", "Time", "Reset" },
	timed = true,
	output = function(gate, Run, Time, Reset)
	    local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
	    gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if ( Reset > 0 ) then
			gate.Accum = 0
		elseif ( gate.Accum > 0 || Run > 0 ) then
			gate.Accum = gate.Accum+DeltaTime
				if(gate.Accum > Time) then
					gate.Accum = 0
				end
			
		end
		if(gate.Accum > 0)then
			return 1
		else
			return 0
		end
	end,
	reset = function(gate)
	    gate.PrevTime = CurTime()
	    gate.Accum = 0
	end,
	label = function(Out, Run, Time, Reset)
	    return "Run:"..Run.." Time:"..Time.." Reset:"..Reset.." = "..Out
	end
}

GateActions["bstimer"] = {
	group = "Time",
	name = "BS_Timer",
	inputs = { "Run", "Reset" },
	timed = true,
	output = function(gate, Run, Reset)
	    local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
	    gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if ( Reset > 0 ) then
			gate.Accum = 0
		elseif ( Run > 0 ) then
			gate.Accum = gate.Accum+DeltaTime
		end
		
		for i = 1,50 do
			local bs = gate.Entity:GetPos()
			local bs1 = gate.Entity:GetAngles()
		end
		
		return gate.Accum or 0
	end,
	reset = function(gate)
	    gate.PrevTime = CurTime()
	    gate.Accum = 0
	end,
	label = function(Out, Run, Reset)
	    return "Run:"..Run.." Reset:"..Reset.." = "..Out
	end
}

//***********************************************************
//		Trig Gates
//***********************************************************
GateActions["quadratic"] = {
	group = "Trig",
	name = "Quadratic Formula",
	inputs = { "A", "B", "C" },
	outputs = { "Pos", "Neg" },
	output = function(gate, A, B, C)
		return ( -B + ( math.sqrt( math.abs( math.exp( B, 2 ) - ( 4*A )*C ) ) ) / 2*A )
	end,
	output = function(gate, A, B, C)
		return ( -B - ( math.sqrt( math.abs( math.exp( B, 2 ) - ( 4*A )*C ) ) ) / 2*A )
	end,
	label = function(Out, A, B, C)
		return "-" .. A .. " +/- sqrt( " ..  B .. "^2 - ( 4*" .. A .. " )*" .. C .. " )  / 2*" .. A
	end
}

GateActions["sin"] = {
	group = "Trig",
	name = "Sin(Rad)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.sin(A)
	end,
	label = function(Out, A)
	    return "sin("..A.."rad) = "..Out
	end
}

GateActions["cos"] = {
	group = "Trig",
	name = "Cos(Rad)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.cos(A)
	end,
	label = function(Out, A)
	    return "cos("..A.."rad) = "..Out
	end
}

GateActions["tan"] = {
	group = "Trig",
	name = "Tan(Rad)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.tan(A)
	end,
	label = function(Out, A)
	    return "tan("..A.."rad) = "..Out
	end
}

GateActions["asin"] = {
	group = "Trig",
	name = "Asin(Rad)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.asin(A)
	end,
	label = function(Out, A)
	    return "asin("..A..") = "..Out.."rad"
	end
}

GateActions["acos"] = {
	group = "Trig",
	name = "Acos(Rad)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.acos(A)
	end,
	label = function(Out, A)
	    return "acos("..A..") = "..Out.."rad"
	end
}

GateActions["atan"] = {
	group = "Trig",
	name = "Atan(Rad)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.atan(A)
	end,
	label = function(Out, A)
	    return "atan("..A..") = "..Out.."rad"
	end
}

GateActions["sin_d"] = {
	group = "Trig",
	name = "Sin(Deg)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.sin(math.rad(A))
	end,
	label = function(Out, A)
	    return "sin("..A.."deg) = "..Out
	end
}

GateActions["cos_d"] = {
	group = "Trig",
	name = "Cos(Deg)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.cos(math.rad(A))
	end,
	label = function(Out, A)
	    return "cos("..A.."deg) = "..Out
	end
}

GateActions["tan_d"] = {
	group = "Trig",
	name = "Tan(Deg)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.tan(math.rad(A))
	end,
	label = function(Out, A)
	    return "tan("..A.."deg) = "..Out
	end
}

GateActions["asin_d"] = {
	group = "Trig",
	name = "Asin(Deg)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.deg(math.asin(A))
	end,
	label = function(Out, A)
	    return "asin("..A..") = "..Out.."deg"
	end
}

GateActions["acos_d"] = {
	group = "Trig",
	name = "Acos(Deg)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.deg(math.acos(A))
	end,
	label = function(Out, A)
	    return "acos("..A..") = "..Out.."deg"
	end
}

GateActions["atan_d"] = {
	group = "Trig",
	name = "Atan(Deg)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.deg(math.atan(A))
	end,
	label = function(Out, A)
	    return "atan("..A..") = "..Out.."deg"
	end
}

GateActions["rad2deg"] = {
	group = "Trig",
	name = "Radians to Degrees",
	inputs = { "A" },
	output = function(gate, A)
	    return math.deg(A)
	end,
	label = function(Out, A)
	    return A.."rad = "..Out.."deg"
	end
}

GateActions["deg2rad"] = {
	group = "Trig",
	name = "Degrees to Radians",
	inputs = { "A" },
	output = function(gate, A)
	    return math.rad(A)
	end,
	label = function(Out, A)
	    return A.."deg = "..Out.."rad"
	end
}

GateActions["angdiff"] = {
	group = "Trig",
	name = "Difference(rad)",
	inputs = { "A", "B" },
	output = function(gate, A, B)
	    return math.rad(math.AngleDifference(math.deg(A), math.deg(B)))
	end,
	label = function(Out, A, B)
	    return A .. "deg - " .. B .. "deg = " .. Out .. "deg"
	end
}

GateActions["angdiff_d"] = {
	group = "Trig",
	name = "Difference(deg)",
	inputs = { "A", "B" },
	output = function(gate, A, B)
	    return math.AngleDifference(A, B)
	end,
	label = function(Out, A, B)
	    return A .. "deg - " .. B .. "deg = " .. Out .. "deg"
	end
}




//***********************************************************
//		Table Gates
//***********************************************************
/*GateActions["table_4merge"] = {
	group = "Table",
	name = "4x merger",
	timed = true,
	inputs = { "A", "B", "C", "D" },
	inputtypes = { "ANY", "ANY", "ANY", "ANY" },
	outputs = { "Tbl" },
	outputtypes = { "TABLE" },
	output = function(gate, A, B, C, D)
		if A then return { A, B, C, D }
		else return {}
		end
	end,
	OnInputWireLink = function(gate, iname, itype, src, oname, otype)
		if (itype == "ANY") then
			WireLib.RetypeInputs(gate, iname, otype)
			for n,con in pairs(gate.Outputs.Tbl.Connected) do
				WireLib.RetypeOutputs(con.Entity, iname, otype)
				Msg("=== con.Entity.Outputs[iname] m ( "..n.." ) type = "..con.Entity.Outputs[iname].Type.."\n")
				PrintTable()
			end
		end
	end,
	OnOutputWireLink = function(gate, oname, otype, dst, iname, itype)
		if (oname == "Tbl") then
			
			for _,iname in pairs(gate.inputs) do
				PrintTable(gate.Inputs.Tbl.Src.Inputs[oname])
			end
			
		end
	end,
}

GateActions["table_4split"] = {
	group = "Table",
	name = "4x splitter",
	timed = true,
	inputs = { "Tbl" },
	inputtypes = { "TABLE" },
	outputs = { "A", "B", "C", "D" },
	outputtypes = { "ANY", "ANY", "ANY", "ANY"  },
	output = function(gate, Tbl)
		if Tbl then return unpack( Tbl )
		else return 0,0,0,0
		end
	end,
	OnInputWireLink = function(gate, iname, itype, src, oname, otype)
		/*Msg("\n=== gate.Outputs s start ===\n")
		PrintTable(gate.Outputs)
		Msg("\n=== gate.Outputs s end ===\n\n")
		
		if (itype == "ANY") then
			Msg("\n=== con.Entity.Outputs[iname] s start ===\n")
			for n,con in pairs(gate.Outputs.Tbl.Connected) do
				Msg("\n=== "..n.." s start ===\n")
				PrintTable(con.Entity.Outputs[iname])
			end
			Msg("\n=== con.Entity.Outputs[iname] m end ===\n\n")
		end*
	end,
	OnOutputWireLink = function(gate, oname, otype, dst, iname, itype)
		if (otype == "ANY") then
			WireLib.RetypeOutputs(gate, oname, itype)
			if (gate.Inputs.Tbl.Src) then
				WireLib.RetypeInputs(gate.Inputs.Tbl.Src, oname, itype)
				Msg("=== gate.Inputs.Tbl.Src.Inputs[oname].Type = "..gate.Inputs.Tbl.Src.Inputs[oname].Type.."\n")
			end
		end
	end,
}*/

GateActions["table_8merge"] = {
	group = "Table",
	name = "8x merger",
	timed = true,
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	outputs = { "Tbl" },
	outputtypes = { "TABLE" },
	output = function(gate, A, B, C, D, E, F, G, H)
		if A then return { A, B, C, D, E, F, G, H }
		else return {}
		end
	end,
}

GateActions["table_8split"] = {
	group = "Table",
	name = "8x splitter",
	timed = true,
	inputs = { "Tbl" },
	inputtypes = { "TABLE" },
	outputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	output = function(gate, Tbl)
		if Tbl then return unpack( Tbl )
		else return 0,0,0,0,0,0,0,0
		end
	end,
}

GateActions["table_8duplexer"] = {
	group = "Table",
	name = "8x duplexer",
	timed = true,
	inputs = { "Tbl", "A", "B", "C", "D", "E", "F", "G", "H" },
	inputtypes = { "BIDIRTABLE" },
	outputs = { "Tbl", "A", "B", "C", "D", "E", "F", "G", "H" },
	outputtypes = { "BIDIRTABLE" },
	output = function(gate, Tbl, A, B, C, D, E, F, G, H)
		local t,v = {0,0,0,0,0,0,0,0}, {}
		if Tbl then t = Tbl end
		if A then v = { A, B, C, D, E, F, G, H } end
		return v, unpack( t )
	end,
}

GateActions["table_valuebyidx"] = {
	group = "Table",
	name = "Value retriever",
	timed = true,
	inputs = { "Tbl", "Index" },
	inputtypes = { "TABLE" },
	outputs = { "Data" },
	output = function(gate, Tbl, idx)
		if Tbl && idx && Tbl[idx] then return Tbl[idx]
		else return 0
		end
	end,
}




//***********************************************************
//		Vector Gates
//***********************************************************

--TODO




WireGatesSorted = {}
for name,gate in pairs(GateActions) do
	if !WireGatesSorted[gate.group] then WireGatesSorted[gate.group] = {} end
	WireGatesSorted[gate.group][name] = gate
end
