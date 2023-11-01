function WasteAllocationGraph(arg,varargin)
% Show a pie chart with the waste allocation values
%   USAGE:
%       WasteAllocationGraph(arg, wkey)
%   INPUT:
%       arg - cResultInfo or cThermoeconomicModel object
%		wkey - Waste flow key. If variable is missing, first waste is chosen
% See also cResultInfo, cThermoeconomicModel
    log=cStatus(cType.VALID);
    if isa(arg,'cResultInfo') || isa(arg,'cThermoeconomicModel')
        graphWasteAllocation(arg, varargin{:});
    else
        log.printError('Invalid data parameter. It sould be a valid object.');
    end
end