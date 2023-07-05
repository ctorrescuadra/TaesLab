function WasteAllocationGraph(arg,varargin)
% Show a pie chart with the waste allocation values
%   USAGE:
%       WasteAllocationGraph(res, wflow)
%   INPUT:
%       res - cResultInfo or cThermoeconomicModel object
%		wflow - Waste flow key. If not selected first waste is chosen
% See also cResultInfo, cThermoeconomicModel
%
	graphWasteAllocation(arg,varargin{:});
end