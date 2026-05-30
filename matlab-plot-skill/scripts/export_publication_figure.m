function export_publication_figure(fig, outputPath, opts)
%EXPORT_PUBLICATION_FIGURE Apply publication-style defaults and export a figure.
%   export_publication_figure(gcf, "Plots/my_figure.pdf")
%
%   This helper is meant to be copied or adapted into project code. It applies
%   explicit sizing, readable defaults, vector export, and an optional PNG
%   preview path for fast visual review. The agent still needs to read the
%   generated figure and iterate on the layout afterward.
%
%   Sizing: the default 6.5 in matches a typical LaTeX \textwidth. Set
%   WidthInches to the figure's FINAL printed width (e.g. ~3.3 in for a single
%   journal column, ~6.5 in for full text width) so the LaTeX include needs no
%   scaling and the fonts below render at their stated point sizes. See
%   references/matlab_figure_guidelines.md.
%
%   Notes:
%   - The layout (super) title is normalized to opts.SuperTitleFontSize and
%     opts.TitleFontWeight, overriding any size/weight a caller set on it.
%   - Line/marker readability floors apply only to 'line' objects; scatter,
%     errorbar, bar, and patch series are not auto-styled.
%
%   Requires MATLAB R2020a+ (exportgraphics); the demo's name=value call syntax
%   requires R2021a+.

arguments
    fig (1,1) matlab.ui.Figure
    outputPath {mustBeTextScalar}
    opts.WidthInches (1,1) double {mustBePositive} = 6.5
    opts.HeightInches (1,1) double {mustBePositive} = 4.0
    % Arial ships on Windows and macOS; Helvetica is effectively macOS-only and
    % is silently substituted elsewhere, which hurts cross-platform reproducibility.
    opts.FontName {mustBeTextScalar} = "Arial"
    opts.AxisFontSize (1,1) double {mustBePositive} = 10
    opts.TitleFontSize (1,1) double {mustBePositive} = 11
    opts.SuperTitleFontSize (1,1) double {mustBePositive} = 12
    opts.TitleFontWeight {mustBeMember(opts.TitleFontWeight, ["normal", "bold"])} = "normal"
    opts.LegendFontSize (1,1) double {mustBePositive} = 9
    opts.LineWidth (1,1) double {mustBePositive} = 1.3
    opts.MarkerSize (1,1) double {mustBePositive} = 7
    opts.ContentType {mustBeTextScalar} = "vector"
    opts.BackgroundColor = "white"
    opts.LayoutPadding {mustBeTextScalar} = "compact"
    opts.TileSpacing {mustBeTextScalar} = "compact"
    opts.PreviewPath {mustBeTextScalar} = ""
    opts.PreviewResolution (1,1) double {mustBePositive} = 220
end

% exportgraphics selects vector vs. raster output via 'ContentType' and ignores
% the figure 'Renderer' property, so there is no renderer to set for the PDF.
set(fig, ...
    'Color', opts.BackgroundColor, ...
    'Units', 'inches');

position = fig.Position;
position(3:4) = [opts.WidthInches, opts.HeightInches];
fig.Position = position;

layoutList = findall(fig, 'Type', 'tiledlayout');
for layout = reshape(layoutList, 1, [])
    layout.Padding = opts.LayoutPadding;
    layout.TileSpacing = opts.TileSpacing;
    style_layout_text(layout, opts);
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

ensure_parent_dir(outputPath);
exportgraphics(fig, outputPath, ...
    'ContentType', opts.ContentType, ...
    'BackgroundColor', opts.BackgroundColor);

if strlength(opts.PreviewPath) > 0
    ensure_parent_dir(opts.PreviewPath);
    exportgraphics(fig, opts.PreviewPath, ...
        'Resolution', opts.PreviewResolution, ...
        'BackgroundColor', opts.BackgroundColor);
end
end

function style_layout_text(layout, opts)
% Normalize the layout-level (super) title and shared axis labels so the most
% prominent text in a multi-panel figure matches the per-axes styling.
sharedText = [layout.Title, layout.XLabel, layout.YLabel];
if isprop(layout, 'Subtitle')   % tiledlayout Subtitle was added in R2021a.
    sharedText = [sharedText, layout.Subtitle];
end
for textHandle = sharedText
    if isgraphics(textHandle)
        textHandle.FontName = opts.FontName;
    end
end
if isgraphics(layout.Title)
    layout.Title.FontSize = opts.SuperTitleFontSize;
    layout.Title.FontWeight = opts.TitleFontWeight;
end
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
    titleHandle.FontWeight = opts.TitleFontWeight;
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
    % LineWidth and MarkerSize act as readability floors: only thin lines and
    % small markers are raised to the minimum; deliberately heavier series are
    % left untouched. Set the option to a target value to make weights uniform.
    lineObj.LineWidth = max(lineObj.LineWidth, opts.LineWidth);
    if strcmp(lineObj.Marker, 'none')
        continue;
    end
    lineObj.MarkerSize = max(lineObj.MarkerSize, opts.MarkerSize);
end
end

function ensure_parent_dir(filePath)
% exportgraphics does not create missing folders, so create the parent first.
parentDir = fileparts(filePath);
if ~isempty(parentDir) && ~isfolder(parentDir)
    mkdir(parentDir);
end
end
