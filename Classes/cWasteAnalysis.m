classdef (Sealed) cWasteAnalysis < cResultId
%cWasteAnalysis - Analyse the cost-saving potential of waste recycling.
%   For a selected waste flow, cWasteAnalysis computes how the unit costs
%   of the system output flows change as the recycling ratio of that waste
%   varies from 0 (no recycling) to 1 (full recycling).
%
%   The analysis sweeps the recycling ratio x in steps of 0.1 over [0, 1]
%   and evaluates the adjusted unit cost vector at each step using the
%   recycling factor formula derived from the Fuel-Product operator.
%   Results are stored as numeric matrices where:
%     column 1       - recycling ratio x  (0, 0.1, 0.2, ..., 1.0)
%     columns 2:end  - unit cost of each output flow at that ratio
%
%   Both direct exergy costs (dValues) and generalised costs (gValues,
%   computed only when resource cost data is supplied) are available.
%
%   cWasteAnalysis Properties:
%     Recycling   - True if the recycling sweep was performed
%     OutputFlows - Cell array of output flow keys used as result variables
%     wasteFlow   - Key of the waste flow selected for recycling analysis
%     wasteTable  - cWasteData object from the cost model
%     dValues     - Direct-cost result matrix (11 × 1+NrOfOutputFlows)
%     gValues     - Generalised-cost result matrix (11 × 1+NrOfOutputFlows)
%
%   cWasteAnalysis Methods:
%     cWasteAnalysis  - Construct and optionally run the recycling sweep
%     buildResultInfo - Return the cResultInfo for display and export
%
%   See also cResultId, cExergyCost, cResultInfo, cResourceData, cWasteData
%
    properties(GetAccess=public,SetAccess=private)
        Recycling    % True if the recycling sweep was performed
        OutputFlows  % Cell array of output flow keys (sweep result variables)
        wasteFlow    % Key of the waste flow selected for recycling analysis
        wasteTable   % cWasteData object (waste allocation data)
        dValues      % Direct-cost matrix: col 1 = ratio, cols 2:end = unit costs
        gValues      % Generalised-cost matrix: col 1 = ratio, cols 2:end = unit costs
    end
    properties(Access=private)
        modelFP                 % cExergyCost object
        resourceData            % cResourceData object
        directCost=true         % Direct costs are calculated
        generalCost=false       % Generalised costs are calculated
        isResourceCost=false;   % Resource cost data is available
    end

    methods
        function obj = cWasteAnalysis(fpm,recycling,wkey,rsd)
        %cWasteAnalysis - Construct and optionally run the recycling sweep
        %   Validates all inputs, sets up the analysis context, and—when
        %   recycling is true—calls recyclingAnalysis to fill dValues and
        %   (if rsd is provided) gValues.
        %   Construction fails when:
        %     - fewer than 3 arguments are supplied
        %     - fpm is not a valid cExergyCost object
        %     - fpm has no waste model (fpm.isWaste is false)
        %     - recycling is not a logical scalar
        %     - wkey is not a char string or not a registered waste key
        %     - rsd is supplied but is not a valid cResourceData object
        %
        %   Syntax:
        %     obj = cWasteAnalysis(fpm, recycling, wkey)
        %     obj = cWasteAnalysis(fpm, recycling, wkey, rsd)
        %
        %   Input Arguments:
        %     fpm       - cExergyCost object carrying the direct cost solution.
        %     recycling - Logical scalar: true to perform the recycling sweep,
        %                 false to build the waste definition tables only.
        %     wkey      - Waste flow key string identifying the waste to analyse.
        %     rsd       - (optional) cResourceData object.  When supplied,
        %                 generalised costs are also computed and stored in gValues.
        %
        %   Output Arguments:
        %     obj - cWasteAnalysis object.  Use isValid(obj) to confirm
        %           successful construction before calling other methods.
        %
            % Check mandatory parameters
            if nargin < 3
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            if ~isObject(fpm,'cExergyCost')
                obj.addLogger(fpm);
                obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(fpm));
                return
            end
            if ~fpm.isWaste
                obj.addLogger(fpm);
                obj.messageLog(cType.ERROR,cMessages.NoWasteModel);
                return
            end
            if ~islogical(recycling)
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            if ~ischar(wkey)
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            wid=fpm.WasteTable.getWasteIndex(wkey);
            if ~wid
                obj.messageLog(cType.ERROR,cMessages.InvalidWasteKey,wkey);
                return
            end
            % Check optional Resource Data
            if nargin==4
                if isObject(rsd,'cResourceData')
                    obj.isResourceCost=true;
                    obj.generalCost=true;
                    obj.resourceData=rsd;
                    setResourceCost(rsd,fpm);
                else
                    rsd.printLogger;
                    obj.addLogger(rsd);
                    obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(rsd));
                    return
                end
            end
            % Assign object variables
            obj.modelFP=fpm;
            obj.wasteFlow=wkey;
            obj.wasteTable=fpm.WasteTable;
            obj.Recycling=recycling;
            if recycling
                obj.recyclingAnalysis;
            end
            % cResultId Properties
            obj.ResultId=cType.ResultId.WASTE_ANALYSIS;
            obj.DefaultGraph=cType.Tables.WASTE_ALLOCATION;
            obj.ModelName=fpm.ModelName;
            obj.State=fpm.State;
            obj.Sample=fpm.Sample;
        end

        function res=buildResultInfo(obj,fmt,param)
        %buildResultInfo - Return the cResultInfo for display and export
        %   Delegates to cResultTableBuilder.getWasteAnalysisResults, which
        %   converts the waste definition, allocation and (optionally)
        %   recycling-sweep matrices into cTable objects.
        %
        %   Syntax:
        %     res = obj.buildResultInfo(fmt, param)
        %
        %   Input Arguments:
        %     fmt   - cResultTableBuilder object.
        %     param - Struct controlling which tables are built:
        %               DirectCost  - logical; include direct-cost sweep table
        %               GeneralCost - logical; include generalised-cost sweep table
        %
        %   Output Arguments:
        %     res   - cResultInfo (WASTE_ANALYSIS) ready for ShowResults/SaveResults.
        %
            res=fmt.getWasteAnalysisResults(obj,param);
        end
    end
    
    methods(Access=private)
        function recyclingAnalysis(obj)
        %recyclingAnalysis - Run the recycling sweep for the selected waste flow
        %   Sweeps the recycling ratio x from 0 to 1 in steps of 0.1 (11
        %   points) and computes the adjusted unit cost of each output flow
        %   at each step using the formula:
        %
        %     rf = x / (1 + mR(wIdx) * x)      % recycling factor
        %     c_out(x) = c_out(0) - c_waste * rf * mR(outputId)
        %
        %   where mR is the row of the waste-recycling operator corresponding
        %   to the selected waste flow.
        %   Results are written to obj.dValues (direct cost) and, when
        %   generalised costs are enabled, obj.gValues.  Both matrices have
        %   11 rows and (1 + NrOfOutputFlows) columns.
        %
        %   Syntax:
        %     obj.recyclingAnalysis()
        %
            % Get Waste Data
            wt=obj.wasteTable;
            ps=obj.modelFP.ps;
            wId=wt.getWasteIndex(obj.wasteFlow);
            idx=wt.Flows(wId);
            % Get Output Flows Id
            tmp=ps.FinalProductFlows;
            outputId=[tmp,idx];
            obj.OutputFlows=ps.FlowKeys(outputId);
            % Get flow cost values;
            sol=obj.modelFP;
            mR=sol.flowOperators.opR.mValues(wId,:);
            if obj.directCost
                df=sol.getFlowsCost;
            end
            if obj.generalCost
                gf=sol.getFlowsCost(obj.resourceData);
            end
            % Generate the table
            x=(0:0.1:1)';
            yd=zeros(size(x,1),size(outputId,2));
            yg=zeros(size(x,1),size(outputId,2));
            for i=1:size(x,1)
                rf=x(i)/(1+mR(idx)*x(i)); %Recycling factor 
                if obj.directCost
                    yd(i,:)=df.c(outputId)-df.c(idx)*rf*mR(outputId);
                end
                if obj.generalCost
                    yg(i,:)=gf.c(outputId)-gf.c(idx)*rf*mR(outputId);
                end
            end
            % Set object variables
            obj.dValues=[x,yd];
            obj.gValues=[x,yg];
        end
    end
end