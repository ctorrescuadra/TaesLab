function res = SummaryResults(data)
%SummaryResults get the summary results of a Data model
%   Input:
%       data - cReadModel object containing the data model 
%   Output:
%       res - cResultInfo object with the summary results
    res=cStatusLogger(cType.ERROR);
    if ~isa(data,'cReadModel') || ~isValid(data)
        res.printError('Invalid data. It should be a cReadModel object');
        return
    end
    model=cThermoeconomicModel(data,'Summary',true);
    res=model.summaryResults;
end