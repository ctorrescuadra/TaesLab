classdef cResultId < cMessageLogger
% cResultId base class to define the ResultId of the classes which provide results
% 	It is used in: cProductiveStructure, cExergyModel, cExergyCost, cDiagnosis, 
%	cRecyclingAnalysis, cDiagramFP, cWasteData and cSummaryResults
%
% cResultId Properties
%   ResultId     - Result Id
%   ResultName   - Result Name
%   ModelName    - Model Name
%   State        - State Name
%   Sample       - Resource Sample Name
%   DefaultGraph - Default Graph
% 
% cResultId Methods
%   setResultId     - Set the resultId
%   setSample       - Set the resource sample name
%   setDefaultGraph - Set the default graph

	properties(GetAccess=public,SetAccess=protected)
		ResultId       % Result Id
		ResultName     % Result Name
        ModelName      % Model Name
        State          % State Name
        Sample         % Sample Name
		DefaultGraph   % Default Graph
    end

	methods
		function obj = cResultId(id)
        % Class constructor
        % Syntax:
        %   obj = cResultId(id)
		% Input Arguments:
		%	id - Result identifier. 
        % See also cType.ResultId
        %
            if isIndex(id,1:cType.MAX_RESULT_INFO)
			    obj.ResultId=id;
                obj.ModelName=cType.EMPTY_CHAR;
                obj.State=cType.EMPTY_CHAR;
                obj.Sample=cType.EMPTY_CHAR;
                obj.DefaultGraph=cType.EMPTY_CHAR;
            else
                obj.messageLog(cType.ERROR,cMessages.InvalidResultId,id);
            end
        end
		
        function res=get.ResultName(obj)
        % Get the result name
            res=cType.EMPTY_CHAR;
            if obj.status
                res=cType.Results{obj.ResultId};
            end
        end

        function setResultId(obj,id)
        % Set ResultId. Internal package use only
            obj.ResultId=id;
        end

        function setSample(obj,sample)
        % Set Resource Sample Name. Internal package use only
            obj.Sample=sample;
        end

        function setDefaultGraph(obj,graph)
        % Set DefaultGraph. Internal package use only
            obj.DefaultGraph=graph;
        end
	end
end