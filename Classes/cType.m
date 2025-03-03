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
		INVALID=false;            % Invalid status
        VALID=true;               % Valid status
		EMPTY=[];                 % Empty value
		EMPTY_CELL={}             % Empty cell array
        EMPTY_CHAR='';            % Empty char
		INTERNAL=1;               % Internal Streams Bit
		ENVIRONMENT=2;            % Environment Bit
		WASTE=3;                  % Waste Bit
        WARNING=-1;               % Warning message
        ERROR=0;                  % Error message
		INFO=1;                   % Info message
        DIRECT=1                  % Direct Cost Tables Bit
        GENERALIZED=2             % Generalized Cost Tables Bit
		STATES=1                  % States Tables Bit
		RESOURCES=2               % Resources Tables Bit
		CAPACITY=4                % Initial capacity for cQueue and cStack
		MAX_RESULT=5              % Number of Results in cModelResults
		MAX_RESULT_INFO=10        % Maximun cResultInfo groups
		DIRECT_SUMMARY_TABLES=4   % Number of Direct Cost Summary Tables
		GENERAL_SUMMARY_TABLES=8  % Number of Generalized Cost Summary Tables
		EPS=1.0e-8                % Zero value for tolerance
		DEFAULT_NUM_LENGHT=10     % Default number length (use in cTableData)
        TRUE='on'                 % Logical true text
        FALSE='off'               % Logical false text                         
		FUEL='FUEL'               % Fuel type option text
		PRODUCT='PRODUCT'         % Product type option text
		FORMAT_ID='%3d'           % Line number format
		DEBUG_MODE=false
		% Node types
		NodeType=struct('PROCESS',1,'STREAM',2,'FLOW',3,'ENV',4);
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
        VarMode=struct('NONE',1,'CELL',2,'STRUCT',3,'TABLE',4);
		DEFAULT_VARMODE='NONE';
        % Cost Table options
        CostTables=struct('DIRECT',1,'GENERALIZED',2,'ALL',3);
		DEFAULT_COST_TABLES='DIRECT';
		SummaryId=struct('NONE',0,'STATES',1,'RESOURCES',2,'ALL',3);
		DEFAULT_SUMMARY='NONE';
        % Options for diagnosis calculation
		DiagnosisMethod=struct('NONE',0,'WASTE_EXTERNAL',1,'WASTE_INTERNAL',2);
		DEFAULT_DIAGNOSIS='WASTE_EXTERNAL';
		% Options for Table View
		TableView=struct('NONE',0,'CONSOLE',1,'HTML',2,'GUI',3);
		DEFAULT_TABLEVIEW='CONSOLE';
		% Input Tables
		TableDataIndex=struct('FLOWS',1,'PROCESSES',2,'EXERGY',3,'FORMAT',4,...
			'WASTEDEF',5,'WASTEALLOC',6,'RESOURCES',7,'DIRECTORY',8);
		TableDataName={'Flows','Processes','Exergy','Format',...
					   'WasteDefinition','WasteAllocation','ResourcesCost','Directory'};
		TableDataDescription={'Flows Data','Processes Data','Exergy Data','Format Data',...
						'Waste Definition','Waste Allocation','Resources Cost','Tables Directory'}
        MandatoryTables=1:4;
		OptionalTables=5:7;
		% Data Model
		DataId=struct('PRODUCTIVE_STRUCTURE',1,'EXERGY_STATES',2,'FORMAT',3,'WASTE',4,'RESOURCES',5);
		DataElements={'ProductiveStructure','ExergyStates','Format','WasteDefinition','ResourcesCost'};
		MandatoryData=1:3;
		OptionalData=4:5;
        % Default Results file
		DATA_MODEL_FILE='DataModel';
        RESULT_FILE='ModelResults';
		SUMMARY_FILE='SummaryResults';
		DIAGRAM_FILE='Diagram';
        TABLE_FILE='table'
		% Format config file
		CFGFILE='printformat.json';
		% Table Names and keys
		Tables=struct('FLOW_TABLE','flows','PROCESS_TABLE','processes','STREAM_TABLE','streams',...
			'FLOW_EXERGY','eflows','PROCESS_EXERGY','eprocesses','STREAM_EXERGY','estreams','TABLE_FP','tfp',...
			'FLOW_EXERGY_COST','dfcost','FLOW_GENERAL_COST','gfcost','PROCESS_COST','dcost',...
			'PROCESS_UNIT_COST','ducost','PROCESS_GENERAL_COST','gcost','PROCESS_GENERAL_UNIT_COST','gucost',...
			'STREAM_EXERGY_COST','dscost','STREAM_GENERAL_COST','gscost',...
			'COST_TABLE_FP','dcfp','COST_TABLE_FPR','dcfpr','GENERAL_COST_TABLE','gcfp',...
			'PROCESS_ICT','dict','PROCESS_GENERAL_ICT','gict','FLOW_ICT','dfict','FLOW_GENERAL_ICT','gfict',...
			'WASTE_DEFINITION','wd','WASTE_ALLOCATION','wa','WASTE_RECYCLING_DIRECT','rad','WASTE_RECYCLING_GENERAL','rag',...
			'DIAGNOSIS','dgn','MALFUNCTION','mf','MALFUNCTION_COST','mfc',...
			'IRREVERSIBILITY_VARIATION','dit','TOTAL_MALFUNCTION_COST','tmfc','FUEL_IMPACT','dft',...
			'DIAGRAM_FP','atfp','COST_DIAGRAM_FP','atcfp',...
			'FLOWS_DIAGRAM','fat','FLOW_PROCESS_DIAGRAM','fpat','PRODUCTIVE_DIAGRAM','sfpat','PROCESS_DIAGRAM','pat',...
			'SUMMARY_EXERGY','exergy','SUMMARY_UNIT_CONSUMPTION','pku','SUMMARY_IRREVERSIBILITY','pI',...
			'SUMMARY_PROCESS_COST','dpc','SUMMARY_PROCESS_UNIT_COST','dpuc',...
			'SUMMARY_FLOW_COST','dfc','SUMMARY_FLOW_UNIT_COST','dfuc',...
			'SUMMARY_PROCESS_GENERAL_COST','gpc','SUMMARY_PROCESS_GENERAL_UNIT_COST','gpuc',...
			'SUMMARY_FLOW_GENERAL_COST','gfc','SUMMARY_FLOW_GENERAL_UNIT_COST','gfuc',...
			'RSUMMARY_PROCESS_GENERAL_COST','rgpc','RSUMMARY_PROCESS_GENERAL_UNIT_COST','rgpuc',...
			'RSUMMARY_FLOW_GENERAL_COST','rgfc','RSUMMARY_FLOW_GENERAL_UNIT_COST','rgfuc');
		% Tables Types 
		TableType=struct('TABLE',1,'MATRIX',2,'SUMMARY',3');
		TypeTables={'TABLE','MATRIX','SUMMARY'};
		GraphType=struct('NONE',0,'COST',1,'DIAGNOSIS',2,'DIAGRAM_FP',3,'RECYCLING',4,'SUMMARY',5,...
				'WASTE_ALLOCATION',6,'DIGRAPH',7,'DIGRAPH_FP',8);
		% Types of define formats
		Format=struct('NODE',1,'TEXT',2,'EXERGY',3,'EXERGY_COST',4,'EXERGY_UNIT_COST',5,...
		'GENERALIZED_COST',6,'GENERALIZED_UNIT_COST',7,'DIAGNOSIS',8,'PERCENTAGE',9);
		% Special symbols unicode (simple dash - \u002D)
		Symbols=jsondecode('{"dash": "\u2014","delta": "\u0394"}');
        % Result Id types
        ResultId=struct('PRODUCTIVE_STRUCTURE',1,'THERMOECONOMIC_STATE',2,'THERMOECONOMIC_ANALYSIS',3,...
            'WASTE_ANALYSIS',4,'THERMOECONOMIC_DIAGNOSIS',5,'PRODUCTIVE_DIAGRAM',6,'DIAGRAM_FP',7,...
			'SUMMARY_RESULTS',8,'DATA_MODEL',9,'RESULT_MODEL',10);
		% Icon Files
		IconFile={'ps.png','ea.png','ta.png','wa.png','td.png','pd.png','fp.png','sr.png','md.png','mr.png'};
		% Names for cModelResults	
		Results={'Productive Structure','Exergy Analysis','Thermoeconomic Analysis',...
			'Waste Analysis','Thermoeconomic Diagnosis','Productive Diagram','Diagram FP',...
			'Summary Results','Data Model','Model Results'};
		ResultVar={'productiveStructure','exergyAnalysis','thermoeconomicAnalysis',...
			'wasteAnalysis','thermoeconomicDiagnosis','productiveDiagram','diagramFP',...
			'summaryResults','dataModel','modelResults'};
		TABLE_INDEX='tindex';
        ResultIndex={'psindex','eaindex','taindex','waindex','tdindex','pdindex','fpindex','srindex',...
            'dmindex','rmindex'};
		% Save extensions
		SAVE_RESULTS={'*.xlsx','XLSX Files';'*.txt','TXT Files'; '*.csv','CSV Files'; ...
		              '*.html','HTML Files';'*.tex','LaTeX Files';'*.mat','MAT Files'};
		SAVE_DATA={'*.xlsx','XLSX Files';'*.json','JSON Files'; '*.csv','CSV Files';...
		           '*.xml','XML Files';'*.mat','MAT Files'};
		SAVE_TABLES={'*.xlsx','XLSX Files';'*.txt','TXT Files'; '*.csv','CSV Files'; ...
		             '*.html','HTML Files';'*.tex','LaTeX Files';'*.mat','MAT Files'; ...
		             '*.json','JSON Files';'*.xml','XML Files'};
        % ClassId types
        ClassId=struct('RESULT_INFO',1,'DATA_MODEL',2,'RESULT_MODEL',3)
		% Tables Directory configuration
		DirCols=struct('DESCRIPTION',1,'RESULT_NAME',2,'GRAPH',3,'TYPE',4,'CODE',5,'RESULT_CODE',6);
		DirColNames={'Description','Results','Graph','Type','Code','Results Code'};
		DIR_COLS_DEFAULT={'DESCRIPTION','RESULT_NAME','GRAPH'};
        ACTIVE_TABLE_COLUMN=4;
		GRAPH_COLUMN=3;
		% Type of columns for uitables
		ColumnFormat=struct('CHAR',1,'NUMERIC',2);
		colType={'char','numeric'};
        % TaesApp Tab Panels
        Panels=struct('WELCOME',1,'INDEX',2,'TABLES',3,'GRAPHS',4,'LOG',5);
        % File Extensions
		FileType=struct('JSON',1,'XLSX',2,'CSV',3,'MAT',4,'XML',5,'TXT',6,'HTML',7,'LaTeX',8);
		FileExt=struct('JSON','.json','XLSX','.xlsx','CSV','.csv','MAT','.mat','XML','.xml','TXT','.txt','HTML','.html','LaTeX','.tex');
        % HTML/CCS style file
		CSSFILE='styles.css';
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
		FILE_PATTERN='^(?!^(PRN|AUX|CLOCK\$|NUL|CON|COM\d|LPT\d)\..*)^\w+.(xlsx|csv|mat|txt|json|xml|html|tex)$'
		% Key Text Patterm
		KEY_PATTERN='^[A-Z][A-Za-z0-9]+$'
		NAME_PATTERN='[A-Za-z]\w+$'
		KEY_LENGTH=2:8
    end
    %----------------------------
    % Static Methods for types
    %----------------------------
	methods (Static)
		function res=checkTypeKey(s,key)
		% Check if key is a field of type structure s
		% Input:
        %   s   - type structure
		%   key - key
        % Output:
        %   res - true/false
			res=false;
			if ischar(key)
            	res=isfield(s,upper(key));
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

		function res=getFormatId(text)
		% Get internal code of a resources cost type text
			res=cType.getTypeId(cType.Format,text);
		end

		function res=getCostTables(text)
		% Get id for CostTables option
			res=cType.getTypeId(cType.CostTables,text);
		end

		function res=getSummaryId(text)
			res=cType.getTypeId(cType.SummaryId,text);
		end

		function res=getDiagnosisMethod(text)
		% Get id for Diagnosis Method option
			res=cType.getTypeId(cType.DiagnosisMethod,text);
		end

		function res=getVarMode(text)
		% Get id for VarMode option
			res=cType.getTypeId(cType.VarMode,text);
		end

		function res=getTableView(text)
		% Get id for TableView option
			res=cType.getTypeId(cType.TableView,text);
		end

		function res=getDirColumns(text)
		% Get id for Directory Table Columns option
			res=cType.getTypeId(cType.DirCols,text);
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

		function res=checkSummaryOption(text)
			res=cType.checkTypeKey(cType.SummaryId,text);
		end

		function res=checkDiagnosisMethod(text)
		% Check DiagnosisMethod value
			res=cType.checkTypeKey(cType.DiagnosisMethod,text);
		end

		function res=checkVarMode(text)
		% Check DiagnosisMethod value
			res=cType.checkTypeKey(cType.VarMode,text);
		end

		function res=checkTableView(text)
		% Check TableView value
			res=cType.checkTypeKey(cType.TableView,text);
		end

		function res=checkDirColumns(text)
		% Check Directory Table Columns option
			res=cType.checkTypeKey(cType.DirCols,text);
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

		function res=SummaryOptions()
			res=fieldnames(cType.SummaryId);
		end

		function res=TableViewOptions()
			% Get a cell array with the Cost Tables Type options
			res=fieldnames(cType.TableView);
		end

		function res=DiagnosisOptions()
		% Get a cell array with the Diagnosis Type options
			res=fieldnames(cType.DiagnosisMethod);
		end
		
		function res=VarModeOptions()
		% Get a cell array with the VarMode Type options
			res=fieldnames(cType.VarMode);
		end

		function res=checkTextKey(text)
		% Check if an element key (flow/process) has a correct format
		%	- Its lenght must be bigger than 1 and less than 8
		%   - Satisfy the regular expression cType.KEY_PATTERN
		%	INPUT:
		%		text - key string
		%   OUTPUT:
		%		res - true/false
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
		
		function tableCode(name)
		% Get the key code of a table
			if ~ischar(name)
				return
			end
			codes=fieldnames(cType.Tables);
			tables=struct2cell(cType.Tables);
			idx=find(strcmpi(name,tables),1);
			if isempty(idx)
				return
			end
			disp(['cType.Tables.',codes{idx}]);
		end

		function res=sequence()
		% Generate a sequence of numbers
			persistent counter;
			if isempty(counter)
				counter=uint64(1);
			else
				counter=counter+1;
			end
			res=counter;
		end

		%%%%
		% File Functions
		%%%%%
		function [res,ext]=getFileType(filename)
		% Get file type acording its extension (ext)
            res=cType.EMPTY;
			[~,~,ext]=fileparts(filename);
			values=struct2cell(cType.FileExt);
			idx=find(strcmp(values(:),ext));
            if ~isempty(idx)
                res=idx;
            end
		end

        function res=checkFileExt(filename,fext)
		% Check if filename has a valid extension
            [~,~,ext]=fileparts(filename);
            res=strcmp(fext,ext);
        end

		function res=getLine(length)
			res=repmat(cType.Symbols.dash,1,length);
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
				otherwise
					res='UNDEFINED';
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
			filename=cType.IconFile{icon};
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