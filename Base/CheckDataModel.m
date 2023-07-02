function data=CheckDataModel(filename)
% Read the data model and check it its elements are valid  
%  USAGE:
%       data=CheckDataModel(filename)
%  INPUT: 
%	    filename - Thermoeconomic data model filename
%  OUTPUT:
%	    data - cReadModel object associated to the data model file
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