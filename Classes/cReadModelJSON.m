classdef (Sealed) cReadModelJSON < cReadModelStruct
% cReadModelXML implements the cReadModel to read JSON data model files
%   This class read a JSON file containing the thermoeconomic model data
%   and store it into a structure data
%   Methods:
%       obj=cReadModelJSON(cfgfile)
%   See also cReadModel, cReadModelStruct
	methods
		function obj=cReadModelJSON(cfgfile)
		% Constructor method
		%	cfgfile - xml file containig the model of the plant
		%
			% Read configuration file
            obj.status=cType.VALID;
            try
				text=fileread(cfgfile);
				sd=jsondecode(text);
		    catch err
                obj.messageLog(cType.ERROR,err.message);
                obj.messageLog(cType.ERROR,'File %s cannot be read',cfgfile);
                return
            end
            % Check and build Data Model
            res=obj.checkDataStructure(sd);
            if res
                obj.setModelProperties(cfgfile);
                obj.ModelData=sd;
            end
        end
    end
end