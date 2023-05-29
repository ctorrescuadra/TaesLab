classdef (Sealed) cReadModelXLS < cReadModelTable
% cReadModelXLS implements the cReadModel to read XLSX data model files
%   This class read a XLSX file containing the thermoeconomic model data
%   and store it into a structure data
%   Methods:
%       obj=cReadModelXLS(cfgfile)
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
        function obj = cReadModelXLS(cfgfile)
        % Construct an instance of the class
		%	cfgfile - xlsx file containig the model of the plant
		%
            % Read configuration file
            Sheets=cType.getInputTables;
            if isOctave
				try
					xls=xlsopen(cfgfile);
                	sht=xls.sheets.sh_names;
				catch err
                    obj.messageLog(cType.ERROR,err.message);
					obj.messageLog(cType.ERROR,'File %s cannot be opened',cfgfile);
					return
				end
			else %is Matlab interface
				sht=sheetnames(cfgfile);
				xls=cfgfile;
            end
            check=ismember(Sheets,sht);
            % Read mandatory tables
            tables=struct();
            for i=cType.MandatoryTables
                wsht=Sheets{i};
                if check(i)
                    tbl=cReadModelXLS.importSheet(xls,wsht);
                    if tbl.isValid
                        tbl.setDescription(wsht)
                        tables.(wsht)=tbl;
                    else
                        obj.addLogger(tbl);
					    obj.messageLog(cType.ERROR,'Error reading sheet %s:%s',cfgfile,wsht);
                        return
                    end
                else
					obj.messageLog(cType.ERROR,'sheet %s:%s does not exists',cfgfile,wsht);
                    return
                end
            end
            % Read optional tables 
            for i=cType.OptionalTables
                wsht=Sheets{i};
                if check(i)
                    tbl=cReadModelXLS.importSheet(xls,wsht);
                    if tbl.isValid
                        tbl.setDescription(wsht)
                        tables.(wsht)=tbl;
                    else
                        obj.addLogger(tbl);
					    obj.messageLog(cType.ERROR,'Error reading sheet %s:%s',cfgfile,wsht);
                    end
                end  
            end
            % Get model filename
            [~,name]=fileparts(cfgfile);
            obj.ModelFile=strcat(pwd,filesep,name,cType.FileExt.CSV);
            obj.ModelName=name;
            tableModel=cModelTables(cType.ResultId.DATA_MODEL,tables);
            tableModel.setProperties(name);
            obj.Tables=tableModel;
            % Build Data Model
            obj.buildDataModel(tableModel);
            if obj.isValid
                obj.setModelProperties;
            end
        end 
    end

    methods(Static, Access=private)
        function tbl=importSheet(xls,wsht)
        %Import a workbook/sheet 
            tbl=cStatusLogger;
            if isOctave
		        if ~isstruct(xls)
			        tbl.messageLog(cType.ERROR,'Invalid XLS pointer');
			        return
		        end
		        % Read file and store into a cell
		        try
			        values=xls2oct(xls,wsht);
                catch err
			        tbl.messageLog(cType.ERROR,err.message);
			        return
		        end
            else %Matlab
                if ~exist(xls,'file')
                    tbl.messageLog(cType.ERROR,'File %s not found',xls);
                    return
                end
                % Read file and store into a cell
		        try
		            values=readcell(xls,'Sheet',wsht);
                catch err
			        tbl.messageLog(cType.ERROR,err.message);
		        end
            end
            tbl=cTableData(values);
        end
    end
end