function WasteAllocationGraph(arg,varargin)
% Show a pie chart with the waste allocation values
%   USAGE:
%       ShowWasteAllocationGraph(arg, wkey)
%   INPUT:
%       arg - cResultInfo or cThermoeconomicModel object
%		wflow - Waste flow key. If not selected first waste is chosen
% See also cResultInfo, cThermoeconomicModel
    log=cStatus(cType.VALID);
    if isa(arg,'cResultInfo') || isa(arg,'cThermoeconomicModel')
        graphWasteAllocation(arg, varargin{:});
    else
        log.printError('Invalid argument. It sould be a vailid object.');
    end
end