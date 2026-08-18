import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: fullRoot

    // Explicit sizing for popup container
    Layout.preferredWidth: Kirigami.Units.gridUnit * 30
    Layout.preferredHeight: Kirigami.Units.gridUnit * 30
    Layout.minimumWidth: Kirigami.Units.gridUnit * 24
    Layout.minimumHeight: Kirigami.Units.gridUnit * 24
    width: Layout.preferredWidth
    height: Layout.preferredHeight

    property real sectionSpacing: Kirigami.Units.gridUnit * 1.0
    property real sideMargin: Kirigami.Units.gridUnit * 1.5

    // --- Main content layout ---
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        // --- Status bar ---
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: fullRoot.sideMargin
            Layout.rightMargin: fullRoot.sideMargin
            Layout.topMargin: Kirigami.Units.gridUnit * 1.0

            // Status pill
            Rectangle {
                radius: height / 2
                color: root.hasError
                    ? Qt.rgba(Kirigami.Theme.negativeTextColor.r, Kirigami.Theme.negativeTextColor.g, Kirigami.Theme.negativeTextColor.b, 0.15)
                    : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
                implicitWidth: statusRow.implicitWidth + Kirigami.Units.gridUnit * 1.0
                implicitHeight: Math.max(statusLabel.implicitHeight, Kirigami.Units.gridUnit * 0.7) + Kirigami.Units.gridUnit * 0.6

                RowLayout {
                    id: statusRow
                    anchors.centerIn: parent
                    spacing: Kirigami.Units.gridUnit * 0.3

                    QQC2.Label {
                        id: statusLabel
                        text: root.hasError ? i18n("Error") : (root.lastUpdated ? i18n("%1 ago", root.lastUpdated) : "")
                        font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.65)
                        font.weight: Font.Medium
                        opacity: 0.7
                    }
                }
            }

            Item { Layout.fillWidth: true }

            QQC2.ToolButton {
                icon.name: "view-refresh"
                implicitWidth: Kirigami.Units.gridUnit * 1.2
                implicitHeight: Kirigami.Units.gridUnit * 1.2
                QQC2.ToolTip.text: i18n("Refresh")
                QQC2.ToolTip.visible: hovered
                onClicked: root.loadUsageData()
            }
        }

        // --- Empty / Error state ---
        Flickable {
            visible: root.hasError || (!root.hasError && root.totalTokens === 0 && root.dailyHistory.length === 0)
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: fullRoot.sideMargin
            Layout.rightMargin: fullRoot.sideMargin
            Layout.topMargin: Kirigami.Units.gridUnit * 1.5
            contentHeight: emptyCol.implicitHeight
            clip: true

            ColumnLayout {
                id: emptyCol
                width: parent.width
                spacing: Kirigami.Units.gridUnit * 0.5

                Kirigami.Icon {
                    source: root.hasError ? "dialog-error" : "office-chart-bar"
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2.0
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2.0
                    Layout.alignment: Qt.AlignHCenter
                    opacity: 0.3
                }

                QQC2.Label {
                    text: root.hasError ? i18n("Unable to load data") : i18n("No usage data yet")
                    font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.75)
                    font.weight: Font.DemiBold
                    opacity: 0.6
                    Layout.alignment: Qt.AlignHCenter
                }

                // --- Setup instructions ---
                ColumnLayout {
                    spacing: Kirigami.Units.gridUnit * 0.4
                    Layout.topMargin: Kirigami.Units.gridUnit * 0.8
                    Layout.leftMargin: Kirigami.Units.gridUnit * 0.5
                    Layout.rightMargin: Kirigami.Units.gridUnit * 0.5

                    QQC2.Label {
                        text: i18n("Setup requires two steps:")
                        font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.55)
                        font.weight: Font.DemiBold
                        opacity: 0.55
                    }

                    QQC2.Label {
                        text: i18n("1. Install ccusage: <tt>bun add -g ccusage</tt>")
                        font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.5)
                        opacity: 0.45
                        wrapMode: Text.Wrap
                        textFormat: Text.RichText
                        Layout.fillWidth: true
                    }

                    QQC2.Label {
                        text: i18n("2. Run setup: <tt>bash extras/setup.sh</tt>")
                        font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.5)
                        opacity: 0.45
                        wrapMode: Text.Wrap
                        textFormat: Text.RichText
                        Layout.fillWidth: true
                    }

                    QQC2.Label {
                        text: i18n("Or see the README for manual setup instructions.")
                        font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.45)
                        opacity: 0.35
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.gridUnit * 0.3
                    }
                }
            }
        }

        // --- Hero metric (shown when data exists) ---
        ColumnLayout {
            visible: !root.hasError && root.totalTokens > 0
            Layout.fillWidth: true
            Layout.leftMargin: fullRoot.sideMargin
            Layout.rightMargin: fullRoot.sideMargin
            Layout.topMargin: Kirigami.Units.gridUnit * 0.6
            spacing: 0

            QQC2.Label {
                text: i18n("TODAY TOKEN USAGE")
                font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.6)
                font.weight: Font.DemiBold
                font.letterSpacing: 1.5
                opacity: 0.5
            }

            QQC2.Label {
                text: root.formatTokens(root.totalTokens)
                font.pixelSize: Math.round(Kirigami.Units.gridUnit * 2.0)
                font.weight: Font.Bold
                Layout.topMargin: -Kirigami.Units.gridUnit * 0.2
            }

            QQC2.Label {
                text: {
                    var parts = [];
                    if (root.showCost && root.totalCost > 0) {
                        parts.push("$" + root.totalCost.toFixed(2));
                    }
                    parts.push(root.formatTokens(root.inputTokens) + " in");
                    parts.push(root.formatTokens(root.outputTokens) + " out");
                    return parts.join("  ·  ");
                }
                font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.7)
                opacity: 0.55
            }
        }

        // --- Separator ---
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: fullRoot.sideMargin
            Layout.rightMargin: fullRoot.sideMargin
            Layout.topMargin: fullRoot.sectionSpacing
            height: 1
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
        }

        // --- Model Breakdown ---
        ColumnLayout {
            visible: root.showBreakdown && root.modelBreakdowns.length > 0
            Layout.fillWidth: true
            Layout.leftMargin: fullRoot.sideMargin
            Layout.rightMargin: fullRoot.sideMargin
            Layout.topMargin: fullRoot.sectionSpacing
            spacing: 0

            QQC2.Label {
                text: i18n("MODEL BREAKDOWN")
                font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.6)
                font.weight: Font.DemiBold
                font.letterSpacing: 1.5
                opacity: 0.5
            }

            Repeater {
                model: root.modelBreakdowns

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.gridUnit * 0.5
                    spacing: Kirigami.Units.gridUnit * 0.5

                    // Rank dot
                    Rectangle {
                        width: 5
                        height: 5
                        radius: 2.5
                        color: Kirigami.Theme.textColor
                        opacity: index === 0 ? 1.0 : (index === 1 ? 0.65 : (index === 2 ? 0.4 : 0.25))
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Model name
                    QQC2.Label {
                        text: modelData.modelName || i18n("unknown")
                        font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.7)
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    // Token count
                    QQC2.Label {
                        text: root.formatTokens((modelData.inputTokens || 0) + (modelData.outputTokens || 0))
                        font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.65)
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignRight
                        Layout.minimumWidth: Kirigami.Units.gridUnit * 3.0
                    }

                    // Cost
                    QQC2.Label {
                        text: "$" + (modelData.cost || 0).toFixed(2)
                        font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.6)
                        opacity: 0.45
                        horizontalAlignment: Text.AlignRight
                        Layout.minimumWidth: Kirigami.Units.gridUnit * 2.0
                        visible: root.showCost
                    }
                }
            }
        }

        // --- 7-Day History ---
        ColumnLayout {
            visible: root.dailyHistory.length > 1
            Layout.fillWidth: true
            Layout.leftMargin: fullRoot.sideMargin
            Layout.rightMargin: fullRoot.sideMargin
            Layout.topMargin: fullRoot.sectionSpacing
            spacing: 0

            QQC2.Label {
                text: i18n("LAST 7 DAYS")
                font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.6)
                font.weight: Font.DemiBold
                font.letterSpacing: 1.5
                opacity: 0.5
            }

            Repeater {
                model: root.dailyHistory

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.gridUnit * 0.5
                    spacing: Kirigami.Units.gridUnit * 0.5

                    // Date
                    QQC2.Label {
                        text: modelData.period ? modelData.period.slice(5) : ""
                        font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.65)
                        opacity: 0.5
                        Layout.minimumWidth: Kirigami.Units.gridUnit * 2.5
                    }

                    // Bar
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 0.35
                        radius: height / 2
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)

                        Rectangle {
                            width: {
                                var maxT = 0;
                                for (var i = 0; i < root.dailyHistory.length; i++) {
                                    if ((root.dailyHistory[i].totalTokens || 0) > maxT) maxT = root.dailyHistory[i].totalTokens;
                                }
                                return maxT > 0 ? ((modelData.totalTokens || 0) / maxT) * parent.width : 0;
                            }
                            height: parent.height
                            radius: height / 2
                            color: modelData.period === root.todayDate
                                ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.7)
                                : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
                        }
                    }

                    // Value
                    QQC2.Label {
                        text: root.formatTokens(modelData.totalTokens || 0)
                        font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.65)
                        font.weight: modelData.period === root.todayDate ? Font.DemiBold : Font.Normal
                        opacity: modelData.period === root.todayDate ? 0.9 : 0.5
                        horizontalAlignment: Text.AlignRight
                        Layout.minimumWidth: Kirigami.Units.gridUnit * 2.5
                    }
                }
            }
        }
    }
}
