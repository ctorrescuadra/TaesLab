function ShowGraph(arg,varargin)
% Show table values as graph
%   USAGE:
%       ShowGraph(res, graph, options)
%   INPUT:
%       res - cResultInfo or cThermoeconomicModel object
%       graph - Name of the table to plot
% See also cResultInfo,cThermoeconomicModel
%
    log=cStatus(cType.VALID);
    if isa(arg,'cThermoeconomicModel') || isa(arg,'cResultInfo')
        graphCost(arg,varargin{:});
    else
        log.printError('Invalid argument. It sould be a cThermoeconomicModel or cResultInfo object');
    end
end