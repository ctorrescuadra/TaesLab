# Thermoeconomic Analysis Toolbox

  Version 1.8 (R2024b) 01-Oct-2025

## TaesLab Classes

### Base Classes

 | Name                | Description                                              |
 |:------------------- |:-------------------------------------------------------- |
 | [cTaesLab][]        | Base class of the TaesLab toolbox.                      |
 | [cMessageBuilder][] | Create and print messages for cTaesLab objects.         |
 | [cMessageLogger][]  | Create and manage a message logger for cTaesLab objects.|

### Static Classes

 | Name             | Description                                         |
 |:---------------- |:--------------------------------------------------- |
 | [cType][]        | Static class to manage the constants of TaesLab.   |
 | [cMessages][]    | Static class which defines the TaesLab messages.   |
 | [cParseStream][] | Static utility class to check and validate strings.|

### Read Data Model Classes

 | Name                 | Description                                                   |
 |:-------------------- |:------------------------------------------------------------- |
 | [cReadModel][]       | Abstract class to implement the model reader classes.        |
 | [cReadModelStruct][] | Abstract class to read a structured data model.              |
 | [cReadModelJSON][]   | Implements the cReadModel to read JSON data model files.     |
 | [cReadModelXML][]    | Implements the cReadModel to read XML data model files.      |
 | [cReadModelTable][]  | Abstract class to read a table data model.                   |
 | [cReadModelCSV][]    | Implements the cReadModel to read CSV data model files.      |
 | [cReadModelXLS][]    | Implements the cReadModel to read XLSX data model files.     |
 | [cModelTable][]      | Container class to store the values read by cReadModelTables.|

### Data Model Classes

 | Name                     | Description                                                          |
 |:------------------------ |:-------------------------------------------------------------------- |
 | [cProductiveStructure][] | Build the productive structure of a plant.                          |
 | [cExergyData][]          | Get and validate the exergy data values for a state of the plant.   |
 | [cFormatData][]          | Get the format configuration data used to display tables of results.|
 | [cResultTableBuilder][]  | Build the cResultInfo objects for the calculation layer.            |
 | [cResourceData][]        | Gets and validates the external cost resources of a system.         |
 | [cResourceCost][]        | Compute the resource cost values properties for a state.            |
 | [cWasteData][]           | Store the waste data information.                                   |

### Result Info Classes

 | Name                     | Description                                           |
 |:------------------------ |:----------------------------------------------------- |
 | [cResultId][]            | Base class for the calculation layer classes.        |
 | [cResultSet][]           | Base class for results classes.                      |
 | [cResultInfo][]          | Container class for the application results.         |
 | [cDataModel][]           | Create the data model object.                        |
 | [cModelData][]           | Container class for the Data Model structure.        |
 | [cThermoeconomicModel][] | Create the thermoeconomic model results object.      |
 | [cModelResults][]        | Container class for the Thermoeconomic Model Results.|

### Thermoeconomic Analysis Classes

 | Name                   | Description                                                |
 |:---------------------- |:---------------------------------------------------------- |
 | [cExergyModel][]       | Build the Flow-Process exergy model.                      |
 | [cExergyCost][]        | Calculate the exergy cost of flows and processes.         |
 | [cDiagnosis][]         | Make a thermoeconomic diagnosis analysis.                 |
 | [cWasteAnalysis][]     | Analyze the potential cost saving of waste recycling.     |
 | [cDiagramFP][]         | Build the adjacency tables of the Diagram FP.             |
 | [cProductiveDiagram][] | Build the productive diagrams' adjacency tables.          |
 | [cSummaryResults][]    | Gets the summary results tables of the model.             |
 | [cSummaryOptions][]    | Determine the summary options depending on the data model.|
 | [cSummaryTable][]      | Stores the properties and values of each summary table.   |
 | [cDigraphAnalysis][]   | Analyze the productive structure digraph.                 |

### Result Tables Classes

 | Name                  | Description                                                              |
 |:--------------------- |:------------------------------------------------------------------------ |
 | [cTable][]            | Abstract class for tabular data.                                        |
 | [cTableIndex][]       | Create a cTable with the index table of a cResultInfo.                  |
 | [cTableData][]        | Implement a cTable to store data model tables.                          |
 | [cTableResult][]      | Abstract class to store results into a cTable.                          |
 | [cTableCell][]        | Implement a cTableResults interface to store the results as cell arrays.|
 | [cTableMatrix][]      | Implement a cTableResults interface to store the matrix results.        |
 | [cTablesDefinition][] | Read and store the tables format configuration file.                    |

### Graph Presentation Classes

 | Name                | Description                                                      |
 |:------------------- |:---------------------------------------------------------------- |
 | [cGraphResults][]   | Abstract class used to show graphs in interactive mode and apps.|
 | [cGraphCost][]      | Plot the irreversibility-cost Table.                            |
 | [cGraphDiagnosis][] | Plot the diagnosis Graphs.                                      |
 | [cGraphDiagramFP][] | Plot the FP Diagram.                                            |
 | [cGraphRecycling][] | Plot the waste recycling cost graphs.                           |
 | [cGraphSummary][]   | Plot the summary graphs for selecting flows or processes.       |
 | [cGraphWaste][]     | Plot the waste allocation graph.                                |
 | [cDigraph][]        | Plot the productive structure digraphs.                         |

### Tables Conversion Classes

 | Name               | Description                                         |
 |:------------------ |:--------------------------------------------------- |
 | [cBuildHTML][]     | Convert a cTable object into HTML files.           |
 | [cBuildLaTeX][]    | Convert a cTable object into a LaTeX code table.   |
 | [cBuildMarkdown][] | Convert a cTable object into a Markdown code table.|
 | [cViewTable][]     | Show a result table using a GUI (uitable).         |

### Data Structures Classes

 | Name            | Description                                                         |
 |:--------------- |:------------------------------------------------------------------- |
 | [cQueue][]      | A simple FIFO queue based on a dynamic cell array.                 |
 | [cDictionary][] | Implement a (key/id) dictionary for TaesLab.                       |
 | [cDataset][]    | Creates a container to store data and to access it by key or index.|
 | [cSparseRow][]  | Store and operate with matrices that contain few non-null rows.    |

### Additional Files

 | Name                 | Description                                                    |
 |:-------------------- |:-------------------------------------------------------------- |
 | [printformat.json][] | Configuration file to define the format of the results tables.|
 | [styles.css][]       | CSS file to define the styles of the HTML tables.             |

<!-- Reference Links - Classes Directory -->

<!-- Base Classes -->
[cTaesLab]: ../Classes/cTaesLab.m
[cMessageBuilder]: ../Classes/cMessageBuilder.m
[cMessageLogger]: ../Classes/cMessageLogger.m

<!-- Static Classes -->
[cType]: ../Classes/cType.m
[cMessages]: ../Classes/cMessages.m
[cParseStream]: ../Classes/cParseStream.m

<!-- Read Data Model Classes -->
[cReadModel]: ../Classes/cReadModel.m
[cReadModelStruct]: ../Classes/cReadModelStruct.m
[cReadModelJSON]: ../Classes/cReadModelJSON.m
[cReadModelXML]: ../Classes/cReadModelXML.m
[cReadModelTable]: ../Classes/cReadModelTable.m
[cReadModelCSV]: ../Classes/cReadModelCSV.m
[cReadModelXLS]: ../Classes/cReadModelXLS.m
[cModelTable]: ../Classes/cModelTable.m

<!-- Data Model Classes -->
[cProductiveStructure]: ../Classes/cProductiveStructure.m
[cExergyData]: ../Classes/cExergyData.m
[cFormatData]: ../Classes/cFormatData.m
[cResultTableBuilder]: ../Classes/cResultTableBuilder.m
[cResourceData]: ../Classes/cResourceData.m
[cResourceCost]: ../Classes/cResourceCost.m
[cWasteData]: ../Classes/cWasteData.m

<!-- Result Info Classes -->
[cResultId]: ../Classes/cResultId.m
[cResultSet]: ../Classes/cResultSet.m
[cResultInfo]: ../Classes/cResultInfo.m
[cDataModel]: ../Classes/cDataModel.m
[cModelData]: ../Classes/cModelData.m
[cThermoeconomicModel]: ../Classes/cThermoeconomicModel.m
[cModelResults]: ../Classes/cModelResults.m

<!-- Thermoeconomic Analysis Classes -->
[cExergyModel]: ../Classes/cExergyModel.m
[cExergyCost]: ../Classes/cExergyCost.m
[cDiagnosis]: ../Classes/cDiagnosis.m
[cWasteAnalysis]: ../Classes/cWasteAnalysis.m
[cDiagramFP]: ../Classes/cDiagramFP.m
[cProductiveDiagram]: ../Classes/cProductiveDiagram.m
[cSummaryResults]: ../Classes/cSummaryResults.m
[cSummaryOptions]: ../Classes/cSummaryOptions.m
[cSummaryTable]: ../Classes/cSummaryTable.m
[cDigraphAnalysis]: ../Classes/cDigraphAnalysis.m

<!-- Result Tables Classes -->
[cTable]: ../Classes/cTable.m
[cTableIndex]: ../Classes/cTableIndex.m
[cTableData]: ../Classes/cTableData.m
[cTableResult]: ../Classes/cTableResult.m
[cTableCell]: ../Classes/cTableCell.m
[cTableMatrix]: ../Classes/cTableMatrix.m
[cTablesDefinition]: ../Classes/cTablesDefinition.m

<!-- Graph Presentation Classes -->
[cGraphResults]: ../Classes/cGraphResults.m
[cGraphCost]: ../Classes/cGraphCost.m
[cGraphDiagnosis]: ../Classes/cGraphDiagnosis.m
[cGraphDiagramFP]: ../Classes/cGraphDiagramFP.m
[cGraphRecycling]: ../Classes/cGraphRecycling.m
[cGraphSummary]: ../Classes/cGraphSummary.m
[cGraphWaste]: ../Classes/cGraphWaste.m
[cDigraph]: ../Classes/cDigraph.m

<!-- Tables Conversion Classes -->
[cBuildHTML]: ../Classes/cBuildHTML.m
[cBuildLaTeX]: ../Classes/cBuildLaTeX.m
[cBuildMarkdown]: ../Classes/cBuildMarkdown.m
[cViewTable]: ../Classes/cViewTable.m

<!-- Data Structures Classes -->
[cQueue]: ../Classes/cQueue.m
[cDictionary]: ../Classes/cDictionary.m
[cDataset]: ../Classes/cDataset.m
[cSparseRow]: ../Classes/cSparseRow.m

<!-- Additional Files -->
[printformat.json]: ../Classes/printformat.json
[styles.css]: ../Classes/styles.css
