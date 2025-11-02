classdef (Sealed) cWasteAnalysis < cResultId
%cWasteAnalysis - Analyze the potential cost saving of waste recycling.
%   This class calculates the unit cost of output flows of the plant as function
%   of the recycling ratio of a waste.
%
%   cWasteAnalysis properties:
%     Recycling    - Indicate if recycling is available (true | false)
%     OutputFlows - Output flows cell array
%     wasteFlow   - Current waste flow key for recycling
%     wasteTable  - cWasteData object
%     dValues     - Recycling Analysis Direct Cost values
%     gValues     - Recycling Analysis Generalized Cost values
%
%   cWasteAnalysis methods:
%     cWasteAnalysis  - Create an instance of the class
%     buildResultInfo - Build the cResultInfo for Waste Analysis
%
%   See also cResultId, cExergyCost,cResultInfo, cResourceData
%
    properties(GetAccess=public,SetAccess=private)
        Recycling    % Indicate if recycling is available
        OutputFlows  % Output flows
        wasteFlow    % Actual waste flow key
        wasteTable   % cWasteData object
        dValues      % Recycling Analysis Direct Cost values
        gValues      % Recycling Analysis Generalized Cost values
    end
    properties(Access=private)
        modelFP                 % cExergyCost object
        resourceData            % cResourceData object
        directCost=true         % Direct cost are calculated
        generalCost=false       % General cost are calculated
        isResourceCost=false;   % Resource Cost available
    end

    methods
        function obj = cWasteAnalysis(fpm,recycling,wkey,rsd)
        %cWasteAnalysis - Create an instance of the class
        %   Syntax:
        %     obj = cWasteAnalysis(fpm,recycling,wkey,rsd)
        %   Input Arguments:
        %     fpm - cExergyCost object
        %     recycling - Indicating if recycling analysis is required
        %     wkey - Current waste flow key 
        %     rsd - cResourcesData object (optional)
        %   Output Arguments:
        %     obj - cWasteAnalysis object
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
            % cResultI dProperties
            obj.ResultId=cType.ResultId.WASTE_ANALYSIS;
            obj.DefaultGraph=cType.Tables.WASTE_ALLOCATION;
            obj.ModelName=fpm.ModelName;
            obj.State=fpm.State;
            obj.Sample=fpm.Sample;
        end

        function res=buildResultInfo(obj,fmt,param)
        %buildResultInfo - Build/Get the cResultInfo object
        %   Syntax:
        %     res = obj.buildResultInfo(fmt,options)
        %   Input Arguments:
        %     fmt - cResultsTableBuilder object
        %     options - structure containing the fields:
        %       DirectCost - Direct Cost Tables will be obtained
        %       GeneralCost - General Cost Tables will be obtained
        %       ResourceCost - cResourceData object if generalized cost is required
            res=fmt.getWasteAnalysisResults(obj,param);
        end
    end
    
    methods(Access=private)
        function recyclingAnalysis(obj)
        %recyclingAnalysis - Do the recycling analysis for the active waste flow
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
            % Save original values
            wrc=obj.wasteTable.RecycleRatio(wId);
            wval=obj.wasteTable.Values;
            sol=obj.modelFP;
            % Generate the table
            x=(0:0.1:1)';
            yd=zeros(size(x,1),size(outputId,2));
            yg=zeros(size(x,1),size(outputId,2));     
            for i=1:size(x,1)
                wt.setRecycleRatio(obj.wasteFlow,x(i));
                if ~isValid(sol.updateWasteOperators)
                    continue
                end
                if obj.directCost
                    fc=sol.getFlowsCost;
                    yd(i,:)=fc.c(outputId);
                end
                if obj.generalCost
                    fc=sol.getFlowsCost(obj.resourceData);
                    yg(i,:)=fc.c(outputId);
                end
            end
            % Set object variables
            obj.dValues=[x,yd];
            obj.gValues=[x,yg];
            % Restore original values
            wt.setRecycleRatio(obj.wasteFlow,wrc);
            wt.updateValues(wval);
            sol.updateWasteOperators;
        end
    end
end