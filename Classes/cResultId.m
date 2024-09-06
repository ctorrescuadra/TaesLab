classdef cResultId < cMessageLogger
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
            if cType.isInteger(id,1:cType.MAX_RESULT_INFO)
			    obj.ResultId=id;
                obj.ModelName=cType.EMPTY_CHAR;
                obj.State=cType.EMPTY_CHAR;
                obj.DefaultGraph=cType.EMPTY_CHAR;
            else
                obj.messageLog(cType.ERROR,'Invalid ResultId %d',id);
            end
        end
		
        function res=get.ResultName(obj)
        % get the result name
            res=cType.EMPTY_CHAR;
            if obj.isValid
                res=cType.Results{obj.ResultId};
            end
        end

        function setResultId(obj,id)
        % Set ResultId. Internal package use only
            obj.ResultId=id;
        end
	end
end