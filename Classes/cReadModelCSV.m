classdef cReadModelCSV < cReadModelTable
%cReadModelCSV - Reads a CSV-based thermoeconomic data model.
%   Concrete implementation of cReadModelTable for CSV format. The input
%   file (cfgfile) is a plain-text file whose sole content is the path to
%   a directory containing one CSV file per data model table. Table names
%   and field layouts are driven by printformat.json. Optional tables are
%   skipped silently when their CSV file is absent.
%
%   Compatible with both MATLAB and Octave.
%
%   cReadModelCSV Properties (inherited from cReadModel / cReadModelTable):
%     ModelFile   - Absolute path of the input descriptor file
%     ModelName   - Model name (file name without extension)
%     ModelData   - Validated cModelData object
%     ModelTables - Struct of cModelTable objects keyed by table name
%
%   cReadModelCSV Methods:
%     cReadModelCSV    - Construct an instance and read all CSV tables
%     getDataModel     - Build and return a cDataModel object (inherited)
%     printModelTables - Display all loaded tables on the console (inherited)
%
%   See also cReadModel, cReadModelTable, cModelData, cModelTable
%
    methods
        function obj=cReadModelCSV(cfgfile)
        %cReadModelCSV - Construct an instance and read all CSV tables.
        %   Reads the folder path from cfgfile, then iterates over the
        %   tables defined in printformat.json and imports each matching
        %   CSV file into a cModelTable. Construction errors are stored
        %   in the logger; check isValid(obj) after construction.
        %
        %   Syntax:
        %     obj = cReadModelCSV(cfgfile)
        %
        %   Input Arguments:
        %     cfgfile - Path to a plain-text descriptor file whose content
        %               is the directory containing the CSV model files
        %
        %   Output Arguments:
        %     obj - cReadModelCSV object
        %
        %   See also cReadModelCSV.getDataModel
        %
        
            % Read data file
			folder=fileread(cfgfile);
            if ~exist(folder,'dir')
                obj.messageLog(cType.ERROR,cMessages.CSVFolderNotExist,folder);
				return
            end
            % Read configuration file
            config=getDataModelConfig(obj);
            if isempty(config)
                return
            end
            tables=struct();
            opts=[config.optional];
            Sheets={config.name};
            % Read Tables
            for i=1:numel(config)
                sname=Sheets{i};
                fname=strcat(sname,cType.FileExt.CSV);
                props=config(i);
                filename=strcat(folder,cType.getPathDelimiter,fname);
                if exist(filename,'file')
                    tbl=cReadModelCSV.import(filename,props);
                    if tbl.status
                        tables.(sname)=tbl;
                    else
                        obj.addLogger(tbl);
					    obj.messageLog(cType.ERROR,cMessages.FileNotRead,fname);
                        continue
                    end              
                elseif opts(i)
                    obj.messageLog(cType.INFO,'Optional Sheet %s is not available',fname);
                    continue
                else
				    obj.messageLog(cType.ERROR,cMessages.FileNotFound,fname);
                end
            end
            % Set Model properties
            if isValid(obj)
                obj.ModelTables=tables;
                obj.setModelProperties(cfgfile);
                obj.ModelData=obj.buildModelData(tables);
            end
        end
    end

    methods(Static, Access=private)
        function tbl=import(filename,props)
        %import - Read a CSV file and wrap it in a cModelTable.
        %   Uses csv2cell (Octave) or readcell (MATLAB) to load the raw
        %   cell array, then delegates validation to cModelTable.
        %
        %   Syntax:
        %     tbl = cReadModelCSV.import(filename, props)
        %
        %   Input Arguments:
        %     filename - Absolute path to the CSV file
        %     props    - Table definition struct from printformat.json
        %
        %   Output Arguments:
        %     tbl - cModelTable object, or cMessageLogger on read error.
        %           Check tbl.status before use.
        %
            tbl=cMessageLogger();
            if isOctave
		        try
			        values=csv2cell(filename);
                catch err
			        tbl.messageLog(cType.ERROR,err.message);
			        return
		        end
            else %Matlab
		        try
		            values=readcell(filename);
                catch err
			        tbl.messageLog(cType.ERROR,err.message);
                    return
		        end
            end
            tbl=cModelTable(values,props);
        end
    end
end