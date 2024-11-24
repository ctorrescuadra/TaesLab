classdef cMessages
    properties(Constant)
        InvalidDataModelFile='Data model file %s is NOT valid'
        ValidDataModel='Data model %s is valid'
        InvalidArgument='Invalid Input Argument'
        InvalidInputFile='Invalid file name %s'
        InvalidOutputFile='Invalid file name %s. File NOT saved'
        InvalidFileExt='Invalid file name extension: %s'
        FileNotExist='File %s does NOT exists'
        DataModelRequired='First argument must be a Data Model'
        ResultSetRequired='First argument must be a cResultSet object'
        TableRequired='First argument must be a cTable object'
        % Invalid Objects
        InvalidDataModel='Invalid Data Model. See error log'
        InvalidResultSet='Invalid cResultSet object. See error log'
        InvalidProductiveStructure='Invalid Productive Structure. See error log'
        InvalidExergyModel='Invalid Exergy Model. See error log'
        InvalidExergyData='Invalid exergy data for state %s. See error log'
        InvalidDiagramFP='Invalid DiagramFP. See error log'
        InvalidDiagramSFP='Invalid Productive Diagram. See error log'
        InvalidDiagnosis='Invalid Diagnosis. See error log'
        InvalidCostAnalysis='Invalid Thermoeconomic Analysis. See error log'
        InvalidWasteData='Invalid Waste Data. See error log'
        InvalidWasteAnalysis='Invalid Waste Analysis. See error log'
        InvalidWasteFlow='Invalid waste flow key %s'
        InvalidSummary='Invalid Summary Results. See error log'
        InvalidResourceData='Invalid Resource Data for sample %s. See error log'
        InvalidResourceCost='Invalid Resource Cost for sample %s. See error log'
        InvalidTable='Invalid Table %s. See error log'
        InvalidTableValues='Invalid Table %s values'
        InvalidTableGUI='Invalid uitable %s'
        InvalidTableDict='Invalid Tables Dictionary'
        InvalidState='State %s does NOT exist'
        InvalidSample='Resource sample %s does NOT exist'
        NoGraphTable='Table %s has NOT graph'
        NoWasteDefined='Waste Data Model is required'
        % Usage Base Functions
        UseCopyDataModel='Usage: CopyDataModel(inputFile,outputFile)'
        UseProductiveStructure='Usage: ProductiveStructure(data,options)'
        UseProductiveDiagram='Usage: ProductiveDiagram(data,options)'
        UseExergyAnalysis='Usage: res=ExergyAnalysis(data,options)'
        UseDiagramFP='Usage: res=DiagramFP(data,options)'
        UseCostAnalysis='Usage: res=ThermoeconomicAnalysis(data,options)'
        UseDiagnosis='Usage: res=ThermoeconomicDiagnosis(data,options)'
        UseWasteAnalysis='Usage: res=WasteAnalysis(data,options)'
        UseSummary='Usage: res=SummaryResults(data,option)'
        UseListResultTables='Usage: res=ListResultTables(options)'
        UseShowGraph='Usage: ShowGraph(res,options)'
        UseShowResults='Usage: res=ShowResults(arg,options)'
        UseShowTable='Usage: res=ShowTable(tbl,options)'
        UseExportResults='Usage: res=ExportResults(res,options)'
        UseSaveResults='Usage: SaveResults(res,filename)'
        UseSaveDataModel='Usage: SaveDataModel(res,filename)'
        UseSaveSummary='Usage: SaveSummary(res,filename)'
        UseSaveTable='Usage: SaveTable(tbl,filename)'
        UseThermoeconomicModel='Usage: model=ThermoeconomicModel(filename,options)'
        UseViewResults='Usage: ViewResults(res)'
        % Other Messages
        ResultVarInfo='%s results available in workspace'
        SummaryNotAvailable='Summary Results are NOT available'
        FileNotSaved='File %s NOT saved. See error log'
        FileReadError='Error reading file %s'
        InvalidObject='Invalid object'
        NoReadMatFiles='Read MAT files is not yet implemented for Octave'
        TableNotAvailable='Table is NOT available'
        % ExergyData
        InvalidDataSetSize='Invalid number of exergy values %d'
        % Diagnosis
        ExergyCostRequired='Input parameters are NOT cExergyCost objects'
        DiagnosisNotAvailable='Thermoeconomic Diagnosis is NOT available'
        InvalidDiagnosisState='Reference and Operation states are equals'
        InvalidDiagnosisStruct='Compare two different productive structures'
        InvalidDiagnosisConf='Compare two different plant configurations'
        InvalidDiagnosisMethod='Invalid Diagnosis Method'
        % cSparseRow messages
        InvalidRowValues='Invalid cSparseRow arguments. Rows and Values dimensions must agree'
        InvalidRowSize='Invalid cSparseRow arguments. Number of Rows must agree'
        InvalidSparseRow='Matrix dimensions must agree: %d %d'
        % Info Messages
        InfoFileSaved='%s is saved in file %s'
        InfoDebug='Debug is set to %s'
        TableFileSaved='Table %s has been saved in file %s'
        NoResourceData='Processes cost data is missing. Default values are assumed'
        ProcessNotActive='Process %s is not active'
        % Data Model Info
        ValidProductiveStructure='Productive Structure is valid'
        ValidFormatDefinition='Format Definition is valid'
        ValidExergyData='Exergy values [%s] are valid'
        ValidWasteDefinition='Waste Definition is valid'
        ValidResourceCost='Resources Cost sample [%s] is valid'
        WasteNotAvailable='Waste Definition is not available. Default is assumed';
        NoWasteModel='The model has NOT waste'
        ResourceNotAvailable='No Resources Cost Data available'
    end


    methods(Static)
        function res=Table
            rowNames=fieldnames(cMessages)';
            N=length(rowNames);
            data=cell(N,1);
            for i=1:N
                data{i}=cMessages.(rowNames{i});
            end
            colNames={'key','message'};
            props.Name='tmsg';props.Description='Messages Table';
            props.State='MESSAGES';props.Sample=cType.EMPTY_CHAR;
            res=cTableData(data,rowNames,colNames,props);
            res.setStudyCase(props);
            if nargout<1
                printTable(res);
            end
        end
    end

end