function ShowRecyclingGraph(arg, varargin)
% Show a pie chart with the waste allocation values
%   USAGE:
%       ShowRecyclingGraph(res,graph)
%   INPUT:
%       res - cResultInfo object with recycling analysis information
%       param - Aditional parameters
%			Graph - type of graph to show
%				cType.Tables.WASTE_RECYCLING_DIRECT (rad)
%           	cType.Tables.WASTE_RECYCLING_GENERAL (rag)
%       		If graph is not selected first option is taken
%			WasteFlows - Waste Flow key (optional)
% See also cResultInfo, cThermoeconomicTool
	log=cStatus(cType.VALID);
	if ~(isa(arg,'cThermoeconomicModel') || isa(arg,'cResultInfo')) || ~isValid(arg)
		log.printError('Invalid result parameter');
		return
	end
	p = inputParser;
	p.addParameter('Graph','rad',@ischar);
	p.addParameter('WasteFlow','',@ischar);
	try
		p.parse(varargin{:});
	catch err
		log.printError(err.message);
		log.printError('Usage: ShowRecyclingGraph(res,options)');
		return
	end
% Get the graph
	param=p.Results;
	if isa(arg,'cResultInfo')
		graphRecycling(arg, param.Graph);
	else %cThermoeconomicModel
		if isempty(param.WasteFlow)
			param.WasteFlow=arg.WasteFlows{1};
		end
		graphRecycling(arg, param.Graph,param.WasteFlow);
	end	
end