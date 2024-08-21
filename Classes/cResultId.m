classdef cResultId < cStatusLogger
% cResultId base class to define the ResultId of the classes which provide results
% 	It is used in: cProductiveStructure, cExergyModel, cExergyCost, cDiagnosis, 
%	cRecyclingAnalysis, cDiagramFP, cWasteData and cSummaryResults
%
	properties(GetAccess=public,SetAccess=protected)
		ResultId     % Result Id
		ResultName   % Result Name
        ModelName    % Model Name
        State        % State Name
		DefaultGraph % Default Graph
    end

	methods
		function obj = cResultId(id)
        % Class constructor
		%  Input:
		%	id - Result identifier. See cType.ResultId
            if isscalar(id) && isnumeric(id) && ismember(id,1:cType.MAX_RESULT_INFO)
			    obj.ResultId=id;
                obj.ModelName='';
                obj.State='';
                obj.DefaultGraph='';
            else
                obj.messageLog(cType.ERROR,'Invalid ResultId %d',id);
            end
        end
		
        function res=get.ResultName(obj)
        % get the result name
            res=[];
            if obj.isValid
                res=cType.Results{obj.ResultId};
            end
        end
	end
end