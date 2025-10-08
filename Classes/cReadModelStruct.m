classdef (Abstract) cReadModelStruct < cReadModel
%cReadModelStruct - Abstract class to read structured data model.
%   It implements the common properties and methods of the model reader
%   based on structured data.
%   Derived classes cReadModelJSON and cReadModelXML
%
%   cReadModelStruct methods:
%     buildModelData - Build the cModelData object
%
%   See also cReadModel, cReadModelJSON, cReadModelXML
%
    methods(Access=protected)
		function res = buildModelData(obj, data)
		% Build the cModelData from structured data
        % Input Arguments:
        %   data - structured data
        % Output Arguments:
        %   res - cModelData object
        %
			res=cModelData(obj.ModelName,data);
			if ~res.status
				obj.addLogger(res);
			end
		end
	end
end