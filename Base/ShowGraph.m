function ShowGraph(arg,varargin)
%ShowGraph - Shows a result table as a graph.
%	Depending on the graph, additional options could be used.
%
% Syntax 
%  	ShowGraph(arg,Name,Value)
% 
% Input Argument
% 	arg - cResultSet object
%
% Name-Value Arguments
%   Graph: Name of the table
%     char array
%   ShowOutput: Use for diagnosis tables
%     false | true (default)
%   WasteFlow: Waste flow key for waste allocation and recycling
%     char array 
%   Variables: Use for summary results. 
%	  cell array
%   Colorbar: Use Colorbar in Diagram FP
%     false | true (default)
%
% Example
%   <a href="matlab:open ShowGraphDemo.mlx">Show Graph Demo</a>
%
% See also cGraphResults, cResultSet
%
    log=cMessageLogger();
	if nargin < 1 || ~isObject(arg,'cResultSet')
		log.printError(cMessages.InvalidObject,class(arg));
		log.printError(cMessages.ShowHelp);
		return
	end
    % Check input parameters
    p = inputParser;
    p.addParameter('Graph',arg.DefaultGraph);
	p.addParameter('ShowOutput',true,@islogical);
	p.addParameter('Variables',cType.EMPTY_CELL,@iscell);
	p.addParameter('WasteFlow',cType.EMPTY_CHAR,@ischar);
	p.addParameter('Colorbar',true,@islogical);
    try
		p.parse(varargin{:});
    catch err
        log.printError(err.message);
        log.printError(cMessages.ShowHelp);
        return
    end
	param=p.Results;
    % Get the resultId and table value
    if arg.ResultId==cType.ResultId.RESULT_MODEL
		res=arg.buildResultInfo(param.Graph);
	else
		res=arg;
    end
    if ~res.status
		printLogger(res)
        log.printError(cMessages.InvalidObject,class(res));
		return
    end
	tbl=getTable(res,param.Graph);
	if ~tbl.status
		printLogger(tbl);
		log.printError(cMessages.InvalidTable,param.Graph);
		return
	end
	if ~tbl.isGraph
		log.printError(cMessages.InvalidGraph,param.Graph);
		return
	end
	% Get aditional parameters
	option=cType.EMPTY;
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
            if isempty(param.WasteFlow)
                option=res.Info.wasteFlow;
            else
                option=param.WasteFlow;
            end
		case cType.GraphType.SUMMARY
			if isempty(param.Variables)
				if tbl.isFlowsTable
					param.Variables=res.Info.getDefaultFlowVariables;
				else
					param.Variables=res.Info.getDefaultProcessVariables;
				end
			end
			option=param.Variables;
        case cType.GraphType.DIAGRAM_FP
            option=param.Colorbar;
        case cType.GraphType.DIGRAPH_FP
            option=param.Colorbar;
	end
	% Show Graph
	gr=cGraphResults(tbl,option);
	gr.showGraph;
end
