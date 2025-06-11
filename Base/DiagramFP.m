function res=DiagramFP(data,varargin)
%DiagramFP - Gets the FP diagrams for a plant state.
%   These diagrams can be represented graphically using the ShowGraph function, 
%   or using external graphics software such as yEd, saving the adjacency tables
%   of the graph in xlsx format.
%  	
%   Syntax
%     res = DiagramFP(data,Name,Value);
%
%   Input Arguments
%     data - cReadModel Object containing the data model information.
%
%   Name-Value Arguments
%     State - Indicate one valid state to get exergy values. 
%       char array
%     Show -  Show results on console
%       true | false (default)
%     SaveAs - Name of the file where the results are saved.
%       char array | string
%
%   Output Arguments
%     res - cResultInfo object contains the FP diagram tables
%      The following tables are obtained:
%       atfp - Diagram FP adjacency matrix                                     
%       atcfp - Cost Diagram FP adjacency matrix
%   
%   Examples
%     <a href="matlab:open DiagramFpDemo.mlx">Diagram FP Demo</a>
%    
%   See also cDataModel, cExergyCost, cResultInfo
%
	res=cMessageLogger();
	if nargin<1 || ~isObject(data,'cDataModel')
		res.printError(cMessages.DataModelRequired);
		res.printError(cMessages.ShowHelp);
		return
	end
	% Check input parameters
	p = inputParser;
	p.addParameter('State',data.StateNames{1},@data.existState);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs',cType.EMPTY_CHAR,@isFilename);
	try
		p.parse(varargin{:});
	catch err
		res.printError(err.message);
		res.printError(cMessages.ShowHelp);
		return
	end
	param=p.Results;
	% Read and check exergy values
	ex=data.getExergyData(param.State);
	if ~ex.status
        ex.printLogger;
		res.printError(cMessages.InvalidExergyData,param.State);
        return
	end	
	% Get FP Diagram model and set results
	pm=cExergyCost(ex);
    dfp=cDiagramFP(pm);
    if ~dfp.status
        dfp.printLogger;
        res.printError(cMessages.InvalidObject,class(dfp));
		return
    end
	res=dfp.buildResultInfo(data.FormatData);
	if ~res.status
		res.printLogger;
        res.printError(cMessages.InvalidObject,class(res));
		return
	end
    % Show and Save results if required
    if param.Show
        printResults(res);
    end
    if ~isempty(param.SaveAs)
        SaveResults(res,param.SaveAs);
    end
end