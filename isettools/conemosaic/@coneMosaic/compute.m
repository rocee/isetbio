function [absorptions, current] = compute(obj, oi, varargin)
% Compute the cone absorptions
%
%  [absorptions, current] = cMosaic.compute(oi);
%
% The cone photon absorptions, which we treat as isomerization (R*), can be
% computed with or without noise, according to obj.noiseFlag.  This can be
% 'random','frozen', or 'none'.  If 'frozen', then you can set the 'seed'
% parameter.  The default is 1.
%
% The absorptions for a single oi can be computed with eye movements, as
% well.  In that case you can send in 'emPath', which defines the eye
% positions.  We recommend, however, simply setting coneMosaic.emPositions,
% say by using coneMosaic.emGenSequence or by an explicit set.
%
% Inputs:
%   oi  - optical image, or oiSequence.  See oiCreate for more details
%
% Optional inputs:
%   seed         - Seed to use when obj.noiseFlag is 'frozen' (default = 1)
%   emPath       - eye movement path (nx2 matrix). 
%                  I believe this should just be set to
%                  coneMosaic.emPositions, but at present we do different
%                  things depending on whether absorptions is empty. BW is
%                  complaining about this.
%   currentFlag  - logical, also compute photocurrent.  Not recommended. We
%                  prefer that you use coneMosaic.computeCurrent.
%
% Outputs:
%   absorptions  - cone photon absorptions
%   current      - cone photocurrent
%
% HJ ISETBIO Team 2016

%% If an oi sequence, head that way

% Send to the specialized compute in that case.
if isequal(class(oi),'oiSequence')
    [absorptions, current] = obj.computeForOISequence(oi,varargin{:});
    return;
end

%% parse inputs
p = inputParser;
p.addRequired('oi', @isstruct);
p.addParameter('currentFlag', false, @islogical);
p.addParameter('seed', 1, @isnumeric);
p.addParameter('emPath', obj.emPositions, @isnumeric);
p.addParameter('theExpandedMosaic', []);
p.parse(oi,varargin{:});

oi          = p.Results.oi;
currentFlag = p.Results.currentFlag;
seed        = p.Results.seed;
emPath      = p.Results.emPath;
theExpandedMosaic = p.Results.theExpandedMosaic;

obj.absorptions = [];
obj.current = [];

%% set eye movement path

% I would prefer to delete this parameter altogether and force people to
% set the emPositions prior to calling this compute.  But when we have
% multiple trials, emPath is (nTrials x row x col), and emGenSequence
% doesn't have an nTrials parameter.  
%
% So, perhaps we can modify to be
%
%    emGenSequence(nPositions,'nTrials',nTrials);
%
obj.emPositions = emPath;

% We need a copy of the object because of eye movements.
if (isempty(theExpandedMosaic))
    % We are not passed theExpandedMosaic. 
    % Generate it here.
    padRows = max(abs(emPath(:, 2)));
    padCols = max(abs(emPath(:, 1)));
    theExpandedMosaic = obj.copy();
    theExpandedMosaic.pattern = zeros(obj.rows+2*padRows, obj.cols+2*padCols);
elseif isa(theExpandedMosaic, 'coneMosaic')
    % OK, we are passed theExpandedMosaic. 
    % Set the current path and integrationTime and use it.
    theExpandedMosaic.emPositions = obj.emPositions;
    theExpandedMosaic.integrationTime = obj.integrationTime;
    theExpandedMosaic.absorptions = [];
    padRows = round((theExpandedMosaic.rows-obj.rows)/2);
    padCols = round((theExpandedMosaic.cols-obj.cols)/2);
else
    error('theExpandedMosaic passed is not a @coneMosaic');
end

% compute full LMS noise free absorptions
LMS = theExpandedMosaic.computeSingleFrame(oi, 'fullLMS', true);
    
% deal with eye movements
absorptions = obj.applyEMPath(LMS, 'emPath', emPath, 'padRows', padRows, 'padCols', padCols);
% vcNewGraphWin; imagesc(absorptions);

% Add photon noise to the whole volume
switch obj.noiseFlag
    case {'frozen','random'}
        if (isa(obj, 'coneMosaicHex'))
            % Only call photonNoise on the non-null cones for a hex mosaic.
            nonNullConeIndices = find(obj.pattern > 1);
            timeSamples = size(absorptions,3);
            absorptions = reshape(permute(absorptions, [3 1 2]), [timeSamples size(obj.pattern,1)*size(obj.pattern,2)]);
            absorptionsCopy = absorptions;
            absorptions = absorptions(:, nonNullConeIndices);
            % Add noise
            absorptionsCopy(:, nonNullConeIndices) = obj.photonNoise(absorptions, 'noiseFlag',obj.noiseFlag,'seed',seed);
            absorptions = permute(reshape(absorptionsCopy, [timeSamples size(obj.pattern,1) size(obj.pattern,2)]), [2 3 1]);
            clear 'absorptionsCopy'
        else % Rectangular mosaic
            % Add noise
            absorptions = obj.photonNoise(absorptions,'noiseFlag',obj.noiseFlag,'seed',seed);
            % vcNewGraphWin; imagesc(absorptions);
        end
    otherwise
        % No noise.
end

% Set the absorptions in the object.
obj.absorptions = absorptions;

%% If we want the photo current, use the os model

% We recommend that you calculate the photocurrent later using
%   coneMosaic.computeCurrent;
% rather than by setting this flag.

current = [];
if currentFlag
    warning('Suggest using coneMosaic.computeCurrent');
    if size(obj.absorptions,3) == 1
        disp('Absorptions are a single frame.  No current to calculate.')        
        return;
    else
        obj.current = obj.os.osCompute(cMosaic);
    end
end

end
