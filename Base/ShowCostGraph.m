function ShowCostGraph(arg,graph)
% ShowGraphCost shows a barplot of the irreversibility-cost tables
%   INPUT:
%	    arg: cResultInfo or cThermoeconomicModel object   
%       graph: Select the graph to plot
%           cType.Graph.PROCESS_COST (dict)
%           cType.Graph.PROCESS_GENERALIZED_COST (gict)
%           cType.Graph.FLOW_COST (dfict)
%           cType.Graph.FLOW_GENERALIZED_COST (gfict)
%
    log=cStatusLogger();
    % Check Input Parameters
    if (nargin==1)
        graph=cType.Tables.PROCESS_ICT;
    end
    if ~(isa(arg,'cResultInfo') || isa(arg,'cThermoeconomicModel'))
        log.printError('Invalid result model',class(arg));
        return
    end
    % Show the plot
    log=graphCost(arg,graph);
    printLogger(log);
end
