function ShowCostGraph(arg,varargin)
% Show a bar plot of an Irreversibility-Cost table
%   USAGE:
%       ShowCostGraph(res, param)
%   INPUT:
%       arg - cResultInfo or cThermoeconomicModel object
%       param - Aditional parameters
%           Graph - Name of the table to plot (optional)
%               cType.Tables.PROCESS_COST (dict)
%               cType.Tables.PROCESS_GENERALIZED_COST (gict)
%               cType.Tables.FLOW_COST (dfict)
%               cType.Tables.FLOW_GENERALIZED_COST (gfict)
%               If graph is not selected first option is taken
% See also cResultInfo, cThermoeconomicModel
%
    log=cStatus(cType.VALID);
	if ~(isa(arg,'cThermoeconomicModel') || isa(arg,'cResultInfo')) || ~isValid(arg)
		log.printError('Invalid result parameter');
		return
	end
    p = inputParser;
    p.addParameter('Graph','dict',@ischar)
    try
		p.parse(varargin{:});
    catch err
        log.printError(err.message);
        log.printError('Usage: ShowCostGraph(res,options)');
        return
    end
    % Get the graph
    param=p.Results;
    graphCost(arg,param.Graph);
end