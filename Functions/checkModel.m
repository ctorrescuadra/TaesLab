function data = checkModel(filename)
% checkModel read and check a data model. Internal Function
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
    data=rdm.getDataModel;
    if isValid(data)
        data.messageLog(cType.INFO,'Data Model %s is valid',data.ModelName);
    else
        data.messageLog(cType.ERROR,'Data Model File %s is NOT valid',filename);
    end
end