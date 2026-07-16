classdef (Abstract) cReadModel < cMessageLogger
%cReadModel - Abstract base class for thermoeconomic data model readers.
%   Defines the common interface and shared behaviour for all model reader
%   classes in TaesLab. Concrete subclasses implement format-specific
%   reading logic (JSON, XML, XLSX, CSV) and populate the ModelData
%   property with a validated cModelData intermediate object.
%
%   Two abstract branches derive from this class:
%     - cReadModelStruct  handles structured text formats (JSON, XML)
%     - cReadModelTable   handles tabular formats (XLSX, CSV)
%
%   After construction, call getDataModel() to obtain a fully validated
%   cDataModel object ready for thermoeconomic analysis.
%
%   cReadModel Properties:
%     ModelFile - Absolute path of the source model file
%     ModelName - Model name derived from the source file name (no extension)
%     ModelData - Intermediate cModelData object populated by the subclass
%
%   cReadModel Methods:
%     getDataModel - Build and return a validated cDataModel object
%
%   Protected Methods (for use by subclasses):
%     setModelProperties - Validate the source file and set ModelFile/ModelName
%
%   See also cReadModelStruct, cReadModelTable, cModelData, cDataModel
%
	properties(GetAccess=public,SetAccess=protected)
        ModelFile   % Absolute path of the source model file
        ModelName   % Model name (file name without extension)
        ModelData   % Intermediate cModelData object populated by the subclass
	end

	methods	
		function res = getDataModel(obj)
		%getDataModel - Build a validated cDataModel object from the model data.
		%   Constructs a cDataModel from the ModelData property populated
		%   during subclass construction. The returned object is the central
		%   data hub used by all thermoeconomic analysis functions.
		%
		%   Syntax:
		%     res = obj.getDataModel()
		%
		%   Output Arguments:
		%     res - cDataModel object. Check isValid(res) to confirm that
		%           the model data passed validation successfully.
		%
		%   See also cDataModel, cModelData
		%
			res = cDataModel(obj.ModelData);
		end
	end

    methods(Access=protected)
		function setModelProperties(obj, cfgfile)
		%setModelProperties - Validate the source file and initialise model properties.
		%   Checks that cfgfile is an existing file, then resolves its
		%   absolute path and extracts the model name from the file name.
		%   Sets ModelFile to the absolute path and ModelName to the file
		%   name without extension. Logs a FileNotFound error and returns
		%   early if cfgfile is not a valid, existing file path.
		%
		%   Syntax:
		%     obj.setModelProperties(cfgfile)
		%
		%   Input Arguments:
		%     cfgfile - Character vector containing the path to the model
		%               file. May be relative (resolved against the current
		%               working directory) or absolute.
		%
		%   See also cType, cMessages
		%
			if ~ischar(cfgfile) || ~isfile(cfgfile)
				obj.messageLog(cType.ERROR, cMessages.FileNotFound, cfgfile);
				return
			end
			[folder, name, ext] = fileparts(cfgfile);
			if isempty(folder)
				folder = pwd;
			end
            obj.ModelFile = strcat(folder, filesep, name, ext);
			obj.ModelName = name;
		end	
    end
end