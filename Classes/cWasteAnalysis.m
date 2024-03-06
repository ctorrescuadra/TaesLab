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
        modelFP                 % cModelFPR object
        resourceCost            % cResourceCost object
        directCost=true         % Direct cost are calculated
        generalCost=false       % General cost are calculated
        isResourceCost=false;   % Resource Cost available
    end

    methods
        function obj = cWasteAnalysis(fpm,recycling,wkey,rsd)
        % Create an instance of cRecyclingAnalysis
        %   Input:
        %       fpm - cModelFPR object
        %       recycling - (true/false)
        %       wkey - Active waste flow key 
        %       rsd - Resources data
            obj=obj@cResultId(cType.ResultId.WASTE_ANALYSIS);
            % Check mandatory parameters
            if ~isa(fpm,'cModelFPR') || ~fpm.isValid
                obj.addLogger(fpm);
                obj.messageLog(cType.ERROR,'Invalid FPR model');
                return
            end
            if ~fpm.isWaste
                obj.addLogger(fpm);
                obj.messageLog(cType.ERROR,'Model has NOT waste');
                return
            end
            wt=fpm.WasteTable;
            switch nargin
            case 1
                recycling=false;
                wkey=wt.WasteKeys{1};
            case 2
                if ~islogical(recycling)
                    res.printError('Invalid recycling parameter');
                    return
                end
                wkey=wt.WasteKeys{1};
            case 3
                if ~ischar(wkey)
                    obj.messageLog(cType.ERROR,'Invalid wkey parameters');
                    return
                end
                wid=fpm.WasteTable.getWasteIndex(wkey);
                if isempty(wid)
                    res.printError('Invalid waste flow key %s',wkey);
                    return
                end
            case 4
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
            otherwise
                obj.messageLog(cType.ERROR,'Invalid number of parameters');
                return
            end
            % Assign object variables
            obj.modelFP=fpm;
            obj.wasteFlow=wkey;
            obj.wasteTable=wt;
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
            rwv=wd.Values;
            wrc=obj.wasteTable.RecycleRatio(wId); % Save original value
            sol=obj.modelFP;
            opW=sol.WasteOperators;
            % Generate the table
            x=(0:0.1:1)';
            yd=zeros(size(x,1),size(outputId,2));
            yg=zeros(size(x,1),size(outputId,2));     
            for i=1:size(x,1)
                obj.wasteTable.setRecycleRatio(wId,x(i));
                sol.setWasteOperators;
                if obj.directCost
                    ucost=sol.getDirectProcessUnitCost;
                    fc=sol.getDirectFlowsCost(ucost);
                    yd(i,:)=fc.c(outputId);
                end
                if obj.generalCost
                    ucost=sol.getGeneralProcessUnitCost(obj.resourceCost);
                    fc=sol.getGeneralFlowsCost(ucost,obj.resourceCost);
                    yg(i,:)=fc.c(outputId);
                end
            end
            % Set object variables
            obj.dValues=[x,yd];
            obj.gValues=[x,yg];
            % Restore original values
            wd.setRecycleRatio(wId,wrc);
            wd.updateValues(rwv);
            sol.setWasteOperators(opW);
        end
    end
end