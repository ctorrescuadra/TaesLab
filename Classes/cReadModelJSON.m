classdef (Sealed) cReadModelJSON < cReadModelStruct
%cReadModelJSON - Reads a JSON thermoeconomic data model file.
%   Concrete implementation of cReadModelStruct for JSON format. Parses
%   the JSON file with importJSON, then delegates struct-to-cModelData
%   conversion to the protected buildModelData method inherited from
%   cReadModelStruct.
%
%   Compatible with both MATLAB and Octave.
%
%   cReadModelJSON Properties (inherited from cReadModel):
%     ModelFile - Absolute path of the source JSON file
%     ModelName - Model name (file name without extension)
%     ModelData - Validated cModelData object
%
%   cReadModelJSON Methods:
%     cReadModelJSON - Construct an instance and parse the JSON file
%     getDataModel   - Build and return a cDataModel object (inherited)
%
%   See also cReadModel, cReadModelStruct, cReadModelXML
%
	methods
		function obj = cReadModelJSON(cfgfile)
		%cReadModelJSON - Construct an instance and parse the JSON model file.
		%   Reads and decodes the specified JSON file. Construction succeeds
		%   only if the file exists and contains valid JSON matching the
		%   expected data model structure. Errors are stored in the object
		%   logger; check isValid(obj) after construction.
		%
		%   Syntax:
		%     obj = cReadModelJSON(cfgfile)
		%
		%   Input Arguments:
		%     cfgfile - Character vector with the path to the JSON model file
		%
		%   Output Arguments:
		%     obj - cReadModelJSON object
		%
		%   See also cReadModelJSON.getDataModel, importJSON
		%
			% Read and decode the JSON file
            sd = importJSON(obj, cfgfile);
            if isempty(sd)
                return;
            end
            % Resolve file metadata and build the data model
            obj.setModelProperties(cfgfile);
            obj.ModelData = obj.buildModelData(sd);
        end
    end
end