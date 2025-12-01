classdef cType
%cType - Static class to manage the constants of TaesLab
%   This class includes constants, enumeration types defined as constant structures, 
%  	and methods to check the correct option names as well as other miscellaneous functions
%
%   cType methods:
%    Check data types methods:
%  	  res=cType.checkFlowTypes(list)
%  	  res=cType.checkProcessTypes(list)
%  	  res=cType.checkResourcesTypes(list)
%  	  res=cType.checkWasteTypes(list)
%    Check option methods
%     res=cType.checkCostTables(option)
%     res=cType.checkSummaryOption(option)
%     res=cType.checkDiagnosisMethod(option)
%     res=cType.checkVarMode(option)
%     res=cType.checkTableView(option)
%     res=cType.checkDirColumns(option)
%    Get type id from key:
%  	  id=cType.getFlowId(key)
%  	  id=cType.getProcessId(key)
%  	  id=cType.getWasteId(key)
%     id=cType.getResourcesId(key)
%     id=cType.getFormatId(key)
%    Get option id
%     id=cType.getCostTables(text)
%     id=cType.getSummaryId(text)
%     id=cType.getDiagnosisMethod(text)
%     id=cType.getVarMode(text)
%     id=cType.getTableView(text)
%     id=cType.getDirColumns(text)    
%    Get type options:
%	  res=cType.WasteTypeOptions()
%	  res=cType.CostTablesOptions()
%	  res=cType.DiagnosisOptions()
%     res=cType.SummaryOptions()
%     res=cType.VarModeOptions()
%     res=cType.TableViewOptions()
%    File Methods  
%	  res=cType.getFileType(filename)
%	  res=cType.checkFileExt(filename,ext)
%    Other methods:
%     res=cType.TaesLabPath()
%     res=cType.tableCode()
%     res=cType.getLine(lenght)
%  	  text=cType.getTextErrorCode(val) 
%	  text=cType.log2text(val)
%  	  char=cType.getNewline()                               
%  	  char=cType.getPathDelimiter() 
%  	  img=cType.getIcon(name)
%  	  file=cType.getTaesImage(path)                        
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
        ON='on'                   % GUI on text
        OFF='off'                 % GUI off text                      
		FUEL='FUEL'               % Fuel type option text
		PRODUCT='PRODUCT'         % Product type option text
		FORMAT_ID='%3d'           % Line number format
		SPACES='\s+'              % Spaces Regular Expresion
		BLANK=char(32)            % Blank character
		DEBUG_MODE=false 	      % Debug mode flag
		% Node types
		NodeType=struct('PROCESS',1,'STREAM',2,'FLOW',3,'ENV',4);
		MARKER_SIZE=5;
		KMARKER_SIZE=7;
		% Types of processes
		Process=struct('PRODUCTIVE',0,'ENVIRONMENT',2,'DISSIPATIVE',4);
        % Types of Streams 
		Stream=struct('FUEL',0,'PRODUCT',1,'OUTPUT',2,'RESOURCE',3,'WASTE',6);
        % Types of Flows
		Flow=struct('INTERNAL',0,'OUTPUT',2,'RESOURCE',3,'WASTE',6);
        % Waste Allocation Types
		WasteAllocation=struct('MANUAL',0,'DEFAULT',1,'RESOURCES',1,'COST',2,'EXERGY',3,'IRREVERSIBILITY',4,'HYBRID',5);
		DEFAULT_WASTE_ALLOCATION='DEFAULT';
        % Types of Resources
		Resources=struct('FLOW',1,'PROCESS',2);
		% Types of define formats
		Format=struct('NODE',1,'TEXT',2,'EXERGY',3,'EXERGY_COST',4,'EXERGY_UNIT_COST',5,...
		'GENERALIZED_COST',6,'GENERALIZED_UNIT_COST',7,'DIAGNOSIS',8,'PERCENTAGE',9);
		% Variable Display Options
        VarMode=struct('NONE',1,'CELL',2,'STRUCT',3,'TABLE',4);
		DEFAULT_VARMODE='NONE';
        % Cost Table options
        CostTables=struct('DIRECT',1,'GENERALIZED',2,'ALL',3);
		DEFAULT_COST_TABLES='DIRECT';
		% Summary Options
		SummaryId=struct('NONE',0,'STATES',1,'RESOURCES',2,'ALL',3);
		DEFAULT_SUMMARY='NONE';
        % Options for diagnosis calculation
		DiagnosisMethod=struct('NONE',0,'WASTE_EXTERNAL',1,'WASTE_INTERNAL',2);
		DEFAULT_DIAGNOSIS='WASTE_EXTERNAL';
		% Options for Table View
		TableView=struct('NONE',0,'CONSOLE',1,'HTML',2,'GUI',3);
		DEFAULT_TABLEVIEW='CONSOLE';
		% Graph styles
		GraphStyles=struct('BAR',1,'STACK',2,'PLOT',3,'PIE',4,'DIGRAPH',5);
		DEFAULT_GRAPHSTYLE='BAR';
		% Input Tables
		TableDataType=struct('KEY',1,'CHAR',2,'NUMERIC',3,'SAMPLE',4);
		TableDataIndex=struct('FLOWS',1,'PROCESSES',2,'EXERGY',3,'FORMAT',4,...
			'WASTEDEF',5,'WASTEALLOC',6,'RESOURCES',7,'DIRECTORY',8);
		% Data Model
		DataId=struct('PRODUCTIVE_STRUCTURE','ProductiveStructure','EXERGY','ExergyStates',...
				'FORMAT','Format','WASTE','WasteDefinition','RESOURCES','ResourcesCost');
        % Default Results file
		DATA_MODEL_FILE='DataModel';
        RESULT_FILE='ModelResults';
		SUMMARY_FILE='SummaryResults';
		DIAGRAM_FILE='Diagram';
        TABLE_FILE='table';
		% key - value fields
		KEYVAL={'key','value'};
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
			'FLOW_RESOURCE_COST','dfrsc','PROCESS_RESOURCE_COST','dprsc',...
			'FLOW_RESOURCE_GENERAL_COST','gfrsc','PROCESS_RESOURCE_GENERAL_COST','gprsc',...
			'WASTE_DEFINITION','wd','WASTE_ALLOCATION','wa','WASTE_RECYCLING_DIRECT','rad','WASTE_RECYCLING_GENERAL','rag',...
			'DIAGNOSIS','dgn','MALFUNCTION','mf','MALFUNCTION_COST','mfc',...
			'IRREVERSIBILITY_VARIATION','dit','TOTAL_MALFUNCTION_COST','tmfc','FUEL_IMPACT','dft',...
			'FLOW_DIAGRAM','fat','FLOW_PROCESS_DIAGRAM','fpat','PRODUCTIVE_DIAGRAM','sfpat',...
			'PROCESS_DIAGRAM','pat','KPROCESS_DIAGRAM','kpat','KTABLE_FP','ktfp','KTABLE_COST_FP','kdcfp',...
			'DIGRAPH_FP','atfp','DIGRAPH_COST_FP','atcfp','KDIGRAPH_FP','katfp','KDIGRAPH_COST_FP','katcfp','PROCESS_GROUP','grps',...
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
				'WASTE_ALLOCATION',6,'DIGRAPH',7,'RESOURCE_COST',8);
		% Result Id types
        ResultId=struct('PRODUCTIVE_STRUCTURE',1,'THERMOECONOMIC_STATE',2,'THERMOECONOMIC_ANALYSIS',3,...
            'WASTE_ANALYSIS',4,'THERMOECONOMIC_DIAGNOSIS',5,'PRODUCTIVE_DIAGRAM',6,'DIAGRAM_FP',7,...
			'SUMMARY_RESULTS',8,'DATA_MODEL',9,'RESULT_MODEL',10);
		% ClassId types
        ClassId=struct('RESULT_INFO',1,'DATA_MODEL',2,'RESULT_MODEL',3)
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
		% Result Tables Properties
		TableMatrixProps={'Name','Description','Resources','GraphType','Format','Unit','NodeType',...
			       'SummaryType','GraphOptions','RowTotal','ColTotal'};
		TableCellProps={'Name','Description','Resources','GraphType','Format','Unit','NodeType',...
			       'DataType','FieldNames','ShowNumber'};
		% Save extensions
		SAVE_RESULTS={'*.xlsx','XLSX Files';'*.txt','TXT Files'; '*.csv','CSV Files'; ...
		              '*.html','HTML Files';'*.tex','LaTeX Files';'*.mat','MAT Files'};
		SAVE_DATA={'*.xlsx','XLSX Files';'*.json','JSON Files'; '*.csv','CSV Files';...
		           '*.xml','XML Files';'*.mat','MAT Files'};
		SAVE_TABLES={'*.xlsx','XLSX Files';'*.txt','TXT Files'; '*.csv','CSV Files'; ...
		             '*.html','HTML Files';'*.tex','LaTeX Files';'*.mat','MAT Files'; ...
		             '*.json','JSON Files';'*.xml','XML Files'};
		% Tables Directory configuration
		DirCols=struct('DESCRIPTION',1,'RESULT_NAME',2,'GRAPH',3,'TYPE',4,'CODE',5,'RESULT_CODE',6);
		DirColNames={'Description','Results','Graph','Type','Code','Results Code'};
		DIR_COLS_DEFAULT={'DESCRIPTION','RESULT_NAME','GRAPH'};
        ACTIVE_TABLE_COLUMN=4;
		GRAPH_COLUMN=3;
		% Type of columns for uitables
		DataType=struct('KEY',1,'CHAR',2,'NUMERIC',3,'SAMPLE',4)
		ColumnFormat=struct('CHAR',1,'NUMERIC',2);
		colType={'char','numeric'};
		% Digraph types
		DigraphType=struct('GRAPH',0,'KERNEL',1,'GRAPH_WEIGHT',2,'KERNEL_WEIGHT',3);
		% Class Info types
		ClassInfo=struct('PROPERTIES',1,'METHODS',2);
        % TaesApp Tab Panels
        Panels=struct('WELCOME',1,'INDEX',2,'TABLES',3,'GRAPHS',4,'LOG',5);
        % File Extensions
		FileType=struct('JSON',1,'XML',2,'XLSX',3,'CSV',4,'MAT',5,'TXT',6,'HTML',7,'LaTeX',8,'MD',9,'MCNT',10,'MHLP',11);
		FileExt=struct('JSON','.json','XML','.xml','XLSX','.xlsx','CSV','.csv','MAT','.mat',...
			'TXT','.txt','HTML','.html','LaTeX','.tex','MD','.md','MCNT','.m','MHLP','.mhlp');
        % HTML/CCS style file
		CSSFILE='styles.css';
        % Taess app welcome image
		TaesImage='TaesLab.png';
        % Taess app Resources folder
		AppResources='Resources';
		% Special symbols unicode (simple dash - \u002D)
		Symbols=jsondecode('{"dash": "\u2014","delta": "\u0394"}');  
		% Icon Files
		IconFile={'ps.png','ea.png','ta.png','wa.png','td.png','pd.png','fp.png','sr.png','md.png','mr.png'};
		% TaesLab Paths
		BasePath=fullfile(cType.TaesLabPath(),'Base');
		ClassesPath=fullfile(cType.TaesLabPath(),'Classes');
		FunctionsPath=fullfile(cType.TaesLabPath(),'Functions');
		ConfigPath=fullfile(cType.TaesLabPath(),'Config');
		DocsPath=fullfile(cType.TaesLabPath(),'Docs');
		ExamplesPath=fullfile(cType.TaesLabPath(),'Examples');
		% System constanst
		NEWLINE_PC='\r\n';    % Newline character for Windows
		NEWLINE_UNIX='\n';    % Newline character for Unix (MAC)
        MAX_PRINT_COLS=20;    % Maximun cols to print in console
		DELIMITER=',';        % CSV Delimiter
		PATH_PC='\'           % Path Character for Windows
		PATH_UNIX='/'         % Path Character for Unix
		% File Pattern
		FILE_PATTERN='^(?!^(PRN|AUX|CLOCK\$|NUL|CON|COM\d|LPT\d)\..*)^\w+\.(xlsx|html|json|tex|csv|txt|xml|mat|md|m|mhlp)$'
    end
    %----------------------------
    % Static Methods for types
    %----------------------------
	methods (Static,Access=private)
		function res=checkTypeKey(s,key)
		%checkTypeKey - Check if key is a field of type structure
		%   Syntax:
		%     res=cType.checkType(s,key)
		%   Input Arguments:
        %     s   - type structure
		%     key - key
        %   Output Arguments:
        %     res - true/false
		%
			res=false;
            if ischar(key)
            	res=isfield(s,upper(key));
            end
        end
	
		function id=getTypeId(s,key)
        %getTypeId - Get the value of key in the type structure s
		%   Syntax:
		%     res=cType.checkType(s,key)
		%   Input Arguments:
        %     s   - type structure
		%     key - type key
        %   Output Arguments:
        %     id - type id
		%
			id=cType.EMPTY;
			if ischar(key)
				if cType.checkTypeKey(s,key)
					id=s.(upper(key));
				end
			end
		end

		function [tf,loc]=checkTypeList(s,keys)
		%checkTypeList - Check if all element of keys are in the type list
		%   Syntax:
		%     [tf,loc] = cType.checkTypeList
		%   Input Arguments:
		%        s - type struct
		%     keys - cell array of keys to check
		%   Output Arguments:
		%       tf - true | false
		%      loc - If true contains the typeId of the keys
		%            If false contains the position of the missing keys
		% 
    		sKeys = fieldnames(s);
			vals=struct2cell(s);
    		% 
    		[res,idx] = ismember(keys, sKeys);
			if all(res)
				tf=true;
				loc = cell2mat(vals(idx));
        	else
				tf=false;
				loc=find(~res);
			end
    	end
	end

	methods (Static)

		function res=getProcessId(text)
		%getProcessId - Get the internal code of a process type text
        %
        %   Syntax:
        %     res=cType.getProcessId(text)
        %   Input Arguments:
        %     text - Process type text
        %   Output Arguments:
        %     res - Process Type Id. (empty if it doesn't exist)
        %
			res=cType.getTypeId(cType.Process,text);
        end

		function res=getFlowId(text)
		%getFlowId - Get the internal code of a flow type text
        %   Syntax:
        %     res=cType.getFlowId(text)
        %   Input Arguments:
        %     text - Flow type text
        %   Output Arguments:
        %     res - Flow Type Id (empty if it doesn't exist)
        %
			res=cType.getTypeId(cType.Flow,text);
        end

        function res=getResourcesId(text)
		%getResourcesId - Get internal code of a resources cost type text
        %   Syntax:
        %     res=cType.getResourcesId(text)
        %   Input Arguments:
        %     text - Resource type text
        %   Output Arguments:
        %     res - Resource Type Id (empty if it doesn't exist)
        %
            res=cType.getTypeId(cType.Resources,text);
        end

		function res=getWasteId(text)
		%getWasteId - Get internal code of a waste allocation type text
        %   Syntax:
        %     res=cType.getWasteId(text)
        %   Input Arguments:
        %     text - Waste Allocation type text
        %   Output Arguments:
        %     res - Waste Allocation Type Id (empty if it doesn't exist)
        %
            res=cType.getTypeId(cType.WasteAllocation,text);
        end

		function res=getFormatId(text)
		%getFormatId - Get internal code of format type text
        %   Syntax:
        %     res=cType.getFormatId(text)
        %   Input Arguments:
        %     text - Format type text
        %   Output Arguments:
        %     res - Format Type Id (empty if it doesn't exist)
        %
			res=cType.getTypeId(cType.Format,text);
		end

		function res=getCostTables(text)
		%getCostTables - Get id for CostTables option
		%   Syntax:
        %     res=cType.getCostTables(text)
        %   Input Arguments:
        %     text - Cost Tables type text
        %   Output Arguments:
        %     res - Cost Tables type Id (empty if it doesn't exist)
        %
			res=cType.getTypeId(cType.CostTables,text);
		end

		function res=getSummaryId(text)
		%getSummaryId - Get id for Summary option
		%   Syntax:
        %     res=cType.getSummaryId(text)
        %   Input Arguments:
        %     text - Summary type text
        %   Output Arguments:
        %     res - Summary Type Id (empty if it doesn't exist)
        %
			res=cType.getTypeId(cType.SummaryId,text);
		end

		function res=getDiagnosisMethod(text)
		%getDiagnosisMethod - Get id for Diagnosis Method option
		%   Syntax:
        %     res=cType.getDiagnosisMethod(text)
        %   Input Arguments:
        %     text - Diagnosis Method type text
        %   Output Arguments:
        %     res - Diagnosis Method type Id (empty if it doesn't exist)
        %
			res=cType.getTypeId(cType.DiagnosisMethod,text);
		end

		function res=getVarMode(text)
		%getVarMode - Get id for VarMode option
        %   Syntax:
        %     res=cType.getVarMode(text)
        %   Input Arguments:
        %     text - Type of result type text
        %   Output Arguments:
        %     res - VarMode Type Id (empty if it doesn't exist)
        %
			res=cType.getTypeId(cType.VarMode,text);
		end

		function res=getTableView(text)
		%getTableView - Get id for TableView option
        %   Syntax:
        %     res=cType.getTableView(text)
        %   Input Arguments:
        %     text - TableView type text
        %   Output Arguments:
        %     res - TableView ype Id (empty if it doesn't exist)
        %
			res=cType.getTypeId(cType.TableView,text);
        end

		function res=getClassInfo(text)
		%getClassInfo - Get the id of ClassInfo option
        %   Syntax:
        %     res=cType.getClassInfo(text)
        %   Input Arguments:
        %     text - ClassInfo type text
        %   Output Arguments:
        %     res - ClassInfo type Id (empty if it doesn't exist)
        %
			res=cType.getTypeId(cType.ClassInfo,text);
        end

		function res=getGraphStyle(text)
		%getGraphStyle - Get the id of Graph Style option
		%   Syntax:
		%     res=cType.getGraphStyle(text)
		%   Input Arguments:
		%     text - Graph Style type text
		%   Output Arguments:
		%     res - Graph Style type Id (empty if it doesn't exist)
		%
			res=cType.getTypeId(cType.GraphStyles,text);
		end

		function [res,idx]=checkProcessTypes(list)
		%checkProcessTypes - Check if the Process Type list is correct
		%   Syntax:
        %     res=cType.checkProcessTypes(list)
        %   Input Arguments:
        %     text - Process type list.
        %   Output Arguments:
        %     res - true| false
		%     idx - if true type Id list, else pos of missing types
        %
			[res,idx]=cType.checkTypeList(cType.Process,list);
		end

		function [res,idx]=checkFlowTypes(list)
		%checkFlowTypes - Check if the Flows Type list is correct
		%   Syntax:
        %     res=cType.checkFlowTypes(list)
        %   Input Arguments:
        %     list - Flow type list.
        %   Output Arguments:
        %     res - true| false
		%     idx - if true type Id list, else pos of missing types
        %
			[res,idx]=cType.checkTypeList(cType.Flow,list);
		end

		function [res,idx]=checkWasteTypes(list)
		%checkFlowTypes - Check if the Flows Type list is correct
		%   Syntax:
        %     res=cType.checkWasteTypes(list)
        %   Input Arguments:
        %     list - Waste type list.
        %   Output Arguments:
        %     res - true | false
		%     idx - if true type Id list, else pos of missing types
        %
			[res,idx]=cType.checkTypeList(cType.WasteAllocation,list);
		end

		function [res,idx]=checkResourceTypes(list)
		%checkResourceTypes - Check if the Flows Type list is correct
		%   Syntax:
        %     res=cType.checkResourceTypes(list)
        %   Input Arguments:
        %     list - Resource type list.
        %   Output Arguments:
        %     res - true | false
		%     idx - if true type Id list, else pos of missing types
        %
			[res,idx]=cType.checkTypeList(cType.Resources,list);
		end

		function res=checkCostTables(text)
		%checkCostTables - Check CostTable type text
		%   Syntax:
        %     res=cType.checkCostTables(text)
        %   Input Arguments:
        %     text - Cost Tables type text.
        %   Output Arguments:
        %     res - true/false
        %		
			res=cType.checkTypeKey(cType.CostTables,text);
		end

		function res=checkSummaryOption(text)
		%checkSummaryOption - Check Summary type text
		%   Syntax:
        %     res=cType.checkSummaryOption(text)
        %   Input Arguments:
        %     text - Summary type text.
        %   Output Arguments:
        %     res - true/false
        %
			res=cType.checkTypeKey(cType.SummaryId,text);
		end

		function res=checkDiagnosisMethod(text)
		%checkDiagnosisMethod - Check Diagnosis method type text
		%   Syntax:
        %     res=cType.checkDiagnosisMethod(text)
        %   Input Arguments:
        %     text - Diagnosis method text.
        %   Output Arguments:
        %     res - true/false
        %
			res=cType.checkTypeKey(cType.DiagnosisMethod,text);
		end

		function res=checkVarMode(text)
		%checkVarMode - Check Variable display option
		%   Syntax:
        %     res=cType.checkVarMode(text)
        %   Input Arguments:
        %     text - Variable display type text.
        %   Output Arguments:
        %     res - true/false
        %
			res=cType.checkTypeKey(cType.VarMode,text);
		end

		function res=checkTableView(text)
		%checkTableView - Check TableView value
		%   Syntax:
        %     res=cType.checkTableView(text)
        %   Input Arguments:
        %     text - Table view type text.
        %   Output Arguments:
        %     res - true/false
        %
			res=cType.checkTypeKey(cType.TableView,text);
		end

		function res=checkClassInfo(text)
		%checkClassInfo - Check ClassInfo value
		%   Syntax:
        %     res=cType.checkClassInfo(text)
        %   Input Arguments:
        %     text - ClassInfo type text.
        %   Output Arguments:
        %     res - true/false
        %
			res=cType.checkTypeKey(cType.ClassInfo,text);
		end

		function res=checkGraphStyle(text)
		%checkGraphStyle - Check Graph Style value
		%   Syntax:
		%     res=cType.checkGraphStyle(text)
		%   Input Arguments:
		%     text - Graph Style type text.
		%   Output Arguments:
		%     res - true/false
		%
			res=cType.checkTypeKey(cType.GraphStyles,text);
		end

		function [res,missing]=checkDirColumns(fields)
		%checkDirColumns - Check Table Directory Columns names
		%   Syntax:
        %     res=cType.checkDirColumns(text)
        %   Input Arguments:
        %     text - Table Directory column name
        %   Output Arguments:
        %     res - true/false
        %
			[res,missing]=cType.checkTypeList(cType.DirCols,fields);
    	end

		function res=WasteTypeOptions()
		%WasteTypeOptions - Get a cell array with the Waste Allocation Type options
		%   Syntax:
        %     res=cType.WasteTypeOptions
			res=fieldnames(cType.WasteAllocation);
		end

		function res=CostTablesOptions()
		%CostTablesOptions - Get a cell array with the Cost Tables Type options
		%   Syntax:
        %     res=cType.CostTablesOptions
			res=fieldnames(cType.CostTables);
		end

		function res=SummaryOptions()
		%SummaryOptions - Get a cell array with the Summary Options
		%   Syntax:
        %     res=cType.SummaryOptions
			res=fieldnames(cType.SummaryId);
		end

		function res=TableViewOptions()
		%TableViewOptions - Get a cell array with the Table view options
		%   Syntax:
        %     res=cType.TableViewOptions
			res=fieldnames(cType.TableView);
		end

		function res=DiagnosisOptions()
		%DiagnosisOptions - Get a cell array with the Diagnosis Type options
		%   Syntax:
        %     res=cType.DiagnosisOptions
			res=fieldnames(cType.DiagnosisMethod);
		end
		
		function res=VarModeOptions()
		%VarModeOptions - Get a cell array with the VarMode Type options
			res=fieldnames(cType.VarMode);
		end

		function res=getPropertiesList(tobj)
		%getPropertiesList - Get the list of additional properties of cResultTables
			res=cType.EMPTY_CELL;
			if isa(tobj,'cTableMatrix')
				res=cType.TableMatrixProps;
			elseif isa(tobj,'cTableCell')
				res=cType.TableCellProps;
			end
		end

		%%%%
		% File Functions
		%%%%%
		function [res,ext]=getFileType(filename)
		%getFileType - Get file type acording its extension (ext)
		%   Syntax:
        %     res=cType.getFileType(filename)
		%   Input Arguments:
		%     filename - file name with extension
		%   Output Arguments:
		%     res - File Type Id
		%     ext - extension characters
            res=cType.EMPTY;
			[~,~,ext]=fileparts(filename);
			values=struct2cell(cType.FileExt);
			idx=find(strcmp(values(:),ext));
            if ~isempty(idx)
                res=idx;
            end
		end

        function res=checkFileExt(filename,fext)
		%checkFileExt - Check if filename has a valid extension
		%   Syntax:
        %     res=cType.checkFileExt
		%   Input Arguments:
		%     filename - file name
		%     fext - Expected file extension
		%   Output Arguments:
		%     res - true/false
            [~,~,ext]=fileparts(filename);
            res=strcmp(fext,ext);
        end

		%%%
		% Other functions
		%%%
		function res=TaesLabPath()
		%TaesLabPath - Get the full path of the TaesLab installation
		%   Syntax:
		%     res=cType.TaesLabPath
			path=fileparts(mfilename('fullpath'));
			res=fileparts(path);
		end
		function res=getLine(length)
		%getLine - Get a dash line of the given length
		%   Syntax:
        %     res=cType.getLine
		%   Input Arguments:
		%     length - lenght of the line in chars
		%   Output Arguments:
		%     res - array of chars with the line		
			res=repmat(cType.Symbols.dash,1,length);
		end

		function tableCode(name)
		%tableCode - Display the key code of a table
		%   Syntax:
        %     res=cType.tableCode
		%   Input Arguments:
		%     name - table name
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

		function res=getTextErrorCode(error)
		%getTextErrorCode - Get the text of the corresponding error code
		%   Syntax:
        %     res=cType.getTextErrorCode
		%   Input Arguments:
		%     error - error code
		%   Output Arguments:
		%     res - error code text
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

		function res=log2text(val)
		%log2text - Get the text representation of a logical value. Used in GUI Apps
		%   Syntax:
		%     res = log2text(x)
	    %   Input Arguments:
        %     val - logical variable or array
        %   Output Arguments:
        %     res - string or cell array
        %
			res=cType.OFF;
			if ~islogical(val) && ~isnumeric(val),  return; end
			if val, res=cType.ON;end
		end

		function res=getNewline()
		%getNewLine - Get the newline character depending on operating system
		%   Syntax:
        %     res=cType.getNewline
			if ispc
				res=cType.NEWLINE_PC;
			else
				res=cType.NEWLINE_UNIX;
			end
		end

		function res=getPathDelimiter()
		%getPathDelimiter - get the path delimiter
		%   Syntax:
        %     res=cType.getPathDelimiter	
			if ispc
				res=cType.PATH_PC;
			else
				res=cType.PATH_UNIX;
			end
		end

		function res=getIcon(icon)
		%getIcon - Get app icons
		%   Syntax:
        %     res=cType.getIcon
		%   Input Arguments:
		%     icon - icon name
		%   Output Arguments:
		%     res - icon image
			filename=cType.IconFile{icon};       
            if isOctave
				folder='icon32';
            else
                folder='icon16';
            end
		    file=fullfile(cType.ConfigPath,folder,filename);
			res=imread(file);
		end

		function res=getTaesImage(path)
		%getTaesImage - Get the full path of the Taes Welcome image
		%	Syntax:
		%     res=cType.getTaesImage
		%   Input Arguments:
		%     path - path of the Resources app
		%   Output Arguments:
		%     res - full path of the image
			res=strcat(path,filesep,cType.AppResources,filesep,cType.TaesImage);
		end
	end
end		