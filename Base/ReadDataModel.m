function data=ReadDataModel(filename,varargin)
%ReadDataModel - Reads a data model file.
%   This function loads a data model file into a cDataModel object.
%   It checks that all elements are valid and displays them in the console.
%   If the 'Debug' option is selected, it provides additional information about the data model.
%   If the 'Show' option is selected, it displays the data tables in the console.
%   A copy of the data model (usually a MAT file) can be created  if the 'SaveAs' option is selected.
%
%   Syntax:
%     data = ReadDataModel(data,Name,Value);
%   
%   Input Arguments:
%     filename - Name of the data model file.
%       char array | string
%
%   Name-Value Arguments:
%     Debug - The validation of each element is shown in the console.
%       true | false (default)
%     Show - Show the data tables in the console
%       true | false (default)
%     SaveAs - Name of the file where the data model will be saved.
%       char array | string
%
%   Output Arguments:
%	  data - cDataModel object containing all the model information.
%
%   Example:
%     <a href="matlab:open ReadDataModelDemo.mlx">Read Model Demo</a>
%
%   See also cReadModel, cDataModel
%
    data=cMessageLogger();
    % Check parameters
    if nargin<1 
        data.printError(cMessages.ShowHelp);
        return
    end
    if ~isFilename(filename)
        data.printError(cMessages.InvalidInputFile);
        return
    end
    if ~exist(filename,'file')
        data.printError(cMessages.FileNotFound,filename);
        return
    end
    % Optional parameters
    p = inputParser;
    p.addParameter('Debug',false,@islogical);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs',cType.EMPTY_CHAR,@isFilename);
    try
		p.parse(varargin{:});
    catch err
		data.printError(err.message);
        data.printError(cMessages.ShowHelp);
        return
    end
    param=p.Results;
    % Read data Model
    data=readModel(filename);
    if param.Debug || ~data.status
        printLogger(data);
    end
    % Show data tables
    if param.Show && data.status
        printResults(data);
    end
    % Optional copy
    if ~isempty(param.SaveAs) && data.status
        SaveDataModel(data,param.SaveAs);
    end

