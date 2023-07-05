function ShowDiagnosisGraph(arg,varargin)
% Show a bar plot of a diagnosis table
%   USAGE:
%       ShowCostGraph(res, graph)
%   INPUT:
%       res - cResultInfo or cThermoeconomicModel object
%       graph - Name of the table to plot (optional)
%           cType.Tables.MALFUNCTION (mf)
%           cType.Tables.MALFUNCTION_COST (mfc)
%           cType.Tables.IRREVERSIBILITY (dit)
%       If graph is not selected first option is taken
% See also cResultInfo,cThermoeconomicModel
%
    graphDiagnosis(arg,varargin{:});
end