function data = checkModel(filename)
% checkModel read and check a data model.
%   INPUT:
%       filename - name of the data model file
%   OUTPUT:
%       data - cReadModel object
%       
    data=readModel(filename);
    if data.checkModel
        data.messageLog(cType.INFO,'Data Model %s is valid',filename);
    else
        data.messageLog(cType.ERROR,'Data Model %s is NOT valid',filename);
    end
end