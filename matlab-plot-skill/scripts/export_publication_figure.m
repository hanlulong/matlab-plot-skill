function export_publication_figure(fig, outputPath, opts)
%EXPORT_PUBLICATION_FIGURE Apply publication-style defaults and export a figure.
%   export_publication_figure(gcf, "Plots/my_figure.pdf")
%
%   This helper is meant to be copied or adapted into project code. It applies
%   explicit sizing, readable defaults, and vector export. The agent still
%   needs to read the generated figure and iterate on the layout afterward.

arguments
    fig (1,1) matlab.ui.Figure = gcf
    outputPath {mustBeTextScalar}
    opts.WidthInches (1,1) double {mustBePositive} = 7.0
    opts.HeightInches (1,1) double {mustBePositive} = 5.25
    opts.FontName {mustBeTextScalar} = "Helvetica"
    opts.AxisFontSize (1,1) double {mustBePositive} = 10
    opts.TitleFontSize (1,1) double {mustBePositive} = 11
    opts.LegendFontSize (1,1) double {mustBePositive} = 9
    opts.LineWidth (1,1) double {mustBePositive} = 1.3
    opts.MarkerSize (1,1) double {mustBePositive} = 7
    opts.Renderer {mustBeTextScalar} = "painters"
    opts.ContentType {mustBeTextScalar} = "vector"
    opts.BackgroundColor = "white"
    opts.LayoutPadding {mustBeTextScalar} = "compact"
    opts.TileSpacing {mustBeTextScalar} = "compact"
end

set(fig, ...
    'Color', opts.BackgroundColor, ...
    'Renderer', opts.Renderer, ...
    'Units', 'inches');

position = fig.Position;
position(3:4) = [opts.WidthInches, opts.HeightInches];
fig.Position = position;

layoutList = findall(fig, 'Type', 'tiledlayout');
for layout = reshape(layoutList, 1, [])
    layout.Padding = opts.LayoutPadding;
    layout.TileSpacing = opts.TileSpacing;
end

axesList = findall(fig, 'Type', 'axes');
for ax = reshape(axesList, 1, [])
    style_axes(ax, opts);
end

legendList = findall(fig, 'Type', 'legend');
for lgd = reshape(legendList, 1, [])
    lgd.FontName = opts.FontName;
    lgd.FontSize = opts.LegendFontSize;
    lgd.Box = 'off';
end

drawnow;
exportgraphics(fig, outputPath, ...
    'ContentType', opts.ContentType, ...
    'BackgroundColor', opts.BackgroundColor);
end

function style_axes(ax, opts)
ax.FontName = opts.FontName;
ax.FontSize = opts.AxisFontSize;
ax.LineWidth = 0.8;
ax.Box = 'off';
ax.TickDir = 'out';

titleHandle = get(ax, 'Title');
if isgraphics(titleHandle)
    titleHandle.FontName = opts.FontName;
    titleHandle.FontSize = opts.TitleFontSize;
    titleHandle.FontWeight = 'bold';
end

xlabelHandle = get(ax, 'XLabel');
if isgraphics(xlabelHandle)
    xlabelHandle.FontName = opts.FontName;
    xlabelHandle.FontSize = opts.AxisFontSize;
end

ylabelHandle = get(ax, 'YLabel');
if isgraphics(ylabelHandle)
    ylabelHandle.FontName = opts.FontName;
    ylabelHandle.FontSize = opts.AxisFontSize;
end

lineList = findall(ax, 'Type', 'line');
for lineObj = reshape(lineList, 1, [])
    lineObj.LineWidth = max(lineObj.LineWidth, opts.LineWidth);
    if strcmp(lineObj.Marker, 'none')
        continue;
    end
    lineObj.MarkerSize = max(lineObj.MarkerSize, opts.MarkerSize);
end
end
