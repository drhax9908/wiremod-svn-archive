include('shared.lua')
include('core/init.lua')

ENT.RenderGroup = RENDERGROUP_OPAQUE

function wire_expression_validate(buffer)
	local status, result = PreProcessor:Execute(buffer)
	if(!status) then 
		if(CLIENT) then return result end
		if(SERVER) then error(result, 0) end
	end
	directives = result[1]
	buffer = result[2]
	
	name = directives.name
	if directives.name == "" then name = "generic" end
	inports = directives.inputs
	outports = directives.outputs
	persists = directives.persist
	
	local status, result = Tokenizer:Execute(buffer)
	if(!status) then 
		if(CLIENT) then return result end
		if(SERVER) then error(result, 0) end
	end
	local tokens = result
	
	local status, result = Parser:Execute(tokens)
	if(!status) then 
		if(CLIENT) then return result end
		if(SERVER) then error(result, 0) end
	end
	local tree, dvars = result[1], result[2]
	
	local status, result = Compiler:Execute(tree, inports[3], outports[3], persists[3], dvars)
	if(!status) then 
		if(CLIENT) then return result end
		if(SERVER) then error(result, 0) end
	end
end