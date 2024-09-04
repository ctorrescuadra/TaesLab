classdef (Abstract) cReadModelStruct < cReadModel
% cReadModelStruct Abstract class to read structured data model
%   This class derives cReadModelJSON and cReadModelXML
% See also cReadModel, cReadModelJSON, cReadModelXML
    methods(Access=protected)
		function res = buildModelData(obj, data)
		% Build the cModelData from structured data
        % Input Arguments:
        %   data - structured data
        % Output Arguments
        %   res - cModelData object
        %
			res=cModelData(obj.ModelName,data);
			if ~isValid(res)
				obj.addLogger(res);
			end
		end
	end
end