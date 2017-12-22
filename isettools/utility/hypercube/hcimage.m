function figH = hcimage(hc, varargin)
% Display a hypercube image.
%
% Syntax:
%   figH = hcimage(hc, [varargin])
%
% Description:
%    Display a hypercube image.
%
% Inputs:
%    hc       - The hypercube
%    varargin - (Optional) Array of arguments representing the display type
%               and various other related information. Possibe options are:
%               dType -  The Display type, with the options of 'mean gray',
%                        'image montage', and 'movie'. The corresponding
%                        default is 'mean gray'.
%               slices - For the 'image montage' option, a number of slices
%                        is a possible input.
%
% Outputs:
%    figH     - The resulting figure
%
% Notes:
%    * [Note: JNM - varargin{1} is referenced for everything, including
%      within image montage, where varargin{1} was already used to
%      calculate the display type.]
%
% See Also:
%    mplay, imageMontage
%

% History:
%    xx/xx/xx       (c) Imageval
%    12/05/17  jnm  Formatting

% Examples:
%{
    % The example doesn't work! File path hyperspectral (let alone file
    % itself) does not exist!
    fname = fullfile(isetbioDataPath, 'images', 'hyperspectral', ...
        'surgicalSWIR.mat');
    load(fname, 'hc');
    nWave = size(hc, 3);
    hcimage(hc, 'image montage');
    hcimage(hc, 'movie');
%}

if notDefined('hc'), error('hypercube image data required'); end

if isempty(varargin)
    dType = 'mean gray';
else
    dType = varargin{1};
end

dType = ieParamFormat(dType);

switch dType
    case 'meangray'
        % Most boring default. Find the mean level across wavelengths and
        % display it as a gray scale image
        vcNewGraphWin;
        img = mean(hc, 3);
        imagesc(img);
        colormap(gray)
        axis image
    case {'imagemontage', 'montage'}
        nWave = size(hc, 3);
        if length(varargin) > 1
            slices = varargin{1}; 
        else
            slices = 1:nWave;
        end

        figH = imageMontage(hc, slices);
        colormap(gray)

    case 'movie'
        % Show the hypercube data as a movie
        hc = 256 * double(hc / max(hc(:)));
        mp = mplay(hc); 
        mFig = mp.hfig;
        set(mFig, 'name', sprintf('Hypercube wavebands: %d', size(hc, 3)));
        
    otherwise
        error('Unknown hc image display type: %s', dType);
end

end