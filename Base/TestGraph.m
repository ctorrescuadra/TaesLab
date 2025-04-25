function TestGraph(arg,varargin)
%ShowGraph - Shows a result table as a graph.
%	Depending on the graph, additional options could be used.
%
%   Syntax 
%  	  ShowGraph(arg,Name,Value)
% 
%   Input Argument
% 	  arg - cResultSet object
%
%   Name-Value Arguments
%     Graph: Name of the table
%       char array
%     ShowOutput: Use for diagnosis tables
%       false | true (default)
%     WasteFlow: Waste flow key for waste allocation and recycling
%       char array 
%     Variables: Use for summary results. 
%	    cell array
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
	% Create Graph
	switch tbl.GraphType
        case cType.GraphType.COST
            gr=cGraphCost(tbl);
		case cType.GraphType.DIAGNOSIS
			if res.Info.Method==cType.DiagnosisMethod.WASTE_INTERNAL
				option=param.ShowOutput;
            else
				option=true;
            end
            gr=cGraphDiagnosis(tbl,option);
		case cType.GraphType.DIGRAPH
			option=res.Info.getNodeTable(param.Graph);
            gr=cDigraph(tbl,option);
		case cType.GraphType.WASTE_ALLOCATION
            if isempty(param.WasteFlow)
                option=res.Info.wasteFlow;
            else
                option=param.WasteFlow;
            end
            gr=cGraphWaste(tbl,option);
        case cType.GraphType.RECYCLING
            gr=cGraphRecycling(tbl);
		case cType.GraphType.SUMMARY
			if isempty(param.Variables)
				if tbl.isFlowsTable
					param.Variables=res.Info.getDefaultFlowVariables;
				else
					param.Variables=res.Info.getDefaultProcessVariables;
				end
			end
			gr=cGraphSummary(tbl,param.Variables);
        case cType.GraphType.DIAGRAM_FP
            gr=cGraphDiagramFP(tbl);
	end
	% Show Graph
	gr.showGraph;
end
