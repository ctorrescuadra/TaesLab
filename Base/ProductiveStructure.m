function res=ProductiveStructure(data)
% Show information about the productive structure of a plant
%	USAGE:
%		res=ProductiveStructure(data)
% 	INPUT:
%		data - cReadModel object containing the data model information
% 	OUTPUT:
%		res - cResultInfo object containing productive structure info.
%		The following tables are obtained
%		  	flows - Flows definition table
%         	streams - Streams definition tables
%         	processes - Processes definition tables
% See also cReadModel, cProductiveStructure, cResultInfo
%
	res=cStatusLogger();
    % Check input parameters
    if nargin~=1
        res.printError('Usage: ShowProductiveStructure(data)');
        return
    end
    if ~isa(data,'cDataModel')
        res.printError('Invalid data. It should be a cReadModel object');
        return
    end
	% Check Productive Structure
	if data.isError
		data.printLogger;
		res.printError('Invalid Productive Structure. See error log');
		return
	end
	if data.isWarning
		data.printLogger;
		res.printWarning('Productive Structure has errors. See error log');
	end
	% Read print format configuration
    fmt=data.FormatData;
	% Get Productive Structure info
	res=getProductiveStructureResults(fmt,data.ProductiveStructure);
	res.setProperties(data.ModelName,'SUMMARY');
end