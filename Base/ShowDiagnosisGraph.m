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
%       shout - Display system output information (default true)
% See also cResultInfo,cThermoeconomicModel
%
    log=cStatus(cType.VALID);
    if isa(arg,'cThermoeconomicModel') || isa(arg,'cResultInfo')
        graphDiagnosis(arg,varargin{:});
    else
        log.printError('Invalid argument. It sould be a cThermoeconomicModel or cResultInfo object');
    end   
end