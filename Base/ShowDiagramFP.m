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
    if isOctave
        log.printError('Graph function not implemented in Octave');
        return
    end
    if ~(isa(arg,'cThermoeconomicModel') || isa(arg,'cResultInfo')) || ~isValid(arg)
        log.printError('Invalid result parameter');
        return
    end
    p = inputParser;
    p.addParameter('Graph','tfp',@ischar)
    try
        p.parse(varargin{:});
    catch err
        log.printError(err.message);
        log.printError('Usage: ShowDiagramFP(res,options)');
        return
    end
    % Get the graph
    param=p.Results;
    showDiagramFP(arg,param.Graph);
end