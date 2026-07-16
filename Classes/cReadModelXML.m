classdef (Sealed) cReadModelXML < cReadModelStruct
%cReadModelXML - Reads an XML thermoeconomic data model file.
%   Concrete implementation of cReadModelStruct for XML format. Uses
%   MATLAB's readstruct to parse the XML file, then re-encodes it via
%   jsonencode/jsondecode to produce a uniform MATLAB struct compatible
%   with buildModelData. XML attribute names are normalised using the
%   'Id' attribute suffix convention.
%
%   Note: XML reading relies on MATLAB's readstruct function and is
%   NOT supported on Octave. Construction on Octave logs an error and
%   returns an invalid object.
%
%   cReadModelXML Properties (inherited from cReadModel):
%     ModelFile - Absolute path of the source XML file
%     ModelName - Model name (file name without extension)
%     ModelData - Validated cModelData object
%
%   cReadModelXML Methods:
%     cReadModelXML - Construct an instance and parse the XML file
%     getDataModel  - Build and return a cDataModel object (inherited)
%
%   See also cReadModel, cReadModelStruct, cReadModelJSON
%
	methods
		function obj = cReadModelXML(cfgfile)
		%cReadModelXML - Construct an instance and parse the XML model file.
		%   Reads the specified XML file using MATLAB's readstruct, converts
		%   the result to a uniform struct via JSON round-trip, and builds
		%   the cModelData object. Construction fails (invalid object) when
		%   run on Octave, when the file cannot be found or read, or when
		%   the XML content does not match the expected model structure.
		%   Errors are stored in the object logger; check isValid(obj)
		%   after construction.
		%
		%   Syntax:
		%     obj = cReadModelXML(cfgfile)
		%
		%   Input Arguments:
		%     cfgfile - Character vector with the path to the XML model file
		%
		%   Output Arguments:
		%     obj - cReadModelXML object
		%
		%   See also cReadModelXML.getDataModel, readstruct
		%
			% XML reading is not supported on Octave
            if isOctave 
		        obj.messageLog(cType.ERROR, cMessages.NoReadFiles, 'XML');
                return
            end
			% Parse the XML file via JSON round-trip for uniform struct layout
            try
		        s = readstruct(cfgfile, 'AttributeSuffix', 'Id');
				f = jsonencode(s);
				sd = jsondecode(f);
		    catch err
                obj.messageLog(cType.ERROR, err.message);
                obj.messageLog(cType.ERROR, cMessages.FileNotRead, cfgfile);
                return
            end
            % Resolve file metadata and build the data model
            obj.setModelProperties(cfgfile);
            obj.ModelData = obj.buildModelData(sd);
        end
	end
end
