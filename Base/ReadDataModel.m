function data=ReadDataModel(filename,varargin)
% ReadDataModel loads a data model file into a cDataModel object.
%   Checks that all the elements are valid, and show it in the console if 'Check'
%   option is selected, optionally a copy of the data model (usualy a MAT file)
%   could be selected if 'SaveAs' is selected.
% USAGE:
%   data=ReadDataModel(data,options)
% INPUT:
%   filename - file name of the data model
%   options - Structure containing additional parameters (optional)
%       Check - The validation of each element is shown in the console (true/false)
%       SaveAs - Name of the file where the data model will be saved. 
% OUTPUT:
%	data - cDataModel containing all the model iformation.
%
% See also cReadModel, cDataModel
%
    data=cStatus();
    % Check parameters
    if (nargin<1) || ~isText(filename)
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
    % Optional parameters
    p = inputParser;
    p.addParameter('Check',false,@islogical);
    p.addParameter('SaveAs','',@ischar);
    try
		p.parse(varargin{:});
    catch err
		data.printError(err.message);
        data.printError('Usage: LoadDataModel(data,options)');
        return
    end
    param=p.Results;
    % Read data Model
    data=checkDataModel(filename);
    if param.Check || ~isValid(data)
        printLogger(data);
    end
    % Optional copy
    if ~isempty(param.SaveAs) && isValid(data)
        SaveDataModel(data,param.SaveAs);
    end

