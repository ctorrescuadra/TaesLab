classdef cMessages
    properties(Constant)
        InvalidDataModelFile='Data model file %s is NOT valid'
        ValidDataModel='Data model %s is valid'
        InvalidArgument='Invalid Input Argument'
        ParametersMissing='Parameters missing'
        DataModelRequired='First argument must be a Data Model'
        ResultSetRequired='First argument must be a cResultSet object'
        TableRequired='First argument must be a cTable object'
        TableNotCreated='Error creating table %s. See error log'
        InvalidTableName='Invalid table name'
        % Read files
        InvalidInputFile='Invalid file name %s'
        InvalidOutputFile='Invalid file name %s. File NOT saved'
        InvalidFileExt='File extension %s is not supported'
        FileNotExist='File %s does NOT exists'
        CSVFolderNotExist='CSV folder data %s NOT exists'
        FileNotRead='Error reading file %s'
        SheetNotExist='Sheet %s NOT exists'
        SheetNotRead='Sheet %s NOT read'
        NoReadFiles='Read %s files is not yet implemented in Octave'
        TableNotFound='Table %s NOT found'
        InvalidXLS='Invalid XLSX file'
        % Invalid Objects
        InvalidThermoeconomicModel='Invalid thermoeconomic model. See error log'
        InvalidDataModel='Invalid Data Model. See error log'
        InvalidResultSet='Invalid cResultSet object. See error log'
        InvalidResultId='Invalid result id %d'
        InvalidProductiveStructure='Invalid Productive Structure. See error log'
        InvalidFormatData='Invalid Format Definition. See error log'
        InvalidExergyModel='Invalid Exergy Model. See error log'
        InvalidResourceModel='Invalid resource cost data model. See error log'
        InvalidExergyData='Invalid exergy data for state %s. See error log'
        InvalidDiagramFP='Invalid DiagramFP. See error log'
        InvalidDiagramSFP='Invalid Productive Diagram. See error log'
        InvalidDiagnosis='Invalid Diagnosis. See error log'
        InvalidCostAnalysis='Invalid Thermoeconomic Analysis. See error log'
        InvalidWasteData='Invalid Waste Data. See error log'
        InvalidWasteAnalysis='Invalid Waste Analysis. See error log'
        InvalidSummary='Invalid Summary Results. See error log'
        InvalidResourceData='Invalid Resource Data for sample %s. See error log'
        InvalidResourceCost='Invalid Resource Cost for sample %s. See error log'
        InvalidTable='Invalid Table %s. See error log'
        InvalidTableValues='Invalid Table %s values'
        InvalidTableGUI='Invalid uitable %s'
        InvalidTableDict='Invalid Tables Dictionary'
        InvalidStateList='Invalid states list'
        InvalidSampleList='Invalid samples list'
        InvalidState='State %s does NOT exist'
        InvalidSample='Resource sample %s does NOT exist'
        NoGraphTable='Table %s has NOT graph'
        ModelDataMissing='%s data is missing'
        % Invalid keys
        InvalidFlowId='Invalid flow Id %d'
        InvalidProcessId='Invalid process Id %d'
        InvalidTextKey='Invalid text key %s'
        InvalidFlowKey='Invalid flow key %s'
        InvalidProcessKey='Invalid process key %s'
        InvalidResourceKey='Invalid resource flow key %s'
        InvalidWasteKey='Invalid waste flow key %s'
        InvalidDataSetKey='Invalid dataset key'
        InvalidStateName='Invalid state name %s'
        InvalidResourceName='Invalid resource name %s'
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
        FileNotSaved='File %s NOT saved. See error log'
        InvalidObject='Invalid object'
        TableNotAvailable='Table is NOT available'
        % ExergyData
        InvalidExergyDataSize='Invalid number of exergy values %d'
        InvalidExergyDefinition='Invalid exergy data structure definition'
        NegativeExergyFlow='Exergy of flow %s is negative %f'
        NegativeExergyStream='Exergy of stream %s is negetive %f'
        NegativeIrreversibilty='Irreversibility of process %s is negative %f'
        ZeroProduct='Product of process %s is zero'
        % Diagnosis
        ExergyCostRequired='Input parameters are NOT cExergyCost objects'
        DiagnosisNotAvailable='Thermoeconomic Diagnosis is NOT available'
        InvalidDiagnosisState='Reference and Operation states are equals'
        InvalidDiagnosisStruct='Compare two different productive structures'
        InvalidDiagnosisConf='Compare two different plant configurations'
        InvalidDiagnosisMethod='Invalid Diagnosis Method %s'
        % cSparseRow messages
        InvalidRowValues='Invalid cSparseRow arguments. Number of valus must agree'
        InvalidRowSize='Invalid cSparseRow arguments. Number of Rows must agree'
        InvalidSparseRow='Matrix dimensions must agree: %d %d'
        % Info Messages
        InfoFileSaved='%s is saved in file %s'
        InfoDebug='Debug is set to %s'
        TableFileSaved='Table %s has been saved in file %s'
        NoResourceData='Processes cost data is missing. Default values are assumed'
        ProcessNotActive='Process %s is not active'
        % Data Model Info
        ResultVarInfo='%s results available in workspace'
        ValidProductiveStructure='Productive Structure is valid'
        ValidFormatDefinition='Format Definition is valid'
        ValidExergyData='Exergy values [%s] are valid'
        ValidWasteDefinition='Waste Definition is valid'
        ValidResourceCost='Resources Cost sample [%s] is valid'
        WasteNotAvailable='Waste Definition is not available. Default is assumed';
        NoWasteModel='The model has NOT waste'
        ResourceNotAvailable='No Resources Cost Data available'
        % Dictionary messages
        ListNotCell='List must be a cell array'
        ListEmpty='List must NOT be empty'
        ListNotUnique='List values must be unique'
        ListNotValid='List values are invalid'
        % Waste messages
        NoWasteDefined='Waste Data Model is required'
        InvalidWasteAllocation='Invalid allocation method %s for waste %s'
        InvalidWasteType='Invalid type %s for waste %s'
        InvalidRecycling='Invalid recycle ratio %f for waste %s'
        NoWasteFlow='Flow %s must be defined as waste'
        NoWasteAllocationValues='No allocation values defined for waste %s'
        NegativeWasteAllocation='Waste allocation value for waste %s cannot be NEGATIVE %f'
        InvalidAllocationProcess='Waste %s cannot be asssigned to dissipative units'
        % Format messages
        InvalidFormatDefinition='Invalid format data structure'
        InvalidFormatKey='Invalid format key %s'
        BadFormatDefinition='Bad format definition for %s'
        % Graph messages
        GraphNotImplemented='Graph function NOT implemented in Octave'
        InvalidGraph='Invalid graph %s'
        InvalidGraphType='Invalid graph type %s'
        % Productive Structure messages
        DuplicatedFlow='There is duplicated flows'
        DuplicatedProcess='There is duplicated processes'
        InvalidProductiveGraph='Invalid productive structure graph'
        InvalidFlowType='Invalid type %s for flow %s'
        InvalidProcessType='Invalid type %s for process %s'
        InvalidFuelStream='Invalid fuel stream %s in process %s'
        InvalidProductStream='Invalid product stream %s in process %s'
        InvalidDissipative='Product %s of dissipative process %s must be a waste'
        InvalidStreamToFlow='Flow %s has not correct (FROM) definition'
        InvalidFlowToStream='Flow %s has not correct (TO) definition'
        InvalidOutputFlow='Invalid output flow %s definition'
        InvalidWasteFlow='Invalid waste flow %s definition'
        InvalidResourceFlow='Invalid resource flow %s definition'
        InvalidFlowDefiniton='Flow %s do not exist'
        InvalidFlowLoop='Flow %s is defined as a LOOP'
        % Resource messages
        InvalidResourceValue='Resource %s value is negative %f'
        InvalidZSize='Invalid resource process size %d'
        InvalidCSize='Invalid resource flow size %d'
        NegativeResourceValue='Resource values must be non-negative'
        InvalidProcessValues='Invalid resource values'
        % Table messages
        NoTableToSave='No tables to save'
        IndexTableNotSave='Index table not saved'
        TableNotSaved='Table %s is NOT saved'
        InvalidDirProp='Invalid tables directory property %s'
        InvalidConfigFile='Invalid config file %s'
        InvalidTableSize='Invalid table size (%d x %d)'
        InvalidTableProp='Invalid table properties. See error log'
        InvalidTableIndex='Invalid table index'
        InvalidViewTable='Invalid Table View option'
    
        % Summary messages
        SummaryNotAvailable='Summary results are NOT available'
        InvalidSummaryOption='Invalid summary option'
        InvalidSummaryData='Invalid summary dataset'
        % Thermoeconomic Model messages
        InvalidCostTable='Invalid Cost Tables parameter value: %s'
        ResultNotAvailable='%s NOT available'
        NoGeneralizedCost='No generalized cost activated'
        NoSetExergyData='Cannot change Reference State values'
        NoParameterChange='No parameter change. The new value is equal to the previous one'
        SetState='Set state %s'
        SetReferenceState='Set reference state %s'
        SetResourceSample='Set resource sample %s'
        SetActiveWaste='Set active waste %s'
        SetSummaryMode='Summary mode is %s'
        RecycleActive='Recycle is active'
        RecycleNotActive='Recycle is not active'
        SetAllocationType='Set allocation of waste %s to %s'
        SetWasteValues='Set allocation values of waste %s'
        SetRecycleRatio='Change recycling ratio for waste %s'
        ComputeTA='Compute thermoeconomic analysis for state %s'
        NoComputeTA='Thermoeconomic analysis cannot be calculated for state %s'
        DiagnosisNotActivated='Thermoeconomic diagnosis is not activated'
        ComputeTD='Compute thermoeconomic diagnosis for state %s'
        NoComputeTD='Thermoeconomic diagnosis cannot be calculated for state %s'
        ComputeSummary='Compute Summary Results %s'
        ComputeRecycling='Compute Recycling Analysis: %s'
        ComputeDiagramFP='Compute Diagram FP'
        ComputeProductiveDiagram='Productive Diagram Active'
        InvalidRecyclingParameter='Invalid Recycling value. Must be true/false'

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