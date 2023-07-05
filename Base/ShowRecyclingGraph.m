function ShowRecyclingGraph(res,varargin)
% Show a pie chart with the waste allocation values
%   USAGE:
%       ShowWasteAllocation(res, wflow)
%   INPUT:
%       res - cResultInfo object with recycling analysis information
%		graph - type of graph to show
%			cType.Tables.WASTE_RECYCLING_DIRECT (rad)
%           cType.Tables.WASTE_RECYCLING_GENERAL (rag)
%       If graph is not selected first option is taken
% See also cResultInfo
	graphRecycling(res,varargin{:});
end