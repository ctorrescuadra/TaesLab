function data = checkDataModel(filename)
%checkDataModel - Read and check a data model.
%   Internal function used in ReadDataModel, ThermoeconomicModel
%   TaesPanel, TaesTool and TaesApp
%   
%   Syntax
%     data = checkDataModel(filename)
%   
%   Input Argument
%     filename - name of the data model file
%       char array | string
%  
%   Output Argument
%       data - cDataModel object
%
%   See also cReadModel, cDataModel
%
    data=cMessageLogger();
    rdm=readModel(filename);
    % Check if data model file is correct
    if ~isValid(rdm)
        rdm.messageLog(cType.ERROR,'Data model file %s is NOT valid',filename);
        data=rdm;
        return
    end
    % If filename is a MAT file then is already done 
    if isa(rdm,'cReadModel') 
        data=rdm.getDataModel;
    elseif isa(rdm,'cDataModel') % Import MAT data model
        data=rdm;
    end
    % Check if data model is valid
    if isValid(data)
        data.messageLog(cType.INFO,'Data model %s is valid',data.ModelName);
    else
        data.messageLog(cType.ERROR,'Data model file %s is NOT valid',filename);
    end
end