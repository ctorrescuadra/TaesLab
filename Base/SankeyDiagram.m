function SankeyDiagram(res, option)
%SankeyDiagram - Generate a Mermaid Sankey diagram file from FP diagram results.
%   Creates a Mermaid sankey-beta formatted file (.mmd) representing energy
%   flows through the productive structure. The diagram visualizes how exergy
%   or costs are transferred between processes and flows in the system.
%
%   The output file uses Mermaid's sankey-beta syntax, which can be rendered
%   in Mermaid-compatible tools, markdown previews, or web applications to
%   produce interactive flow diagrams.
%
%   Syntax:
%     SankeyDiagram(res, option)
%
%   Input Arguments:
%     res - FP diagram result container
%       cResultInfo object with ResultId == cType.ResultId.DIAGRAM_FP
%       Must be obtained from a prior call to DiagramFP()
%       Contains the kernel adjacency tables used as Sankey edge data
%
%     option - Table to use as Sankey edge source
%       char array
%       Selects whether to build the Sankey diagram from exergy flows or costs:
%         cType.Tables.KDIGRAPH_FP       - Kernel FP digraph (exergy flow values)
%         cType.Tables.KDIGRAPH_COST_FP  - Kernel cost FP digraph (cost flow values)
%
%   Output:
%     Generate log information about errors and file creation
%
%   Output File:
%     <modelname>_<option>.mmd  - Mermaid sankey-beta file saved in the current directory
%       Each line represents one directed edge in the format: source,target,value
%
%   Examples:
%     % Generate exergy-flow Sankey diagram for the design state
%     data  = ReadDataModel('cgam_model.json');
%     fpRes = DiagramFP(data);
%     log   = SankeyDiagram(fpRes, cType.Tables.KDIGRAPH_FP);
%
%     % Generate cost-flow Sankey diagram
%     log = SankeyDiagram(fpRes, cType.Tables.KDIGRAPH_COST_FP);
%
%   See also: DiagramFP, ShowGraph, cType.Tables


    log = cTaesLab();
    % Check number of input arguments
    if nargin < 2
        log.printError(cMessages.NarginError, cMessages.ShowHelp);
        return
    end
    % Validate res is a cResultInfo with DIAGRAM_FP ResultId
    if ~isObject(res, 'cResultInfo') || res.ResultId ~= cType.ResultId.DIAGRAM_FP
        log.printError(cMessages.InvalidObject, class(res));
        return
    end
    % Validate option is one of the valid values
    validOptions = {cType.Tables.KDIGRAPH_FP, cType.Tables.KDIGRAPH_COST_FP};
    if ~ischar(option) || ~ismember(option, validOptions)
        log.printError(cMessages.InvalidParameter, option);
        return
    end
    % Retrieve edges information from result info tables
    tbl=res.Tables.(option);
    edges=cell2struct(tbl.Data,tbl.FieldNames(2:end),2);
    % Build the Mermaid Sankey content
    nEdges = numel(edges);
    lines = cell(nEdges + 2, 1);
    lines{1} = 'sankey-beta';
    lines{2} = cType.EMPTY_CHAR;
    for i = 1:nEdges
        lines{i+2} = sprintf('%s,%s,%f', edges(i).source, edges(i).target, edges(i).value);
    end
    content = strjoin(lines, newline);
    % Build the output filename from model name and option
    modelName = strsplit(res.Info.ModelName,'_');
    if isempty(modelName)
        modelName = 'sankey';
    end
    filename = [modelName{1}, '_', option, '.mmd'];
    % Save to file
    try
        fId = fopen(filename, 'wt');
        if fId < 0
            log.printError(cMessages.FileNotSaved, filename);
            return
        end
        fprintf(fId, '%s\n', content);
        fclose(fId);
        log.printInfo(cMessages.FileSaved, filename);
    catch err
        log.printError(cType.ERROR, err.message);
        log.printError(cType.ERROR, cMessages.FileNotSaved, filename);
    end
end