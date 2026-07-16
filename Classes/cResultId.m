classdef(Abstract) cResultId < cMessageLogger
%cResultId - Abstract base class that provides identification context for thermoeconomic results.
%   Every computation result (exergy analysis, cost calculation, diagnosis, etc.) inherits
%   from this class to carry the model name, operating state, resource sample, and the
%   numeric identifier that links it to an entry in cType.Results.
%   Concrete subclasses include cProductiveStructure, cExergyModel, cExergyCost, cDiagnosis,
%   cWasteAnalysis, cDiagramFP, cWasteData, and cSummaryResults.
%
%   cResultId Properties:
%     ResultId     - Numeric identifier that indexes cType.Results (read-only)
%     ResultName   - Human-readable result name derived from ResultId (read-only)
%     ModelName    - Name of the plant model that produced these results
%     State        - Thermodynamic operating state name (e.g. 'design', 'offdesign')
%     Sample       - Resource cost sample name (e.g. 'summer', 'winter')
%     DefaultGraph - Name of the default graph table shown by showGraph
%
%   cResultId Methods:
%     setResultId     - Assign the numeric result identifier (internal use)
%     setSample       - Assign the resource cost sample name (internal use)
%     setDefaultGraph - Assign the default graph table name (internal use)
%
%   See also cProductiveStructure, cExergyModel, cExergyCost, cDiagnosis,
%            cWasteAnalysis, cDiagramFP, cWasteData, cSummaryResults.
%   

	properties(GetAccess=public,SetAccess=protected)
		ResultId                       % Numeric result type identifier (see cType.ResultId)
		ResultName                     % Human-readable result name derived from ResultId
        ModelName=cType.EMPTY_CHAR     % Plant model name that produced these results
        State=cType.EMPTY_CHAR         % Thermodynamic operating state name
        Sample=cType.EMPTY_CHAR        % Resource cost sample name
		DefaultGraph=cType.EMPTY_CHAR  % Default graph table name used by showGraph
    end

	methods
		
        function res=get.ResultName(obj)
        %get.ResultName - Return the human-readable result name for this object
        %   Looks up ResultId in cType.Results. Returns an empty string when the
        %   object is not valid (status is false).
        %
        %   Output Arguments:
        %     res - Character vector with the result name, or empty string
            res=cType.EMPTY_CHAR;
            if obj.status
                res=cType.Results{obj.ResultId};
            end
        end

        function setResultId(obj,id)
        %setResultId - Assign the numeric result type identifier. Internal package use only.
        %   Validates that id is a valid index in the range [1, cType.MAX_RESULT_INFO].
        %
        %   Syntax:
        %     obj.setResultId(id)
        %   Input Arguments:
        %     id - Integer result type identifier (see cType.ResultId)
            if ~isIndex(id,1,cType.MAX_RESULT_INFO)
                obj.messageLog(cType.ERROR,cMessages.InvalidResultId,id);
                return
            end
            obj.ResultId=id;
        end

        function setSample(obj,sample)
        %setSample - Assign the resource cost sample name. Internal package use only.
        %
        %   Syntax:
        %     obj.setSample(sample)
        %   Input Arguments:
        %     sample - Character vector with the resource cost sample name
            obj.Sample=sample;
        end

        function setDefaultGraph(obj,graph)
        %setDefaultGraph - Assign the default graph table name. Internal package use only.
        %
        %   Syntax:
        %     obj.setDefaultGraph(graph)
        %   Input Arguments:
        %     graph - Character vector with the default graph table name
            obj.DefaultGraph=graph;
        end
	end
end