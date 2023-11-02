function ShowFlowsDiagram(arg)
% Show a digraph of the flows diagram (Only MATLAB)
%   USAGE:
%       ShowFlowsDiagram(res)
%   INPUT:
%       res - cResultInfo or cThermoeconomicModel object
% See also cResultInfo, cThermoeconomicModel
%
	log=cStatus(cType.VALID);
	if isOctave
        log.printError('Graph function not implemented in Octave');
        return
	end
	if isa(arg,'cThermoeconomicModel') || isa(arg,'cResultInfo')
		showFlowsDiagram(arg)
    else
		log.printError('Invalid result parameter');
	end   	
end