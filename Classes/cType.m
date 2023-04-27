classdef cType
% cType It is a static class to manage the constants of ExIoLab
%  	This class include constants, enumeration types defined as constant structures, 
%  	methods to check the correct type names, and determine the key and value of
%  	the enumerated types.
% cType methods:
%  	res=checkCostAlgorithm(text)
%  	res=checkDiagnosisMethod(text) 
%  	res=checkCostTables(text)
% Check data types methods:
%  	res=checkFlowKey(text)
%  	res=checkProcessKey(text)
%  	res=checkStreamKey(text)
%  	res=checkResourcesKey(text)
%  	res=checkWasteKey(text)
%	res=checkTextKey(key)
% Get key type from id:
%  	key=getCostAlgorithm(id)
%  	key=getDiagnosisMethod(id)
%  	key=getFlowKey(id)
%  	key=getProcessKey(id)
%  	key=getStreamKey(id)
%  	key=getWasteKey(id)
%  	key=getResourcesKey(id)
% Get id from key:
%  	id=getFlowId(key)
%  	id=getProcessId(key)
%  	id=getStreamKey(key)
%  	id=getWasteKey(key)
%  	id=getResourcesKey(key)
% Get type options:
%	res=FlowTypeOptions()
%	res=ProcessTypeOptions()
%	res=StreamTypeOptions()
%	res=WasteTypeOptions()
%	res=CostAlgorithmsOptions()
%	res=CostTablesOptions()
%	res=DiagnosisOptions()
%	res=getInputTables()
% File Methods
%	res=getFileType(filename)
%	res=checkFileWrite(filename)
%	res=checkFileRead(filename)
%	res=checkFileExt(filename,ext)
% Other methods:
%	res=checkTextKey(key)
%	res=getInputTables;
%  	img=getIcon(name)
%  	file=getTaesImage(path)          
%  	text=getTextErrorCode(val)      
%  	id=getFileType(ext)                           
%  	char=getNewline()                               
%  	char=getPathDelimiter()                
%                 
	properties (Constant)
		PRODUCTIVE=1;             % Productive Bit
		ENVIRONMENT=2;            % Environment Bit
		WASTE=3;                  % Waste Bit
        WARNING=-1;               % Warning message
        EMPTY=-1;                 % Empty objectId
        ERROR=0;                  % Error message
        VALID=1;                  % OK
		INFO=1;                   % Info message
        DIRECT=1                  % Direct Cost Tables Bit
        GENERALIZED=2             % Generalized Cost Tables Bit
		CAPACITY=8	              % Initial capacity for cQueue and cStack
		MAX_RESULT=4              % Number of results in cModelResults
		DIRECT_SUMMARY_TABLES=4   % Number of Direct Cost Summary Tables
		GENERAL_SUMMARY_TABLES=8  % Number of Generalized Cost Summary Tables
		FUEL='FUEL'       % Fuel type option text
		PRODUCT='PRODUCT' % Product type option text
		% Types of processes
		Process=struct('PRODUCTIVE',0,'ENVIRONMENT',2,'DISSIPATIVE',4);
        % Types of Streams 
		Stream=struct('FUEL',0,'PRODUCT',1,'OUTPUT',2,'RESOURCE',3,'WASTE',6);
        % Types of Flows
		Flow=struct('INTERNAL',0,'OUTPUT',2,'RESOURCE',3,'WASTE',6);
        % Waste Allocation Types
		WasteAllocation=struct('MANUAL',0,'DEFAULT',1,'RESOURCES',1,'COST',2,'EXERGY',3,'IRREVERSIBILITY',4,'HYBRID',5);
        % Types of Resources
		Resources=struct('FLOW',1,'PROCESS',2);
		% Variable Display Options
        VarMode=struct('CELL',1,'STRUCT',2,'TABLE',3);
		DEFAULT_VARMODE='CELL';
        % Cost Table options
        CostTables=struct('DIRECT',1,'GENERALIZED',2,'ALL',3);
		DEFAULT_COST_TABLES='DIRECT';
        % Optionsfor diagnosis calculation
		Diagnosis=struct('NONE',1,'WASTE_OUTPUT',2,'WASTE_INTERNAL',3);
		DEFAULT_DIAGNOSIS='WASTE_OUTPUT';
		% Input Tables
		InputTables=struct('FLOWS','Flows','PROCESSES','Processes','EXERGY','Exergy',...
							'WASTEDEF','WasteDefinition','WASTEALLOC','WasteAllocation',...
							'RESOURCES','ResourcesCost','FORMAT','Format');
        % Mandatory Tables
        MandatoryTables=1:3;
		OptionalTables=4:7;
		% Data Model
		DataId=struct('PRODUCTIVE_STRUCTURE',1,'EXERGY_STATES',2,'WASTE',3,'RESOURCES',4,'FORMAT',5);
		DataElements={'ProductiveStructure','ExergyStates','WasteDefinition','ResourcesCost','Format'};
		MandatoryData=1:2;
		OptionalData=3:5;
        % Default Results file
        RESULT_FILE='ModelResults';
		SUMMARY_FILE='SummaryResults';
		DIAGRAM_FILE='DiagramFP';
		% Format config file
		CFGFILE='printformat.json';
        % Cell Tables
		CellTable=struct('FLOW_EXERGY_COST',1,'FLOW_GENERALIZED_COST',2,'PROCESS_COST',3,...
			'PROCESS_UNIT_COST',4,'PROCESS_GENERALIZED_COST',5,'PROCESS_GENERALIZED_UNIT_COST',6,...
			'DIAGNOSIS',7,'PROCESS_TABLE',8,'STREAM_TABLE',9,'FLOW_TABLE',10,...
			'PROCESS_EXERGY',11,'STREAM_EXERGY',12,'FLOW_EXERGY',13,'DIAGRAM_FP',14,...
			'COST_DIAGRAM_FP',15,'WASTE_DEFINITION',16);
		% Matrix Tables
		MatrixTable=struct('TABLE_FP',1,'COST_TABLE_FP',2,'COST_TABLE_FPR',3,'GENERALIZED_COST_TABLE',4,...
			'PROCESS_ICT',5,'PROCESS_GENERALIZED_ICT',6,'FLOW_ICT',7,'FLOW_GENERALIZED_ICT',8,...
			'MALFUNCTION_TABLE',9,'MALFUNCTION_COST_TABLE',10,'IRREVERSIBILITY_TABLE',11,...
			'WASTE_ALLOCATION',12,'WASTE_RECYCLING_DIRECT',13,'WASTE_RECYCLING_GENERAL',14);
		SummaryId=struct('PROCESS_DIRECT_COST',1,'PROCESS_DIRECT_UNIT_COST',2,'FLOW_DIRECT_COST',3,'FLOW_DIRECT_UNIT_COST',4,...
			'PROCESS_GENERALIZED_COST',5,'PROCESS_GENERALIZED_UNIT_COST',6,'FLOW_GENERALIZED_COST',7,'FLOW_GENERALIZED_UNIT_COST',8,...
			'EXERGY',9,'UNIT_CONSUMPTION',10);
		SummaryTables=struct('EXERGY','exergy','UNIT_CONSUMPTION','pku','PROCESS_DIRECT_COST','dpc','PROCESS_DIRECT_UNIT_COST','dpuc',...
			'FLOW_DIRECT_COST','dfc','FLOW_DIRECT_UNIT_COST','dfuc','PROCESS_GENERALIZED_COST','gpc',...
			'PROCESS_GENERALIZED_UNIT_COST','gpuc','FLOW_GENERALIZED_COST','gfc','FLOW_GENERALIZED_UNIT_COST','gfuc');
		SummaryTableIndex={'dpc','dpuc','dfc','dfuc','gpc','gpuc','gfc','gfuc'};
		% Type of columns for uitables
        colType={'char','numeric'};   
		% Types of definet formats
		Format=struct('NODE',1,'TEXT',2,'EXERGY',3,'EXERGY_COST',4,'EXERGY_UNIT_COST',5,...
		'GENERALIZED_COST',6,'GENERALIZED_UNIT_COST',7,'DIAGNOSIS',8,'PERCENTAGE',9);
        % Result Id types 
        ResultId=struct('PRODUCTIVE_STRUCTURE',1,'THERMOECONOMIC_STATE',2,'THERMOECONOMIC_ANALYSIS',3,...
            'THERMOECONOMIC_DIAGNOSIS',4,'EXERGY_COST_CALCULATOR',5,'WASTE_ANALYSIS',6,'DIAGRAM_FP',7,...
			'RECYCLING_ANALYSIS',8,'SUMMARY_RESULTS',9,'DATA_MODEL',10,'RESULT_MODEL',11);
		% Names for cModelResults	
		Results={'Productive Structure','Thermoeconomic State','Thermoeconomic Analysis',...
			'Thermoeconomic Diagnosis','Exergy Cost Calculator','Waste Analysis','Diagram FP',...
			'Recycling Analysis','Summary Results','Data Model','Model Results'};
		Tables=struct('FLOW_TABLE','flows','PROCESS_TABLE','processes','STREAM_TABLE','streama',...
			'FLOW_EXERGY','eflows','PROCESS_EXERGY','eprocesses','STREAM_EXERGY','estreams',...
			'TABLE_FP','tfp','DIAGRAM_FP','atfp','COST_DIAGRAM_FP','atcfp',...
			'FLOW_EXERGY_COST','dfcost','FLOW_GENERALIZED_COST','gfcost','PROCESS_COST','dcost',...
			'PROCESS_UNIT_COST','ducost','PROCESS_GENERALIZED_COST','gcost','PROCESS_GENERALIZED_UNIT_COST','gucost',...
			'COST_TABLE_FP','dcfp','COST_TABLE_FPR','dcfpr','GENERALIZED_COST_TABLE','gcfp',...
			'PROCESS_ICT','dict','PROCESS_GENERALIZED_ICT','gict','FLOW_ICT','dfict','FLOW_GENERALIZED_ICT','gfict',...
			'DIAGNOSIS','dgn','MALFUNCTION','mf','MALFUNCTION_COST','mfc','IRREVERSIBILITY_VARIATION','dit',...
			'WASTE_DEFINITION','wd','WASTE_ALLOCATION','wa','WASTE_RECYCLING_DIRECT','rad','WASTE_RECYCLING_GENERAL','rag');
        GraphType=struct('NONE',0,'COST',1,'DIAGNOSIS',2,'DIAGRAM_FP',3,'RECYCLING',4,'SUMMARY',5,'WASTE_ALLOCATION',6,'DIGRAPH',7);
        % File Extension
		FileType=struct('JSON',1,'XLSX',2,'CSV',3,'MAT',4,'XML',5,'TXT',6);
		FileExt=struct('JSON','.json','XLSX','.xlsx','CSV','.csv','MAT','.mat','XML','.xml','TXT','.txt');
		% Icon Files
		IconFile=struct('ProductiveStructure','ps.png','ThermoeconomicState','ts.png','ThermoeconomicAnalysis','ta.png','ThermoeconomicDiagnosis','td.png');
        % Taess app welcome image
		TaesImage='TaesLab.png';
        % Taess app Resources folder
		AppResources='Resources';
		NEWLINE_PC='\r\n';    % Newline character for Windows
		NEWLINE_UNIX='\n';    % Newline character for Unix (MAC)
        MAX_PRINT_COLS=20;    % Maximun cols to print in console
		DELIMITER=',';        % CSV Delimiter
		PATH_PC='\'           % Path Character for Windows
		PATH_UNIX='/'         % Path Character for Unix
		% File Pattern
		FILE_PATTERN='^(?!^(PRN|AUX|CLOCK\$|NUL|CON|COM\d|LPT\d)\..*)^\w+.(xlsx|csv|mat|txt|json|xml)$'
		% Key Text Patter
		KEY_PATTERN='^[A-Z][A-Za-z0-9]+$'
		KEY_LENGTH=2:8
    end
    %----------------------------
    % Static Methods for types
    %----------------------------
	methods (Static)
		function res=isEmpty(arg)
		% check if the type check is valid
			res=(arg==cType.EMPTY);
		end

		function res=checkTypeKey(s,key)
		% Check if key is a field of type structure s
		% Input:
        %   s   - type structure
		%   key - key
        % Output:
        %   res - true/false
			res=false;
			if ischar(key)
            	res= isfield(s,upper(key));
			end
        end
		
		function id=getTypeId(s,key)
        % Get the value of key in the type structure s
		% Input:
        %   s   - type structure
		%   key - type key
        % Output:
        %   id - type id
			id=cType.EMPTY;
			if ischar(key)
				if cType.checkTypeKey(s,key)
					id=s.(upper(key));
				end
			elseif iscell(key)
				try
					id=cellfun(@(x) cType.getTypeId(s,x),key);
				catch
					return
				end
			end
		end
		
		function res=getProcessId(text)
		% Get the internal code of a process type text
			res=cType.getTypeId(cType.Process,text);
		end

		function res=getStreamId(text)
		% Get the internal code of a stream type text
			res=cType.getTypeId(cType.Stream,text);	
		end

		function res=getFlowId(text)
		% Get the internal id of a flow type text
        	res=cType.getTypeId(cType.Flow,text);
		end

		function res=getWasteId(text)
		% Get internal code of a waste allocation type text
            res=cType.getTypeId(cType.WasteAllocation,text);
		end

		function res=getResourcesId(text)
		% Get internal code of a resources cost type text
            res=cType.getTypeId(cType.Resources,text);
        end

		function res=getCostTables(text)
			res=cType.getTypeId(cType.CostTables,text);
		end

		function res=getDiagnosisMethod(text)
		% Get key code of Diagnosis Methods Id
			res=cType.getTypeId(cType.Diagnosis,text);
		end

		function res=getVarMode(text)
			res=cType.getTypeId(cType.VarMode,text);
		end

		function res=checkProcessKey(text)
		% Check if process type text is valid
			res=cType.checkTypeKey(cType.Process,text);
		end

		function res=checkFlowKey(text)
		% Check if flow type text is valid
        	res=cType.checkTypeKey(cType.Flow,text);
		end

		function res=checkWasteKey(text)
		% Check if waste allocation type text is valid
        	res=cType.checkTypeKey(cType.WasteAllocation,text);
		end

		function res=checkResourcesKey(text)
		% Check if resources cost type text is valid
        	res=cType.checkTypeKey(cType.Resources,text);
		end

		function res=checkCostTables(text)
		% Check CostTable value 
			res=cType.checkTypeKey(cType.CostTables,text);
		end

		function res=checkDiagnosisMethod(text)
		% Check DiagnosisMethod value
			res=cType.checkTypeKey(cType.Diagnosis,text);
		end

		function res=checkVarMode(text)
		% Check DiagnosisMethod value
			res=cType.checkTypeKey(cType.VarMode,text);
		end

		function res=FlowTypeOptions()
		% Get a cell array with the Flow Type options
			res=fieldnames(cType.Flow);
		end

		function res=StreamTypeOptions()
		% Get a cell array with the Stream Type options
			res=fieldnames(cType.Stream);
		end

		function res=ProcessTypeOptions()
		% Get a cell array with the Process Type options
			res=fieldnames(cType.Stream);
		end

		function res=WasteTypeOptions()
		% Get a cell array with the Waste Allocation Type options
			res=fieldnames(cType.WasteAllocation);
		end

		function res=CostTablesOptions()
		% Get a cell array with the Cost Tables Type options
			res=fieldnames(cType.CostTables);
		end

		function res=DiagnosisOptions()
		% Get a cell array with the Diagnosis Type options
			res=fieldnames(cType.Diagnosis);
		end
		
		function res=VarModeOptions()
		% Get a cell array with the VarMode Type options
			res=fieldnames(cType.VarMode);
		end

		function res=getInputTables()
		% Get the names of the Input Tables as cell
			res=transpose(struct2cell(cType.InputTables));
        end

		function res=checkTextKey(text)
		% Check if an element key (flow/process) has a correct format
		%	- Its lenght must be bigger than 1 and less than 8
		%   - Satisfy the regular expression cType.KEY_PATTERN
		%	INPUT:
		%		text: key string
		%   OUTPUT:
		%		res: true/false
		%
			res=false;
			if ~ismember(length(text),cType.KEY_LENGTH)
				return
			end
			if isempty(regexp(text,cType.KEY_PATTERN,'once'))
				return
			end
			res=true;
		end

		%%%%
		% File Functions
		%%%%%
		function res=getFileType(filename)
		% Get file type acording its extension (ext)
			[~,~,ext]=fileparts(filename);
			res=cType.ERROR;
			names=fieldnames(cType.FileExt);
			values=struct2cell(cType.FileExt);
			idx=strcmp(values(:),ext);			
			if any(idx)
				field=names{idx};
				res=cType.getTypeId(cType.FileType,field);
			end
		end

		function res=checkFileWrite(filename)
		% Check if file name is valid for write mode 
			res=false;
			if ~ischar(filename)
				return
			end
			if regexp(filename,cType.FILE_PATTERN,'once')
				res=true;
			end
		end

		function res=checkFileRead(filename)
		% Check if file name exists
			res=false;
            if ~ischar(filename)
                return
            end
            [~,file,ext]=fileparts(filename);
			if isempty(regexp(strcat(file,ext),cType.FILE_PATTERN,'once'))
				return
			end
			res=exist(filename,'file');
        end

        function res=checkFileExt(filename,fext)
		% Check if filename has a valid extension
            [~,~,ext]=fileparts(filename);
            res=strcmp(fext,ext);
        end

		%%%
		% Other functions
		%%%
		function res=getTextErrorCode(error)
		% Get the text of the corresponding error code
			switch error
				case cType.VALID
					res='INFO';
				case cType.WARNING
					res='WARNING';
				case cType.ERROR
					res='ERROR';
			end
		end

		function res=getNewline()
		% Get the newline character depending on operating system
			if ispc
				res=cType.NEWLINE_PC;
			else
				res=cType.NEWLINE_UNIX;
			end
		end

		function res=getPathDelimiter()
		% get path delimiter
			if ispc
				res=cType.PATH_PC;
			else
				res=cType.PATH_UNIX;
			end
		end

		function res=getIcon(icon)
		% Get app icons path
			filename=cType.IconFile.(icon);
            path=fileparts(mfilename('fullpath'));         
            if isOctave
				folder='icon32';
            else
                folder='icon16';
            end
		    file=strcat(path,filesep,folder,filesep,filename);
			res=imread(file);
		end

		function res=getTaesImage(path)
		% Get the full path of the Taes Welcome image
		% Input
		%  path - path of the Resources app
			res=strcat(path,filesep,cType.AppResources,filesep,cType.TaesImage);
		end
	end
end		