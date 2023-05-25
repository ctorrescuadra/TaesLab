classdef (Abstract) cReadModel < cStatusLogger
% cReadModel Abstract class to implemenent the model reader classes
% 	This class provides general properties and methods to get information
%   of the thermoeconomic model of the plant
% 	Methods:
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
% 	See also cReadModelStruct, cReadModelTable
%
	properties(GetAccess=public,SetAccess=protected)
		NrOfFlows            % Number of Flows
		NrOfProcesses        % Number of Processes
		NrOfWastes=0         % Number of Wastes
        NrOfStates           % Number of States
		States               % States Dictionary
		NrOfResourceSamples  % Number of Resources Samples
		ResourceSamples      % Resources samples Dictionary
		isWaste=0            % Waste Information is defined
		isFormat=0           % Format Information is defined
		isResourceCost=0     % Resource Cost is defined
		isDiagnosis          % Diagnosis is posible (two states defined)
		isTableModel         % Indicates if is a table model
		ProductiveStructure  % Productive Structure
        ModelFile            % File name of the model
        ModelName            % Name of the model
		ModelData            % cModelData object 
	end

	methods	
		function res=get.isTableModel(obj)
		% Check if it is a cReadModelTable
            res=isa(obj,'cReadModelTable');          
		end

		function res=get.isDiagnosis(obj)
			res=(obj.NrOfStates>1);
		end
		
		function res=get.NrOfFlows(obj)
		% Return the number of flows of the system
			res=0;
			if obj.isValid
				res=obj.ProductiveStructure.NrOfFlows;
			end
		end
			
		function res=get.NrOfProcesses(obj)
		% Return the number of processes of the system
			res=0;
			if obj.isValid
				res=obj.ProductiveStructure.NrOfProcesses;
			end
		end
			
		function res=get.NrOfWastes(obj)
		% Return the number of wastes of the system
			res=0;
			if obj.isValid
				res=obj.ProductiveStructure.NrOfWastes;
			end
    	end

		function res=get.NrOfStates(obj)
		% get the number of states
			res=0;
			if ~isempty(obj.States)
				res=numel(obj.States);
			end
		end

		function res=get.NrOfResourceSamples(obj)
		% get the number of resources samples
			res=0;
			if ~isempty(obj.ResourceSamples) && obj.isResourceCost
				res=numel(obj.ResourceSamples);
			end
		end

		function res=getStateName(obj,ind)
		% Return the state name of the corresponding index
		% Input:
		%  ind - state index to retrieve
			res=obj.States{ind};
		end

		function res=getStateId(obj,state)
		% return index of a state
			res=find(strcmp(obj.States,state));
		end
		
		function res=existState(obj,state)
		% determine if state is defined in States
			res=ismember(state,obj.States);
		end

        function res=getResourceSample(obj,ind)
		% Return the state number of the corresponding index
		% Input:
		%  ind - state index to retrieve
			res=obj.ResourceSamples{ind};
		end
		
		function res=getSampleId(obj,sample)
		% Return the state number of the corresponding index
		% Input:
		%  ind - state index to retrieve
			res=find(strcmp(obj.ResourceSamples,sample));
		end
		
		function res=existSample(obj,sample)
		% Determine if sample is defined in ResourceSamples
			res=ismember(sample,obj.ResourceSamples);
        end

		function res=getWasteFlows(obj)
		% Get a cell array of the waste flows
			res={};
			if ~obj.isWaste
				return;
			end
			ps=obj.ProductiveStructure;
			idx=ps.Waste.flows;
			res={ps.Flows(idx).key};
        end

        function res=checkCostTables(obj,value)
            res=false;
            pct=cType.getCostTables(value);
            if cType.isEmpty(pct)
                return
            end
            if bitget(pct,cType.GENERALIZED) && ~obj.isResourceCost
                return
            end
            res=true;
        end

        function res=readExergy(obj,state)
		% get a cReadExergy object with the exergy values of state
			res=cStatusLogger();
            ps=obj.ProductiveStructure;
			if nargin==1
				state=obj.getStateName(1);
			end	
			if ~obj.existState(state)	
				res.messageLog(cType.ERROR,'Invalid Exergy sample %s',state);
				return
			end
			idx=obj.getStateId(state);
			data=obj.ModelData.ExergyStates.States(idx);
			M=numel(data.exergy);
			if M~=ps.NrOfFlows
				res.messageLog('Invalid number of exergy values %d',M);
			else
				res=cReadExergy(data,ps);
			end
		end
		
		function res=readWaste(obj)
		% get a cReadWaste object with waste definition
			res=cStatusLogger;
            ps=obj.ProductiveStructure;
			if obj.isWaste
				data=obj.ModelData.WasteDefinition;
				NR=numel(data.wastes);
                if NR~=ps.NrOfWastes
					res.messageLog(cType.ERROR,'Invalid number of wastes %d',NR);
					return
                end
			else
				data=ps.WasteData;
			end
			res=cReadWaste(data,ps);
		end

		function res=readResources(obj,sample)
		% Get a cReadResources object with the resources cost info
		% 	Input:
		%		exm: cExergyModel object
		%		sample: sample name
			res=cStatusLogger();
            if (nargin==1) || isempty(sample)
                sample=obj.getResourceSample(1);
            end
			if obj.isResourceCost
                if ~obj.existSample(sample)	
					res.messageLog(cType.ERROR,'Invalid Resource sample %s',sample);
					return
                end
				idx=obj.getSampleId(sample);
                tmp=obj.ModelData.ResourcesCost.Samples;
				data.flows=obj.ModelData.ResourcesCost.Samples(idx).flows;
                if isfield(tmp,'processes')
				    data.processes=obj.ModelData.ResourcesCost.Samples(idx).processes;
                end
				res=cReadResources(data,obj.ProductiveStructure);
			end
		end
		
		function res=readFormat(obj)
		% Get a cResultTableBuilder object with the tables format definition
            if obj.isFormat
				data.format=obj.ModelData.Format.definitions;		
            else
				data=struct();
            end
            res=cResultTableBuilder(data,obj.ProductiveStructure);
		end

		function status=checkModel(obj)
		%  checkModel - checks if all elements of the thermoeconomic model are valid, and logs about errors
		%	it is called by CheckDataModel base function
			status=false;
			log=cStatusLogger; % Temporal logger
			if isValid(obj)
				log.messageLog(cType.INFO,'Productive Structure is valid');
			else
				log.messageLog(cType.ERROR,'Productive Structure is NOT valid. See error log');
				return
			end
			status=obj.status;
			% Read and Check Format configuration
			rfmt=obj.readFormat;
			if obj.isFormat
				switch rfmt.status
					case cType.VALID
						log.messageLog(cType.INFO,'Format Configuration is valid');
					case cType.WARNING
						log.addLogger(rfmt);
						log.messageLog(cType.WARNING,'Format Configuration is NOT valid. Default is used')
					otherwise
						log.addLogger(rfmt);
						log.messageLog(cType.ERROR,'Format Configuration is NOT valid. See error log');
				end
				status= status & rfmt.status;
			else
				log.messageLog(cType.INFO,'Format Configuration is not available. Default is used');
			end
				
			% Read and check Exergy Values
			states=obj.States;
			for i=1:obj.NrOfStates
				rex=obj.readExergy(states{i});
				if isValid(rex)
					message=sprintf('Exergy values [%s] are valid',states{i});
					log.messageLog(cType.INFO,message);
				else
					log.addLogger(rex)
					message=sprintf('Exergy values [%s] are NOT valid. See Error Log',states{i});
					log.messageLog(cType.ERROR,message);
				end
				status=status & isValid(rex);
			end
			% Read and check Resources Cost values
			if obj.isResourceCost
				samples=obj.ResourceSamples;
				for i=1:obj.NrOfResourceSamples
					rsc=obj.readResources(samples{i});
					if isValid(rsc)
						message=sprintf('Resources Cost sample [%s] is valid',samples{i});
						log.messageLog(cType.INFO,message);
					else
						status=false;
						log.addLogger(rsc);
						message=sprintf('Resources Cost sample [%s] is NOT valid. See error log',samples{i});
						log.messageLog(cType.ERROR,message);
					end
					status=status & isValid(rsc);
				end
			else
				log.messageLog(cType.INFO,'No Resources Cost Data available')
			end
			% Read and check Waste definition
			if obj.NrOfWastes > 0
				if obj.isWaste
					wd=obj.readWaste;
					if isValid(wd)
						message=sprintf('Waste definition is valid');
						log.messageLog(cType.INFO,message);
					else
						log.addLogger(wd);
						message=sprintf('Waste definition is NOT valid. See error log');
						log.messageLog(cType.ERROR,message);
					end
					status=status & isValid(wd);
				else
					log.messageLog(cType.INFO,'Waste Definition is not available. Default is used');
				end
			else
				log.messageLog(cType.INFO,'The plant has not waste');
			end
			obj.addLogger(log);
			obj.status=status;
		end	

        function log=saveAsMAT(obj,filename)
            log=cStatusLogger(cType.VALID);
            if isOctave
				log.messageLog(cType.ERROR,'Save MAT files is not implemented in Octave');
	            return
            end
			if nargin==1 % Default name
                [~,name]=fileparts(obj.ModelFile);
                filename=strcat(name,cType.FileExt.MAT);
			end
			% Determine fullfile
			path=fileparts(filename);
            if isempty(path)
				fname=fullfile(pwd,filesep,filename);
            end
			obj.setModelFile(fname);
            % Save the object
            try
				save(filename,'obj');
			catch err
                log.messageLog(cType.ERROR,err.message);
                log.messageLog(cType.ERROR,'File %s cannot be written',filename);
            end
		end

		function log=saveDataModel(obj,filename)
		% Save data model depending of filename extension
			log=cStatusLogger(cType.VALID);
			% Check inputs
			if ~isValid(obj)
				log.messageLog(cType.ERROR,'Invalid data model %s',obj.ModelName);
                return
			end
            if ~cType.checkFileWrite(filename)
				log.messageLog(cType.ERROR,'Invalid file name %s',filename);
                return
            end
			% Save data model depending of fileType
			fileType=cType.getFileType(filename);
			switch fileType
				case cType.FileType.JSON
					log=obj.ModelData.saveAsJSON(filename);
                case cType.FileType.XML
                    log=obj.ModelData.saveAsXML(filename);
				case cType.FileType.CSV
					tm=obj.getTableModel;
                    log=tm.saveAsCSV(filename);
				case cType.FileType.XLSX
					tm=obj.getTableModel;
                    log=tm.saveAsXLS(filename);
				case cType.FileType.MAT
					log=obj.saveAsMAT(filename);
				otherwise
					log.messageLog(cType.WARNING,'File extension %s is not supported',filename);
            end
        end                
    end

    methods(Access=protected)
        function setModelProperties(obj)
		% Set data model properties
			sd=obj.ModelData;
        	% Optional variables
			obj.isWaste=sd.isWaste;
			obj.isResourceCost=sd.isResourceCost;
			obj.isFormat=sd.isFormat;
			% Define States and Resource Samples
			obj.States={sd.ExergyStates.States(:).stateId};
            if obj.isResourceCost
				obj.ResourceSamples={sd.ResourcesCost.Samples(:).sampleId};
            end
        end

		function setModelFile(obj,filename)
		% Set the name of the data model file
			obj.ModelFile=filename;
		end	
    end
end