classdef (Sealed) cReadModelXML < cReadModelStruct
% cReadModelXML implements the cReadModel to read XML data model files
%   This class read a XML file containing the thermoeconomic model data
%   and store it into a structure data
%   Methods:
%       obj=cReadModelXML(cfgfile)
%   See also cReadModel, cReadModelStruct
%
	methods
		function obj=cReadModelXML(cfgfile)
		% Constructor method
		%	cfgfile - xml file containig the model of the plant
		%
			%check arguments
            if isOctave 
		        obj.messageLog(cType.ERROR,'This function is not yet implemented');
                return
            end
			% Read configuration file
            try
		        s=readstruct(cfgfile,'AttributeSuffix','Id');
				f=jsonencode(s);
				sd=jsondecode(f);
		    catch err
                obj.messageLog(cType.ERROR,err.message);
                obj.messageLog(cType.ERROR,'File %s cannot be read',cfgfile);
                return
            end
            % Set object properties
            if obj.checkDataStructure(sd)
                obj.setModelProperties(cfgfile);
                obj.ModelData=cModelData(sd);
            end
        end
	end
end
