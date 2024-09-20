classdef (Sealed) cWasteAnalysis < cResultId
% cWasteAnalysis analyze the potential cost saving of waste recycling
%   This class calculates the unit cost of output flows of the plant as function
%   of the recycling ratio of a waste.
%
% cWasteAnalysis Properties:
%   Recycling    - Indicate if recycling is available (true | false)
%   OutputFlows - Output flows cell array
%   wasteFlow   - Current waste flow key for recycling
%   wasteTable  - cWasteData object
%   dValues     - Recycling Analysis Direct Cost values
%   gValues     - Recycling Analysis Generalized Cost values
%
% cWasteAnalysis Methods:
%   getResultInfo - Get the cResultInfo for Waste Analysis
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
        resourceCost            % cResourceCost object
        directCost=true         % Direct cost are calculated
        generalCost=false       % General cost are calculated
        isResourceCost=false;   % Resource Cost available
    end

    methods
        function obj = cWasteAnalysis(fpm,recycling,wkey,rsd)
        % Create an instance of cWasteAnalysis
        % Syntax:
        %   obj = cWasteAnalysis(fpm,recycling,wkey,rsd)
        % Input Arguments:
        %   fpm - cExergyCost object
        %   recycling - Indicating if recycling analysis is required
        %   wkey - Current waste flow key 
        %   rsd - cResourcesData object (optional)
        %
            obj=obj@cResultId(cType.ResultId.WASTE_ANALYSIS);
            % Check mandatory parameters
            if nargin < 3
                obj.messageLog(cType.ERROR,'Invalid number of parameters');
                return
            end
            if ~isObject(fpm,'cExergyCost')
                obj.addLogger(fpm);
                obj.messageLog(cType.ERROR,'Invalid FPR model');
                return
            end
            if ~fpm.isWaste
                obj.addLogger(fpm);
                obj.messageLog(cType.ERROR,'Model has NOT waste');
                return
            end
            if ~islogical(recycling)
                res.messageLog(cType.ERROR,'Invalid recycling parameter');
                return
            end
            if ~ischar(wkey)
                obj.messageLog(cType.ERROR,'Invalid wkey parameters');
                return
            end
            wid=fpm.WasteTable.getWasteIndex(wkey);
            if isempty(wid)
                res.messageLog(cType.ERROR,'Invalid waste flow key %s',wkey);
                return
            end
            if nargin==4
                if isObject(rsd,'cResourceData')
                    obj.isResourceCost=true;
                    obj.generalCost=true;
                    obj.resourceCost=getResourceCost(rsd,fpm);
                else
                    rsd.printLogger;
                    obj.addLogger(rsd);
                    obj.messageLog(cType.ERROR,'Invalid resource cost data');
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
            obj.DefaultGraph=cType.Tables.WASTE_ALLOCATION;
            obj.ModelName=fpm.ModelName;
            obj.State=fpm.State;
        end

        function res=getResultInfo(obj,fmt,param)
        % Get the cResultInfo object
        % Syntax:
        %   res = obj.getResultInfo(fmt,options)
        % Input Arguments:
        %   fmt - cResultsTableBuilder object
        %   options - structure containing the fields:
        %     DirectCost - Direct Cost Tables will be obtained
        %     GeneralCost - General Cost Tables will be obtained
        %     ResourceCost - cResourceData object if generalized cost is required
            res=fmt.getWasteAnalysisResults(obj,param);
        end
    end
    methods(Access=private)
        function recyclingAnalysis(obj)
        % Do the recycling analysis for a waste flow
            wt=obj.wasteTable;
            ps=obj.modelFP.ps;
            wId=wt.getWasteIndex(obj.wasteFlow);
            idx=wt.Flows(wId);
            % Get Output Flows Id
            tmp=ps.FinalProducts.flows;
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
                sol.updateWasteOperators;
                if obj.directCost
                    fc=sol.getFlowsCost;
                    yd(i,:)=fc.c(outputId);
                end
                if obj.generalCost
                    fc=sol.getFlowsCost(obj.resourceCost);
                    yg(i,:)=fc.c(outputId);
                end
            end
            % Set object variables
            obj.dValues=[x,yd];
            obj.gValues=[x,yg];
            % Restore original values
            wt.setRecycleRatio(obj.wasteFlow,wrc);
            wt.updateValues(wval);
        end
    end
end