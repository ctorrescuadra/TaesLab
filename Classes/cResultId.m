classdef cResultId < cStatusLogger
% cResultId base class to define the ResultId of the classes which provide results
% 	It is used in: cProductiveStructure, cExergyModel, cModelFPR, cDiagnosis, 
%	cRecyclingAnalysis, cDiagramFP, cWasteData and cSummaryResults
%
	properties(GetAccess=public,SetAccess=protected)
		ResultId=cType.ResultId.DATA_MODEL % Result Id
		ResultName % Result Name
		DefaultGraph % Default Graph
    end

	methods
		function obj = cResultId(id)
        % Class constructor
		% 	Input:
		%		id - Result identifier. See cType.ResultId
			if (nargin==1) &&isscalar(id) && isnumeric(id)
				N=length(cType.Results);
				if any (id==1:N)
					obj.ResultId=id;
                    obj.status=cType.VALID;
				end
			end
        end
		
        function res=get.ResultName(obj)
        % get the result name 
            res=cType.Results{obj.ResultId};
        end
	end
end