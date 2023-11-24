classdef cProductiveDiagram < cResultId
% cProductiveDiagram build the productive diagram info
    properties(GetAccess=public,SetAccess=private)
        FlowsMatrix         % Flow Matrix
        FlowProcessMatrix   % Flow-Process Matrix
        ProductiveMatrix    % Productive Matrix
    end

    methods
        function obj = cProductiveDiagram(ps)
            % Construct an instance of this class
            obj=obj@cResultId(cType.ResultId.PRODUCTIVE_DIAGRAM);
            obj.FlowsMatrix=ps.StructuralMatrix;
            obj.FlowProcessMatrix=ps.FlowProcessMatrix;
            obj.ProductiveMatrix=ps.ProductiveMatrix;
            obj.status=cType.VALID;
        end

        function res = getResultInfo(obj,fmt)
        % Get cResultInfo object
            res=fmt.getProductiveDiagram(obj);
        end
    end
end