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
        InvalidExergyData='Exergy values are NOT correct. See error log'
        InvalidDiagramFP='Invalid DiagramFP. See error log'
        InvalidDiagramSFP='Invalid Productive Diagram. See error log'
        InvalidDiagnosis='Invalid Diagnosis. See error log'
        InvalidCostAnalysis='Invalid Thermoeconomic Analysis. See error log'
        InvalidWasteData='Invalid Waste Data. See error log'
        InvalidWasteAnalysis='Invalid Waste Analysis. See error log'
        InvalidWasteFlow='Invalid waste flow key %s'
        InvalidSummary='Invalid Summary Results. See error log'
        InvalidResourceCost='Invalid Resource Cost. See error log'
        InvalidTable='Invalid Table %s. See error log'
        InvalidState='Invalid state %s'
        InvalidSample='Invalid resource sample %s'
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
        % Diagnosis
        ExergyCostRequired='Input parameters are NOT cExergyCost objects'
        DiagnosisNotAvailable='Thermoeconomic Diagnosis is NOT available'
        InvalidDiagnosisState='Reference and Operation states are equals'
        InvalidDiagnosisStruct='Compare two different productive structures'
        InvalidDiagnosisConf='Compare two different plant configurations'
        InvalidDiagnosisMethod='Invalid Diagnosis Method'
        % Info Messages
        InfoFileSaved='%s is saved in file %s'
        InfoDebug='Debug is set to %s'
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