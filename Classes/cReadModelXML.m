classdef (Sealed) cReadModelXML < cReadModelStruct
%cReadModelXML - Implements the cReadModelStruct to read XML data model files.
%   This class read a XML file containing the thermoeconomic data
%   and store it into a structure data.
%
%   cReadModelXML Properties:
%     - ModelName   - Name of the model
%     - ModelData   - cModelData object
%     - ModelFile   - File name of the model
%
%   cReadModelXML methods:
%     cReadModelXML - Build an instance of the class
%     getDataModel  - Get the data model object
%
%   See also cReadModel, cReadModelStruct
%
	methods
		function obj=cReadModelXML(cfgfile)
		% cReadModelXML - Build an instance of the object
		%   Syntax:
		%     obj = cReadModelXML(cfgfile)
		%   Input Arguments:
		%	  cfgfile - xml file containig the model of the plant
		%   Output Arguments:
		%     obj - cReadModelXML object
		%
			%check arguments
            if isOctave 
		        obj.messageLog(cType.ERROR,cMessages.NoReadFiles,'XML');
                return
            end
			% Read configuration file
            try
		        s=readstruct(cfgfile,'AttributeSuffix','Id');
				f=jsonencode(s);
				sd=jsondecode(f);
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
