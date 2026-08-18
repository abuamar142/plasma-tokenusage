import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_refreshInterval: refreshIntervalSpinBox.value
    property alias cfg_dataFilePath: dataFilePath.text
    property alias cfg_showCost: showCostCheckBox.checked
    property alias cfg_showBreakdown: showBreakdownCheckBox.checked

    QQC2.SpinBox {
        id: refreshIntervalSpinBox
        Kirigami.FormData.label: i18n("Refresh interval (seconds):")
        from: 10
        to: 300
        stepSize: 5
    }

    QQC2.TextField {
        id: dataFilePath
        Kirigami.FormData.label: i18n("Data file path:")
    }

    QQC2.CheckBox {
        id: showCostCheckBox
        Kirigami.FormData.label: i18n("Display:")
        text: i18n("Show cost in tooltip")
    }

    QQC2.CheckBox {
        id: showBreakdownCheckBox
        Kirigami.FormData.label: ""
        text: i18n("Show model breakdown in popup")
    }
}
