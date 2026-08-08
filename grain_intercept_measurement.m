% GRAIN_INTERCEPT_MEASUREMENT
% Manual line-intercept measurement of grain size from microscopy images.
%
% The script:
%   1. Loads a microscopy image.
%   2. Calibrates pixel size using a scale bar.
%   3. Creates horizontal and vertical test lines.
%   4. Records grain-boundary intersections by manual clicking.
%   5. Calculates individual intercept lengths in micrometres.
%   6. Exports measurements and summary statistics to Excel.
%   7. Saves an annotated copy of the original image.
%
% Requirements:
%   - MATLAB
%   - Image Processing Toolbox (drawline)
%
% The original measurement workflow is preserved.

clc
clear
close all

%% ==========================================================
% LOAD IMAGE
%% ==========================================================
[file,path] = uigetfile({'*.tif;*.tiff;*.png;*.jpg;*.jpeg',...
    'Image Files (*.tif,*.png,*.jpg)'});

if isequal(file,0)
    disp('No image selected.');
    return;
end

img = imread(fullfile(path,file));

figure('Name','Manual Grain Intercept Measurement',...
    'NumberTitle','off',...
    'Color','w');

imshow(img);
ax  = gca;        % lock in this axes handle so later dialogs (msgbox/questdlg)
fig = ax.Parent;  % ...never accidentally get used instead of the image window
hold(ax,'on');

%% ==========================================================
% SCALE CALIBRATION
%% ==========================================================

title(ax,'Click the TWO ends of the scale bar');

[xs,ys] = ginput(2);

plot(ax,xs,ys,'ro',...
    'MarkerFaceColor','r',...
    'MarkerSize',8);

pixelScale = hypot(xs(2)-xs(1),ys(2)-ys(1));

answer = inputdlg('Enter Scale Length (Microns)',...
                  'Scale Calibration',1,{'200'});

if isempty(answer)
    return;
end

figure(fig);   % bring the image window back to front after the dialog

scaleLength = str2double(answer{1});

umPerPixel = scaleLength/pixelScale;

fprintf('\n');
fprintf('Calibration = %.6f micron/pixel\n',umPerPixel);

%% ==========================================================
% COLOR SETTINGS
% Horizontal lines/dots stay green/red.
% Vertical lines/dots use a different color so the two
% directions are easy to tell apart, on screen and in the
% saved image.
%% ==========================================================

horizLineColor = 'g';            % on-screen ROI color for horizontal lines
vertLineColor  = 'b';            % on-screen ROI color for vertical lines  (cyan)

horizDotColor  = 'r';            % on-screen dot color for horizontal points
vertDotColor   = 'm';            % on-screen dot color for vertical points (magenta)

horizLinePix = reshape(uint8([0 255 0]),1,1,3);     % green
vertLinePix  = reshape(uint8([0 255 255]),1,1,3);   % cyan

horizDotPix  = reshape(uint8([255 0 0]),1,1,3);     % red
vertDotPix   = reshape(uint8([255 0 255]),1,1,3);   % magenta

%% ==========================================================
% ASK HOW MANY LINES OF EACH TYPE
%% ==========================================================

answer = inputdlg(...
    {'Number of HORIZONTAL lines','Number of VERTICAL lines'},...
    'Line Count',1,{'1','1'});

if isempty(answer)
    return;
end

figure(fig);   % bring the image window back to front after the dialog

numHorizontal = round(str2double(answer{1}));
numVertical   = round(str2double(answer{2}));

if isnan(numHorizontal) || numHorizontal<0
    numHorizontal = 0;
end
if isnan(numVertical) || numVertical<0
    numVertical = 0;
end

%% ==========================================================
% DRAW REFERENCE LINES, THEN AUTO-GENERATE THE REST
%
% User manually places:
%   - TOP horizontal line, BOTTOM horizontal line
%   - LEFT vertical line, RIGHT vertical line
%
% Any additional horizontal lines are spaced evenly in Y between
% the top and bottom lines. Any additional vertical lines are
% spaced evenly in X between the left and right lines.
%% ==========================================================

lineHandles = gobjects(0);   % ROI handle for each line
lineDir     = {};            % 'Horizontal' / 'Vertical' for each line
lineXLim    = {};            % clamp range for projecting clicks
lineYLim    = {};

%% ---------------- HORIZONTAL LINES ----------------
if numHorizontal >= 1

    title(ax,'Draw the TOP horizontal line');
    hTop = drawline(ax,'Color',horizLineColor,'LineWidth',0.5);
    wait(hTop);
    posTop = hTop.Position;
    posTop(:,2) = mean(posTop(:,2));
    hTop.Position = posTop;
    hTop.InteractionsAllowed = 'none';

    if numHorizontal == 1
        lineHandles(end+1) = hTop;
        lineDir{end+1}      = 'Horizontal';
        lineXLim{end+1}      = sort(posTop(:,1));
        lineYLim{end+1}      = sort(posTop(:,2));
    else
        title(ax,'Draw the BOTTOM horizontal line');
        hBottom = drawline(ax,'Color',horizLineColor,'LineWidth',0.5);
        wait(hBottom);
        posBottom = hBottom.Position;
        posBottom(:,2) = mean(posBottom(:,2));
        hBottom.Position = posBottom;
        hBottom.InteractionsAllowed = 'none';

        % Common X-span used for every horizontal line (avg of top/bottom)
        topX    = sort(posTop(:,1));
        bottomX = sort(posBottom(:,1));
        xLeft   = mean([topX(1),bottomX(1)]);
        xRight  = mean([topX(2),bottomX(2)]);

        yTop    = posTop(1,2);
        yBottom = posBottom(1,2);
        yAll    = linspace(yTop,yBottom,numHorizontal);   % includes top & bottom

        for k = 1:numHorizontal
            if k==1
                h = hTop;
            elseif k==numHorizontal
                h = hBottom;
            else
                pos = [xLeft yAll(k); xRight yAll(k)];
                h = drawline(ax,'Position',pos,'Color',horizLineColor,'LineWidth',0.5);
                h.InteractionsAllowed = 'none';
            end

            lineHandles(end+1) = h;
            lineDir{end+1}      = 'Horizontal';
            lineXLim{end+1}      = sort([xLeft xRight]);
            lineYLim{end+1}      = [yAll(k) yAll(k)];
        end
    end
end

%% ---------------- VERTICAL LINES ----------------
if numVertical >= 1

    title(ax,'Draw the LEFT vertical line');
    hLeft = drawline(ax,'Color',vertLineColor,'LineWidth',0.5);
    wait(hLeft);
    posLeft = hLeft.Position;
    posLeft(:,1) = mean(posLeft(:,1));
    hLeft.Position = posLeft;
    hLeft.InteractionsAllowed = 'none';

    if numVertical == 1
        lineHandles(end+1) = hLeft;
        lineDir{end+1}      = 'Vertical';
        lineXLim{end+1}      = sort(posLeft(:,1));
        lineYLim{end+1}      = sort(posLeft(:,2));
    else
        title(ax,'Draw the RIGHT vertical line');
        hRight = drawline(ax,'Color',vertLineColor,'LineWidth',0.5);
        wait(hRight);
        posRight = hRight.Position;
        posRight(:,1) = mean(posRight(:,1));
        hRight.Position = posRight;
        hRight.InteractionsAllowed = 'none';

        % Common Y-span used for every vertical line (avg of left/right)
        leftY  = sort(posLeft(:,2));
        rightY = sort(posRight(:,2));
        yTop2    = mean([leftY(1),rightY(1)]);
        yBottom2 = mean([leftY(2),rightY(2)]);

        xLeft2  = posLeft(1,1);
        xRight2 = posRight(1,1);
        xAll    = linspace(xLeft2,xRight2,numVertical);   % includes left & right

        for k = 1:numVertical
            if k==1
                h = hLeft;
            elseif k==numVertical
                h = hRight;
            else
                pos = [xAll(k) yTop2; xAll(k) yBottom2];
                h = drawline(ax,'Position',pos,'Color',vertLineColor,'LineWidth',0.5);
                h.InteractionsAllowed = 'none';
            end

            lineHandles(end+1) = h;
            lineDir{end+1}      = 'Vertical';
            lineXLim{end+1}      = [xAll(k) xAll(k)];
            lineYLim{end+1}      = sort([yTop2 yBottom2]);
        end
    end
end

%% ==========================================================
% VARIABLES
%% ==========================================================

Measurement    = [];
LineNumber     = [];
Direction      = {};
PointNumber    = [];

Point_X = [];
Point_Y = [];

Intercept_um = [];   % distance from the previous point on the same line

%% ==========================================================
% MEASUREMENT LOOP - now goes through each line already drawn
% (while-loop so we can jump straight to the vertical lines
% if the user chooses "Go to Vertical")
%% ==========================================================

idx = 1;

while idx <= numel(lineHandles)

    lineID  = idx;
    dirName = lineDir{lineID};
    xLim    = lineXLim{lineID};
    yLim    = lineYLim{lineID};

    % Highlight the active line in yellow while clicking
    origColor = lineHandles(lineID).Color;
    lineHandles(lineID).Color = 'y';

    title(ax,{sprintf('Line %d of %d (%s): click grain boundary intersections',...
           lineID,numel(lineHandles),dirName);...
           'Press ENTER after the last point'});

    [xClick,yClick] = ginput;

    % Restore the line to its original color once done
    lineHandles(lineID).Color = origColor;

    if numel(xClick) < 2
        uiwait(msgbox(sprintf('Line %d skipped (need at least 2 points).',lineID),...
            'Skipped','warn'));
        figure(fig);   % bring the image window back to front after the dialog
        idx = idx+1;
        continue
    end

    % Project every click exactly onto the fixed line
    if strcmp(dirName,'Horizontal')
        xProj = min(max(xClick,xLim(1)),xLim(2));
        yProj = repmat(yLim(1),size(xClick));  % yLim(1)==yLim(2) for a horizontal line
        dotColor = horizDotColor;
    else
        yProj = min(max(yClick,yLim(1)),yLim(2));
        xProj = repmat(xLim(1),size(yClick));  % xLim(1)==xLim(2) for a vertical line
        dotColor = vertDotColor;
    end

    % Plot dots exactly on the line (no offset); color depends on direction
    plot(ax,xProj,yProj,'.','Color',dotColor,'MarkerSize',15)

    %% ------------------------------------------------------
    % STORE EVERY REAL INTERCEPT (distance from the previous
    % point). The very first point on a line has no previous
    % point to measure from, so it is NOT stored as a row.
    %% ------------------------------------------------------
    for i = 2:numel(xProj)

        dPix    = hypot(xProj(i)-xProj(i-1), yProj(i)-yProj(i-1));
        dMicron = dPix*umPerPixel;

        Measurement(end+1,1) = length(Measurement)+1;
        LineNumber(end+1,1)  = lineID;
        Direction{end+1,1}   = dirName;
        PointNumber(end+1,1) = i;

        Point_X(end+1,1) = xProj(i);
        Point_Y(end+1,1) = yProj(i);

        Intercept_um(end+1,1) = dMicron;

    end

    %% ------------------------------------------------------
    % ASK WHAT TO DO NEXT
    %% ------------------------------------------------------
    if strcmp(dirName,'Horizontal')
        choiceNext = questdlg(...
            sprintf('Line %d of %d (%s) finished.',lineID,numel(lineHandles),dirName),...
            'Line Finished',...
            'Next','Go to Vertical','Finish Measurement','Next');
    else
        choiceNext = questdlg(...
            sprintf('Line %d of %d (%s) finished.',lineID,numel(lineHandles),dirName),...
            'Line Finished',...
            'Next','Finish Measurement','Next');
    end

    figure(fig);   % bring the image window back to front after the dialog

    switch choiceNext

        case 'Go to Vertical'
            % Jump to the next un-measured vertical line, if any
            vIdx = find(strcmp(lineDir,'Vertical') & (1:numel(lineDir))>lineID,1,'first');
            if isempty(vIdx)
                vIdx = find(strcmp(lineDir,'Vertical'),1,'first');
            end
            if isempty(vIdx)
                idx = idx+1;   % no vertical lines exist
            else
                idx = vIdx;
            end

        case 'Finish Measurement'
            break

        otherwise   % 'Next'
            idx = idx+1;

    end

end

%% ==========================================================
% CREATE TABLE
%% ==========================================================

T = table(...
    Measurement,...
    LineNumber,...
    Direction,...
    PointNumber,...
    Point_X,...
    Point_Y,...
    Intercept_um,...
    'VariableNames',...
    {'Measurement',...
     'Line',...
     'Direction',...
     'Point',...
     'X',...
     'Y',...
     'Intercept_um'});

disp(T)

%% ==========================================================
% SUMMARY STATISTICS (computed now so they can be saved to Excel too)
%% ==========================================================

realIntercepts = Intercept_um;   % every stored row is now a real intercept

if isempty(realIntercepts)
    TotalIntercepts = 0;
    AvgIntercept_um = NaN;
    StdIntercept_um = NaN;
    MinIntercept_um = NaN;
    MaxIntercept_um = NaN;
else
    TotalIntercepts = numel(realIntercepts);
    AvgIntercept_um = mean(realIntercepts);
    StdIntercept_um = std(realIntercepts);
    MinIntercept_um = min(realIntercepts);
    MaxIntercept_um = max(realIntercepts);
end

Tsummary = table(...
    TotalIntercepts,AvgIntercept_um,StdIntercept_um,MinIntercept_um,MaxIntercept_um,...
    'VariableNames',...
    {'Total_Intercepts','Average_um','StdDev_um','Min_um','Max_um'});

%% ==========================================================
% SAVE RESULTS
%% ==========================================================

[~,imageName,~] = fileparts(file);

excelFile = fullfile(path,[imageName '.xlsx']);
imageFile = fullfile(path,[imageName '_Measured.png']);

writetable(T,excelFile,'Sheet','Measurements');
writetable(Tsummary,excelFile,'Sheet','Summary');

%% ------------------------------------------------------
% BUILD THE ANNOTATED IMAGE BY DRAWING DIRECTLY ONTO THE
% ORIGINAL PIXEL DATA (NOT a figure screenshot). This
% guarantees the saved image is EXACTLY the same size as
% the source image, with no title/instruction text on it.
%% ------------------------------------------------------

imgAnnotated = img;

if size(imgAnnotated,3) == 1
    imgAnnotated = repmat(imgAnnotated,[1 1 3]);   % force RGB for coloring
end

imgAnnotated = im2uint8(imgAnnotated);

[imgH,imgW,~] = size(imgAnnotated);

% ---- Draw every line (1 px thick, exactly horizontal/vertical);   ----
% ---- color depends on direction (green = horizontal, cyan = vertical) ----
for lineID = 1:numel(lineHandles)

    if strcmp(lineDir{lineID},'Horizontal')

        yPix = round(lineYLim{lineID}(1));
        yPix = min(max(yPix,1),imgH);

        xStart = max(1,round(lineXLim{lineID}(1)));
        xEnd   = min(imgW,round(lineXLim{lineID}(2)));

        imgAnnotated(yPix,xStart:xEnd,:) = repmat(horizLinePix,1,xEnd-xStart+1,1);

    else

        xPix = round(lineXLim{lineID}(1));
        xPix = min(max(xPix,1),imgW);

        yStart = max(1,round(lineYLim{lineID}(1)));
        yEnd   = min(imgH,round(lineYLim{lineID}(2)));

        imgAnnotated(yStart:yEnd,xPix,:) = repmat(vertLinePix,yEnd-yStart+1,1,1);

    end

end

% ---- Draw every dot as a small filled ROUND circle (matches the   ----
% ---- markers shown on screen); color depends on direction         ----
% ---- (red = horizontal, magenta = vertical)                       ----
dotRadius = 8;   % pixels; increase/decrease to match the on-screen dot size

for i = 1:numel(Point_X)

    if strcmp(Direction{i},'Horizontal')
        dotPix = horizDotPix;
    else
        dotPix = vertDotPix;
    end

    cx = round(Point_X(i));
    cy = round(Point_Y(i));

    rr = max(1,cy-dotRadius):min(imgH,cy+dotRadius);
    cc = max(1,cx-dotRadius):min(imgW,cx+dotRadius);

    [ccGrid,rrGrid] = meshgrid(cc,rr);
    mask = (ccGrid-cx).^2 + (rrGrid-cy).^2 <= dotRadius^2;

    for ch = 1:3
        channel = imgAnnotated(rr,cc,ch);
        channel(mask) = dotPix(ch);
        imgAnnotated(rr,cc,ch) = channel;
    end

end

imwrite(imgAnnotated,imageFile);

fprintf('\n');
fprintf('Results Saved Successfully\n');
fprintf('-----------------------------------------\n');
fprintf('Excel File   : %s\n',excelFile);
fprintf('Measured Img : %s\n',imageFile);

%% ==========================================================
% SUMMARY (console + popup)
%% ==========================================================

if isempty(realIntercepts)

    fprintf('\n');
    fprintf('No intercepts were recorded.\n');
    msgbox(sprintf('Measurement Complete\n\nNo intercepts were recorded.'),'Summary');

else

    fprintf('\n');
    fprintf('-----------------------------------------\n');
    fprintf('Total Points       : %d\n',height(T));
    fprintf('Total Intercepts   : %d\n',TotalIntercepts);
    fprintf('Average Intercept  : %.3f um\n',AvgIntercept_um);
    fprintf('Standard Deviation : %.3f um\n',StdIntercept_um);
    fprintf('Minimum            : %.3f um\n',MinIntercept_um);
    fprintf('Maximum            : %.3f um\n',MaxIntercept_um);
    fprintf('-----------------------------------------\n');

    msgbox(sprintf(...
        ['Measurement Complete\n\n' ...
         'Total Intercepts   : %d\n' ...
         'Average Intercept  : %.3f um\n' ...
         'Standard Deviation : %.3f um'],...
        TotalIntercepts,AvgIntercept_um,StdIntercept_um),...
        'Summary');

end