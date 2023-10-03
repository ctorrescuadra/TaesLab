function GraphResults(res,graph,varargin)
% Show table values as graph
%   USAGE:
%       ShowGraph(res, graph, options)
%   INPUT:
%       res - cResultInfo object
%       graph - Name of the table to plot
%       option - options depending on table
% See also cResultInfo,cThermoeconomicModel
%
    log=cStatus(cType.VALID);
	if ~isa(res,'cResultInfo') || ~isValid(res)
		log.printError('Invalid cResultInfo object');
		return
	end
    % Check input parameters
    p = inputParser;
    p.addRequired('graph',@ischar)
	p.addParameter('ShowOutput',true,@islogical);
	p.addParameter('Variables',{},@iscell);
	p.addParameter('WasteFlow','',@ischar);
    try
		p.parse(graph,varargin{:});
    catch err
        log.printError(err.message);
        log.printError('Usage: GraphResults(res,graph,options)');
        return
    end
    param=p.Results;
	res.showGraph(param);
end