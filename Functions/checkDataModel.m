function data = checkDataModel(filename)
% checkDataModel - Read and check a data model.
% Internal function. Don't print error messages.
%   USAGE:
%       data = checkDataModel(filename)
%   INPUT:
%       filename - name of the data model file
%   OUTPUT:
%       data - cDataModel object
%   See also ReadDataModel, CheckDataModel  
    rdm=readModel(filename);
    if ~isValid(rdm)
        rdm.messageLog(cType.ERROR,'Data Model File %s is NOT valid',filename);
        data=rdm;
        return
    end
    data=rdm.getDataModel;
    if isValid(data)
        data.messageLog(cType.INFO,'Data Model %s is valid',data.ModelName);
    else
        data.messageLog(cType.ERROR,'Data Model File %s is NOT valid',filename);
    end
end