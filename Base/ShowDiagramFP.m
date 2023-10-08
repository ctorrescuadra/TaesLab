function ShowDiagramFP(arg,varargin)
% Show the digraph of the Table FP
%   USAGE:
%       ShowDiagramFP(res, param)
%   INPUT:
%       arg - cResultInfo or cThermoeconomicModel object
%       param - Aditional parameters
%           Graph - Graph table name
%               cType.Tables.TABLE_FP (tfp)
%               cType.Tables.COST_TABLE_FP (dcfp)
% See also cResultInfo,cThermoeconomicModel
%
    log=cStatus(cType.VALID);
    if ~(isa(arg,'cThermoeconomicModel') || isa(arg,'cResultInfo')) || ~isValid(arg)
        log.printError('Invalid model');
        return
    end
    p = inputParser;
    p.addParameter('Graph','tfp',@ischar)
    try
        p.parse(varargin{:});
    catch err
        log.printError(err.message);
        log.printError('Usage: ShowCostGraph(res,options)');
        return
    end
    % Get the graph
    param=p.Results;
    showDiagramFP(arg,param.Graph);
end