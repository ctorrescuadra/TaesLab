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
    % Check if data model file is correct
    if ~isValid(rdm)
        rdm.messageLog(cType.ERROR,'Data model file %s is NOT valid',filename);
        data=rdm;
        return
    end
    % If filename is a MAT file then is already done
    if isa(rdm,'cDataModel')
        rdm.messageLog(cType.INFO,'Data model file %s has been loaded',filename);
        data=rdm;
        return
    end
    % Get the data model for cReadModel 
    data=rdm.getDataModel;
    if isValid(data)
        data.messageLog(cType.INFO,'Data Model %s is valid',data.ModelName);
    else
        data.messageLog(cType.ERROR,'Data Model %s is NOT valid',filename);
    end
end