function optics = opticsSet(optics, parm, val, varargin)
% Set optics structure parameters
%
% Syntax:
%   optics = opticsSet(optics, paramName, val, [varargin])
%
% Description:
%    The optics structure contains the basic optics parameters used to
%    control image formation. The parameters define parameters used in the
%    diffraction-limited or shift-invariant optics models. See opticsGet
%    for further information about these models.
%
%    The optics structure is normally part of the optical image and can be
%    retrieved using
%
%        oi = vcGetObject('OI');
%        optics = oiGet(oi, 'optics');
%
%    Often, we get and set optics properties from the oiSet/Get commands
%    as in 
%
%         fnumber = oiGet(oi, 'optics fnumber')
%         oi = oiSet(oi, 'optics fnumber', 2.8);
%
%    Those calls act via opticsGet and opticsSet 
%
%    To set the aperture you must change either the focal length or the
%    f# = fL/aperture, so aperture = fL/f#
%
% Inputs:
%    optics   - Struct. An optics structure
%    parm     - String. The parameter you wish to change. The options and
%               their value types include:
%        Optics model
%           {'model'}         - String. One of the following:
%                               'diffractionLimited' or 'ShiftInvariant'
%        Diffraction limited optics specifications.
%           {'name'}          - String. This optics name
%           {'type'}          - String. Always 'optics'
%           {'fnumber'}       - Numeric. f# is focal length/aperture value
%                               is dimensionless.
%           {'focallength'}   - Numeric. The focal distance in meters for
%                               image at infinity
%           {'transmittance'} - Wavelength transmittance  ([0, 1])
%        OTF Information for shift-invariant optics model
%           {'otfdata'}       - Array. Used to store custom data.
%                               Row x Col x Wave
%           {'otffx'}         - Vector. Frequency samples across otfdata
%                               cols (in cyc/mm)
%           {'otffy'}         - Vector. Frequency samples down otfdata rows
%                               (in cyc/mm)
%           {'otfwave'}       - Vector. The otf wavelengths
%           {'lens'}          - Obj. lens object specifying transmittance
%        Relative illumination data
%           {'relillummethod'}   - Poorly-named offAxis flag. (See below)
%           {'off axis method'}  - Set to 'Skip' to turn off or 'cos4th'
%           {'cos4thdata'}       - Cached cos4th data
%    val      - The value to assign to the parameter, following the form
%               specified by the parameter examples above.
%    varargin - (Optional) Additional arguments that may be required. Some
%               examples include units. 
%
% Outputs:
%    optics   - Struct. The modified optics structure.
%
% Optional key/value pairs:
%    **Needs to be filled out**
%
% See Also:
%    oiGet oiSet opticsGet
%

% History:
%    xx/xx/05       Copyright ImagEval Consultants, LLC, 2005.
%    03/13/18  jnm  Formatting

% Examples:
%{
oi = oiCreate('diffraction limited');
oiGet(oi,'optics fnumber')
oi = oiSet(oi,'optics fnumber',8);
oiGet(oi,'optics fnumber')
%}

%%
if ~exist('optics','var') || isempty(optics)
  error('No optics specified.'); 
end
if ~exist('parm','var') || isempty(parm)
    error('No parameter specified.'); 
end
if ~exist('val','var')
    error('No value.'); 
end

%%
parm = ieParamFormat(parm);
switch parm
    case 'name'
        optics.name = val;

    case 'type'
        % Should always be 'optics'
        if ~strcmp(val, 'optics')
            warning('Non standard optics type setting');
        end
        optics.type = val;
        
    case {'model','opticsmodel'}
        % Set the optics model type
        %
        % diffractionlimited and shiftinvariant are the legitimate
        % options. We allow 'raytrace' this is mainly in service of
        % TL's comment below.
        %
        % TL: I put back the ray trace model for now, since if we switch to
        % shiftinvariant it will try to find the lens info in the oi.optics
        % structure, which is non-existent for ray-tracing. Because of this
        % it will throw errors when you try to run oiWindow. This requires
        % more thought about how to handle this...
        %
        % BW: If we need a special case for sceneeye, let's make that.
        % ray trace is used for a different meaning in ISETCAM.  We
        % should use a different name for the scene eye calculation.
        
        % Remove white space and force lower case
        val = ieParamFormat(val);
        valid = {'diffractionlimited', 'shiftinvariant','iset3d'};

        if validatestring(val, valid)
            optics.model = ieParamFormat(val);
        else
            error('Invalid model %s\n', val);
        end

    case {'fnumber', 'f#'}
        optics.fNumber = val;

    case {'focallength', 'flength'}
        optics.focalLength = val;

    case {'spectrum'}
        % Spectrum structure
        warning('optics spectrum set, line 92')
        optics.spectrum = val;

    case {'wavelength', 'wave'}
        % This appears to be unnecessary. In fact, the whole
        % optics.spectrum slot may be unnecessary.
        %
        % We used to change the OTF at the same time. But this is not
        % necessary because the OTF structure has a wave term, and when we
        % need the OTF(w) we simply interpolate it from the OTF structure.
        %
        % I am not sure we ever use this particular wave for SI data, where
        % we use the OTF.wave and the oi.spectrum.wave. This one is kind
        % of caught in the middle. ISETBIO doesn't use rt, so the other
        % thing to check is whether it is used for diffraction.

        % Set new wavelength
        warning('optics spectrum wave set, line 110')
        optics.spectrum.wave = val(:);

    case {'transmittance', 'transmittancescale'}
        % Set the lens transmittance scale factor
        % opticsSet(optics, 'transmittance', val)
        %   val must be [0, 1] and length(wave)
        %
        if max(val) > 1 || min(val) < 0
            error('Transmittance scale should be in [0, 1].')
        end
        if checkfields(optics, 'transmittance')
            wave = length(optics.transmittance.wave);
            if length(val) == length(wave)
                optics.transmittance = val;
            else
                error('Transmittance data does not match current wave')
            end
        end

    case {'transmittancewave'}
        % Set a new set of wavelength samples. Interpolate the scale to
        % match This is not usually done in computation. Normally we just
        % request the scale factors at specific wave samples.

    case {'lens'}
        % New lens object. This should replace transmittance.
        optics.lens = val;

    % ---- Relative illumination calculations
    case {'offaxis', 'offaxismethod', 'relillummethod', 'cos4thflag'}
        % Flag determining whether you use the cos4th method 
        % Bad naming because of history.
        optics.offaxis = val;

    case {'cos4thfunction', 'cos4thmethod'}
        % We only have cos4th offaxis implemented, and this probably is all
        % we will need.
        optics.cos4th.function = val;

    case {'cos4th', 'cos4thdata', 'cos4thvalue'}
        % Numerical values. Should change field to data from value.
        optics.cos4th.value = val;

    % ---- OTF information for shift-invariant calculations
    case {'otffunction', 'otfmethod'}
        % This should probably not be here.
        % We should probably only be using the 'model' option
        % But it is used, so we need to carefully debug
        % Current choices are 'dlmtf' ... - MP, BW
        optics.OTF.function = val;

    case {'otf', 'otfdata'}
        % Fraction of amplitude transmitted
        optics.OTF.OTF = val;

    case {'otffx'}
        % Units are cyc/mm
        %   - frequency samples across col of otfdata
        %   - these seem to have 0 at entry floor(n / 2) + 1, while the
        %     actual otf is not shifted this way.
        optics.OTF.fx = val;

    case {'otffy'}
        % Units are cyc/mm
        %   - frequency samples down rows of otfdata
        optics.OTF.fy = val;

    case {'otfwave'}
        % - otf wavelengths (nm)
        optics.OTF.wave = val;

    otherwise
        error('Unknown parameter')
end

end