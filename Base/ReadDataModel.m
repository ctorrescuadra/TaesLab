function data=ReadDataModel(filename,varargin)
%ReadDataModel - Reads a data model file.
%   This function loads a data model file into a cDataModel object.
%   Checks that all the elements are valid, and show it in the console if 'Debug'
%   option is selected. If 'Show' is selected display the data tables in Console.
%   Optionally a copy of the data model (usualy a MAT file) could be created if 'SaveAs' is selected.
%
%   Syntax
%     data = ReadDataModel(data,Name,Value);
%   
%   Input Arguments
%     filename - Name of the data model file.
%       char array | string
%
%   Name-Value Arguments
%     Debug - The validation of each element is shown in the console.
%       true | false (default)
%     Show - Show the data tables in the console
%       true | false (default)
%     SaveAs - Name of the file where the data model will be saved.
%       char array | string
%
%   Output Arguments
%	data - cDataModel object containing all the model information.
%
%   Example
%     <a href="matlab:open ReadDataModelDemo.mlx">Read Model Demo</a>
%
%   See also cReadModel, cDataModel
%
    data=cStatusLogger(cType.VALID);
    % Check parameters
    if (nargin<1) || ~isFilename(filename)
        data.printError('Usage: data=ReadDataModel(filename)');
        return
    end
    if ~exist(filename,'file')
        data.printError('File %s does NOT exists',filename);
        return
    end
    % Optional parameters
    p = inputParser;
    p.addParameter('Debug',false,@islogical);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs','',@isFilename);
    try
		p.parse(varargin{:});
    catch err
		data.printError(err.message);
        data.printError('Usage: ReadDataModel(data,options)');
        return
    end
    param=p.Results;
    % Read data Model
    data=checkDataModel(filename);
    if param.Debug || ~isValid(data)
        printLogger(data);
    end
    if param.Show && isValid(data)
        printResults(data);
    end
    % Optional copy
    if ~isempty(param.SaveAs) && isValid(data)
        SaveDataModel(data,param.SaveAs);
    end

