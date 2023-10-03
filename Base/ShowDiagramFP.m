function ShowDiagramFP(arg,table)
% Show the digraph of the Table FP
%   USAGE:
%       ShowDiagramFP(res, graph)
%   INPUT:
%       arg - cResultInfo or cThermoeconomicModel object
% See also cResultInfo,cThermoeconomicModel
%
    log=cStatus(cType.VALID);
    if isa(arg,'cThermoeconomicModel') || isa(arg,'cResultInfo')
        showDiagramFP(arg,table);
    else
        log.printError('Invalid argument. It sould be a cThermoeconomicModel or cResultInfo object');
    end   
end