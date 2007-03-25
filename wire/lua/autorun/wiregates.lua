AddCSLuaFile( "autorun/wiregates.lua" )

/*
All gate functions
*/
GateActions = {}
/*WireGates.Arithmetic = WireGates.Arithmetic or {}
WireGates.Comparison = WireGates.Comparison or {}
WireGates.Logic = WireGates.Logic or {}
WireGates.Memory = WireGates.Memory or {}
WireGates.Selection = WireGates.Selection or {}
WireGates.Time = WireGates.Time or {}
WireGates.Trig = WireGates.Trig or {}*/

/***********************************************************
		Arithmetic Gates
***********************************************************/
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



/***********************************************************
		Comparison Gates
***********************************************************/
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
	name = "Greater Then",
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



/***********************************************************
		Logic Gates
***********************************************************/
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



/***********************************************************
		Memory Gates
***********************************************************/
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




/***********************************************************
		Selection Gates
***********************************************************/
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




/***********************************************************
		Time Gates
***********************************************************/
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




/***********************************************************
		Trig Gates
***********************************************************/
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




WireGatesSorted = {}
for name,gate in pairs(GateActions) do
	if !WireGatesSorted[gate.group] then WireGatesSorted[gate.group] = {} end
	WireGatesSorted[gate.group][name] = gate
end