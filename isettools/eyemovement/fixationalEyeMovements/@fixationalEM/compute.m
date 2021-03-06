function compute(obj, emDurationSeconds, sampleDurationSeconds, nTrials, computeVelocity, varargin)
    p = inputParser;
    p.addParameter('useParfor', false, @islogical);
    p.parse(varargin{:});
    
    % Reset output arrays
    obj.initOutputs();
    
    % Set random seed
    if (isempty(obj.randomSeed))
        rng('shuffle');
    else
        rng(obj.randomSeed);
    end
    
    if (obj.beVerbose)
        fprintf('Computing emModel for %2.2f seconds; sampleT = %2.4f sec, samples: %d\n', emDurationSeconds, sampleDurationSeconds, obj.tStepsNum);
    end
        
    % Compute first trial
    iTrial = 1;
    computeSingleTrial(obj, emDurationSeconds, sampleDurationSeconds);
    allTrialsEmPosArcMin = zeros(nTrials, length(obj.emPosTimeSeriesArcMin), 2);
    allTrialsEmPosArcMin(iTrial,:,:) = reshape(obj.emPosTimeSeriesArcMin', [1 length(obj.emPosTimeSeriesArcMin) 2]);
    
    if (computeVelocity)
        allTrialsVelocityArcMin = zeros(nTrials, length(obj.velocityArcMinPerSecTimeSeries), 1);
        allTrialsVelocityArcMin(iTrial,:) = obj.velocityArcMinPerSecTimeSeries;
    end

    % Compute remaining trials
    if (p.Results.useParfor)
        parfor iTrial = 2:nTrials
            computeSingleTrial(obj, emDurationSeconds, sampleDurationSeconds);
            allTrialsEmPosArcMin(iTrial,:,:) = reshape(obj.emPosTimeSeriesArcMin', [1 length(obj.emPosTimeSeriesArcMin) 2]);
            if (computeVelocity)
                allTrialsVelocityArcMin(iTrial,:) = obj.velocityArcMinPerSecTimeSeries;
            end
        end
    else
        for iTrial = 2:nTrials
            computeSingleTrial(obj, emDurationSeconds, sampleDurationSeconds);
            allTrialsEmPosArcMin(iTrial,:,:) = reshape(obj.emPosTimeSeriesArcMin', [1 length(obj.emPosTimeSeriesArcMin) 2]);
            if (computeVelocity)
                allTrialsVelocityArcMin(iTrial,:) = obj.velocityArcMinPerSecTimeSeries;
            end
        end
    end
    
    obj.emPosArcMin = allTrialsEmPosArcMin;
    if (computeVelocity)
        obj.velocityArcMin = allTrialsVelocityArcMin;
    end
end