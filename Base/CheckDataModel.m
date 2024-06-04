function data=CheckDataModel(filename)
% Reads the data model and checks that its elements are valid  
% USAGE:
%   data=CheckDataModel(filename)
% INPUT: 
%   filename - Name of the file of the thermoeconomic data model
% OUTPUT:
%   data - cDataModel object 
%
    data=cStatusLogger();
    % Check parameters
    if (nargin~=1) || ~isText(filename)
        data.printError('Usage: data=CheckDataModel(filename)');
        return
    end
    if isstring(filename)
        filename=convertStringsToChars(filename);
    end
    if ~cType.checkFileRead(filename)
        data.printError('Invalid file name: %s', filename);
        return
    end
    % Read and Check the data model and print logger
    data=checkDataModel(filename);
    printLogger(data);
end