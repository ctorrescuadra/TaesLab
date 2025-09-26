classdef cReadModelCSV < cReadModelTable
%cReadModelCSV - Implements the cReadModelTable to read XLSX data model files.
%   This class read a set of CSV files containing the thermoeconomic model data
%   and build the data model
% 
%   cReadModelCSV constructor
%     obj=cReadModelCSV(cfgfile)
%   
%   See also cReadModel, cReadModelTable
%
    methods
        function obj=cReadModelCSV(cfgfile)
        %cReadModelCSV - Build an instance of the class
        %   Read a CSV file containing the data model
        %   Syntax:
        %     obj=cReadModelCSV(cfgfile)
        %   Input Arguments:
		%	  cfgfile - csv file containig the model of the plant
		%   Output Argument:
        %     obj - cReadModel object
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
                    obj.messageLog(cType.INFO,'Optional Sheet %s is not available',sht);
                    continue
                else
				    obj.messageLog(cType.ERROR,cMessages.FileNotFound,fname);
                end
            end
            % Set Model properties
            obj.modelTables=tables;
            obj.setModelProperties(cfgfile);
            obj.ModelData=obj.buildModelData(tables);
        end
    end

    methods(Static, Access=private)
        function tbl=import(filename,props)
        %import - Read a file and store into a cModelTable object
        %   Syntax:
        %     tbl = import(filename,props)
        %   Input Arguments:
        %     filename - CSV filename
        %     props - Properties of the table
        %   Output Argument
        %     res - cModelTable object
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