function ShowSummaryGraph(arg,varargin)
% Show a bar plot of the summary cost for all the plant states
%   USAGE:
%       ShowSummaryGraph(arg, param)
%   INPUT:
%       arg - cResultInfo or cThermoeconomicModel object
%       param - Optional parameters
%           Graph - Name of the table to plot (optional)
%               cType.SummaryTables.FLOW_UNIT_COST (dfuc)
%               cType.SummaryTables.FLOW_GENERAL_UNIT_COST (gfuc)
%               cType.SummaryTables.PROCESS_UNIT_COST (dpuc)
%               cType.SummaryTables.PROCESS_GENERAL_UNIT_COST (gpuc)
%               cType.SummaryTables.UNIT_CONSUMPTION (pku)
%		        If graph is not selected first value is taken
%		    Variables - cell array with the names of the flows or processes to show (optional)
%		    If the graph is related to processes the var list is mandatory, if graph	                                                                                                                            is related to flows by default the output flows are selected.
% See also cResultInfo,cThermoeconomicModel
%
    log=cStatus(cType.VALID);
	if ~(isa(arg,'cThermoeconomicModel') || isa(arg,'cResultInfo')) || ~isValid(arg)
		log.printError('Invalid model');
		return
	end
    % Check input parameters
    p = inputParser;
    p.addParameter('Graph','dfuc',@ischar);
    p.addParameter('Variables',{},@iscell);
    try
        p.parse(varargin{:});
    catch err
        log.printError(err.message);
        log.printError('Usage: GraphResults(res,graph,options)');
        return
    end
    % Get the graph
    param=p.Results;
    graphSummary(arg,param.Graph,param.Variables);
end