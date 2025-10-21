% Thermoeconomic Analysis Toolbox
%   Version 1.8 (R2024b) 01-Oct-2025
%
% Classes
%
%  cTaesLab.m                - Base class of the TaesLab toolbox.
%  cMessageBuilder.m         - Create and print messages for cTaesLab objects.
%  cMessageLogger.m          - Create and manage a message logger for cTaesLab objects.
%
%  cType.m                   - Static class to manage the constants of TaesLab.
%  cMessages.m               - Static class which defines the TaesLab messages.
%  cParseStream.m            - Static utility class to check and validate strings.
%
%  cReadModel.m              - Abstract class to implement the model reader classes.
%  cReadModelStruct.m        - Abstract class to read a structured data model.
%  cReadModelJSON.m          - Implements the cReadModel to read JSON data model files.
%  cReadModelXML.m           - Implements the cReadModel to read XML data model files.
%  cReadModelTable.m         - Abstract class to read a table data model.
%  cReadModelCSV.m           - Implements the cReadModel to read CSV data model files.
%  cReadModelXLS.m           - Implements the cReadModel to read XLSX data model files.
%  cModelTable.m             - Container class to store the values read by cReadModelTables.
%
%  cResultId.m               - Base class for the calculation layer classes.
%  cResultSet.m              - Base class for results classes.
%  cDataModel.m              - Create the data model object.
%  cThermoeconomicModel.m    - Create the thermoeconomic model results object.
%  cResultInfo.m             - Container class for the application results.
%  cModelData.m              - Container class for the Data Model structure.
%  cModelResults.m           - Container class for the Thermoeconomic Model Results
%
%  cProductiveStructure.m    - Build the productive structure of a plant.
%  cExergyData.m             - Get and validate the exergy data values for a state of the plant.
%  cFormatData.m             - Get the format configuration data used to display tables of results.
%  cResultTableBuilder.m     - Build the cResultInfo objects for the calculation layer.
%  cResourceData.m           - Gets and validates the external cost resources of a system.
%  cResourceCost.m           - Compute the resource cost values properties for a state.
%  cWasteData.m              - Store the waste data information.
%
%  cExergyModel.m            - Build the Flow-Process exergy model.
%  cExergyCost.m             - Calculate the exergy cost of flows and processes.
%  cDiagnosis.m              - Make a thermoeconomic diagnosis analysis.
%  cWasteAnalysis.m          - Analyze the potential cost saving of waste recycling.
%  cDiagramFP.m              - Build the adjacency tables of the Diagram FP.
%  cProductiveDiagram.m      - Build the productive diagrams' adjacency tables.
%  cSummaryResults.m         - Gets the summary results tables of the model.
%  cSummaryOptions.m         - Determine the summary options depending on the data model.
%  cSummaryTable.m           - Stores the properties and values of each summary table.
%  cDrigraphAnalysis.m       - Analyze the productive structure digraph.
%
%  cTable.m                  - Abstract class for tabular data.
%  cTableIndex.m             - Create a cTable with the index table of a cResultInfo.
%  cTableData.m              - Implement a cTable to store data model tables.
%  cTableResult.m            - Abstract class to store results into a cTable.
%  cTableCell.m              - Implement a cTableResults interface to store the results as cell arrays.
%  cTableMatrix.m            - Implement a cTableResults interface to store the matrix results.
%  cTablesDefinition.m       - Read and store the tables format configuration file.
%
%  cGraphResults.m           - Abstract class used to show graphs in interactive mode and apps.
%  cGraphCost.m              - Plot the irreversibility-cost Table.
%  cGraphDiagnosis.m         - Plot the diagnosis Graphs.
%  cGraphDiagramFP.m         - Plot the FP Diagram.
%  cGraphRecycling.m         - Plot the waste recycling cost graphs.
%  cGraphSummary.m           - Plot the summary graphs for selecting flows or processes.
%  cGraphWaste.m             - Plot the waste allocation graph.
%  cDigraph.m                - Plot the productive structure digraphs.
%
%  cBuildHTML.m              - Convert a cTable object into HTML files.
%  cBuildLaTeX.m             - Convert a cTable object into a LaTeX code table.
%  cBuildMarkdown.m          - Convert a cTable object into a Markdown code table.
%  cViewTable.m              - Show a result table using a GUI (uitable).
%
%  cDictionary.m             - Implement a (key, id) dictionary for TaesLab.
%  cQueue.m                  - A simple FIFO queue based on a dynamic cell array.
%  cDataset.m                - Creates a container to store data and to access it by key or index.
%  cSparseRow.m              - Store and operate with matrices that contain few non-null rows.
%
%  printformat.json          - Configuration file to define the format of the results tables.
%  styles.css                - CSS file to define the styles of the HTML tables.
%








