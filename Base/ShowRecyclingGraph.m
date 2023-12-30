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
% See also cResultInfo, cThermoeconomicTool
	log=cStatus(cType.VALID);
	if ~(isa(arg,'cThermoeconomicModel') || isa(arg,'cResultInfo')) || ~isValid(arg)
		log.printError('Invalid result parameter');
		return
	end
	p = inputParser;
	p.addParameter('Graph','rad',@ischar);
	try
		p.parse(varargin{:});
	catch err
		log.printError(err.message);
		log.printError('Usage: ShowRecyclingGraph(res,param)');
		return
	end
	% Get the graph
	param=p.Results;
	graphRecycling(arg, param.Graph);
end