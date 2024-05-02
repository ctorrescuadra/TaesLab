function ShowGraph(arg,varargin)
% ShowGraph shows a result table as graph
%   If a cThermoeconomicModel is used the name of the graph
%   should be provided. If a cResultInfo is used and the name
%   of the graph is not provided the default graph is used
%   Depending on the graph, additional options could be used,
% 
%   USAGE:
%       ShowGraph(arg, param)
%   INPUT:
%       arg - cResultSet object
%       param - options depending on grah type
%           Graph: Name of the graph
%			ShowOutput: Use for diagnosis tables
%			WasteFlow: Waste flow key for waste allocation and recycling
%			Variables: Use for summary results. 
%				Cell array with the variables to represent
% See also cGraphResults
%
    log=cStatus(cType.VALID);
	if ~(isa(arg,'cResultSet')) || ~isValid(arg)
		log.printError('Invalid result parameter');
		return
	end
    % Check input parameters
    p = inputParser;
    p.addParameter('Graph','',@ischar);
	p.addParameter('ShowOutput',true,@islogical);
	p.addParameter('Variables',{},@iscell);
	p.addParameter('WasteFlow','',@ischar);
    try
		p.parse(varargin{:});
    catch err
        log.printError(err.message);
        log.printError('Usage: ShowGraph(res,graph,options)');
        return
    end
	param=p.Results;
    switch arg.classId
        case cType.ClassId.RESULT_INFO
            if isempty(param.Graph)
			    param.Graph=arg.Info.DefaultGraph;
            end
            res=arg;
        case cType.ClassId.RESULT_MODEL
            if isempty(param.Graph)
			   log.printError('Not enough input arguments');
               return
            end
            res=arg.getResultInfoTable(param.Graph);
        otherwise
            log.printError('Invalid input argument');
            return
    end
    if isempty(res)
        log.printError('Invalid input argument');
        return
    end
    % Get the table values
	tbl=getTable(res,param.Graph);
	if ~isValid(tbl) || ~tbl.isGraph
		log.printError('Invalid graph table: %s',param.Graph);
		return
	end
	% Get aditional parameters
	option=[];
	switch tbl.GraphType
		case cType.GraphType.DIAGNOSIS
			if res.Info.Method==cType.DiagnosisMethod.WASTE_INTERNAL
				option=param.ShowOutput;
            else
				option=true;
			end
		case cType.GraphType.DIGRAPH
			option=res.Info.getNodeTable(param.Graph);
		case cType.GraphType.WASTE_ALLOCATION
            option=res.Info.wasteFlow;
		case cType.GraphType.SUMMARY
			if isempty(param.Variables)
				if tbl.isFlowsTable
					param.Variables=arg.Info.getDefaultFlowVariables;
				else
					param.Variables=arg.Info.getDefaultProcessVariables;
				end
			end
			option=param.Variables;
	end
	% Show Graph
	gr=cGraphResults(tbl,option);
	gr.showGraph;
end
