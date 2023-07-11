classdef (Abstract) cReadModelStruct < cReadModel
% cReadModelStruct Abstract class to read structured data model
%   This class derives cReadModelJSON and cReadModelXML
%   Methods:
%	See also cReadModel, cReadModelJSON, cReadModelXML
    methods(Access=protected)
		function res = checkDataStructure(obj, data)
		% checkDataStructure
			res=true;
			for i=cType.MandatoryData
				fld=cType.DataElements{i};
				if ~isfield(data,fld)
					obj.messageLog(cType.ERROR,'Invalid model. %s is missing',fld);
					res=false;
				end  
			end
		end
	end
end