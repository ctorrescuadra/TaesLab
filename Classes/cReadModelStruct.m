classdef (Abstract) cReadModelStruct < cReadModel
%cReadModelStruct - Abstract base class for structured-format model readers.
%   Extends cReadModel to handle data model files stored as hierarchical
%   structured data (e.g. JSON, XML). Subclasses are responsible for
%   parsing the source file into a MATLAB struct and then calling
%   buildModelData() to produce the validated cModelData object.
%
%   Concrete derived classes:
%     cReadModelJSON - reads JSON model files
%     cReadModelXML  - reads XML model files (MATLAB only)
%
%   cReadModelStruct Methods (protected):
%     buildModelData - Construct a cModelData from a parsed struct
%
%   See also cReadModel, cReadModelJSON, cReadModelXML, cModelData
%
    methods(Access=protected)
		function res = buildModelData(obj, data)
		%buildModelData - Construct a cModelData object from a parsed struct.
		%   Creates a cModelData from the struct produced by the subclass
		%   parser. If the resulting object is invalid, its messages are
		%   merged into the caller's logger via addLogger.
		%
		%   Syntax:
		%     res = obj.buildModelData(data)
		%
		%   Input Arguments:
		%     data - MATLAB struct containing the parsed model data,
		%            with fields matching the cModelData section names
		%            (ProductiveStructure, ExergyStates, Format, etc.)
		%
		%   Output Arguments:
		%     res  - cModelData object. Check isValid(res) or inspect the
		%            caller's logger for details when validation fails.
		%
		%   See also cModelData, cMessageLogger.addLogger
		%
			res=cModelData(obj.ModelName,data);
			if ~res.status
				obj.addLogger(res);
			end
		end
	end
end