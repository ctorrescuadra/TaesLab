classdef cReadModelCSV < cReadModelTable
% cReadModelCSV implements the cReadModel to read XLSX data model files
%   This class read a set of CSV files containing the thermoeconomic model data
%   and build the data model
%
% See also cReadModel, cReadModelTable
%
    methods
        function obj=cReadModelCSV(cfgfile)
        % Construct an instance of the class
		%	cfgfile - xlsx file containig the model of the plant
		% 
            % Read configuration file
			folder=fileread(cfgfile);
            if ~exist(folder,'dir')
                obj.messageLog(cType.ERROR,'CSV folder data: %s not exists',folder);
				return
            end
            tables=struct();
            Sheets=cType.TableDataName;
            % Read Mandatory Tables
            for i=cType.MandatoryTables
                sname=Sheets{i};
                fname=strcat(sname,cType.FileExt.CSV);
                filename=strcat(folder,cType.getPathDelimiter,fname);
                if exist(filename,'file')
                    tbl=cReadModelCSV.import(filename);
                    if tbl.isValid
                        tbl.setProperties(sname,cType.TableDataDescription{i})
                        tables.(sname)=tbl;
                    else
                        obj.addLogger(tbl);
					    obj.messageLog(cType.ERROR,'Error reading CSV file: %s',fname);
                        return
                    end
                else
				    obj.messageLog(cType.ERROR,'File %s not found',fname);
                    return
                end
            end
            % Read Optional Tables
            for i=cType.OptionalTables
                sname=Sheets{i};
                fname=strcat(sname,cType.FileExt.CSV);
                filename=strcat(folder,filesep,fname);
                if exist(filename,'file')
                    tbl=cReadModelCSV.import(filename);
                    if tbl.isValid
                        tbl.setProperties(sname,cType.TableDataDescription{i})
                        tables.(sname)=tbl;
                    else
                        obj.addLogger(tbl);
					    obj.messageLog(cType.ERROR,'Error reading CSV file: %s',fname);
                    end
                end
            end
            % Set Model properties
            obj.modelTables=tables;
            obj.setModelProperties(cfgfile);
            obj.ModelData=obj.buildModelData(tables);
        end
    end

    methods(Static, Access=private)
        function tbl=import(filename)
        % import a CSV file
            tbl=cMessageLogger;
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
            tbl=cTableData.create(values);
        end
    end
end