function data=ReadDataModel(filename)
% Read a data model file.
%   USAGE:
%       data=ReadDataModel(filename)
%   INPUT:
%       filename - data model file name
%   OUTPUT:
%       data - cReadModel object containing the data model
% See also cReadModel
%
    data=cStatusLogger();
    %Check parameters
    if (nargin~=1) || ~ischar(filename)
        data.printError('Usage: ReadDataModel(filename)');
        return
    end
    if ~cType.checkFileRead(filename)
        data.printError('Invalid file name %s', filename);
        return
    end
    % Read the model and print messages
    data=readModel(filename);
    switch data.status
        case cType.ERROR
            data.printLogger;
            data.printError('Invalid data model %s. See error log',filename);
        case cType.WARNING
            data.printLogger;
            data.printWarning('The data model %s is NOT valid. See error log',filename);
    end
end