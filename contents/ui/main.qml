import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // --- State ---
    property int totalTokens: 0
    property int inputTokens: 0
    property int outputTokens: 0
    property int cacheReadTokens: 0
    property int cacheCreationTokens: 0
    property real totalCost: 0.0
    property var modelBreakdowns: []
    property var dailyHistory: []
    property string lastUpdated: ""
    property bool hasError: false
    property string errorMessage: ""
    property string todayDate: new Date().toISOString().slice(0, 10)

    // --- Home directory ---
    // In Qt 6 QML sandbox: Qt.getenv removed, Qt.resolvedUrl follows symlinks,
    // StandardPaths unavailable. We hardcode for this personal widget.
    // Change this if deploying to a different user/system.
    readonly property string homeDir: "/home/abuamar"

    // --- Config ---
    readonly property int refreshInterval: Plasmoid.configuration.refreshInterval || 30
    readonly property string dataFilePath: {
        var configured = Plasmoid.configuration.dataFilePath;
        if (configured && configured.length > 0) {
            if (configured.charAt(0) === "~") {
                return homeDir + configured.substring(1);
            }
            return configured;
        }
        return homeDir + "/.cache/ccusage/tokenusage.json";
    }
    readonly property bool showCost: Plasmoid.configuration.showCost
    readonly property bool showBreakdown: Plasmoid.configuration.showBreakdown

    // --- Number formatting (toLocaleString broken in QML) ---
    function formatTokens(n) {
        if (n >= 1000000000) return (n / 1000000000).toFixed(1).replace(/\.0$/, "") + "B";
        if (n >= 1000000) return (n / 1000000).toFixed(1).replace(/\.0$/, "") + "M";
        if (n >= 1000) return (n / 1000).toFixed(1).replace(/\.0$/, "") + "K";
        return n.toString();
    }

    // --- Tooltip ---
    toolTipMainText: hasError ? "Token Usage — Error" : formatTokens(totalTokens)
    toolTipSubText: {
        if (hasError) return errorMessage;
        var parts = [];
        if (showCost && totalCost > 0) parts.push("$" + totalCost.toFixed(2));
        parts.push(formatTokens(inputTokens) + " in · " + formatTokens(outputTokens) + " out");
        if (lastUpdated) parts.push(lastUpdated);
        return parts.join("\n");
    }

    // --- Icon ---
    Plasmoid.icon: {
        if (hasError) return "dialog-error";
        return "office-chart-bar";
    }

    preferredRepresentation: null

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    // --- Timer for auto-refresh ---
    Timer {
        id: refreshTimer
        interval: root.refreshInterval * 1000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.loadUsageData()
    }

    // --- Reload config on change ---
    Connections {
        target: Plasmoid.configuration
        function onDataFilePathChanged() { root.loadUsageData(); }
        function onRefreshIntervalChanged() { refreshTimer.interval = root.refreshInterval * 1000; }
    }

    // --- Data loading ---
    function loadUsageData() {
        var filePath = root.dataFilePath;
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "file://" + filePath);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    root.parseUsageData(xhr.responseText);
                } else {
                    root.hasError = true;
                    root.errorMessage = i18n("Data file not found");
                }
            }
        };
        xhr.send();
    }

    function parseUsageData(jsonStr) {
        try {
            var data = JSON.parse(jsonStr);
            root.hasError = false;
            root.errorMessage = "";

            if (data.error) {
                root.hasError = true;
                root.errorMessage = data.error;
                return;
            }

            // ccusage JSON format: { daily: [...], totals: {...} }
            // Each daily entry: { period, totalTokens, inputTokens, outputTokens, cacheReadTokens, cacheCreationTokens, totalCost, modelBreakdowns: [...] }
            var today = root.todayDate;
            var todayData = null;

            if (data.daily && data.daily.length > 0) {
                // Find today's entry (period field = "YYYY-MM-DD")
                for (var i = 0; i < data.daily.length; i++) {
                    if (data.daily[i].period === today) {
                        todayData = data.daily[i];
                        break;
                    }
                }

                // Keep last 7 days for history (most recent first)
                var sorted = data.daily.slice().sort(function(a, b) {
                    return a.period > b.period ? -1 : (a.period < b.period ? 1 : 0);
                });
                root.dailyHistory = sorted.slice(0, 7);
            }

            if (todayData) {
                root.totalTokens = todayData.totalTokens || 0;
                root.inputTokens = todayData.inputTokens || 0;
                root.outputTokens = todayData.outputTokens || 0;
                root.cacheReadTokens = todayData.cacheReadTokens || 0;
                root.cacheCreationTokens = todayData.cacheCreationTokens || 0;
                root.totalCost = todayData.totalCost || 0;
                root.modelBreakdowns = todayData.modelBreakdowns || [];
            } else if (data.totals) {
                // Fallback: use totals if no today data
                root.totalTokens = data.totals.totalTokens || 0;
                root.inputTokens = data.totals.inputTokens || 0;
                root.outputTokens = data.totals.outputTokens || 0;
                root.cacheReadTokens = data.totals.cacheReadTokens || 0;
                root.cacheCreationTokens = data.totals.cacheCreationTokens || 0;
                root.totalCost = data.totals.totalCost || 0;
                root.modelBreakdowns = [];
            } else {
                root.totalTokens = 0;
                root.inputTokens = 0;
                root.outputTokens = 0;
                root.cacheReadTokens = 0;
                root.cacheCreationTokens = 0;
                root.totalCost = 0;
                root.modelBreakdowns = [];
            }

            // Timestamp
            var now = new Date();
            root.lastUpdated = now.getHours().toString().padStart(2, "0") + ":" +
                               now.getMinutes().toString().padStart(2, "0");

        } catch (e) {
            root.hasError = true;
            root.errorMessage = i18n("Parse error: %1", e.toString());
        }
    }

    Component.onCompleted: {
        loadUsageData();
    }
}
