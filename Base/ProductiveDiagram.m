function res=ProductiveDiagram(data,varargin)
%ProductiveDiagram - Get the productive diagrams of the plant.
%   These diagrams could be represented graphically using the function
%   ShowGraph, or saving the adjacency tables in xlsx format, which can be
%   used by external graph software such as yEd
%
%   Syntax
%     res = ProductiveStructure(data,Name,Value)
%
%   Input Arguments
%     data - cReadModel object containing the data information
%    
%   Name-Value Arguments
%     Show -  Show the results on console.  
%       true | false (default)
%     SaveAs - Name of file (with extension) to save the results.
%       char array | string
%
%   Output Arguments
%     res - cResultsInfo object contains the productive structure information
%     The following tables are obtained:
%       fat - Flow adjacency matrix
%       pat - Productive adjacency matrix
%       fpat - Flow-Process adjacency matrix
%
%   Example
%     <a href="matlab:open ProductiveStructureDemo.mlx">Productive Structure Demo</a>
%
%   See also cDataModel, cProductiveDiagram, cResultInfo
%
	res=cMessageLogger();
	if nargin <1 || ~isObject(data,'cDataModel')
		res.printError(cMessages.DataModelRequired);
        res.printError(cMessages.ShowHelp);
		return
	end
    %Check input parameters
    p = inputParser;
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
	% Get Productive Diagram info
	pd=cProductiveDiagram(data.ProductiveStructure);
    if pd.status
        res=pd.buildResultInfo(data.FormatData);
    else
        pd.printLogger;
        res.printError(cMessages.InvalidObject,class(pd));
    end 
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