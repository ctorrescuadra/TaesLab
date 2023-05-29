classdef (Abstract) cReadModelStruct < cReadModel
% cReadModelStruct Abstract class to read structured data model
%   This class derives cReadModelJSON and cReadModelXML
%   Methods:
%		res=obj.buildDataModel(sd)
%		res=obj.getTableModel
%	Methods inhereted from cReadModel
%		res=obj.getStateName(id)
%		res=obj.getStateId(name)
%   	res=obj.existState()
%   	res=obj.getResourceSample(id)
%   	res=obj.getSampleId(sample)
%		res=obj.existSample(sample)
%	    res=obj.getWasteFlows;
%		res=obj.checkModel;
%   	log=obj.saveAsMAT(filename)
%   	log=obj.saveDataModel(filename)
%   	res=obj.readExergy(state)
%   	res=obj.readResources(sample)
%   	res=obj.readWaste
%   	res=obj.readFormat
%	See also cReadModel, cReadModelJSON, cReadModelXML
%
    methods
		function buildDataModel(obj,sd)
		% Check and build Data Model.
		%	Add cModelData and cProductiveStructure object to the class
		%	Input:
		%	sd - cModelData
			ps=cProductiveStructure(sd.ProductiveStructure);
			if isValid(ps)
				% Exist Waste and is not defined, then takes the default value
                if (ps.NrOfWastes>0) && isempty(sd.WasteDefinition)
                    sd.setWasteDefinition(ps.WasteData);
                end
				obj.ModelData=sd;
				obj.ProductiveStructure=ps;
			else
				obj.addLogger(ps);
			end
			obj.status=ps.status;
		end
		
		function res=getTableModel(obj)
		% Generates a cModelTables object with the data model info
			data=obj.ModelData;
			psdata=data.ProductiveStructure;
            ps=obj.ProductiveStructure;
			tables=struct();
			% Flows Table
			sheet=cType.InputTables.FLOWS;
			tbl=cTableData(psdata.flows);
			tbl.setDescription(sheet);
			tables.(sheet)=tbl;
			fNames=tbl.RowNames;
			% Process Table
			sheet=cType.InputTables.PROCESSES;
			tbl=cTableData(psdata.processes);
			tbl.setDescription(sheet);
			tables.(sheet)=tbl;
			pNames=tbl.RowNames';
			% Exergy Table
			sheet=cType.InputTables.EXERGY;
			rex=data.ExergyStates;
			rowNames=fNames;
			colNames=['key',obj.States];			
			values=zeros(obj.NrOfFlows,obj.NrOfStates);
			for i=1:obj.NrOfStates
				fkey={rex.States(i).exergy.key};
				fId=ps.getFlowId(fkey);
				values(fId,i)=cell2mat({rex.States(i).exergy.value});
			end
			tmp=[colNames;[rowNames',num2cell(values)]];   
			tbl=cTableData(tmp);
			tbl.setDescription(sheet);
			tables.(sheet)=tbl;
			% Format table
			sheet=cType.InputTables.FORMAT;
			fmt=data.Format.definitions;
			tbl=cTableData(fmt);
			tbl.setDescription(sheet);
			tables.(sheet)=tbl;
			% Waste tables
			if (obj.NrOfWastes>0) && obj.isWaste
				% Waste Definition
				sheet=cType.InputTables.WASTEDEF;
                wt=data.WasteDefinition.wastes;
                isWasteAlloc=isfield(wt,'values');
                if isWasteAlloc
				    wt=rmfield(wt,'values');
                end
				tbl=cTableData(wt);
				tbl.setDescription(sheet);
				tables.(sheet)=tbl;
				% Waste Allocation
                if isWasteAlloc
				    sheet=cType.InputTables.WASTEALLOC;
				    rowNames=ps.ProductiveProcesses.key;
				    pprocess=cDictionary(rowNames);
				    colNames=['Process',{wt.flow}];
				    N=pprocess.NrOfEntries;
				    wv=zeros(N,obj.NrOfWastes);
				    for i=1:obj.NrOfWastes
					    dw=data.WasteDefinition.wastes(i).values;
					    wId=cellfun(@(x) pprocess.getIndex(x), {dw.process});
					    wv(wId,i)=[dw.value];
				    end
				    tmp=[colNames;[rowNames',num2cell(wv)]];
				    tbl=cTableData(tmp);
				    tbl.setDescription(sheet);
				    tables.(sheet)=tbl;
                end
			end
			% Resources Cost tables
			if data.isResourceCost
				sheet=cType.InputTables.RESOURCES;
				rsc=data.ResourcesCost;
				colNames=[{'Key','Type'},obj.ResourceSamples];
				%Flows
				rNames=fNames(ps.Resources.flows)';
				rTypes=repmat({'FLOW'},numel(rNames),1);
				rval=zeros(ps.NrOfResources,obj.NrOfResourceSamples);
				for i=1:obj.NrOfResourceSamples
					fId=cellfun(@(x) find(strcmp(rNames,x)), {rsc.Samples(i).flows.key});
					rval(fId,i)=[rsc.Samples(i).flows.value];
				end
				cflow=[rNames,rTypes,num2cell(rval)];
				% Processes
				pval=zeros(obj.NrOfProcesses,obj.NrOfResourceSamples);
				pTypes=repmat({'PROCESS'},obj.NrOfProcesses,1);
				for i=1:obj.NrOfResourceSamples
					pId=ps.getProcessId({rsc.Samples(i).processes.key});
					pval(pId,i)=[rsc.Samples(i).processes.value];
				end
				cprocess=[pNames,pTypes,num2cell(pval)];
				tmp=[colNames;cflow;cprocess];
				tbl=cTableData(tmp);
				tbl.setDescription(sheet);
				tables.(sheet)=tbl;
			end
			res=cModelTables(cType.ResultId.DATA_MODEL,tables);
			res.setProperties(obj.ModelName);
		end		
    end
end