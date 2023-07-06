function ShowSummaryGraph(arg,varargin)
% Show a bar plot of the summary cost for all the plant states
%   USAGE:
%       ShowSummaryGraph(arg, graph, var)
%   INPUT:
%       arg - cResultInfo or cThermoeconomicModel object
%       graph - Name of the table to plot (optional)
%           cType.SummaryTables.FLOW_UNIT_COST (dfuc)
%           cType.SummaryTables.FLOW_GENERAL_UNIT_COST (gfuc)
%           cType.SummaryTables.PROCESS_UNIT_COST (dpuc)
%           cType.SummaryTables.PROCESS_GENERAL_UNIT_COST (gpuc)
%           cType.SummaryTables.UNIT_CONSUMPTION (pku)
%		If graph is not selected first value is taken
%		var - cell array with the names of the flows or processes to show (optional)
%		If the graph is related to processes the var list is mandatory, if graph
%		is related to flows by default the output flows are selected.
% See also cResultInfo,cThermoeconomicModel
%
    log=cStatus(cType.VALID);
    if isa(arg,'cThermoeconomicModel') || isa(arg,'cResultInfo')
        graphSummary(arg,varargin{:});
    else
        log.printError('Invalid argument. It sould be a cThermoeconomicModel or cResultInfo object');
    end
end