function res=ProductiveStructure(data,varargin)
% Show information about the productive structure of a plant
%	USAGE:
%		res=ProductiveStructure(data,options)
% 	INPUT:
%		data - cReadModel object containing the data model information
%   	options - Structure contains additional parameters (optional)
%           Show -  Show results on console (true/false)
%           SaveAs - Save results in an external file
% 	OUTPUT:
%		res - cResultInfo object containing productive structure info.
%		The following tables are obtained
%		  	flows - Flows definition table
%         	streams - Streams definition tables
%         	processes - Processes definition tables
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
	% Check Productive Structure
	if data.isError
		data.printLogger;
		res.printError('Invalid productive structure. See error log');
		return
	end
	if data.isWarning
		data.printLogger;
		res.printWarning('Productive structure is not well defined. See error log');
	end
	% Get Productive Structure info
	res=getResultInfo(data.ProductiveStructure,data.FormatData);
	res.setProperties(data.ModelName,'SUMMARY');
    % Show and Save results if required
    if param.Show
        printResults(res);
    end
    if ~isempty(param.SaveAs)
        SaveResults(res,param.SaveAs);
    end
end