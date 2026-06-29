classdef (Sealed) cExergyCost < cExergyModel
%cExergyCost - Calculates the exergy cost of flows and processes for thermoeconomic analysis.
%   This class extends cExergyModel by building the cost operators derived from the FP
%   (Fuel-Product) table and the unit consumption vector. It supports both direct exergy
%   cost (no monetary resources) and generalized exergy cost (with external resource costs
%   and capital/O&M expenditures). Waste cost allocation is handled via cWasteData.
%
%   Two dual operator frameworks are provided:
%     - FP framework (fpOperators): cost propagation from resources to products
%     - PF framework (pfOperators): unit cost propagation from products to fuels
%   A flow-level operator (flowOperators) is also built for flow-by-flow cost analysis.
% 
%   cExergyCost properties:
%     SystemOutput           - Column vector of process output exergy to the plant product (from TableFP last column)
%     FinalDemand            - Effective final demand per process (equals SystemOutput, adjusted for waste recycling)
%     Resources              - Row vector of external resource exergy consumed by each process (from TableFP last row)
%     SystemUnitCost         - Ratio of total resource exergy to total final demand (plant-level unit cost)
%     RecirculationFactor    - Diagonal of opCP; measures internal recirculation share per process
%     fpOperators            - FP-framework operators: mFP (fuel/product ratios), mRP (waste allocation), opCP (cost operator), opR (waste cost operator)
%     pfOperators            - PF-framework operators: mPF (product/fuel ratios), mKP (consumption-weighted), mKR (waste unit cost), opP (cost operator), opI (irreversibility operator), opR (waste cost operator)
%     flowOperators          - Flow-level operators: mG (internal flow recirculation matrix), opB (Leontief inverse for flows), opR (waste flow cost operator)
%     isWaste                - true if the system includes waste (dissipative) processes
%     WasteTable             - cWasteData object defining waste allocation rules
%     TableR                 - Exergy-weighted waste allocation matrix (cSparseRow)
%     RecycleRatio           - Fraction of waste exergy recycled back as product, per waste process
%     WasteWeight            - Diagonal weights of the waste cost operator (opR), one per waste process
%     WasteAllocationRatios  - Normalized waste allocation ratios (rows: wastes, columns: productive processes)
%
%   cExergyCost methods:
%     cExergyCost                  - Create an instance of the class
%     buildResultInfo              - Build the cResultInfo object for THERMOECONOMIC_ANALYSIS
%     getSpectralRatio             - Get the spectral ratio of the productive structure matrix
%     getProcessCost               - Get absolute cost of processes (direct or generalized)
%     getProcessUnitCost           - Get unit cost of processes (direct or generalized)
%     getFlowsCost                 - Get absolute and unit cost of flows (direct or generalized)
%     getStreamsCost               - Get absolute and unit cost of productive streams
%     getCostTableFP               - Get the direct FP cost table scaled by process unit costs
%     getDirectCostTableFPR        - Get the direct-cost FPR table (with waste recycling rows)
%     getGeneralCostTableFPR       - Get the generalized-cost FPR table (with external resource costs)
%     getIrreversibilityCostTables - Get process and flow Irreversibility Cost Tables (ICT)
%     getResourcesCostDistribution - Get resource cost distribution across flows and processes
%     updateWasteOperators         - Recompute waste allocation ratios and all waste cost operators
%  
%   See also cResultId, cExergyModel, cResultInfo, cWasteData, cResourceData
%
	properties(GetAccess=public,SetAccess=private)
        SystemOutput           % (double) Column vector [Nx1] of process output exergy flowing to the plant product
        FinalDemand            % (double) Column vector [Nx1] of effective final demand; equals SystemOutput, with waste rows scaled by RecycleRatio
        Resources              % (double) Row vector [1xN] of external resource exergy consumed by each process
        SystemUnitCost         % (double) Scalar plant-level unit exergy cost: sum(Resources)/sum(FinalDemand)
        RecirculationFactor    % (double) Row vector [1xN] of internal recirculation factors (diagonal of opCP)
        WasteWeight            % (double) Row vector [1xNR] of diagonal weights of the waste cost operator, one per waste process
        fpOperators            % (struct) FP-framework cost operators: mFP, mRP, opCP, and (if waste) opR
        pfOperators            % (struct) PF-framework cost operators: mPF, mKP, opP, opI, and (if waste) mKR, opR
        flowOperators          % (struct) Flow-level operators: mG (recirculation), opB (Leontief inverse), and (if waste) opR
        isWaste=false          % (logical) true when the system includes dissipative (waste) processes
        WasteTable             % (cWasteData) Waste definition and allocation rules object
        TableR                 % (cSparseRow) Exergy-weighted waste allocation matrix [NR x N]
        RecycleRatio           % (double) Row vector [1xNR] of recycle fractions for each waste process
        WasteAllocationRatios  % (double) Matrix [NR x N] of normalized waste allocation ratios
    end
    
    properties(Access=private)
       mpL  % (double) Matrix mapping process products to flows: mP(1:N,:)*mL; used for flow ICT computation
    end
    
	methods
		function obj=cExergyCost(exd,wd)
		%cExergyCost - Creates an instance of the cExergyCost class.
        %   Builds all cost operators from the exergy model. When a cWasteData object
        %   is provided and the system has waste processes, waste allocation ratios and
        %   the corresponding waste cost operators are also initialized.
        %
        %   Syntax:
        %     obj = cExergyCost(exd)
        %     obj = cExergyCost(exd, wd)
        %   Input Arguments:
		%     exd - (cExergyData) Validated exergy data for the state to analyze
        %     wd  - (cWasteData) Waste definition object [optional]
        %   Output Arguments:
        %     obj - (cExergyCost) Constructed object; obj.status is false if initialization fails
        %
			obj=obj@cExergyModel(exd);
            % Abort if the base exergy model is invalid
            if ~obj.status
                return
            end
            obj.ResultId=cType.ResultId.THERMOECONOMIC_ANALYSIS;
			N=obj.NrOfProcesses;
            M=obj.NrOfFlows;
            vK=obj.UnitConsumption;   % Unit consumption vector (kj = Fj/Pj)
            vk1=zerotol(vK-1);        % kj - 1; used to build the irreversibility operator opI
            % --- Flow-level operators ---
            % mG: internal recirculation matrix of flows (excludes resource and output rows)
            % opB: Leontief inverse (eye - mG)^{-1}; maps final demands to total flow exergy
			fpm=obj.FlowProcessModel;
            mG=fpm.mF(:,1:N)*fpm.mP(1:N,:)+fpm.mV;
            opB=eye(M)/(eye(M)-mG);
            obj.mpL=fpm.mP(1:N,:)*fpm.mL;  % Used later for flow ICT computation
            obj.flowOperators=struct('mG',mG,'opB',zerotol(opB));
            % --- PF-framework operators ---
            % mPF: product-to-fuel unit flow ratios (normalized TableFP columns by fuel exergy)
            % mKP: mPF scaled by unit consumption vK (the consumption matrix)
            % opP: (eye - mKP)^{-1}; unit cost propagation operator
            % opI: scaleRow(opP, vk1); maps irreversibilities to their unit cost contributions
            tfp=obj.TableFP;        
            mPF=divideCol(tfp(:,1:N),obj.FuelExergy);
            mKP=scaleCol(mPF,vK);
            opP=eye(N)/(eye(N)-mKP(1:N,:));
            opI=scaleRow(opP,vk1);
            obj.pfOperators=struct('mPF',mPF,'mKP',mKP,'opP',opP,'opI',opI);
            % --- FP-framework operators ---
            % mFP: fuel-to-product unit flow ratios (normalized TableFP rows by product exergy)
            % opCP: resource-equivalent of opP, adjusted for product scaling
            mFP=divideRow(tfp(1:N,:),obj.ProductExergy);
            opCP=similarResourceOperator(opP,obj.ProductExergy);
            obj.fpOperators=struct('mFP',mFP,'opCP',opCP);
            obj.DefaultGraph=cType.Tables.PROCESS_ICT;
            % --- Waste operators (optional) ---
            % Only initialized when a cWasteData object is provided and waste processes exist
            if (nargin==2) && (obj.NrOfWastes>0)
				obj.isWaste=true;
                setWasteTable(obj,wd)
                wlog=obj.updateWasteOperators;
                if ~wlog.status
                    obj.addLogger(wlog);
                    obj.messaggeLogger(cType.ERROR,cMessages.InvalidWasteOperator,obj.State);
                end
            end
		end

        function res=get.SystemOutput(obj)
        % Returns the last column of TableFP (rows 1:N), i.e. the exergy
        % delivered by each process directly to the plant final product.
            res=cType.EMPTY;
            if obj.status
                res=obj.TableFP(1:end-1,end);
            end
        end
        
        function res=get.FinalDemand(obj)
        % Returns the effective final demand vector.
        % For productive processes this equals SystemOutput.
        % For waste (dissipative) processes the output is scaled by RecycleRatio
        % to account for the fraction of waste exergy recovered as useful product.
            res=obj.SystemOutput;
            if obj.status && obj.isWaste
                idx=obj.ps.Waste.processes;
                res(idx)=scaleRow(obj.TableFP(idx,end),obj.RecycleRatio);
            end
        end    
                
        function res=get.Resources(obj)
        % Returns the last row of TableFP (columns 1:N), i.e. the external
        % resource exergy consumed by each process.
            res=cType.EMPTY;
            if obj.status
                res=obj.TableFP(end,1:end-1);
            end
        end

        function res=get.SystemUnitCost(obj)
        %SystemUnitCost - Get the plant-level unit exergy cost.
        %   Computes the ratio of total resource exergy to total effective final demand,
        %   accounting for waste recycling contributions to the final product.
        %
        %   Syntax:
        %     res = obj.SystemUnitCost
        %   Output Arguments:
        %     res - (double) Scalar plant-level unit cost [kJ_resource / kJ_product]
        %  
            res=cType.EMPTY;
            if obj.status
                res=sum(obj.Resources)/sum(obj.FinalDemand);
            end
        end
                    
        function res=get.RecirculationFactor(obj)
        % Returns the diagonal of opCP as a row vector.
        % Each element quantifies the fraction of a process product cost that
        % originates from internal recirculation rather than external resources.
            res=cType.EMPTY;
            if obj.status
                res=diag(obj.fpOperators.opCP)';
            end
        end
    
        function res=get.WasteWeight(obj)
        % Returns the self-loop diagonal weights of the waste cost operator opR
        % (one scalar per waste process). A weight > 1 indicates amplification
        % of costs due to mutual waste allocation between processes.
            res=cType.EMPTY;
            if obj.isWaste
                opR=obj.fpOperators.opR;
                res=diag(opR.mValues(:,opR.mRows))';
            end
        end

        function res=get.WasteAllocationRatios(obj)
        % Returns the normalized waste allocation matrix mRP.mValues [NR x N].
        % Entry (i,j) gives the fraction of waste process i's cost assigned to process j.
            res=obj.fpOperators.mRP.mValues;
        end
    
        function res=buildResultInfo(obj,fmt,options)
        %buildResultInfo - Get the cResultInfo object for thermoeconomic analysis
        %   Syntax:
        %     res=obj.buildResultInfo(fmt,options)
        %   Input Arguments:
        %     fmt - cResultTableBuilder object
        %     options - structure indicating the table to obtain
        %       DirectCost: get direct cost tables (true | false)
        %       GeneralCost: get generalized cost tables (true | false)
        %
            if nargin==2
                options.DirectCost=true;
                options.GeneralCost=false;
            end
            res=fmt.getCostResults(obj,options);
        end

        function res=getSpectralRatio(obj)
        %getSpectralRatio - Get the spectral ratio of the productive structure matrix.
        %   The spectral radius of mFP determines whether the cost equations have a
        %   unique solution. A value < 1 guarantees convergence of the cost series.
        %
        %   Syntax:
        %     res = obj.getSpectralRatio
        %   Output Arguments:
        %     res - (double) Spectral radius (absolute value of dominant eigenvalue of mFP)
        %
            N=obj.NrOfProcesses;
            res=abs(eigs(obj.mFP(:,1:N),1));
        end
   
        function res=getProcessCost(obj,rsc)
		%getProcessCost - Get absolute cost of processes (direct or generalized).
        %   Without rsc, computes the direct exergy cost (resources valued at their
        %   exergy content). With rsc, computes the generalized cost including
        %   external resource prices and capital/O&M expenditures (Z).
        %
        %   Syntax:
        %     res = obj.getProcessCost
        %     res = obj.getProcessCost(rsc)
		%   Input Arguments:
		%     rsc - (cResourceData) External resource cost data [optional]
		%   Output Arguments:
		%     res - (struct) Cost components per process:
        %       Z   - capital/O&M cost vector (zero for direct cost)
        %       CPE - cost due to resource exergy
        %       CPZ - cost due to capital expenditures
        %       CPR - cost allocated from waste processes
        %       CP  - total product cost (CPE + CPZ + CPR)
        %       CF  - fuel cost vector
        %       CR  - waste cost received by each productive process
        %
            res=struct();
            czoption=(nargin==2);
			N=obj.NrOfProcesses;
			zero=zeros(1,N);
            aux=obj.fpOperators;
			if czoption % Generalized cost: use external resource prices and Z
                Ce=rsc.Ce;      % Resource cost vector (monetary or exergo-economic)
                res.Z=rsc.Z;    % Capital/O&M cost per process
				res.CPE=Ce * aux.opCP;
				res.CPZ=res.Z * aux.opCP;
			else % Direct cost: resource cost equals resource exergy from TableFP
                res.Z=zero;
				Ce=obj.TableFP(end,1:N);
				res.CPE=Ce * aux.opCP;
				res.CPZ=zero;
			end
            % Waste cost allocation (only when dissipative processes are defined)
			if obj.isWaste
				res.CPR=(res.CPE+res.CPZ) * aux.opR;  % Cost received from waste allocation
				res.CP=res.CPE + res.CPZ + res.CPR;
				res.CR=res.CP * aux.mRP;               % Cost charged to waste processes
			else
				res.CPR=zero;
				res.CP=res.CPE+res.CPZ;
				res.CR=zero;
			end
            % Fuel cost: sum of resource cost and cost flowing in from other processes
			res.CF= Ce+res.CP*obj.fpOperators.mFP(:,1:end-1);
		end

        function res = getProcessUnitCost(obj,rsc)
    	%getProcessUnitCost - Get unit cost of processes (direct or generalized).
        %   Without rsc, computes the direct unit exergy cost (ce = 1 for all resources).
        %   With rsc, computes the generalized unit cost including external resource
        %   unit prices (ce) and specific capital/O&M costs (zP).
        %
        %   Syntax:
        %     res = obj.getProcessUnitCost
        %     res = obj.getProcessUnitCost(rsc)
		%   Input Arguments:
		%     rsc - (cResourceData) External resource cost data [optional]
		%   Output Arguments:
		%     res - (struct) Unit cost components per process:
        %       k   - unit consumption vector (kj = Fj/Pj)
        %       cPE - unit cost due to resource exergy
        %       cPZ - unit cost due to capital expenditures
        %       cPR - unit cost allocated from waste processes
        %       cP  - total unit product cost (cPE + cPZ + cPR)
        %       cF  - unit fuel cost
        %       cR  - unit waste cost charged to productive processes
        %
            res=struct();
            czoption=(nargin==2);
            N=obj.NrOfProcesses;
            zero=zeros(1,N);
            res.k=obj.UnitConsumption;
            if czoption % Generalized cost: use external unit resource prices and specific Z
                ce= rsc.ce;             % Unit cost of each resource [cost/exergy]
                ke=ce .* res.k;         % Resource unit cost weighted by consumption
                res.cPE= ke * obj.pfOperators.opP;
                res.cPZ= rsc.zP * obj.pfOperators.opP;
            else % Direct cost: resources valued at unit exergy (ce from last row of mPF)
                ce=obj.pfOperators.mPF(end,:);
                ke=ce .* res.k;
                res.cPE= ke * obj.pfOperators.opP;
                res.cPZ= zero;
            end
            % Waste cost allocation (only when dissipative processes are defined)
            if obj.isWaste
                res.cPR=(res.cPE+res.cPZ)*obj.pfOperators.opR;
                res.cP=res.cPE+res.cPZ+res.cPR;
                res.cR=res.cP*obj.pfOperators.mKR;  % Unit cost charged to waste processes
            else
                res.cPR=zero;
                res.cP=res.cPE+res.cPZ;
                res.cR=zero;
            end
            % Unit fuel cost: resource unit cost plus cost flowing in from other processes
            res.cF=ce+res.cP*obj.pfOperators.mPF(1:end-1,1:end);
        end  

        function res=getFlowsCost(obj,rsc)
        %getFlowsCost - Get the absolute and unit exergy cost of all flows.
        %   Without rsc, computes the direct exergy cost using opB (Leontief inverse),
        %   where each resource flow contributes with unit exergy cost = 1.
        %   With rsc, computes the generalized cost using external resource unit prices
        %   (c0) and capital/O&M specific costs (zP) distributed over flows.
        %
        %   Syntax:
        %     res = obj.getFlowsCost
        %     res = obj.getFlowsCost(rsc)
        %   Input Arguments:
		%     rsc - (cResourceData) External resource cost data [optional]
        %   Output Arguments:
        %     res - (struct) Cost components for each flow:
        %       B   - flow exergy vector
        %       cE  - unit cost due to resource exergy
        %       CE  - absolute cost due to resource exergy (cE .* B)
        %       cZ  - unit cost due to capital expenditures (zero for direct cost)
        %       CZ  - total capital cost (cZ .* B)
        %       cR  - unit cost allocated from waste flows
        %       CR  - total waste cost (cR .* B)
        %       c   - total unit cost (cE + cZ + cR)
        %       C   - total absolute cost (CE + CZ + CR)
        %
            res=struct();
            czoption=(nargin==2);
            zero=zeros(1,obj.NrOfFlows);	   
            aux=obj.flowOperators;
            res.B=obj.FlowsExergy;
            fpm=obj.FlowProcessModel;
            idx=obj.ps.ResourceFlows;  % Indices of external resource flows
            if czoption % Generalized cost: propagate external unit prices through opB
                zB = rsc.zP * fpm.mP(1:end-1,:);   % Capital cost distributed to flows via process-flow mapping
                res.cE = rsc.c0(idx) * aux.opB(idx,:);
                res.CE = res.cE .* res.B;
                res.cZ = zB * aux.opB;  
                res.CZ = res.cZ .* res.B;
            else % Direct cost: each resource flow has unit cost = 1; sum rows of opB for resource rows
                res.cE = sum(aux.opB(idx,:),1);
                res.CE = res.cE .* res.B;
                res.cZ = zero;
                res.CZ = zero;
            end
            % Waste cost allocation across flows (only when dissipative processes are defined)
            if obj.isWaste
                res.cR = (res.cE + res.cZ) * aux.opR;
                res.CR = res.cR .* res.B;
                res.c = res.cE + res.cZ + res.cR;
                res.C = res.CE + res.CZ+res.CR;
            else
                res.cR = zero;
                res.CR = zero;
                res.c = res.cE+res.cZ;
                res.C = res.CE+res.CZ;
            end
        end
        
        function res=getStreamsCost(obj,fcost)
        %getStreamsCost - Get the absolute and unit exergy cost of productive streams.
        %   Aggregates flow costs into stream costs using flows2Streams, matching the
        %   stream grouping defined by the productive structure. The presence of a CZ
        %   field in fcost determines whether generalized costs are included.
        %
        %   Syntax:
        %     res = obj.getStreamsCost(fcost)
        %   Input Arguments:
		%     fcost - (struct) Flow cost structure returned by getFlowsCost; must contain CE
        %   Output Arguments:
        %     res - (struct) Cost components for each productive stream:
        %       E   - stream exergy vector
        %       CE  - absolute cost due to resource exergy
        %       cE  - unit cost due to resource exergy
        %       CR  - absolute waste cost (zero if no waste)
        %       cR  - unit waste cost (zero if no waste)
        %       CZ  - absolute capital cost (only if fcost contains CZ)
        %       cZ  - unit capital cost (only if fcost contains CZ)
        %       C   - total absolute cost
        %       c   - total unit cost
        %
            res=struct();
            % Validate the input flow cost structure
            if (nargin~=2) || ~isstruct(fcost) || ~isfield(fcost,'CE')
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument,'fcost');
                return
            end
            zero=zeros(1,obj.NrOfStreams);
            res.E=obj.StreamsExergy.E;
            % Aggregate flow costs to stream level
            res.CE=obj.ps.flows2Streams(fcost.CE);
            res.cE=vDivide(res.CE,res.E);
            % Aggregate waste costs to stream level
            if obj.isWaste
                res.CR=obj.ps.flows2Streams(fcost.CR);
                res.cR=vDivide(res.CR,res.E);
            else
                res.CR=zero;
                res.cR=zero;
            end
            % Include capital cost if fcost was produced by a generalized cost calculation
            if isfield(fcost,'CZ')
                res.CZ=obj.ps.flows2Streams(fcost.CZ);
                res.cZ=vDivide(res.CZ,res.E);
                res.C=res.CE+res.CR+res.CZ;
                res.c=res.cE+res.cR+res.cZ;
            else
                res.C=res.CE+res.CR;
                res.c=res.cE+res.cR;
            end
        end

        function res = getCostTableFP(obj,ucost)
        %getCostTableFP - Get the FP Cost Table scaled by process unit costs.
        %   Each row of TableFP is multiplied by the corresponding unit cost cPE,
        %   so entries represent cost flows rather than exergy flows. The last row
        %   (resources) is kept at scale 1 (resource exergy equals its direct cost).
        %
        %   Syntax:
        %     res = obj.getCostTableFP
        %     res = obj.getCostTableFP(ucost)
        %   Input Arguments:
        %     ucost - (struct) Unit cost structure from getProcessUnitCost [optional]
        %   Output Arguments:
        %     res - (double) Matrix [N+1 x N+1] of cost-scaled FP table values
        %
            if nargin==1
                ucost=obj.getProcessUnitCost;
            end
            aux=[ucost.cPE,1];  % Scale factor: unit cost for each process, 1 for resource row
            res=scaleRow(obj.TableFP,aux);
        end

        function res = getDirectCostTableFPR(obj,ucost)
        %getDirectCostTableFPR - Get the direct-cost FPR table.
        %   Builds the FPR (Fuel-Product-Residue) cost table for direct exergy costs.
        %   For waste processes, the product column is replaced by the recycled fraction
        %   (TableFP * RecycleRatio) and the fuel columns by the waste allocation TableR.
        %   Each productive row is scaled by the total unit product cost cP.
        %
        %   Syntax:
        %     res = obj.getDirectCostTableFPR
        %     res = obj.getDirectCostTableFPR(ucost)
        %   Input Arguments:
        %     ucost - (struct) Unit cost structure from getProcessUnitCost [optional]
        %   Output Arguments:
        %     res - (double) Matrix [N+1 x N+1] of direct-cost FPR table values
        %
            if nargin==1
                ucost=obj.getProcessUnitCost;
            end	
            N=obj.NrOfProcesses;
            aux=obj.TableFP(end,:);   % Resource row (unchanged)
            tmp=obj.TableFP(1:N,:);   % Process rows (to be modified for waste)
            if obj.isWaste
                % Replace waste process rows with allocation-weighted values
                tR=obj.TableR;
                recycle=scaleRow(obj.TableFP(tR.mRows,end),obj.RecycleRatio);
                tmp(tR.mRows,:)=[tR.mValues,recycle];
            end
            res=[scaleRow(tmp,ucost.cP);aux];
        end 
    
        function res = getGeneralCostTableFPR(obj,rsc,ucost)
        %getGeneralCostTableFPR - Get the generalized-cost FPR table.
        %   Extends getDirectCostTableFPR by replacing the resource row with the
        %   actual monetary (or exergo-economic) cost of resources: Ce = ce .* vF,
        %   plus capital/O&M expenditures Z. Each productive row is scaled by the
        %   generalized unit product cost cP.
        %
        %   Syntax:
        %     res = obj.getGeneralCostTableFPR(rsc)
        %     res = obj.getGeneralCostTableFPR(rsc, ucost)
        %   Input Arguments:
        %     rsc   - (cResourceData) External resource cost data
        %     ucost - (struct) Generalized unit cost structure from getProcessUnitCost(rsc) [optional]
        %   Output Arguments:
        %     res - (double) Matrix [N+1 x N+1] of generalized-cost FPR table values
        %
            if nargin<3
                ucost=obj.getProcessUnitCost(rsc);
            end	
            N=obj.NrOfProcesses;
            % Resource row: monetary cost of process fuels plus capital expenditures
            Ce= rsc.ce .* obj.ProcessesExergy.vF(1:N);  % Cost rate = unit price × fuel exergy
            aux=[Ce+rsc.Z,0];
            tmp=obj.TableFP(1:N,:);
            % Replace waste process rows with allocation-weighted values
            if obj.isWaste
                tR=obj.TableR;
                recycle=scaleRow(obj.TableFP(tR.mRows,end),obj.RecycleRatio);
                tmp(tR.mRows,:)=[tR.mValues,recycle];
            end
            res=[scaleRow(tmp,ucost.cP);aux];
        end 

        function [pict,fict]=getIrreversibilityCostTables(obj,rsc)
        %getIrreversibilityCostTables - Get process and flow Irreversibility Cost Tables (ICT).
        %   The ICT decomposes the cost of each process into contributions from the
        %   irreversibilities of every other process. Entry (i,j) of pict gives the
        %   unit cost charged to process j due to the irreversibility of process i.
        %   Without rsc, the direct ICT is returned (cn = 1). With rsc, the generalized
        %   ICT uses the minimum cost vector cn from getMinCost.
        %   fict extends pict to the flow level via the process-to-flow mapping mpL.
        %
        %   Syntax:
        %     pict = obj.getIrreversibilityCostTables
        %     pict = obj.getIrreversibilityCostTables(rsc)
        %     [pict,fict] = obj.getIrreversibilityCostTables(rsc)
        %   Input Arguments:
        %     rsc  - (cResourceData) External resource cost data [optional]
        %   Output Arguments:
        %     pict - (double) Matrix [N+1 x N] of process ICT values; last row is cn
        %     fict - (double) Matrix [N+1 x M] of flow ICT values; last row is cm
        %
            narginchk(1,2);
            N=obj.NrOfProcesses;
            M=obj.NrOfFlows;
            fpm=obj.FlowProcessModel;
            pf=obj.pfOperators;
            czoption=(nargin==2);
            % Build the process-level ICT matrix:
            % ict(i,j) = cost of process j attributed to irreversibility of process i
            if czoption
                cn=obj.getMinCost(rsc);           % Generalized minimum unit costs
                ict=zerotol(scaleRow(pf.opI,cn)); % Scale opI rows by cn
            else
                cn=ones(1,N);                     % Direct cost: unit cost = 1 for all processes
                ict=zerotol(pf.opI);
            end
            % Add waste allocation cost contribution to ict
            if obj.isWaste
                cin=cn+sum(ict);         % Effective cost including irreversibility contributions
                mopCR=scaleRow(pf.opR,cin);
                ict=ict+mopCR;
            end
            pict=[ict;cn];  % Append the reference cost row (cn)
            if nargout==1
                return
            end
            % Project process ICT onto flows using mpL = mP(1:N,:)*mL
            if czoption
                cm=rsc.c0*fpm.mL+cn*obj.mpL;  % Generalized flow reference cost
            else
                cm=ones(1,M);                  % Direct cost: unit flow cost = 1
            end
            fict=[ict*obj.mpL;cm];
        end

        function [frsc,prsc,idx]=getResourcesCostDistribution(obj,rsd)
        %getResourcesCostDistribution - Get the resource cost distribution across flows and processes.
        %   Decomposes the exergy (or monetary) cost of each flow and process into
        %   contributions from individual resource flows, using the Leontief operator opB.
        %   Without rsd, each resource flow contributes with unit weight (direct exergy cost).
        %   With rsd, each resource flow is weighted by its unit cost c0 (generalized cost).
        %
        %   Syntax:
        %     [frsc, prsc, idx] = obj.getResourcesCostDistribution
        %     [frsc, prsc, idx] = obj.getResourcesCostDistribution(rsd)
        %   Input Arguments:
        %     rsd - (cResourceData) External resource cost data [optional]
        %   Output Arguments:
        %     frsc - (double) Matrix [NR x M] of resource cost distribution over flows;
        %            entry (r,j) is the cost of flow j attributed to resource r
        %     prsc - (double) Matrix [NR x N] of resource cost distribution over processes
        %     idx  - (integer) Indices of resource flows in the full flow list
        %
            narginchk(1,2);
            czoption=(nargin==2);
            idx=obj.ps.ResourceFlows;   % Row indices of resource flows in opB
            opB=obj.flowOperators.opB;
            fpm=obj.FlowProcessModel;
            % Flow-level distribution: rows of opB for resource flows, optionally weighted by c0
            if czoption
                c0=rsd.c0(idx);               % Unit cost of each resource flow
                frsc=scaleRow(opB(idx,:),c0); % Weight each resource row by its unit cost
            else
                frsc=opB(idx,:);              % Unit-weighted (direct exergy cost)
            end
            % Project flow distribution onto processes via the flow-process mapping
            prsc=frsc*fpm.mF(:,1:end-1);
        end

        function log=updateWasteOperators(obj)
        %updateWasteOperators - Recompute waste allocation ratios and all waste cost operators.
        %   Iterates over each waste (dissipative) process and computes its allocation
        %   vector according to the strategy defined in WasteTable (MANUAL, RESOURCES,
        %   COST, EXERGY, IRREVERSIBILITY, or HYBRID). The resulting normalized allocation
        %   matrix sol is then used to build the waste cost operators opR/mKR/mRP and
        %   update the relevant operator structs.
        %
        %   This method is called automatically by the constructor when waste data is
        %   provided, and can be called explicitly after modifying WasteTable externally.
        %
        %   Syntax:
        %     log = obj.updateWasteOperators
        %   Output Arguments:
        %     log - (cMessageLogger) Log object; check log.status for errors
        %
            log=cMessageLogger();
            if ~obj.isWaste
                log.messageLog(cType.ERROR,cMessages.NoWasteModel);
                return
            end
            % Extract working variables
            wt=obj.WasteTable;
            NR=wt.NrOfWastes;       % Number of waste (dissipative) processes
            N=obj.NrOfProcesses;
            M=obj.NrOfFlows;
            aR=wt.Processes;        % Indices of waste processes
            aP=setdiff(1:N,aR);     % Indices of productive processes
            tmp=zeros(1,N);         % Scratch allocation vector for one waste process
            sol=zeros(NR,N);        % Allocation matrix (NR rows, N columns)
            % Cache operator references to avoid repeated struct field access
            tFP=obj.TableFP;
            mKP=obj.pfOperators.mKP;
            opP=obj.pfOperators.opP;
            opI=obj.pfOperators.opI;
            opCP=obj.fpOperators.opCP;
            vP=obj.ProductExergy;
            % Pre-compute direct exergy cost vector only if COST-type allocation is used
            if (any(wt.TypeId==cType.WasteAllocation.COST))
                cp=obj.computeCostR(aR);
            end
            % Build allocation row for each waste process according to its allocation type
            for i=1:NR
                j=aR(i);  % Global process index for the i-th waste process
                if ~obj.ActiveProcesses(j)
                    log.messageLog(cType.WARNING,cMessages.ProcessNotActive,obj.ps.ProcessKeys{j});
                    continue
                end 
                key=wt.Names{i};      
                switch wt.TypeId(i)
                    case cType.WasteAllocation.MANUAL
                        % User-specified allocation weights; zero out inactive processes
                        tmp=wt.getValues(key);
                        tmp(~obj.ActiveProcesses)=0.0;
                    case cType.WasteAllocation.RESOURCES  
                        % Proportional to resource consumption weighted by cost operator opP
                        tmp(aP)=mKP(end,aP).*opP(aP,j)';
                    case cType.WasteAllocation.COST
                        % Proportional to direct exergy cost times fuel received from waste j
                        tmp(aP)=cp(aP).*tFP(aP,j)';
                    case cType.WasteAllocation.EXERGY
                        % Proportional to fuel exergy received by each process from waste j
                        tmp(aP)=tFP(aP,j)';            
                    case cType.WasteAllocation.IRREVERSIBILITY
                        % Proportional to irreversibility cost attributed to waste j
                        tmp(aP)=opI(aP,j);
                        case cType.WasteAllocation.HYBRID
                        % Hybrid: exergy proportion plus irreversibility contribution
                        tmp(aP)=tFP(aP,j)';
                        tmp=tmp/sum(tmp);          % Normalize exergy part first
                        tmp(aP)=tmp(aP)+opI(aP,j)';
                    otherwise
                        log.messageLog(cType.ERROR,cMessages.InvalidWasteType,wt.Type{i},key);
                        return
                end
                if isempty(find(tmp,1))				
                    log.messageLog(cType.ERROR,cMessages.NoWasteAllocationValues,key);
                    return
                end
                sol(i,:)=tmp/sum(tmp);  % Normalize to obtain allocation ratios
            end
            % Scale by (1 - RecycleRatio) so recycled fraction does not enter allocation
            sol=scaleRow(sol,1-wt.RecycleRatio);
            % Verify that the waste-inclusive cost system still has a unique solution
            mS=sol*opCP(:,aR);
            if ~isProductiveMatrix(mS)
                log.messageLog(cType.ERROR,cMessages.InvalidWasteDefinition);
                return
            end
            % Build sparse waste allocation matrices and update all operator structs
            mRP=cSparseRow(aR,sol);             % Sparse allocation matrix mRP [NR x N]
            obj.TableR=scaleRow(mRP,vP);         % Exergy-weighted allocation table
            mKR=divideCol(obj.TableR,vP);        % Unit waste cost matrix
            opR=cExergyCost.getOpR(mKR,opP);     % PF-framework waste cost operator
            wflows=obj.ps.Waste.flows;
            wt.updateValues(sol);
            obj.WasteTable=wt;
            obj.fpOperators.mRP=mRP;
            obj.fpOperators.opR=cExergyCost.getOpR(mRP,opCP);            % FP-framework waste operator
            obj.pfOperators.mKR=mKR;
            obj.pfOperators.opR=opR;
            obj.flowOperators.opR=cSparseRow(wflows,opR.mValues*obj.mpL,M);  % Flow-level waste operator
            obj.RecycleRatio=wt.RecycleRatio;
        end 
    end
    
    methods(Static)
        function res=updateOperator(op,opR)
        %updateOperator - Add waste cost contributions to a base cost operator.
        %   Computes op + op*opR, which accounts for the indirect cost amplification
        %   caused by waste allocation back into the productive processes.
        %
        %   Syntax:
        %     res = cExergyCost.updateOperator(op, opR)
        %   Input Arguments:
        %     op  - (double) Base cost operator matrix
        %     opR - (cSparseRow) Waste cost operator
        %   Output Arguments:
        %     res - (double) Updated operator: op + op*opR
        %
            res=op+op*opR;
        end

        function res=getOpR(mR,opL)
        %getOpR - Build the waste cost operator from an allocation matrix and a cost operator.
        %   Solves the fixed-point equation for waste cost recycling:
        %     opR = (I - mR.mValues * opL(:, mR.mRows))^{-1} * (mR.mValues * opL)
        %   The result captures how waste costs propagate back through the system
        %   via the allocation matrix mR and the base cost operator opL.
        %
        %   Syntax:
        %     res = cExergyCost.getOpR(mR, opL)
        %   Input Arguments:
        %     mR  - (cSparseRow) Sparse waste allocation matrix (fields: mValues, mRows, NR)
        %     opL - (double) Base cost operator (opP or opCP depending on framework)
        %   Output Arguments:
        %     res - (cSparseRow) Waste cost operator with same sparsity pattern as mR
        %
            tmp=mR.mValues*opL;
            opR=(eye(mR.NR)-tmp(:,mR.mRows))\tmp;
            res=cSparseRow(mR.mRows,opR);
        end
	end

    methods(Access=private)
        function setWasteTable(obj,wd)
        %setWasteTable - Validate and store the cWasteData object.
        %   Called once from the constructor before updateWasteOperators.
        %
        %   Input Arguments:
        %     wd - (cWasteData) Waste definition object to store
            if ~obj.isWaste
                obj.messageLog(cType.ERROR,cMessages.NoWasteModel);
                return
            end
            if ~isObject(wd,'cWasteData')
                obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(wd));
                return
            end
            obj.WasteTable=wd;
        end

        function res=getMinCost(obj,rsc)
        %getMinCost - Compute the minimum generalized unit cost vector.
        %   Solves (ce + zF) * (I - mPF)^{-1} for the process-level minimum unit cost,
        %   which is used as the reference cost vector cn in the generalized ICT.
        %
        %   Input Arguments:
        %     rsc - (cResourceData) External resource cost data
        %   Output Arguments:
        %     res - (double) Row vector [1xN] of minimum generalized unit costs
            N=obj.NrOfProcesses;
            res=(rsc.ce+rsc.zF)/(eye(N)-obj.pfOperators.mPF(1:N,:));
        end
    
        function cp=computeCostR(obj,aR)
	    %computeCostR - Compute process unit costs accounting for waste fuel contributions.
        %   Used internally during COST-type waste allocation to avoid circular dependency.
        %   Modifies the consumption matrix by treating fuel received from waste processes
        %   as a diagonal self-contribution, then solves the resulting linear system.
        %
        %   Input Arguments:
        %     aR - (integer vector) Indices of waste (dissipative) processes
        %   Output Arguments:
        %     cp - (double) Row vector [1xN] of unit production costs including waste fuel
		    N=obj.NrOfProcesses;
		    tmp=zeros(N,N);
		    aP=setdiff(1:N,aR);                          % Productive process indices
		    tmp(:,aP)=obj.pfOperators.mKP(1:N,aP);       % Fill productive columns of consumption matrix
		    ke=obj.pfOperators.mKP(end,:);               % Resource row of the consumption matrix
            % Add waste fuel contribution to the diagonal of productive process block
            tmp(aP, aP) = tmp(aP, aP) + diag(sum(obj.fpOperators.mFP(aP,aR),2));
		    cp=ke/(eye(N)-tmp);
        end
    end
end