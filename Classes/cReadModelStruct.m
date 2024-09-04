classdef (Abstract) cReadModelStruct < cReadModel
% cReadModelStruct Abstract class to read structured data model
%   This class derives cReadModelJSON and cReadModelXML
%   Methods:
%	See also cReadModel, cReadModelJSON, cReadModelXML
    methods(Access=protected)
		function res = buildModelData(obj, data)
			res=cModelData(data);
			if ~isValid(res)
				obj.addLogger(res);
			end
		end
	end
end