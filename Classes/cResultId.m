classdef(Abstract) cResultId < cMessageLogger
%cResultId base class to define the ResultId of the classes which provide results
% 	It is used in: cProductiveStructure, cExergyModel, cExergyCost, cDiagnosis, 
%	cRecyclingAnalysis, cDiagramFP, cWasteData and cSummaryResults
%
%   cResultId Properties
%     ResultId     - Result Id
%     ResultName   - Result Name
%     ModelName    - Model Name
%     State        - State Name
%     Sample       - Resource Sample Name
%     DefaultGraph - Default Graph
% 
%   cResultId Methods
%     setResultId     - Set the resultId
%     setSample       - Set the resource sample name
%     setDefaultGraph - Set the default graph

	properties(GetAccess=public,SetAccess=protected)
		ResultId                       % Result Id
		ResultName                     % Result Name
        ModelName=cType.EMPTY_CHAR     % Model Name
        State=cType.EMPTY_CHAR         % State Name
        Sample=cType.EMPTY_CHAR        % Sample Name
		DefaultGraph=cType.EMPTY_CHAR  % Default Graph
    end

	methods
		
        function res=get.ResultName(obj)
        % Get the result name
            res=cType.EMPTY_CHAR;
            if obj.status
                res=cType.Results{obj.ResultId};
            end
        end

        function setResultId(obj,id)
        %setResultId - Set ResultId. Internal package use only
        %   Input Arguments
        %     id - ResultId number
            obj.ResultId=id;
        end

        function setSample(obj,sample)
        %setSample - Set Resource Sample Name. Internal package use only
        %   Input Arguments
        %     sample - Resource sample name
            obj.Sample=sample;
        end

        function setDefaultGraph(obj,graph)
        %setDefaultGraph - Set Default Graph. Internal package use only
        %   Input Arguments
        %     sample - Resource sample name
            obj.DefaultGraph=graph;
        end
	end
end