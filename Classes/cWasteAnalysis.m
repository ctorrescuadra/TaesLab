classdef (Sealed) cWasteAnalysis < cResultId
% cRecyclingAnalysis analyze the potential cost saving of waste recycling
%   This class calculates the direct unit cost of output flows of the plant as function
%   of the recycling ratio of a waste.
%   Methods:
%       obj=cRecyclingAnalysis()
%       res=obj.getResultInfo(fmt,param)
%   See also cResultId
    properties(GetAccess=public,SetAccess=private)
        Recycling    % Indicate if recycling is available
        OutputFlows  % Output flows
        wasteFlow    % Actual waste flow key
        wasteTable   % cWasteTable object
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
        % Create an instance of cRecyclingAnalysis
        %   Input:
        %       fpm - cExergyCost object
        %       recycling - (true/false)
        %       wkey - Active waste flow key 
        %       rsd - Resources data
            obj=obj@cResultId(cType.ResultId.WASTE_ANALYSIS);
            % Check mandatory parameters
            if nargin < 3
                obj.messageLog(cType.ERROR,'Invalid number of parameters');
                return
            end
            if ~isa(fpm,'cExergyCost') || ~fpm.isValid
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
                if isa(rsd,'cResourceData') && rsd.isValid
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
            obj.status=cType.VALID;
        end

        function res=getResultInfo(obj,fmt,param)
        % Get the cResultInfo object
            res=fmt.getWasteAnalysisResults(obj,param);
        end
    end
    methods(Access=private)
        function recyclingAnalysis(obj)
        % Do the recycling analysis for a waste flow
            wd=obj.wasteTable;
            ps=obj.modelFP.ps;
            wId=wd.getWasteIndex(obj.wasteFlow);
            if isempty(wId)
                obj.messageLog(cType.ERROR,'Invalid waste key %s',wkey);
                return
            end
            idx=wd.Flows(wId);
            % Get Output Flows Id
            tmp=ps.FinalProducts.flows;
            outputId=[tmp,idx];
            obj.OutputFlows={ps.Flows(outputId).key};
            % Save original values
            wrc=obj.wasteTable.RecycleRatio(wId);
            wval=obj.wasteTable.Values;
            sol=obj.modelFP;
            % Generate the table
            x=(0:0.1:1)';
            yd=zeros(size(x,1),size(outputId,2));
            yg=zeros(size(x,1),size(outputId,2));     
            for i=1:size(x,1)
                wd.setRecycleRatio(wId,x(i));
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
            wd.setRecycleRatio(wId,wrc);
            wd.setTableValues(wval);
        end
    end
end