classdef cResultInfo < cResultSet
% cResultInfo is a class container of the application results
% It stores the tables and the application class info.
% It provide methods to:
%   - Show the results in console
%   - Show the results in workspace
%   - Show the results in graphic user interfaces
%   - Save the results in files: XLSX, CSV, TXT and HTML
%   The diferent types (ResultId) of cResultInfo object are defined in cType.ResultId
%   Methods:
%       obj.printResults
%       obj.showResults(table,option)
%       res=obj.getTable(name,varmode)
%       res=obj.getTableIndex(varmode)
%       obj.showTableIndex(option);
%       obj.showGraph(name,options)
%       res=obj.exportTable(table,varmode,format)
%       res=obj.exportResults(varmode,format)
%       log=obj.saveResults(filename)
%       log=obj.saveTable(name,filename)
%       obj.summaryDiagnosis
% See: cResultTableBuilder, cTable
%
    properties (GetAccess=public, SetAccess=private)
        ResultId     % Result Id
        ResultName   % Result name
        Tables       % Struct containing the tables
        NrOfTables   % Number of tables
        Info         % cResultId object containing the results
        ModelName    % Model Name
        State        % State Name
    end

    properties (Access=private)
        tableIndex   % cTableIndex object with tables information
    end

    methods
        function obj=cResultInfo(info,tables)
        % Construct an instance of this class
        %  Usage:
        %   cResultInfo(info,tables)
        %  Input:
        %   info - cResultId containing the results
        %   tables - struct containig the result tables
        %
            % Check parameters
            obj=obj@cResultSet(cType.ClassId.RESULT_INFO);
            if ~isValidResult(info)
                obj.messageLog(cType.ERROR,'Invalid ResultId object');
                return
            end
            if ~isstruct(tables)
                obj.messageLog(cType.ERROR,'Invalid tables parameter');
                return
            end
            % Fill the class values
            obj.Info=info;
            obj.setResultId(info.ResultId)
            obj.Tables=tables;
            obj.tableIndex=cTableIndex(obj);
            obj.NrOfTables=obj.tableIndex.NrOfRows;
            obj.setProperties(info.ModelName,info.State);
            obj.status=info.status;
        end

        function res=getResultInfo(obj)
        % getResultInfo - get cResultInfo object from cResultSet
            res=obj;
        end

        %%%
        % Show Result Tables
        function printResults(obj)
        % Print the tables on console
            if isValid(obj)
                cellfun(@(x) printTable(x),obj.tableIndex.Content);
            else
                obj.printWarning('Invalid object');
            end  
        end

        function showResults(obj,name,varargin)
        % View an individual table
        %   Usage:
        %       obj.showResults(table,option)
        %   Input:
        %       name - Name of the table
        %       option - Way to display the table
        %           cType.TableView.CONSOLE 
        %           cType.TableView.GUI
        %           cType.TableView.HTML (default)
        %
            if nargin==1
                printResults(obj);
                return
            end
            tbl=obj.getTable(name);
            if isValid(tbl)
                showTable(tbl,varargin{:});
            end
        end

        function res = getTable(obj,name)
        % Get the table called name
        %   Usage:
        %       res=obj.getTable(name)
        %   Input:
        %       name - Name of the table
        %   Output:
        %       res - cTable 
            res = cStatus();
            if nargin<2
                res.printError('Table name is missing')
            end
            if obj.existTable(name)
                res=obj.Tables.(name);
            else
                res.printError('Table name %s does NOT exists',name);
            end
        end

        function res=getTableIndex(obj,varargin)
        % Get the Table Index
        %  Usage:
        %   res=getTableIndex(obj,options)
        %  Input:
        %   options - VarMode options
        %       cType.VarMode.NONE: cTable object
        %       cType.VarMode.CELL: cell array
        %       cType.VarMode.STRUCT: structured array
        %       cType.VarModel.TABLE: Matlab table
        %  Output:
        %   res - Table Index info in the format selected
            res=exportTable(obj.tableIndex,varargin{:});
        end

        function showTableIndex(obj,varargin)
        % View the index tables
        %   Usage:
        %       obj.showTableIndex(table,option)
        %   Input:
        %       name - Name of the table
        %       option - Way to display the table
        %           cType.TableView.CONSOLE (default)
        %           cType.TableView.GUI
        %           cType.TableView.HTML
        %       
            tbl=obj.tableIndex;
            if isValid(tbl)
                tbl.showTable(varargin{:});
            else
                obj.printWarning('Invalid Table index');
            end
        end

        function showGraph(obj,graph,varargin)
        % Show graph with options
        %   Usage:
        %       obj.showGraph(graph, options)
        %   Input:
        %       graph - [optional] graph table name
        %       options - graph options
        % See also cGraphResults, cTableResults
            if nargin==1
                graph=obj.Info.DefaultGraph;
            end
	        tbl=getTable(obj,graph);
	        if ~isValid(tbl)
		        obj.printError('Invalid graph table: %s',graph);
		        return
	        end
	        % Get default optional parameters
            if isempty(varargin)
                switch tbl.GraphType
		            case cType.GraphType.DIAGNOSIS
			            option=true;
		            case cType.GraphType.WASTE_ALLOCATION
                        tmp=obj.Info;
                        if isa(obj.Info,'cThermoeconomicModel')
                            tmp=tmp.wasteAnalysis.Info;
                        end
				        option=tmp.wasteFlow;
                    case cType.GraphType.DIGRAPH                     
                        option=obj.Info.getNodeTable(graph);
		            case cType.GraphType.SUMMARY
                        if tbl.isFlowsTable
					        option=obj.Info.getDefaultFlowVariables;
				        else
					        option=obj.Info.getDefaultProcessVariables;
                        end
                    otherwise
                        option=[];
                end
            else
                option=varargin{:};
            end
	        % Show Graph
	        showGraph(tbl,option);
        end

        function res=exportTable(obj,name,varmode,fmt)
        % Export a table using diferent formats.
        %  Input:
        %   name - name of the table
        %   varmode - result type.
       %       cType.VarMode.NONE: cTable object
        %      cType.VarMode.CELL: cell array
        %      cType.VarMode.STRUCT: structured array
        %      cType.VarModel.TABLE: Matlab table
        %   fmt - Format values (false/true)
        % Output:
        %   res - Table values in the required format
        %
            res=[];
            narginchk(3,4);
            if (nargin<4)
                fmt=false;
            end
            tbl=obj.getTable(name);
            if isValid(tbl)
                res=tbl.exportTable(varmode,fmt);
            end
        end

        function res=exportResults(obj,varmode,fmt)
        % Export result tables into a structure using diferent formats.
        %  Input:
        %   name - name of the table
        %   varmode - result type.
       %       cType.VarMode.NONE: cTable object
        %      cType.VarMode.CELL: cell array
        %      cType.VarMode.STRUCT: structured array
        %      cType.VarModel.TABLE: Matlab table
        %   fmt - Format values (false/true)
        %  Output:
        %   res - structure with the tables in the required format
        %
            res=[];
            if nargin < 2
                obj.printError('Not enough input arguments');
                return
            end
            if nargin==2
                fmt=false;
            end
            names=obj.getListOfTables;
            tables=cellfun(@(x) exportTable(obj,x,varmode,fmt),names,'UniformOutput',false);
            res=cell2struct(tables,names,1);
        end

        %%%
        % Save result tables
        %%%
        function log=saveResults(obj,filename)
        % Save result tables in different file formats depending on file extension
        %   Accepted extensions: xlsx, csv, html, txt, tex
        %   Usage:
        %       log=obj.saveResults(filename)
        %   Input:
        %       filename - File name. Extensión is used to determine the save mode.
        %   Output:
        %       log - cStatusLogger object with error messages
            log=cStatusLogger(cType.VALID);
            if nargin < 2
                log.messageLog(cType.ERROR,'filename missing');
                return
            end
            if ~isValid(obj)
                log.messageLog(cType.ERROR,'Invalid cResultInfo object')
                return
            end
            if ~cType.checkFileWrite(filename)
                log.messageLog(cType.ERROR,'Invalid file name: %s',filename);
                return
            end
            [fileType,ext]=cType.getFileType(filename);
            switch fileType
                case cType.FileType.CSV
                    slog=obj.saveAsCSV(filename);
                case cType.FileType.XLSX
                    slog=obj.saveAsXLS(filename);
                case cType.FileType.HTML
                    slog=obj.saveAsHTML(filename);
                case cType.FileType.TXT
                    slog=obj.saveAsTXT(filename);
                case cType.FileType.LaTeX
                    slog=obj.saveAsLaTeX(filename);
                case cType.FileType.MAT
                    slog=exportMAT(obj,filename);
            otherwise
                log.messageLog(cType.ERROR,'File extension %s is not supported',ext);
                return
            end
            log.addLogger(slog);
			if isValid(log)
				log.messageLog(cType.INFO,'File %s has been saved',filename);
			end
        end

        function log=saveTable(obj,tname,filename)
        % saveTable save the table name in a file depending extension
        %   Usage:
        %       obj.saveTable(tname, filename)
        %   Input:
        %       tname - name of the table
        %       filename - name of the file with extension
        %
            log=cStatusLogger(cType.VALID);
            if nargin < 3
                log.messageLog(cType.ERROR,'Invalid input parameters');
                return
            end
            tbl=obj.getTable(tname);
            if isValid(tbl)
                log=saveTable(tbl,filename);
            else
                log.messageLog(cType.ERROR,'Table name %s does NOT exists',tname);
            end
        end

        %%%
        % Thermoeconomic Diagnosis info methods
        %%%
        function res=getDiagnosisSummary(obj)
        % get the Fuel Impact/Malfunction Cost as a string including format and unit
            res=[];
            if isValid(obj) && obj.ResultId==cType.ResultId.THERMOECONOMIC_DIAGNOSIS
                format=obj.Tables.dit.Format;
                unit=obj.Tables.dit.Unit;
                tfmt=['Fuel Impact:',format,' ',unit];
                res.FuelImpact=sprintf(tfmt,obj.Info.FuelImpact);
                tfmt=['Malfunction Cost:',format,' ',unit];
                res.MalfunctionCost=sprintf(tfmt,obj.Info.TotalMalfunctionCost);
            end
        end
    
        function summaryDiagnosis(obj)
        % Show diagnosis summary results
            if isValid(obj) && obj.ResultId==cType.ResultId.THERMOECONOMIC_DIAGNOSIS
                res=obj.getDiagnosisSummary;
                fprintf('%s\n%s\n',res.FuelImpact,res.MalfunctionCost);
            end
        end

        function totalMalfunctionCost(obj)
        % Show malfunction cost summary
            log=cStatus();
            dgn=obj.Info;
            if ~isa(dgn,'cDiagnosis')
                log.printError('Invalid input argument');
                return
            end
            % Retrieve information
            N=dgn.NrOfProcesses+1;
            data=zeros(N,3);
            data(:,1)=dgn.getMalfunctionCost';
            data(:,2)=dgn.getWasteMalfunctionCost';
            data(:,3)=dgn.getDemmandCorrectionCost';
            % Build the results table
            rowNames=obj.Tables.dgn.RowNames;
            colNames={'Key','MF*','MR*','MPt*'};
            p.Format=obj.Tables.mfc.Format;
            p.Unit=obj.Tables.mfc.Unit;
            p.rowTotal=false;
            p.colTotal=true;
            p.key='tmfc';
            p.Description='Total Malfunction Cost';
            p.GraphType=0;
            p.GraphOptions=0;
            tbl=cTableMatrix.create(data,rowNames,colNames,p);
            obj.summaryDiagnosis;
            printTable(tbl);
        end

		%%%
        % Internal functions
		%%%
        function setResultId(obj,id)
        % Set ResultId
            obj.ResultId=id;
            obj.ResultName=cType.Results{id};
        end

        function setProperties(obj,model,state)
         % Set model and state properties
            obj.ModelName=model;
            cellfun(@(x) setState(x,state),obj.tableIndex.Content);
            obj.State=state;
        end

        function status=isResultTable(obj)
        % Determine if the tables are results
            status=(obj.ResultId~=cType.ResultId.DATA_MODEL);
        end

        function status=existTable(obj,name)
        % Check if there is a table called name
            status=isfield(obj.Tables,name);
        end

        function log=saveAsCSV(obj,filename)
		% Save result tables as CSV files, each table in a file
		%   Usage:
		%       log=obj.saveAsCSV(filename)
		%   Input:
		%       filename - Name of the file where the csv file information is stored
		%   Output:
		%       log - cStatusLog object with error messages
			log=cStatusLogger(cType.VALID);
			% Check Input
			if obj.tableIndex.NrOfRows<1
				log.messageLog(cType.ERROR,'No tables to save');
				return
			end
			% Check Folder and print info file
			[~,name,ext]=fileparts(filename);
			folder=strcat('.',filesep,name,'_csv');
			% Write the info directory
			try
				fid = fopen(filename, 'wt');
				fprintf (fid, '%s', folder);
				fclose (fid);
			catch err
				log.messageLog(cType.ERROR,err.message)
				log.messageLog(cType.ERROR,'Writting file info %s',filename);
				return
			end
			if ~exist(folder,'dir')
				mkdir(folder);
			end
			% Save Index file
			tidx=obj.tableIndex;
			fname=strcat(folder,filesep,'index',ext);
			slog=exportCSV(tidx,fname);
			if ~slog.isValid
				log.addLogger(slog);
				log.messageLog(cType.ERROR,'Index file is NOT saved');
			end
			% Save each table in a file
            for i=1:obj.NrOfTables
				tbl=obj.tableIndex.Content{i};
				fname=strcat(folder,filesep,tbl.Name,ext);
				slog=exportCSV(tbl,fname);
				if ~slog.isValid
					log.addLogger(slog);
					log.messageLog(cType.ERROR,'file %s is NOT saved',fname);
				end
            end
		end

        function log=saveAsXLS(obj,filename)
        % Save the result tables in a Excel file, each table in a worksheet.
		%   Usage:
		%       log=obj.saveASXLS(filename)
		%  Input:
		%       filename - name of the worksheet file
		%  Output:
		%       log - cStatusLog object with error messages
			log=cStatusLogger(cType.VALID);
			% Check Input
			if obj.tableIndex.NrOfRows<1
				log.messageLog(cType.ERROR,'No tables to save');
				return
			end
			% Open file
			if isOctave
				try
					fId=xlsopen(filename,1);
				catch err
					log.messageLog(cType.ERROR,err.message);
					log.messageLog(cType.ERROR,'Error open file %s',filename);
					return
				end
			else
				fId=filename;
			end
			% Save table index sheet
			tidx=obj.tableIndex;
			if isOctave
				[fId,status]=oct2xls(tidx.Values,fId,'Index');
				if ~status || isempty(fId)
					log.messageLog(cType.ERROR,'Index Sheet is NOT saved');
					return
				end
			else
				try
					writecell(tidx.Values,fId,'Sheet','Index');
				catch err
					log.messageLog(cType.ERROR,err.message);
					log.messageLog(cType.ERROR,'Index Sheet is NOT saved');
					return
				end
			end
			% Save tables
            for i=1:obj.NrOfTables
				tbl=obj.tableIndex.Content{i};
				if isOctave
					[fId,status]=oct2xls(tbl.Values,fId,tbl.Name);
					if ~status || isempty(fId)
						log.messageLog(cType.ERROR,'Sheet %s is NOT saved',tbl.Name);
					end
				else
					try
						writecell(tbl.Values,fId,'Sheet',tbl.Name);
					catch err
						log.messageLog(cType.ERROR,err.message);
						log.messageLog(cType.ERROR,'Sheet %s is NOT saved',tbl.Name);
					end
				end
            end
            if isOctave
				fId=xlsclose(fId);
				if ~isempty(fId)
					log.messageLog(cType.ERROR,'Result file %s is NOT saved',filename);
				end
            end
		end
		
		function log=saveAsHTML(obj,filename)
		% Save result tables as HTML files.
		%	Create a index file and a folder containing all the table files
		%   Usage:
		%       log=obj.saveAsHTML(filename)
		%   Input:
		%       filename - Name of the index file
		%   Output:
		%       log - cStatusLog object with error messages
			log=cStatusLogger(cType.VALID);
			% Check Input
			if obj.tableIndex.NrOfRows<1
				log.messageLog(cType.ERROR,'No tables to save');
				return
			end
			% Get folder name and create it.
			[~,name,ext]=fileparts(filename);
			folder=strcat('.',filesep,name,'_html');
			if ~exist(folder,'dir')
				mkdir(folder);
			end
			% Create html index page
			html=cBuildHTML(obj.tableIndex,folder);
			log=html.saveTable(filename);
			% Save each table in a file
			for i=1:obj.NrOfTables
				tbl=obj.tableIndex.Content{i};
				fname=strcat(folder,filesep,tbl.Name,ext);
				html=cBuildHTML(tbl);
				slog=html.saveTable(fname);
				if ~slog.isValid
					log.addLogger(slog);
					log.messageLog(cType.ERROR,'file %s is NOT saved',fname);
				end
			end
		end

		function log=saveAsTXT(obj,filename)
		% Save the result tables if a formatted text file
		%   Usage:
		%       log=saveAsTXT(filename)
		%   Input:
		%       filename - name of the worksheet file
		%   Output:
		%       log - cStatusLog object with save status and error messages
			log=cStatusLogger(cType.VALID);
			% Open text file
			try
				fId = fopen (filename, 'wt');
			catch err
				log.messageLog(cType.ERROR,err.message)
				log.messageLog(cType.ERROR,'Open file %s',filename);
				return
			end
			% Print tables into file
			cellfun(@(x) printTable(x,fId),obj.tableIndex.Content);
			fclose(fId);
		end

		function log=saveAsLaTeX(obj,filename)
		% Save the tables into a file in LaTeX format
		%   Usage:
		%       log=saveAsLaTeX(filename)
		%   Input:
		%       filename - name of the file
		%   Output:
		%       log - cStatusLog object with save status and error messages
			log=cStatusLogger(cType.VALID);
			% Open text file
			try
				fId = fopen (filename, 'wt');
			catch err
				log.messageLog(cType.ERROR,err.message)
				log.messageLog(cType.ERROR,'Open file %s',filename);
				return
			end
			% Save the tables in the file
			for i=1:obj.NrOfTables
				tbl=obj.tableIndex.Content{i};
				ltx=cBuildLaTeX(tbl);
				fprintf(fId,'%s',ltx.getLaTeXcode);
			end
			fclose(fId);
		end
    end
end
