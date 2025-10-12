classdef cMessages
%cMessages - Static class which defines the TaesLab messages.
% 
%   cMessages methods:
%     Table    - get the message tables
%     ShowHelp - generate a hyperlink text to the help of the function caller
%
    properties(Constant)
        % Read Model messages
        InvalidInputFile='Invalid file name %s'
        InvalidOutputFile='Invalid file name %s. File NOT saved'
        InvalidFileExt='File extension %s is not supported'
        FileNotFound='File %s NOT found'
        CSVFolderNotExist='CSV folder data %s NOT exists'
        FileNotRead='Error reading file %s'
        SheetNotExist='Sheet %s NOT exists'
        SheetNotRead='Sheet %s NOT read'
        NoReadFiles='Read %s files is not implemented in Octave'
        NoSaveFiles='Save %s files is not implemented in Octave'
        InvalidDataModelFile='Data model file %s is NOT valid'
        ModelDataMissing='%s data is missing'
        InvalidMatFileObject='Invalid %s object from file %s'
        NoDataModel='MAT file does not contains a valid Data Model'
        % Input arguments messages
        NarginError='Invalid number of input arguments. %s'
        InvalidArgument='Invalid input arguments. %s'
        DataModelRequired='First argument must be a valid Data Model'
        ResultSetRequired='First argument must be a valid cResultSet object'
        TableRequired='First argument must be a valid cTable object'
        % Invalid objects messages
        InvalidObject='Invalid %s object. See error log'
        InvalidDataModel='Invalid data model. See error log'
        InvalidResultId='Invalid result id %d'
        InvalidResourceModel='Invalid resource cost data model. See error log'
        InvalidWasteData='Invalid waste data. See error log'
        InvalidExergyData='Invalid exergy data for state [%s]. See error log'
        InvalidResourceData='Invalid resource data for sample [%s]. See error log'
        InvalidResourceCost='Invalid resource cost for sample [%s]. See error log'
        InvalidStateList='Invalid Exergy states list'
        InvalidSampleList='Invalid Resource samples list'
        NodeNotReachedFromSource='Process %s not reached from resources'
        OutputNotReachedFromNode='Output not reached from Process %s'
        % Invalid Model Table definitions
        InvalidFieldNumber='Invalid number of fields %d in table %s'
        InvalidField='Invalid column %s in table %s'
        InvalidFieldDatatype='Invalid data type for column %s in table %s'
        InvalidKey='Key %s is invalid'
        DuplicateKey='Duplicate key %s'
        InvalidCaseName='Invalid Case %s'
        DuplicateCaseName='Duplicate Case %s'
        InvalidProcessTableKey='Invalid process key %s in table %s'
        InvalidFlowTableKey='Invalid flow key %s in table %s'
        InvalidManualAllocation='No Manual Waste Allocation defined'
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
        InvalidSampleName='Invalid resource sample name %s'
        StateAlreadyExists='State %s already exists'
        SampleAlreadyExists='Resource Sample %s already exists'
        % Save messages
        FileNotSaved='File %s NOT saved. See error log'
        NoTableToSave='No tables to save'
        IndexTableNotSave='Index table not saved'
        TableNotSaved='Table %s is NOT saved'
        InfoFileSaved='%s is saved in file %s'
        TableFileSaved='Table %s has been saved in file %s'
        % Data Model Info
        ValidDataModel='Data model %s is valid'
        ResultVarInfo='%s results available in workspace'
        ValidProductiveStructure='Productive Structure is valid'
        ValidFormatDefinition='Format Definition is valid'
        ValidExergyData='Exergy values [%s] are valid'
        ValidWasteDefinition='Waste Definition is valid'
        ValidResourceCost='Resources Cost sample [%s] is valid'
        WasteNotAvailable='Waste Definition is not available. Default is assumed'
        ResourceNotAvailable='No Resources Cost Data available'
        NoResourceData='Processes cost data is missing. Default values are assumed'
        % Productive Structure messages
        DuplicatedFlow='There are duplicated flows in Dictionary'
        DuplicatedProcess='There are duplicated processses in Dictionary'
        InvalidProductiveGraph='Invalid productive structure graph'
        InvalidFlowType='Invalid type %s for flow %s'
        InvalidProcessType='Invalid type %s for process %s'
        InvalidResourcesType='Invalid type %s for resource %s'
        InvalidFuelStream='Invalid fuel stream %s in process %s'
        InvalidProductStream='Invalid product stream %s in process %s'
        InvalidDissipative='Product %s of dissipative process %s must be a waste'
        InvalidStreamToFlow='Flow %s has not correct (FROM) definition'
        InvalidFlowToStream='Flow %s has not correct (TO) definition'
        InvalidOutputFlow='Invalid output flow %s definition'
        InvalidWasteFlow='Invalid waste flow %s definition'
        InvalidResourceFlow='Invalid resource flow %s definition'
        InvalidFlowDefinition='Flow %s is no used'
        InvalidFlowLoop='Flow %s is defined as a LOOP'
        NoResources='Data Model has no resource flows defined'
        NoOutputs='Data Model has no final products defined'
        % Format messages
        InvalidFormatDefinition='Invalid format data structure'
        InvalidFormatKey='Invalid format key %s'
        BadFormatDefinition='Bad format definition for %s'
        % ExergyData messages
        InvalidExergyKeys='Exergy Flow keys are not well defined'
        InvalidExergyDataSize='Invalid number of exergy values %d'
        InvalidExergyDefinition='Invalid exergy data structure definition'
        NegativeExergyFlow='Exergy of flow %s is negative %f'
        NegativeExergyStream='Exergy of stream %s is negative %f'
        NegativeIrreversibilty='Irreversibility of process %s is negative %f'
        ZeroProduct='Product of process %s is zero'
        ProcessNotActive='Process %s is not active'
        NoProductiveState='The data model is not productive for state %s'
        SingularMatrix='The matrix is singular'
        NegativeMatrix='The Matrix has negative elements'
        % Diagnosis
        ExergyCostRequired='Input parameters are NOT cExergyCost objects'
        DiagnosisNotAvailable='Thermoeconomic Diagnosis is NOT available'
        InvalidDiagnosisState='Reference and Operation states are equals'
        InvalidDiagnosisStruct='Compare two different productive structures'
        InvalidDiagnosisConf='Compare two different plant configurations'
        InvalidDiagnosisMethod='Invalid Diagnosis Method %s'
        % Waste messages
        NoWasteModel='The model has NOT waste'
        NoWasteFlows='No WASTE flows defined'
        InvalidWasteAllocation='Invalid allocation method %s for waste %s'
        InvalidWasteType='Invalid type %s for waste %s'
        InvalidRecycling='Invalid recycle ratio %f for waste %s'
        InvalidWasteValues='Invalid waste values for waste %s'
        NoWasteFlow='Flow %s must be defined as waste'
        NoWasteAllocationValues='No allocation values defined for waste %s'
        NegativeWasteAllocation='Waste allocation value for waste %s cannot be NEGATIVE %f'
        InvalidAllocationProcess='Waste cannot be allocated to a dissipative units %s'
        InvalidWasteOperator='The waste operator for State %s is singular or bad conditioned'
        InvalidWasteDefinition='Invalid waste definition. See error log.'
        % Resource messages
        InvalidResourceValue='Resource %s value is negative %f'
        InvalidZSize='Invalid resource process size %d'
        InvalidCSize='Invalid resource flow size %d'
        NegativeResourceValue='Resource values must be non-negative'
        InvalidProcessValues='Invalid resource values'
        ZeroResourceCost='Total resource-Flow cost is zero'
        NoProcessResourceData='No resource process data'
        % Summary messages
        SummaryNotAvailable='Summary Results NOT available'
        InvalidSummaryOption='Invalid summary option'
        InvalidSummaryData='Invalid summary dataset'
        % Table messages
        InvalidConfigFile='Invalid config file %s'
        InvalidTableSize='Invalid table size (%d x %d)'
        InvalidTableProp='Invalid table properties. See error log'
        InvalidResultTables='Invalid results tables'
        InvalidTableIndex='Invalid table index'
        InvalidVTableView='Invalid table view option'
        TableNotCreated='Error creating table %s. See error log'
        TableNotFound='Table %s NOT found'
        TableNotAvailable='Table %s is NOT available'
        InvalidTable='Invalid table %s. See error log'
        InvalidTableValues='Invalid table %s values'
        InvalidTableGUI='Invalid uitable %s'
        InvalidTableDict='Invalid tables dictionary'
        InvalidTableDefinition='Invalid tables definition'
        NoValuesAvailable='No values available %s'
        InvalidColumnNames='Columns %s are invalid'
        % Graph messages
        GraphNotImplemented='Graph function NOT implemented in Octave'
        InvalidGraph='Invalid graph %s'
        InvalidGraphType='Invalid graph type %s'
        % Thermoeconomic Model messages
        ResultNotAvailable='%s NOT available'
        InvalidCostTable='Invalid Cost Tables parameter value: %s'
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
        InfoDebug='Debug is set to %s'
        % cSparseRow messages
        InvalidRowValues='Invalid cSparseRow arguments. Number of valus must agree'
        InvalidRowSize='Invalid cSparseRow arguments. Number of Rows must agree'
        InvalidSparseRow='Matrix dimensions must agree: %d %d'
        InvalidNodeNames='Invalid number of nodes %d - %d';
        NonSquareMatrix='Non square matrix [%d x %d]';
        % Dictionary messages
        ListNotCell='List must be a cell array'
        ListEmpty='List must NOT be empty'
        ListNotUnique='List values must be unique'
        ListNotValid='List values are invalid'
        % Digraph analysis
        InvalidDigraph='Invalid Digraph Analysis'
        NoTableFP='The table %s is not a FP-Table';
        % Function messages
        NotImplemented='Function %s NOT implemented in Octave'
        ScaleColsError='Matrix must have the same number of columns than the scale vector'
        ScaleRowsError='Matrix must have the same number of rows than the scale vector'
        SquareMatrixError='Input must be a square matrix'
        NonNegativeMatrixError='Input matrix must be square and non-negative'
    end

    methods(Static)
        function res = Table
        % Get or show in console a table with all the messages or show in console
        %   If no output argument table is shown in console, else a cTableData is created
        % Syntax:
        %   cMessages.Table
        % Output Arguments:
        %   res - cTable with the messages
        %
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

        function res = ShowHelp
        % Get a string with the hyperlink to the help of the caller function
        % Syntax:
        %   cMessages.ShowHelp
        % Output:
        %   res - hyperlink text
        %
            res=cType.EMPTY_CHAR;
            stack = dbstack('-completenames');
            if numel(stack)<2
                return
            end
            fname=stack(2).name;
            if isOctave
                res=sprintf('See %s documentation.',fname);
            else
                res=sprintf('See help <a href="matlab:help(''%s'')">%s</a>',fname,fname);
            end
        end
    end

end