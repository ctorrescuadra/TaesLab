function res=ProductiveDiagram(data,varargin)
% Get the adjacency tables of the productive structure
%	USAGE:
%		res=ProductiveDiagram(data)
% 	INPUT:
%		data - cReadModel object containing the data model information
%   	options - Structure contains additional parameters (optional)
%           Show -  Show results on console (true/false)
%           SaveAs - Save results in an external file
% 	OUTPUT:
%		res - cResultInfo object containing productive structure info.
%		The following tables are obtained
%		  	fat - Flows adjacency matrix
%         	pat - Productive adjacency matrix
% See also cReadModel, cProductiveStructure, cResultInfo
%
	res=cStatusLogger();
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
    res=pd.getResultInfo(data.FormatData);  
    % Show and Save results if required
    if param.Show
        printResults(res);
    end
    if ~isempty(param.SaveAs)
        SaveResults(res,param.SaveAs);
    end
end