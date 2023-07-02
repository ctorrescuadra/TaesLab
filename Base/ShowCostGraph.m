function ShowSummaryGraph(arg,varargin)
% Show a bar plot of an Irreversibility-Cost table
%   USAGE:
%       ShowCostGraph(res, graph)
%   INPUT:
%       res - cResultInfo or cThermoeconomicModel object
%       graph - Name of the table to plot (optional)
%           cType.Graph.PROCESS_COST (dict)
%           cType.Graph.PROCESS_GENERALIZED_COST (gict)
%           cType.Graph.FLOW_COST (dfict)
%           cType.GraphMatrixTable.FLOW_GENERALIZED_COST (gfict)
%       If graph is not selected first option is taken
% See also cResultInfo,cThermoeconomicModel
%
    graphCost(arg,varargin{:});
end