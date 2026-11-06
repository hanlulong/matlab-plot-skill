function export_publication_figure(fig, outputPath, opts)
%EXPORT_PUBLICATION_FIGURE Apply publication-style defaults and export a figure.
%   export_publication_figure(fig, "out/figure.pdf", WidthInches=6.5, HeightInches=4)
%   export_publication_figure(fig, "out/figure.pdf", WidthInches=6.5, ...
%       HeightInches=4, PreviewPath="out/figure.png")
%
%   This helper is meant to be copied or adapted into project code. It applies
%   readable defaults, vector export, and an optional PNG preview path for fast
%   visual review. The agent still needs to read the generated figure and
%   iterate on the layout afterward.
%
%   Sizing: pass WidthInches and HeightInches as the figure's FINAL printed
%   size (e.g. 6.5 in for a 1-in-margin letter text width, about 3.2-3.5 in
%   for one column of a two-column class). A dimension you omit keeps the
%   figure's current size, so a size set with
%   figure('Units','inches','Position',...) is respected. MATLAB's default
%   figure size depends on the platform and session (about 10 x 6 in under
%   matlab -batch), so a warning is issued when either dimension is omitted
%   and the figure still has the default size.
%
%   Exported size: on R2025a+ the helper passes the figure size to
%   exportgraphics (Width/Height/Units), so the PDF page and the PNG preview
%   are exactly that size, the LaTeX include at that width needs no scaling,
%   and in a figure built at that size the fonts below print within about 1%
%   of their stated point sizes (a re-export of a resized figure can be 1-3%
%   off). Before R2025a (installed MATLAB) exportgraphics has no Width/Height
%   options and crops the export to its content, so the PDF comes out about
%   5-15% smaller than the figure. Check with: pdfinfo figure.pdf (Page size
%   in pt; divide by 72).
%   See references/matlab_figure_guidelines.md.
%
%   Layout spacing: LayoutPadding and TileSpacing are applied to every
%   tiledlayout only when passed; by default each layout keeps the spacing
%   the caller chose.
%
%   Notes:
%   - Axes, axes titles, axis labels (both sides of yyaxis axes), legends,
%     and a tiledlayout's shared X/Y labels get the font sizes below. Every
%     text object in the figure (including text() annotations, xline/yline
%     labels, and colorbars) gets opts.FontName, so the PDF does not mix
%     fonts. The exception is text with Interpreter='latex', which MATLAB
%     always typesets in Computer Modern (pdffonts lists mwa_cmr10 /
%     mwa_cmmi10); that is expected. Use the 'tex' interpreter (e.g.
%     '\pi_t') when a label should use the figure font.
%   - The layout (super) title keeps the caller's size and weight unless
%     SuperTitleFontSize and/or SuperTitleFontWeight is passed.
%   - On R2025a+ the figure is switched to the light theme so a dark-theme
%     session does not export gray text on a black plot box.
%   - Line/marker readability floors apply only to 'line' objects; scatter,
%     errorbar, bar, and patch series are not auto-styled.
%
%   Requires MATLAB R2021a+ (name=value call syntax; mustBeTextScalar is
%   R2020b+). fontname (R2022a+), theme (R2025a+), and the exportgraphics
%   Width/Height/Units options (R2025a+) are used when available.

arguments
    fig (1,1) matlab.ui.Figure
    outputPath {mustBeTextScalar}
    % [] keeps the figure's current width / height.
    opts.WidthInches double {mustBeScalarOrEmpty, mustBePositive} = []
    opts.HeightInches double {mustBeScalarOrEmpty, mustBePositive} = []
    % Arial ships on Windows and macOS; Helvetica is effectively macOS-only and
    % is silently substituted elsewhere, which hurts cross-platform reproducibility.
    opts.FontName {mustBeTextScalar} = "Arial"
    opts.AxisFontSize (1,1) double {mustBePositive} = 10
    opts.TitleFontSize (1,1) double {mustBePositive} = 11
    opts.TitleFontWeight {mustBeTextScalar} = "normal"
    % [] / "" keep the layout (super) title's own size / weight.
    opts.SuperTitleFontSize double {mustBeScalarOrEmpty, mustBePositive} = []
    opts.SuperTitleFontWeight {mustBeTextScalar} = ""
    opts.LegendFontSize (1,1) double {mustBePositive} = 9
    opts.LineWidth (1,1) double {mustBePositive} = 1.3
    opts.MarkerSize (1,1) double {mustBePositive} = 7
    opts.ContentType {mustBeTextScalar} = "vector"
    opts.BackgroundColor = "white"
    % "" keeps each tiledlayout's own Padding / TileSpacing.
    opts.LayoutPadding {mustBeTextScalar} = ""
    opts.TileSpacing {mustBeTextScalar} = ""
    opts.PreviewPath {mustBeTextScalar} = ""
    opts.PreviewResolution (1,1) double {mustBePositive} = 220
end

% Accept "Bold", "BOLD", etc.; validatestring returns the canonical spelling.
opts.TitleFontWeight = validatestring(opts.TitleFontWeight, ["normal", "bold"], ...
    mfilename, "TitleFontWeight");
if strlength(opts.SuperTitleFontWeight) > 0
    opts.SuperTitleFontWeight = validatestring(opts.SuperTitleFontWeight, ...
        ["normal", "bold"], mfilename, "SuperTitleFontWeight");
end

% R2025a+ figures can inherit a dark theme (desktop or MCP sessions), which
% exports gray text on a black plot box. Force the light theme before styling.
if exist('theme', 'file') == 2 && isprop(fig, 'Theme')
    theme(fig, 'light');
end

exportSize = apply_size(fig, opts);

% exportgraphics selects vector vs. raster output via 'ContentType' and ignores
% the figure 'Renderer' property, so there is no renderer to set for the PDF.
fig.Color = opts.BackgroundColor;

layoutList = findall(fig, 'Type', 'tiledlayout');
for layout = reshape(layoutList, 1, [])
    if strlength(opts.LayoutPadding) > 0
        layout.Padding = opts.LayoutPadding;
    end
    if strlength(opts.TileSpacing) > 0
        layout.TileSpacing = opts.TileSpacing;
    end
    style_layout_text(layout, opts);
end

axesList = findall(fig, 'Type', 'axes');
for ax = reshape(axesList, 1, [])
    style_axes(ax, opts);
end

legendList = findall(fig, 'Type', 'legend');
for lgd = reshape(legendList, 1, [])
    lgd.FontSize = opts.LegendFontSize;
    lgd.Box = 'off';
end

unify_font(fig, opts.FontName);

drawnow;

sizeArgs = export_size_args(exportSize);

ensure_parent_dir(outputPath);
exportgraphics(fig, outputPath, ...
    'ContentType', opts.ContentType, ...
    'BackgroundColor', opts.BackgroundColor, sizeArgs{:});

if strlength(opts.PreviewPath) > 0
    ensure_parent_dir(opts.PreviewPath);
    exportgraphics(fig, opts.PreviewPath, ...
        'Resolution', opts.PreviewResolution, ...
        'BackgroundColor', opts.BackgroundColor, sizeArgs{:});
end
end

function args = export_size_args(exportSize)
% exportgraphics crops to the content by default, so without Width/Height the
% PDF is narrower than the figure. On R2026a a figure resized after it was
% drawn can also export at its previous size until MATLAB catches up; passing
% the size explicitly fixes the page size in both cases (text in a re-export
% of a resized figure can still be 1-3% off). Width/Height/Units need R2025a+
% in installed MATLAB; older releases keep the cropped export.
args = {};
if ~isMATLABReleaseOlderThan("R2025a")
    args = {'Width', exportSize(1), 'Height', exportSize(2), 'Units', 'inches'};
end
end

function exportSize = apply_size(fig, opts)
% Resize only the dimensions the caller passed; keep the rest of the figure's
% current size. Check for MATLAB's default size BEFORE resizing, so a call
% that passes only one dimension (e.g. WidthInches=6.5 on a plain figure())
% still warns that the other dimension is MATLAB's default, not a choice.
% Returns the final [width height] in inches, computed from the request
% rather than read back from the figure, which can lag behind a resize.
omitted = strings(1, 0);
if isempty(opts.WidthInches)
    omitted(end + 1) = "WidthInches";
end
if isempty(opts.HeightInches)
    omitted(end + 1) = "HeightInches";
end
if ~isempty(omitted)
    fig.Units = 'pixels';
    defaultPosition = get(groot, 'defaultFigurePosition');
    if isequal(round(fig.Position(3:4)), round(defaultPosition(3:4)))
        fig.Units = 'inches';
        defaultInches = fig.Position(3:4);
        if numel(omitted) == 2
            missing = "neither WidthInches nor HeightInches was passed";
        else
            missing = omitted + " was not passed";
        end
        warning('export_publication_figure:defaultSize', ...
            ['The figure still has MATLAB''s default size (%.2f x %.2f in) ' ...
            'and %s, so the export keeps that default. Pass WidthInches ' ...
            'and HeightInches for the final printed size.'], ...
            defaultInches(1), defaultInches(2), missing);
    end
end

fig.Units = 'inches';
position = fig.Position;
if ~isempty(opts.WidthInches)
    position(3) = opts.WidthInches;
end
if ~isempty(opts.HeightInches)
    position(4) = opts.HeightInches;
end
fig.Position = position;
exportSize = position(3:4);
end

function style_layout_text(layout, opts)
% Shared X/Y labels match the per-axes label size. The super title keeps the
% caller's size and weight unless SuperTitleFontSize/Weight is passed.
for labelHandle = [layout.XLabel, layout.YLabel]
    if isgraphics(labelHandle)
        labelHandle.FontSize = opts.AxisFontSize;
    end
end
if isgraphics(layout.Title)
    if ~isempty(opts.SuperTitleFontSize)
        layout.Title.FontSize = opts.SuperTitleFontSize;
    end
    if strlength(opts.SuperTitleFontWeight) > 0
        layout.Title.FontWeight = opts.SuperTitleFontWeight;
    end
end
end

function style_axes(ax, opts)
ax.FontSize = opts.AxisFontSize;
ax.LineWidth = 0.8;
ax.Box = 'off';
ax.TickDir = 'out';

titleHandle = get(ax, 'Title');
if isgraphics(titleHandle)
    titleHandle.FontSize = opts.TitleFontSize;
    titleHandle.FontWeight = opts.TitleFontWeight;
end

% Style every ruler's label, not just get(ax, 'YLabel'), which returns only
% the active side's label on yyaxis axes and would leave the other side at
% MATLAB's 1.1x label size.
% Loop per axis: X, Y and Z rulers can be different classes (numeric,
% datetime, categorical), so they are not concatenated into one array.
for rulers = {ax.XAxis, ax.YAxis, ax.ZAxis}
    for ruler = reshape(rulers{1}, 1, [])
        if isgraphics(ruler.Label)
            ruler.Label.FontSize = opts.AxisFontSize;
        end
    end
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

function unify_font(fig, fontName)
% Set one font on every text object, including text() annotations and
% xline/yline labels, which per-axes styling does not reach.
if exist('fontname', 'file') == 2   % R2022a+
    fontname(fig, fontName);
else
    set(findall(fig, '-property', 'FontName'), 'FontName', fontName);
end
end

function ensure_parent_dir(filePath)
% exportgraphics does not create missing folders, so create the parent first.
% strlength, not isempty: for a string path with no folder ("s.pdf"),
% fileparts returns the 1x1 string "", which isempty treats as nonempty.
parentDir = fileparts(filePath);
if strlength(parentDir) > 0 && ~isfolder(parentDir)
    mkdir(parentDir);
end
end
