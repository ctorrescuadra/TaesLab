function res = SummaryResults(data)
%SummaryResults get the Summary Tables of the data model
% 	INPUT:
%		data - cReadModel object containing the data model information
% 	OUTPUT:
%		res - cResultInfo object containing the summary tables.
%  
    if ~data.isValid
		data.printLogger;
		data.printError('Invalid Productive Structure. See error log');
		return
    end
    model=cThermoeconomicModel(data,'debug',false);
    if model.isValid
        res=model.summaryResults;
    else
        printLogger(model);
    end
end