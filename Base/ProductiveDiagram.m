function res=ProductiveDiagram(data,varargin)
% ProductiveDiagram gets the adjacency tables of the productive structure.
%  USAGE:
%   res = ProductiveDiagram(data, options).
%  INPUT:
%   data - ccDataModel object containing the data model information of the plant
%   options - Structure containing additional parameters (optional)
%       Show - Show the results in the console (true/false).
%       SaveAs - Name of the file where the results will be saved. 
%  OUTPUT:
%   res - cResultInfo object containing information of the productive structure.
%   The following tables are obtained:
%       fat - Flow adjacency matrix
%       pat - Productive adjacency matrix
%       fpat - Flow-Process adjacency matrix
%
% See also cProductiveDiagram, cResultInfo
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
	% Get Productive Diagram info
	pd=cProductiveDiagram(data.ProductiveStructure);
    if isValid(pd)
        res=pd.getResultInfo(data.FormatData);
    else
        data.printLogger;
        res.printError('Invalid productive structure. See error log');
    end 
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