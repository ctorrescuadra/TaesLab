classdef cReadModelCSV < cReadModelTable
% cReadModelCSV implements the cReadModel to read XLSX data model files
%   This class read a set of CSV files containing the thermoeconomic model data
%   and store it into a structure data
%   Methods:
%       obj=cReadModelCSV(cfgfile)
%   Methods inhereted for cReadModelTable
%		res=obj.buildDataModel(tm)
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
%   See also cReadModel, cReadModelTable
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
            Sheets=cType.getInputTables;
            % Read Mandatory Tables
            for i=cType.MandatoryTables
                sname=Sheets{i};
                fname=strcat(sname,cType.FileExt.CSV);
                filename=strcat(folder,cType.getPathDelimiter,fname);
                if cType.checkFileRead(filename)
                    tbl=cReadModelCSV.import(filename);
                    if tbl.isValid
                        tbl.setDescription(sname)
                        tables.(sname)=tbl;
                    else
                        obj.addLogger(tbl);
					    obj.messageLog(cType.ERROR,'Error Reading CSV file: %s',fname);
                        return
                    end
                else
				    obj.messageLog('File %s not found',fname);
                    return
                end
            end
            % Read Optional Tables
            for i=cType.OptionalTables
                sname=Sheets{i};
                fname=strcat(sname,cType.FileExt.CSV);
                filename=strcat(folder,filesep,fname);
                if cType.checkFileRead(filename)
                    tbl=cReadModelCSV.import(filename);
                    if tbl.isValid
                        tbl.setDescription(sname)
                        tables.(sname)=tbl;
                    else
                        obj.addLogger(tbl);
					    obj.messageLog(cType.ERROR,'Error reading CSV file: %s',fname);
                    end
                end
            end
            % Get model filename
            [~,name]=fileparts(cfgfile);
            obj.ModelFile=strcat(pwd,filesep,name,cType.FileExt.CSV);
            obj.ModelName=name;
            tableModel=cModelTables(cType.ResultId.DATA_MODEL,tables);
            tableModel.setProperties(name);
            % Build Data Model
            obj.buildDataModel(tableModel);
            if obj.isValid
                obj.Tables=tableModel;
                obj.setModelProperties;
            end
        end
    end

    methods(Static, Access=private)
        function tbl=import(filename)
        % import a CSV file
            tbl=cStatusLogger;
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
            tbl=cTableData(values);
        end
    end
end