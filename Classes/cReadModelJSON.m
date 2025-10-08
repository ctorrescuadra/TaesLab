classdef (Sealed) cReadModelJSON < cReadModelStruct
%cReadModelXML - Implement the cReadModelStruct to read JSON data model files.
%   This class reads a JSON file containing the thermoeconomic data
%   and store it into a structure data.
%
%   cReadModelCSV methods:
%     - cReadModelCSV - Build an instance of the class
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
            %check arguments
            if isOctave 
                obj.messageLog(cType.ERROR,cMessages.NoReadFiles,'JSON');
                return
            end
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