function res=DiagramFP(data,varargin)
%DiagramFP - Gets the diagram FP tables for one plant State
%	This function gets the adjacency tables of the diagram FP
%   for one state of the plant. 
%   These diagrams could be represented grafically using the function
%   ShowGraph, by external graph software as yEd saving the adjancency
%   tables of the graph in xlsx format.
%  	
%   Syntax
%	  res = DiagramFP(data,Name,Value);
%
%   Input Arguments
%	  data - cReadModel Object containing the data model information.
%
%   Name-Value Arguments
%	  State - Indicate one valid state to get exergy values. 
%  	    char array
%     Show -  Show results on console
%       true | false (default)
%     SaveAs - Name of the file where the results are saved.
%	    char array | string
%
% 	Output Arguments
%	 res - cResultInfo object contains the FP diagram tables
%    The following tables are obtained:
%		atfp - Diagram FP adjacency matrix                                     
%       atcfp - Cost Diagram FP adjacency matrix
%   
%   Examples
%     <a href="matlab:open DiagramFpDemo.mlx">Diagram FP Demo</a>
%    
%   See also cDataModel, cExergyCost, cResultInfo
%
	res=cStatus(); 
	checkModel=@(x) isa(x,'cDataModel');
	% Check input parameters
	p = inputParser;
	p.addRequired('data',checkModel);
	p.addParameter('State','',@ischar);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs','',@ischar);
	try
		p.parse(data,varargin{:});
	catch err
		res.printError(err.message);
        res.printError('Usage: DiagramFP(data,param)');
		return
	end
	param=p.Results;
	% Check Data Model
	if ~data.isValid
		data.printLogger;
		res.printError('Invalid data model. See error log');
		return
	end
	% Read and check exergy values
	if isempty(param.State)
		param.State=data.getStateName(1);
	end
	ex=data.getExergyData(param.State);
	if ~isValid(ex)
        ex.printLogger;
		res.printError('Invalid exergy values. See error log');
        return
	end	
	% Get FP Diagram model and set results
	pm=cExergyCost(ex);
    dfp=cDiagramFP(pm);
    if ~isValid(dfp)
        dfp.printLogger;
        res.printError('Invalid Diagram FP. See error log');
		return
    end
	res=dfp.getResultInfo(data.FormatData);
	if ~isValid(res)
		res.printLogger;
        res.printError('Invalid cResultInfo. See error log');
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