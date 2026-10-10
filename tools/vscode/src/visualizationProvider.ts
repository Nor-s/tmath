import * as path from "node:path";
import * as vscode from "vscode";
import type {PreviewContext, PreviewContextBase, PreviewContextResolver, PreviewSeries} from "./previewPanel";
import {explicitSourceRange, findSymbolRange, findSymbolRanges} from "./symbolLocator";
import {visualizationThumbnailKey} from "./thumbnailCache";
import {thumbnailSidecarPath} from "./thumbnailPath";
import {
    matchingVisualizationAnimation,
    matchingVisualizationLocations,
    matchingVisualizationUsage,
    normalizeWorkspacePath,
    parseVisualizationManifest,
    visualizationSeriesGroups,
    type VisualizationEntry,
    type VisualizationLocation,
} from "./visualizationManifest";

const MANIFEST_PATH = [".vscode", "tmath", "visualizations.json"];
const OPEN_COMMAND = "tmathPreview.openVisualization";
const OPEN_SOURCE_COMMAND = "tmathPreview.openVisualizationSource";

type VisualizationReference = {
    workspace: string;
    entry: VisualizationEntry;
};

type ManifestState = {
    uri: vscode.Uri;
    entries: VisualizationEntry[];
};

export function registerCodeVisualizations(
    diagnostics: vscode.DiagnosticCollection,
    openPreview: (uri: vscode.Uri, context: PreviewContext, preserveFocus?: boolean) => Promise<void>,
): {
    disposables: vscode.Disposable[];
    previewContextForAnimation: PreviewContextResolver;
    previewSeriesCatalog: () => Promise<PreviewSeries | undefined>;
} {
    const provider = new VisualizationProvider(diagnostics, openPreview);
    const selector: vscode.DocumentSelector = {scheme: "file"};
    return {
        disposables: [
            provider,
            vscode.languages.registerCodeLensProvider(selector, provider),
            vscode.languages.registerHoverProvider(selector, provider),
            vscode.commands.registerCommand(OPEN_COMMAND, (reference: unknown) => provider.open(reference)),
            vscode.commands.registerCommand(
                OPEN_SOURCE_COMMAND,
                (reference: unknown, index: unknown) => provider.openSource(reference, index),
            ),
        ],
        previewContextForAnimation: (document, sourceColumn) => provider.previewContextForAnimation(document, sourceColumn),
        previewSeriesCatalog: () => provider.previewSeriesCatalog(),
    };
}

class VisualizationProvider implements vscode.CodeLensProvider, vscode.HoverProvider, vscode.Disposable {
    private readonly codeLensEmitter = new vscode.EventEmitter<void>();
    private readonly watcher = vscode.workspace.createFileSystemWatcher("**/.vscode/tmath/visualizations.json");
    private readonly manifests = new Map<string, Promise<ManifestState>>();
    private readonly subscriptions: vscode.Disposable[] = [];
    readonly onDidChangeCodeLenses = this.codeLensEmitter.event;

    constructor(
        private readonly diagnostics: vscode.DiagnosticCollection,
        private readonly openPreview: (uri: vscode.Uri, context: PreviewContext, preserveFocus?: boolean) => Promise<void>,
    ) {
        const invalidate = (): void => {
            this.manifests.clear();
            this.codeLensEmitter.fire();
        };
        const invalidateManifest = (uri: vscode.Uri): void => {
            this.diagnostics.delete(uri);
            invalidate();
        };
        this.watcher.onDidCreate(invalidateManifest, null, this.subscriptions);
        this.watcher.onDidChange(invalidateManifest, null, this.subscriptions);
        this.watcher.onDidDelete(invalidateManifest, null, this.subscriptions);
        vscode.workspace.onDidChangeWorkspaceFolders(invalidate, null, this.subscriptions);
    }

    async provideCodeLenses(document: vscode.TextDocument): Promise<vscode.CodeLens[]> {
        const found = await this.entriesFor(document);
        if (!found) return [];
        const ranges = await Promise.all(found.matches.map((match) => this.rangeFor(document, match)));
        return found.matches.flatMap((match, index) => {
            const range = ranges[index];
            if (!range) return [];
            const entry = match.entry;
            const reference: VisualizationReference = {workspace: found.workspace.uri.toString(), entry};
            return [new vscode.CodeLens(range, {
                command: OPEN_COMMAND,
                title: match.relatedLabel
                    ? `$(play-circle) Preview related “${entry.title ?? entry.symbol}” animation`
                    : `$(play-circle) Preview “${entry.title ?? entry.symbol}” animation`,
                tooltip: `Open ${entry.animation} in tmath Preview`,
                arguments: [reference],
            })];
        });
    }

    async provideHover(document: vscode.TextDocument, position: vscode.Position): Promise<vscode.Hover | undefined> {
        const found = await this.hoverLocation(document, position);
        if (!found) return undefined;
        const {match, range, workspace} = found;
        const entry = match.entry;
        const reference: VisualizationReference = {workspace: workspace.uri.toString(), entry};
        const commandUri = vscode.Uri.parse(`command:${OPEN_COMMAND}?${encodeURIComponent(JSON.stringify([reference]))}`);
        const markdown = new vscode.MarkdownString();
        const thumbnail = await this.cachedThumbnail(reference);
        if (thumbnail) {
            markdown.baseUri = thumbnail.with({path: `${path.posix.dirname(thumbnail.path)}/`});
            const image = encodeURIComponent(path.posix.basename(thumbnail.path));
            markdown.appendMarkdown(`[![${escapeMarkdown(entry.title ?? entry.symbol)} animation](./${image})](${commandUri.toString()})  \n`);
        }
        const kind = match.relatedLabel === "Usage"
            ? "tmath usage visualization"
            : match.relatedLabel ? "tmath related visualization" : "tmath visualization";
        markdown.appendMarkdown(`**${kind}**  \n`);
        markdown.appendMarkdown(`[\u25b6 Preview ${escapeMarkdown(entry.title ?? entry.symbol)} animation](${commandUri.toString()})`);
        markdown.appendMarkdown(`  \n\n**Related source**  \n`);
        const sources = [
            {label: "Definition", index: -1},
            ...entry.links.map((link, index) => ({label: link.label, index})),
        ];
        markdown.appendMarkdown(sources.map((source) => {
            const uri = vscode.Uri.parse(`command:${OPEN_SOURCE_COMMAND}?${encodeURIComponent(JSON.stringify([reference, source.index]))}`);
            return `[\`${escapeMarkdown(source.label)}\`](${uri.toString()})`;
        }).join(" · "));
        markdown.isTrusted = {enabledCommands: [OPEN_COMMAND, OPEN_SOURCE_COMMAND]};
        return new vscode.Hover(markdown, range);
    }

    async open(raw: unknown): Promise<void> {
        const reference = visualizationReference(raw);
        if (!reference) return;
        await this.openReference(reference, {preserveFocus: false, quiet: false});
    }

    async previewContextForAnimation(
        document: vscode.TextDocument,
        sourceColumn?: vscode.ViewColumn,
    ): Promise<PreviewContext | undefined> {
        const workspace = vscode.workspace.getWorkspaceFolder(document.uri);
        if (!workspace) return undefined;
        const animation = normalizeWorkspacePath(path.relative(workspace.uri.fsPath, document.uri.fsPath));
        if (!animation) return undefined;
        const manifest = await this.manifest(workspace);
        const entry = matchingVisualizationAnimation(manifest.entries, animation);
        if (!entry) return undefined;
        return this.previewContextWithSeries(workspace, entry, sourceColumn, manifest.entries);
    }

    async previewSeriesCatalog(): Promise<PreviewSeries | undefined> {
        const workspace = (vscode.window.activeTextEditor
            ? vscode.workspace.getWorkspaceFolder(vscode.window.activeTextEditor.document.uri)
            : undefined) ?? vscode.workspace.workspaceFolders?.[0];
        if (!workspace) return undefined;
        const manifest = await this.manifest(workspace);
        const groups = visualizationSeriesGroups(manifest.entries);
        if (!groups.length) return undefined;
        const sourceColumn = vscode.window.activeTextEditor?.viewColumn;
        const workspaceKey = workspace.uri.toString();
        const thumbnails = vscode.workspace.getConfiguration("tmathPreview", workspace.uri)
            .get<boolean>("codeVisualizations.hoverThumbnails", true);
        return {
            activeGroupIndex: 0,
            groups: groups.map((group) => ({
                label: group.label,
                activeIndex: -1,
                items: group.entries.map((entry) => ({
                    label: entry.title ?? entry.symbol,
                    uri: workspaceUri(workspace, entry.animation),
                    context: this.previewContextForEntry(
                        workspace,
                        workspaceKey,
                        entry,
                        sourceColumn,
                        thumbnails,
                    ),
                })),
            })),
        };
    }

    async openSource(raw: unknown, rawIndex: unknown): Promise<void> {
        const reference = visualizationReference(raw);
        if (!reference || !Number.isInteger(rawIndex)) return;
        const index = rawIndex as number;
        if (index < -1 || index >= reference.entry.links.length) return;
        const workspace = vscode.workspace.workspaceFolders?.find((folder) => folder.uri.toString() === reference.workspace);
        if (!workspace) return;
        const source = index === -1
            ? {source: reference.entry.source, symbol: reference.entry.symbol, line: reference.entry.line, column: undefined}
            : reference.entry.links[index];
        try {
            const document = await vscode.workspace.openTextDocument(workspaceUri(workspace, source.source));
            const editor = await vscode.window.showTextDocument(document, {
                viewColumn: vscode.window.activeTextEditor?.viewColumn ?? vscode.ViewColumn.One,
                preview: false,
            });
            const sourceRange = "range" in source ? source.range : undefined;
            const explicitRange = sourceRange ? explicitSourceRange(document, sourceRange) : undefined;
            const located = explicitRange
                ? {range: explicitRange, selectionRange: explicitRange}
                : await findSymbolRanges(
                    document,
                    source.symbol ?? reference.entry.symbol,
                    source.line,
                    source.column,
                );
            if (located) {
                const selection = explicitRange ? located.range : located.selectionRange;
                editor.selection = new vscode.Selection(selection.start, selection.end);
                editor.revealRange(located.range, vscode.TextEditorRevealType.InCenterIfOutsideViewport);
            }
        } catch {
            void vscode.window.showErrorMessage(`Could not open related source: ${source.source}`);
        }
    }

    private async openReference(
        reference: VisualizationReference,
        options: {preserveFocus: boolean; quiet: boolean},
    ): Promise<boolean> {
        const workspace = vscode.workspace.workspaceFolders?.find((folder) => folder.uri.toString() === reference.workspace);
        if (!workspace) {
            if (!options.quiet) void vscode.window.showErrorMessage("The workspace for this tmath visualization is no longer open.");
            return false;
        }
        const animationUri = workspaceUri(workspace, reference.entry.animation);
        try {
            await vscode.workspace.fs.stat(animationUri);
        } catch {
            if (!options.quiet) void vscode.window.showErrorMessage(`tmath animation not found: ${reference.entry.animation}`);
            return false;
        }
        const sourceColumn = vscode.window.activeTextEditor?.viewColumn;
        const manifest = await this.manifest(workspace);
        const entry = reference.entry;
        const context = this.previewContextWithSeries(workspace, entry, sourceColumn, manifest.entries);
        await this.openPreview(animationUri, context, options.preserveFocus);
        return true;
    }

    private previewContextWithSeries(
        workspace: vscode.WorkspaceFolder,
        entry: VisualizationEntry,
        sourceColumn: vscode.ViewColumn | undefined,
        entries: VisualizationEntry[],
    ): PreviewContext {
        const workspaceKey = workspace.uri.toString();
        const thumbnails = vscode.workspace.getConfiguration("tmathPreview", workspace.uri)
            .get<boolean>("codeVisualizations.hoverThumbnails", true);
        const context: PreviewContext = this.previewContextForEntry(
            workspace,
            workspaceKey,
            entry,
            sourceColumn,
            thumbnails,
        );
        const seriesGroups = visualizationSeriesGroups(entries);
        if (seriesGroups.length) {
            const activeGroupIndex = seriesGroups.findIndex((group) => group.label === entry.series);
            context.series = {
                activeGroupIndex: Math.max(0, activeGroupIndex),
                groups: seriesGroups.map((group) => ({
                    label: group.label,
                    activeIndex: group.entries.findIndex(
                        (item) => visualizationEntryKey(item) === visualizationEntryKey(entry),
                    ),
                    items: group.entries.map((item) => ({
                        label: item.title ?? item.symbol,
                        uri: workspaceUri(workspace, item.animation),
                        context: this.previewContextForEntry(
                            workspace,
                            workspaceKey,
                            item,
                            sourceColumn,
                            thumbnails,
                        ),
                    })),
                })),
            };
        }
        return context;
    }

    private previewContextForEntry(
        workspace: vscode.WorkspaceFolder,
        workspaceKey: string,
        entry: VisualizationEntry,
        sourceColumn: vscode.ViewColumn | undefined,
        thumbnails: boolean,
    ): PreviewContextBase {
        return {
            title: entry.title ?? entry.symbol,
            primarySource: {
                label: entry.symbol,
                uri: workspaceUri(workspace, entry.source),
                line: entry.line,
                symbol: entry.symbol,
            },
            relatedSources: entry.links.map((link) => ({
                label: link.label,
                uri: workspaceUri(workspace, link.source),
                line: link.line,
                column: link.column,
                symbol: link.symbol,
                range: link.range,
                diff: link.diff
                    ? {
                        base: link.diff.base,
                        head: link.diff.head,
                        oldUri: workspaceUri(workspace, link.diff.oldPath ?? link.source),
                    }
                    : undefined,
            })),
            sourceColumn,
            thumbnailKey: thumbnails ? visualizationThumbnailKey(workspaceKey, entry.animation) : undefined,
            thumbnailTarget: thumbnails ? workspaceUri(workspace, thumbnailSidecarPath(entry.animation)) : undefined,
            description: entry.description ?? defaultDescription(entry),
        };
    }

    dispose(): void {
        this.watcher.dispose();
        while (this.subscriptions.length) this.subscriptions.pop()?.dispose();
        this.codeLensEmitter.dispose();
        for (const manifest of this.manifests.values()) {
            void manifest.then((state) => this.diagnostics.delete(state.uri));
        }
        this.manifests.clear();
    }

    private async cachedThumbnail(reference: VisualizationReference): Promise<vscode.Uri | undefined> {
        const workspace = vscode.workspace.workspaceFolders?.find((folder) => folder.uri.toString() === reference.workspace);
        if (!workspace || !vscode.workspace.getConfiguration("tmathPreview", workspace.uri)
            .get<boolean>("codeVisualizations.hoverThumbnails", true)) return undefined;
        const uri = workspaceUri(workspace, thumbnailSidecarPath(reference.entry.animation));
        try {
            await vscode.workspace.fs.stat(uri);
            return uri;
        } catch {
            return undefined;
        }
    }

    private async hoverLocation(document: vscode.TextDocument, position: vscode.Position): Promise<{
        workspace: vscode.WorkspaceFolder;
        match: VisualizationLocation;
        range: vscode.Range;
    } | undefined> {
        const workspace = vscode.workspace.getWorkspaceFolder(document.uri);
        if (!workspace) return undefined;
        const relative = normalizeWorkspacePath(path.relative(workspace.uri.fsPath, document.uri.fsPath));
        if (!relative) return undefined;
        const manifest = await this.manifest(workspace);
        for (const match of matchingVisualizationLocations(manifest.entries, relative)) {
            const range = await this.rangeFor(document, match);
            if (range?.contains(position)) return {workspace, match, range};
        }

        const range = document.getWordRangeAtPosition(position);
        if (!range) return undefined;
        const word = document.getText(range);
        const definitions = await vscode.commands.executeCommand<Array<vscode.Location | vscode.LocationLink>>(
            "vscode.executeDefinitionProvider",
            document.uri,
            position,
        );
        const definitionPaths: string[] = [];
        for (const definition of definitions ?? []) {
            const uri = "targetUri" in definition ? definition.targetUri : definition.uri;
            if (vscode.workspace.getWorkspaceFolder(uri)?.uri.toString() !== workspace.uri.toString()) continue;
            const definitionPath = normalizeWorkspacePath(path.relative(workspace.uri.fsPath, uri.fsPath));
            if (definitionPath) definitionPaths.push(definitionPath);
        }
        if (definitions?.length && !definitionPaths.length) return undefined;
        const entry = matchingVisualizationUsage(manifest.entries, word, definitionPaths);
        if (!entry) return undefined;
        return {workspace, match: {entry, symbol: word, relatedLabel: "Usage"}, range};
    }

    private async entriesFor(document: vscode.TextDocument): Promise<{
        workspace: vscode.WorkspaceFolder;
        matches: VisualizationLocation[];
    } | undefined> {
        const workspace = vscode.workspace.getWorkspaceFolder(document.uri);
        if (!workspace) return undefined;
        const relative = normalizeWorkspacePath(path.relative(workspace.uri.fsPath, document.uri.fsPath));
        if (!relative) return undefined;
        const manifest = await this.manifest(workspace);
        const matches = matchingVisualizationLocations(manifest.entries, relative);
        return matches.length ? {workspace, matches} : undefined;
    }

    private rangeFor(document: vscode.TextDocument, match: VisualizationLocation): Promise<vscode.Range | undefined> {
        if (match.range) return Promise.resolve(explicitSourceRange(document, match.range));
        return findSymbolRange(document, match.symbol, match.line, match.column);
    }

    private manifest(workspace: vscode.WorkspaceFolder): Promise<ManifestState> {
        const key = workspace.uri.toString();
        let cached = this.manifests.get(key);
        if (!cached) {
            cached = this.readManifest(workspace);
            this.manifests.set(key, cached);
        }
        return cached;
    }

    private async readManifest(workspace: vscode.WorkspaceFolder): Promise<ManifestState> {
        const uri = vscode.Uri.joinPath(workspace.uri, ...MANIFEST_PATH);
        let bytes: Uint8Array;
        try {
            bytes = await vscode.workspace.fs.readFile(uri);
        } catch {
            this.diagnostics.delete(uri);
            return {uri, entries: []};
        }
        let raw: unknown;
        try {
            raw = JSON.parse(Buffer.from(bytes).toString("utf8"));
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            this.setManifestErrors(uri, [`Invalid JSON: ${message}`]);
            return {uri, entries: []};
        }
        const parsed = parseVisualizationManifest(raw);
        this.setManifestErrors(uri, parsed.errors);
        return {uri, entries: parsed.entries};
    }

    private setManifestErrors(uri: vscode.Uri, errors: string[]): void {
        if (!errors.length) {
            this.diagnostics.delete(uri);
            return;
        }
        this.diagnostics.set(uri, errors.map((message) => {
            const diagnostic = new vscode.Diagnostic(new vscode.Range(0, 0, 0, 1), message, vscode.DiagnosticSeverity.Error);
            diagnostic.source = "tmath Visualizations";
            return diagnostic;
        }));
    }
}

function workspaceUri(workspace: vscode.WorkspaceFolder, relative: string): vscode.Uri {
    return vscode.Uri.joinPath(workspace.uri, ...relative.split("/"));
}

function visualizationReference(value: unknown): VisualizationReference | undefined {
    if (!value || typeof value !== "object") return undefined;
    const reference = value as Partial<VisualizationReference>;
    if (typeof reference.workspace !== "string" || !reference.entry || typeof reference.entry !== "object") return undefined;
    const parsed = parseVisualizationManifest({version: 2, visualizations: [reference.entry]});
    if (parsed.errors.length || !parsed.entries[0]) return undefined;
    return {workspace: reference.workspace, entry: parsed.entries[0]};
}

function visualizationEntryKey(entry: VisualizationEntry): string {
    return `${entry.source}\0${entry.symbol}\0${entry.line ?? ""}\0${entry.animation}`;
}

function defaultDescription(entry: VisualizationEntry): string {
    return `Animation for \`${entry.symbol}\` in \`${entry.source}\`.`;
}

function escapeMarkdown(value: string): string {
    return value.replace(/[\\`*_{}[\]()<>#+.!|\-]/g, "\\$&");
}
