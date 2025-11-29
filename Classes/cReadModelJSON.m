classdef (Sealed) cReadModelJSON < cReadModelStruct
%cReadModelXML - Implement the cReadModelStruct to read JSON data model files.
%   This class reads a JSON file containing the thermoeconomic data
%   and store it into a structure data.
%
%   cReadModelJSON Properties:
%     - ModelName   - Name of the model
%     - ModelData   - cModelData object
%     - ModelFile   - File name of the model
%
%   cReadModelJSON methods:
%     - cReadModelJSON - Build an instance of the class
%     - getDataModel   - Get the data model object
%
%   See also cReadModel, cReadModelStruct
%
	methods
		function obj=cReadModelJSON(cfgfile)
		%cReadModelJSON - Construct an instance of the class
        %   Syntax:
        %     obj=cReadModelJSON(cfgfile)
        %   Input Arguments:
		%	  cfgfile - json file containig the model of the plant
        %   Output Arguments:
        %     obj - cReadModelJSON object
        % 
			% Read configuration file
            sd=importJSON(obj,cfgfile);
            if isempty(sd)
                return;
            end
            % Build Data Model
            obj.setModelProperties(cfgfile);
            obj.ModelData=obj.buildModelData(sd);
        end
    end
end