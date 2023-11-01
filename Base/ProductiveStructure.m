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
        res.printError('Invalid data parameter. It should be a cDataModel object');
        return
    end
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
end