function data = checkModel(filename)
% checkModel read and check a data model.
%   INPUT:
%       filename - name of the data model file
%   OUTPUT:
%       data - cDataModel object
%       
    rdm=readModel(filename);
    if ~isValid(rdm)
        rdm.messageLog(cType.ERROR,'Data Model File %s is NOT valid',filename);
        data=rdm;
        return
    end
    data=cDataModel(rdm);
    if isValid(data)
        data.messageLog(cType.INFO,'Data Model %s is valid',data.ModelName);
    else
        data.messageLog(cType.ERROR,'Data Model %s is NOT valid',data.ModelName);
    end
end