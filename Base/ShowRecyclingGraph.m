function ShowRecyclingGraph(res,varargin)
% Show a pie chart with the waste allocation values
%   USAGE:
%       ShowRecyclingGraph(res,graph)
%   INPUT:
%       res - cResultInfo object with recycling analysis information
%		graph - type of graph to show
%			cType.Tables.WASTE_RECYCLING_DIRECT (rad)
%           cType.Tables.WASTE_RECYCLING_GENERAL (rag)
%       If graph is not selected first option is taken
% See also cResultInfo
	log=cStatus();
	if isa(res,'cResultInfo')
		graphRecycling(res,varargin{:});
	else
		log.printError('input must be a cResultInfo object');	
	end
end