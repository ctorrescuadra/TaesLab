function ShowGraph(arg,varargin)
%ShowGraph - Shows a result table as a graph.
%	Depending on the graph, additional options could be used.
%
%	Syntax 
%  	  ShowGraph(arg,Name,Value)
% 
%   Input Argument
% 	  arg - cResultSet object
%
%   Name-Value Arguments
%     Graph: Name of the table
%       char array
%     ShowOutput: Use for diagnosis tables
%       true | false (default)
%     WasteFlow: Waste flow key for waste allocation and recycling
%       char array 
%	  Variables: Use for summary results. 
%	    cell array
%
%   Example
%     <a href="matlab:open ThermoeconomicModelDemo.mlx">Thermoeconomic Model Demo</a>
%
% 	See also cGraphResults, cResultSet
%
    log=cMessageLogger();
	if ~isResultSet(arg)
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
        log.printError('Usage: ShowGraph(res,options)');
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
            res=arg.getResultInfo(param.Graph);
        otherwise
            log.printError('Invalid input argument');
            return
    end
    if ~isValid(res)
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
					param.Variables=res.Info.getDefaultFlowVariables;
				else
					param.Variables=res.Info.getDefaultProcessVariables;
				end
			end
			option=param.Variables;
	end
	% Show Graph
	gr=cGraphResults(tbl,option);
	gr.showGraph;
end
