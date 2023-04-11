classdef cResultId < cStatusLogger
% cResultId base class to define the ResultId of the classes which provide results
% 	It is used in: cReadProductiveStructure, cExergyModel, cModelFPR, cDiagnosis, 
%	cRecyclingAnalysis, cDiagramFP, cReadWaste
%
	properties(GetAccess=public,SetAccess=protected)
		ResultId=cType.ResultId.DATA_MODEL % Result Id
		ResultName
	end

	methods
		function obj = cResultId(id)
			obj=obj@cStatusLogger();
			if (nargin==1) &&isscalar(id) && isnumeric(id)
				N=length(cType.Results);
				if any (id==1:N)
					obj.ResultId=id;
				end
			end
        end
        function res=get.ResultName(obj)
            res=cType.Results{obj.ResultId};
        end
	end
end