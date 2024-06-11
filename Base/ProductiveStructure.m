function res=ProductiveStructure(data,varargin)
% ProductiveStructure gets the information about the productive structure of the plant
%  USAGE:
%   res = ProductiveStructure(data,options)
%  INPUT:
%   data - cDataModel object containing the data model information
%   options - Structure containing additional parameters (optional)
%       Show - Show the results in the console (true/false)
%       SaveAs - Name of the file where the results will be saved. 
%  OUTPUT:
%	res - cResultInfo object containing the productive structure info.
%	The following tables are obtained
%       flows - Flows definition table
%       streams - Streams definition table
%       processes - Processes definition table
%
% See also cProductiveStructure, cResultInfo
%
	res=cStatus();
	checkModel=@(x) isa(x,'cDataModel');
    %Check input parameters
    p = inputParser;
    p.addRequired('data',checkModel);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs','',@ischar);
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