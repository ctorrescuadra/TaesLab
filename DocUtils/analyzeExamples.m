function tbl = analyzeExamples(varargin)
%analyzeExamples - Generate a summary table of all data model files in Examples
%
%   Syntax:
%     tbl = analyzeExamples()
%     tbl = analyzeExamples(Name, Value)
%
%   Description:
%     Batch analysis utility that searches for data model files matching the
%     pattern '*_model.*' in the Examples folder hierarchy and extracts key
%     properties from each model. The function loads each data model using
%     cDataModel.create and compiles structural information into a cTableData
%     object for inspection and comparison.
%
%     The resulting table contains one row per example with columns showing
%     the number of flows, processes, resources, states, and other model
%     properties. This provides a quick overview of the complexity and
%     composition of all example models in the repository.
%
%     Optionally, the summary table can be saved to a file
%     and debug information can be displayed during processing to show timing
%     and validation results for each model.
%
%   Name-Value Arguments:
%     Format - File format(s) to search for in Examples folder
%       char array. 
%       Valid values: 'JSON' | 'XLSX' | 'XML' | 'CSV' | 'MAT'
%       Default: 'XLSX'
%
%     SaveAs - Output file path to save the summary table
%       char array. File extension determines format
%       If empty, the table is only returned, not saved.
%
%     Debug - Display detailed progress and timing information
%       logical. If true, prints validation messages and processing
%       time (in milliseconds) for each model, plus a final summary.
%       Default: true
%
%   Output Arguments:
%     tbl - cTableData object with one row per valid example model
%       Columns contain the following information:
%         Name       - Example name (without '_model' suffix)
%         Folder     - Folder containing the example
%         Flows      - Number of flows in the productive structure
%         Processes  - Number of processes in the productive structure
%         Wastes     - Number of waste flows
%         Resources  - Number of resource (external input) flows
%         Outputs    - Number of system output flows
%         Products   - Number of final product flows
%         States     - Number of exergy states defined
%         Samples    - Number of resource cost samples defined
%         Summary    - Summary report options available for the model
%       If an error occurs, returns a cTaesLab object with error status.
%
%   Examples:
%     % Analyze all XLSX examples and display results
%     tbl = analyzeExamples();
%
%     % Analyze JSON models only, save to Excel, suppress debug output
%     tbl = analyzeExamples('Format', 'JSON', 'SaveAs', 'json_summary.xlsx', 'Debug', false);
%
%     % Analyze all formats and save to MAT file
%     analyzeExamples('Format', 'ALL', 'SaveAs', 'all_examples.mat');
%
%   Algorithm:
%     1. Parse and validate Name-Value arguments (Format, SaveAs, Debug)
%     2. Search Examples folder for files matching '*_model.ext' pattern
%     3. For each file:
%        a. Load the data model using cDataModel.create
%        b. Extract structural properties (flows, processes, states, etc.)
%        c. Optionally display validation status and timing (if Debug=true)
%     4. Compile extracted properties into a cTableData object
%     5. Optionally save the table using SaveTable (if SaveAs specified)
%     6. Display summary statistics (if Debug=true)
%
%   Notes:
%     - Only processes files matching the '*_model.*' naming convention
%     - Invalid or corrupted models are skipped (errors logged if Debug=true)
%     - Processing time is measured using tic/toc and displayed in milliseconds
%     - The function uses filesInfo to recursively search subdirectories
%     - Table properties are set to Name='examples', Description='Examples List Analysis'
%
%   See also:
%     ReadDataModel, convertExamples, cDataModel, cDataModel.create, SaveTable
%
    tbl=cTaesLab();
    % Parse input arguments
    p = inputParser;
    addParameter(p, 'Format', cType.DEFAULT_MODEL_FORMAT,@cType.checkModelFormat);
    addParameter(p, 'SaveAs', cType.EMPTY_CHAR, @isFilename);
    addParameter(p, 'Debug', true, @islogical)
    try
        p.parse(varargin{:});
    catch err
        tbl.printError(err.message);
        return
    end
    param = p.Results;  
    % Setup source folder
    sourceFolder = fullfile('Examples','**');
    mId=cType.getModelFormat(param.Format);
    pattern=strcat('*_model',cType.DataModelExt{mId});
    allModelFiles=filesInfo(sourceFolder,pattern);    
    if isempty(allModelFiles)
        tbl.printError(cMessages.NoModelsFound);
        return;
    end
    nFiles=length(allModelFiles);
    s = cell(nFiles, 1); cnt=0;   
    % Process each file
    for i = 1:nFiles
        file = allModelFiles(i);
        sourceFile = fullfile(file.folder, file.name);
        % Extract example name (without _model suffix)
        [~, baseName, ~] = fileparts(file.name);
        shortName=strrep(baseName,'_model','');
        % Extract folder name (last component of path)
        [~, folderName, ~] = fileparts(file.folder);
        % Read Data Model
        t1=tic;
        data = cDataModel.create(sourceFile);
        if isValid(data) % Extract Properties
            cnt=cnt+1;
            s{cnt} = struct('Name',shortName,...
                 'Folder',folderName,...
                 'Flows',data.NrOfFlows,...
                 'Processes',data.NrOfProcesses,...
                 'Wastes',data.NrOfWastes,...
                 'Resources',data.NrOfResources,...
                 'Outputs',data.NrOfSystemOutputs,...
                 'Products',data.NrOfFinalProducts,...
                 'States',data.NrOfStates,...
                 'Samples',data.NrOfSamples,...
                 'Summary',data.getSummaryOption);
            if param.Debug % Print additional info
                pt = ceil(1000*toc(t1));
                tbl.printInfo(cMessages.ValidDataModelPlus,baseName,pt);
            end           
        else % Invalid data
            data.printLogger;
            continue;
        end           
    end
    % Create table
    sol=cell2mat(s(1:cnt));
    values=[fieldnames(sol),struct2cell(sol)]';
    props=struct('Name','examples','Description','Examples List Analysis');
    tbl=cTableData.create(values,props);
    % Save Table if required
    if ~isempty(param.SaveAs)
        SaveTable(tbl, param.SaveAs);
    end
    % Summary Analysis
    if param.Debug
        fprintf('\n=== Conversion Summary ===\n');
        fprintf('Total files:    %d\n', nFiles);
        fprintf('Analyzed:       %d\n', cnt);
        fprintf('Failed:         %d\n', nFiles-cnt);
        fprintf('\n');
    end
end