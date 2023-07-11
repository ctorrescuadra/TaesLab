function data=ReadDataModel(filename)
% Read a data model file.
%   USAGE:
%       data=ReadDataModel(filename)
%   INPUT:
%       filename - data model file name
%   OUTPUT:
%       data - cReadModel object containing the data model
% See also cReadModel, cDataModel
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
    % Read and Check the data model and print logger
    data=checkModel(filename);
    if ~isValid(data)
	    data.printLogger;
    end
end