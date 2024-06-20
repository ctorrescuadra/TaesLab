function res=ProductiveStructure(data,varargin)
%ProductiveStructure - Gets the information about the productive structure of a plant.
%   This function obtains the information of the productive structure of
%   the plant. If 'Show' option is activated it displays the productive
%   structure tables on console. If 'SaveAs' option is used these tables
%   are saved in an external file.
%
%  Syntax
%    res = ProductiveStructure(data,Name,Value)
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
%       flows - Flows definition table
%       streams - Streams definition table
%       processes - Processes definition table
%
%   Example
%     <a href="matlab:open ProductiveStructureDemo.mlx">Productive Structure Demo</a>
%
%   See also cDataModel, cProductiveStructure, cResultInfo
%
    res=cStatus();
	checkModel=@(x) isa(x,'cDataModel');
    %Check input parameters
    p = inputParser;
    p.addRequired('data',checkModel);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs','',@isFilename);
    try
		p.parse(data,varargin{:});
    catch err
		res.printError(err.message);
        res.printError('Usage: ProductiveStructure(data,param)');
        return
    end
    param=p.Results;
	% Check data model
    ps=data.ProductiveStructure;
    if ps.isValid
        res=getResultInfo(ps,data.FormatData);
    else
        data.printLogger;
        res.printError('Invalid productive structure. See error log');
    end     
	% Get Productive Structure info
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