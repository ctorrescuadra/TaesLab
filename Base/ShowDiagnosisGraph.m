function ShowDiagnosisGraph(arg, varargin)
% Show a bar plot of a diagnosis table
%   USAGE:
%       ShowDiagnosis(res, param)
%   INPUT:
%       arg - cResultInfo or cThermoeconomicModel object
%       param - Aditional parameters
%           Graph - Name of the table to plot (optional)
%               cType.Tables.MALFUNCTION (mf)
%               cType.Tables.MALFUNCTION_COST (mfc)
%               cType.Tables.IRREVERSIBILITY (dit)
%               If graph is not selected first option is taken
%           ShowOutput - Display system output information (default true)
% See also cResultInfo, cThermoeconomicModel
%
    log=cStatus(cType.VALID);
    if ~(isa(arg,'cThermoeconomicModel') || isa(arg,'cResultInfo')) || ~isValid(arg)
        log.printError('Invalid result parameter');
        return
    end
    p = inputParser;
    p.addParameter('Graph','mfc',@ischar)
    p.addParameter('ShowOutput','true',@islogical)
    try
        p.parse(varargin{:});
    catch err
        log.printError(err.message);
        log.printError('Usage: ShowDiagnosisGraph(res,options)');
        return
    end
    % Get the graph
    param=p.Results;
    graphDiagnosis(arg,param.Graph,param.ShowOutput);
end