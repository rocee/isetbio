function hFig = visualizeActivationMaps(obj, activation, varargin)
% Visualize mosaic activations separately for each submosaic and for the
% entire mosaic.
%
% NPC, ISETBIO TEAM, 2015

    p = inputParser;
    p.addParameter('figureSize', [920 875], @isnumeric);
    p.addParameter('signalName', ' ', @ischar);
    p.addParameter('mapType', 'modulated hexagons', @ischar);
    p.addParameter('colorMap', jet(1024), @isnumeric);
    p.parse(varargin{:});  
    
    if (any(size(activation) ~= size(obj.pattern)))
       % reshape the activation patten to obj.pattern
       nonNullCones = obj.pattern(find(obj.pattern>1));
       if (numel(activation) == numel(nonNullCones))
            
            tmp = activation;
            iLsource = find(nonNullCones==2);
            iMsource = find(nonNullCones==3);
            iSsource = find(nonNullCones==4);
            
            iLdest = find(obj.pattern==2);
            iMdest = find(obj.pattern==3);
            iSdest = find(obj.pattern==4);
                
            activation = zeros(size(obj.pattern));
            activation(iLdest) = tmp(iLsource);
            activation(iMdest) = tmp(iMsource);
            activation(iSdest) = tmp(iSsource);
       else
           error('The elements of the activation pattern (%d) does not match the number of non-null cones (%d) ', numel(activation), numel(nonNullCones));
       end
    end
    
    
    if strcmp(p.Results.mapType, 'modulated disks') || strcmp(p.Results.mapType, 'modulated hexagons')
        hFig = visualizeMosaicActivationsMapsAsModulatedPixels(obj, activation, p.Results.mapType, p.Results.colorMap, p.Results.signalName, p.Results.figureSize);
    elseif strcmp(p.Results.mapType, 'density plot')
        hFig = visualizeMosaicActivationsAsDensityMaps(obj, activation, p.Results.colorMap, p.Results.signalName, p.Results.figureSize);
    else
        error('visualizeActivationMaps:: Unknown map type');
    end
end


function hFig = visualizeMosaicActivationsMapsAsModulatedPixels(obj, activation, mapType, cMap, signalName, figureSize)
% Visualize mosaic activations as disk mosaics

    sampledHexMosaicXaxis = squeeze(obj.patternSupport(1,:,1)) + obj.center(1);
    sampledHexMosaicYaxis = squeeze(obj.patternSupport(:,1,2)) + obj.center(2);
    
    if strcmp(mapType, 'modulated disks') 
        iTheta = (0:5:360)/180*pi;
        apertureOutline.x = obj.pigment.width/2.0 * cos(iTheta);
        apertureOutline.y = obj.pigment.height/2.0 * sin(iTheta);
    elseif strcmp(mapType, 'modulated hexagons')
        iTheta = (0:60:360)/180*pi;
        apertureOutline.x = 1.1*obj.pigment.width/2.0 * cos(iTheta);
        apertureOutline.y = 1.1*obj.pigment.height/2.0 * sin(iTheta);
    end
    
    disp('here')
    size(activation)
    size(obj.pattern)
    
    activeConesActivations = activation(obj.pattern>1);
    activationRange = [min(activeConesActivations(:)) max(activeConesActivations(:))];
    
    hFig = figure();
    set(hFig, 'Position', cat(2, [10 10], figureSize), 'Color', [0 0 0]); % , 'MenuBar', 'None');
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
           'rowsNum', 1, ...
           'colsNum', 4, ...
           'heightMargin',   0.03, ...
           'widthMargin',    0.03, ...
           'leftMargin',     0.04, ...
           'rightMargin',    0.06, ...
           'bottomMargin',   0.03, ...
           'topMargin',      0.02);
    
    for subplotIndex = 1:4
        subplot('Position', subplotPosVectors(1,subplotIndex).v);
        set(gca, 'Color', [0 0 0]);
        switch subplotIndex
            case 1
                idx = find(obj.pattern == 2);
                [iRows,iCols] = ind2sub(size(obj.pattern), idx);
                subplotTitle = 'L-cone submosaic activation';
                showXticks = true;
                showYticks = true;
                edgeColor = 'none'; 
                lineWidth = 0.1;
            case 2
                idx = find(obj.pattern == 3);
                [iRows,iCols] = ind2sub(size(obj.pattern), idx);
                subplotTitle = 'M-cone submosaic activation';
                showXticks = true;
                showYticks = false;
                edgeColor = 'none'; 
                lineWidth = 0.1;
            case 3
                idx = find(obj.pattern == 4);
                [iRows,iCols] = ind2sub(size(obj.pattern), idx);
                subplotTitle = 'S-cone submosaic activation';
                showXticks = true;
                showYticks = false;
                edgeColor = 'none'; 
                lineWidth = 0.1;
            case 4
                idx = find(obj.pattern > 1);
                [iRows,iCols] = ind2sub(size(obj.pattern), idx);
                subplotTitle = 'total mosaic activation';
                showXticks = true;
                showYticks = false;
                edgeColor = 'none'; 
                lineWidth = 0.1;
        end
        
        lineStyle = '-'; 
        cMapLevels = size(cMap,1);
        activationsNlevels = round((activation(idx)-activationRange(1))/(activationRange(2)-activationRange(1))*cMapLevels);
        faceColorsNormalizedValues = activationsNlevels/cMapLevels;
        renderPatchArray(apertureOutline, sampledHexMosaicXaxis(iCols), sampledHexMosaicYaxis(iRows),faceColorsNormalizedValues,  edgeColor,  lineStyle, lineWidth);
        set(gca, 'CLim', [0 1]);
        axis 'image'; axis 'xy';
        xTicks = [sampledHexMosaicXaxis(1) obj.center(1) sampledHexMosaicXaxis(end)];
        yTicks = [sampledHexMosaicYaxis(1) obj.center(2) sampledHexMosaicYaxis(end)];
        xTickLabels = sprintf('%2.0f um\n', xTicks*1e6);
        yTickLabels = sprintf('%2.0f um\n', yTicks*1e6);
        set(gca, 'XTick', xTicks, 'YTick', yTicks, 'XTickLabel', xTickLabels, 'YTickLabel', yTickLabels, 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8]);
        if (~showXticks)
            set(gca, 'XTick', []);
        end
        if (~showYticks)
            set(gca, 'YTick', []);
        end
        box on; grid off;
        set(gca, 'XLim', [sampledHexMosaicXaxis(1)-obj.pigment.width sampledHexMosaicXaxis(end)+obj.pigment.width]);
        set(gca, 'YLim', [sampledHexMosaicYaxis(1)-obj.pigment.width sampledHexMosaicYaxis(end)+obj.pigment.width]);
        set(gca, 'FontSize', 14);
        title(subplotTitle, 'FontSize', 16, 'Color', [1 1 1]);
        
        if (subplotIndex == 4)
            ticks = 0:0.1:1.0;
            tickLabels = sprintf('%2.0f\n', round(activationRange(1) + ticks * (activationRange(2)-activationRange(1))));
            % Add colorbar
            originalPosition = get(gca, 'position');
            hCbar = colorbar('eastoutside', 'peer', gca, 'Ticks', ticks, 'TickLabels', tickLabels);
            hCbar.Orientation = 'vertical';
            hCbar.Label.String = signalName;
            hCbar.FontSize = 14;
            hCbar.FontName = 'Menlo';
            hCbar.Color = [0.2 0.2 0.2];
            % The addition changes the figure size, so undo this change
            newPosition = get(gca, 'position');
            set(gca,'position',[newPosition(1) newPosition(2) originalPosition(3) originalPosition(4)]);
        end
        
    end
    colormap(cMap);
    drawnow
end

function renderPatchArray(pixelOutline, xCoords, yCoords, faceColorsNormalizedValues,  edgeColor, lineStyle, lineWidth)
    verticesNum = numel(pixelOutline.x);
    x = zeros(verticesNum, numel(xCoords));
    y = zeros(verticesNum, numel(xCoords));
    for vertexIndex = 1:verticesNum
        x(vertexIndex, :) = pixelOutline.x(vertexIndex) + xCoords;
        y(vertexIndex, :) = pixelOutline.y(vertexIndex) + yCoords;
    end
    patch(x,y, faceColorsNormalizedValues, 'EdgeColor', edgeColor, 'LineWidth', lineWidth, 'LineStyle', lineStyle);
end



function hFig = visualizeMosaicActivationsAsDensityMaps(obj, activation, cMap, signalName, figureSize)
% Visualize mosaic activations as density maps
            
    % Compute activation image maps
    [activationImage, activationImageLMScone, sampledHexMosaicXaxis, sampledHexMosaicYaxis] = obj.computeActivationDensityMap(activation);
    activeConesActivations = activation(obj.pattern>1);
    %activationRange = prctile(activeConesActivations, [10 90]);
    activationRange = [min(activeConesActivations(:)) max(activeConesActivations(:))];
    
    hFig = figure();
    set(hFig, 'Position', cat(2, [10 10], figureSize), 'Color', [1 1 1]); % , 'MenuBar', 'None');
    
    subplotPositions = [...
        0.02 0.52 0.45 0.45; ...
        0.49 0.52 0.45 0.45; ...
        0.02 0.03 0.45 0.45; ...
        0.49 0.03 0.45 0.45];
    
    for subplotIndex = 1:4
        subplot('Position', subplotPositions(subplotIndex,:));
        switch subplotIndex
            case 1
                activationMapImage  = squeeze(activationImageLMScone(:,:,1));
                subplotTitle = 'L-cone submosaic activation';
                showXticks = false;
                showYticks = true;
            case 2
                activationMapImage  = squeeze(activationImageLMScone(:,:,2));
                subplotTitle = 'M-cone submosaic activation';
                showXticks = false;
                showYticks = false;
            case 3
                activationMapImage  = squeeze(activationImageLMScone(:,:,3));
                subplotTitle = 'S-cone submosaic activation';
                showXticks = true;
                showYticks = true;
            case 4
                activationMapImage  = activationImage;
                subplotTitle = 'total mosaic activation';
                showXticks = true;
                showYticks = false;
        end
        
        imagesc(sampledHexMosaicXaxis, sampledHexMosaicYaxis, activationMapImage);
        axis 'image'; axis 'xy';
        xTicks = [sampledHexMosaicXaxis(1) obj.center(1) sampledHexMosaicXaxis(end)];
        yTicks = [sampledHexMosaicYaxis(1) obj.center(2) sampledHexMosaicYaxis(end)];
        xTickLabels = sprintf('%2.0f um\n', xTicks*1e6);
        yTickLabels = sprintf('%2.0f um\n', yTicks*1e6);
        set(gca, 'XTick', xTicks, 'YTick', yTicks, 'XTickLabel', xTickLabels, 'YTickLabel', yTickLabels);
        set(gca, 'CLim', activationRange);
        if (~showXticks)
            set(gca, 'XTick', []);
        end
        if (~showYticks)
            set(gca, 'YTick', []);
        end
        box on; grid off;
        set(gca, 'XLim', [sampledHexMosaicXaxis(1)-obj.pigment.width sampledHexMosaicXaxis(end)+obj.pigment.width]);
        set(gca, 'YLim', [sampledHexMosaicYaxis(1)-obj.pigment.width sampledHexMosaicYaxis(end)+obj.pigment.width]);
        set(gca, 'FontSize', 14);
        title(subplotTitle, 'FontSize', 16);
        
        if (subplotIndex == 4)
            % Add colorbar
            originalPosition = get(gca, 'position');
            hCbar = colorbar('eastoutside', 'peer', gca); % , 'Ticks', cbarStruct.ticks, 'TickLabels', cbarStruct.tickLabels);
            hCbar.Orientation = 'vertical';
            hCbar.Label.String = signalName;
            hCbar.FontSize = 14;
            hCbar.FontName = 'Menlo';
            hCbar.Color = [0.2 0.2 0.2];
            % The addition changes the figure size, so undo this change
            newPosition = get(gca, 'position');
            set(gca,'position',[newPosition(1) newPosition(2) originalPosition(3) originalPosition(4)]);
        end
        
    end

    cMap(1,:) = 0;
    colormap(cMap);
    drawnow
end
