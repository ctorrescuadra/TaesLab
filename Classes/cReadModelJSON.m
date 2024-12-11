classdef (Sealed) cReadModelJSON < cReadModelStruct
% cReadModelXML implements the cReadModel to read JSON data model files
%   This class read a JSON file containing the thermoeconomic model data
%   and build the data model
%
% See also cReadModel, cReadModelStruct
%
	methods
		function obj=cReadModelJSON(cfgfile)
		% Constructor method
		%	cfgfile - xml file containig the model of the plant
		%
			% Read configuration file
            try
				text=fileread(cfgfile);
				sd=jsondecode(text);
		    catch err
                obj.messageLog(cType.ERROR,err.message);
                obj.messageLog(cType.ERROR,cMessages.FileNotRead,cfgfile);
                return
            end
            % Build Data Model
            obj.setModelProperties(cfgfile);
            obj.ModelData=obj.buildModelData(sd);
        end
    end
end