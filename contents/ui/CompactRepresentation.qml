import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

MouseArea {
    id: compactRoot

    property bool wasExpanded

    Layout.minimumWidth: Kirigami.Units.gridUnit
    Layout.minimumHeight: Kirigami.Units.gridUnit
    Layout.preferredWidth: Kirigami.Units.gridUnit
    Layout.preferredHeight: Kirigami.Units.gridUnit

    Accessible.name: Plasmoid.title
    Accessible.role: Accessible.Button

    onPressed: wasExpanded = root.expanded
    onClicked: root.expanded = !wasExpanded

    Kirigami.Icon {
        anchors.centerIn: parent
        source: Plasmoid.icon
        width: Kirigami.Units.gridUnit
        height: Kirigami.Units.gridUnit
    }
}
