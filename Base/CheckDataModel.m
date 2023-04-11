function data=CheckDataModel(filename)
%  CheckDataModel - checks if all elements of the thermoeconomic model are valid, and logs about errors
%   INPUT:
%	    data_file - Thermoeconomic data model filename
%   OUTPUT:
%	    data - cReadModel object associated to the data model file
%	    Log information about Thermoeconomic model validation
% See also cReadModel
%	
    data=cStatusLogger();
    % Check parameters
    if (nargin~=1) || ~ischar(filename)
        data.printError('Usage: data=CheckDataModel(filename)');
        return
    end
    if ~cType.checkFileRead(filename)
        data.printError('Invalid file name %s', filename);
        return
    end
    % Read and Check the data model and print logger
	data=checkModel(filename);
	data.printLogger;
end