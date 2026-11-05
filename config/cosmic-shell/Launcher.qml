import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

// Lanzador: las apps salen en espiral del agujero negro y vuelven a él al cerrarse
PanelWindow {
    id: win
    property bool open: false
    property string query: ""
    property bool showAll: false
    property int launchStamp: 0

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    // sin ancla arriba ni abajo: lateral izquierdo, centrado en vertical
    anchors { left: true }
    margins { left: 12 }
    implicitWidth: 528
    implicitHeight: Math.min(660, (win.screen?.height ?? 1080) - 110)
    exclusiveZone: 0
    color: "transparent"
    visible: open || closeTimer.running
    WlrLayershell.namespace: "cosmic-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    HyprlandFocusGrab { windows: [win]; active: win.open; onCleared: win.open = false }
    Timer { id: closeTimer; interval: Theme.anim }

    onOpenChanged: {
        if (open) {
            query = ""; showAll = false; search.text = ""; launchStamp++;
            grid.currentIndex = 0; grid.positionViewAtBeginning();
            search.forceActiveFocus();
        } else {
            closeTimer.restart();
        }
    }

    // Accesos favoritos; lo que no esté instalado no aparece
    readonly property var favIds: [
        { name: "Archivos", id: "org.gnome.Nautilus" },
        { name: "Terminal", id: "kitty" },
        { name: "Firefox", id: "firefox" },
        { name: "WhatsApp", icon: "/usr/share/icons/Qogir/scalable/apps/whatsapp.svg", needs: "chromium",
          command: "chromium --app=https://web.whatsapp.com --class=whatsapp-web" },
        { name: "Telegram", id: "org.telegram.desktop" },
        { name: "VS Code", id: ["com.microsoft.VSCode", "code", "code-oss"] },
        { name: "Discord", id: "discord" },
        { name: "Kate", id: "org.kde.kate" },
        { name: "Calculadora", id: "org.kde.kcalc" },
        { name: "Monitor", icon: "utilities-system-monitor", needs: "btop", command: "kitty --class btop -e btop" },
        { name: "LibreOffice", id: "libreoffice-startcenter" },
        { name: "Máquinas", id: "virt-manager" },
        { name: "Ajustes", id: "systemsettings" }
    ]

    function wrap(entry, name) {
        return { name: name || entry.name, icon: entry.icon, generic: entry.genericName || "",
                 keywords: (entry.keywords || []).join(" "), run: () => entry.execute() };
    }
    // cada objeto se crea una vez: ScriptModel reconoce los que siguen en la lista
    readonly property var apps: DesktopEntries.applications.values
        .filter(e => !e.noDisplay && e.name !== "")
        .map(e => wrap(e))
        .sort((a, b) => a.name.localeCompare(b.name))
    // las entradas cargan en segundo plano: leer applications hace que esto se recalcule
    readonly property var favs: {
        const all = DesktopEntries.applications.values;
        const find = id => [].concat(id).map(i => all.find(e => e.id === i)).find(x => x);
        return favIds.map(f => {
            if (f.command) {
                return f.needs === "btop" || find(f.needs)
                    ? { name: f.name, icon: f.icon, generic: "", keywords: "", run: () => Sys.run(f.command) } : null;
            }
            const e = find(f.id);
            return e ? wrap(e, f.name) : null;
        }).filter(x => x);
    }

    readonly property var shown: {
        const q = query.trim().toLowerCase();
        if (q === "") return showAll ? apps : favs;
        const rank = a => a.name.toLowerCase().startsWith(q) ? 0 : a.name.toLowerCase().includes(q) ? 1 : 2;
        return apps.filter(a => (a.name + " " + a.generic + " " + a.keywords).toLowerCase().includes(q))
                   .sort((a, b) => rank(a) - rank(b));
    }

    function launch(a) { if (!a) return; a.run(); open = false; }

    Item {
        id: panel
        anchors.fill: parent
        opacity: win.open ? 1 : 0
        scale: win.open ? 1 : 0.94
        transformOrigin: Item.Left
        Behavior on opacity { NumberAnimation { duration: Theme.anim } }
        Behavior on scale { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveDecel } }

        ClippingRectangle {
            anchors.fill: parent
            radius: Theme.radiusXl
            color: Theme.bg
            CosmicBackdrop {
                id: backdrop
                anchors.fill: parent
                running: win.visible
                holeX: parent.width / 2; holeY: parent.height * 0.5; holeR: 74
                strength: win.query === "" && !win.showAll ? 0.5 : 0.22
            }
        }
        CosmicBorder { anchors.fill: parent; running: win.visible }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 12

            // Buscador
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 46; radius: 23
                color: Theme.card
                border.width: 1; border.color: search.activeFocus ? Theme.primary : Theme.edge
                Behavior on border.color { ColorAnimation { duration: Theme.anim } }
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 10
                    MIcon { name: "search"; size: 20; color: Theme.primary }
                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        color: Theme.text; font.family: Theme.font; font.pixelSize: 15
                        selectionColor: Theme.primary; selectedTextColor: Theme.fgOnPrimary
                        clip: true
                        onTextChanged: { win.query = text; grid.currentIndex = 0; }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "Buscar en el universo…"; color: Theme.faint; font: search.font; visible: search.text === "" }
                        Keys.onEscapePressed: win.open = false
                        Keys.onReturnPressed: win.launch(win.shown[grid.currentIndex])
                        Keys.onEnterPressed: win.launch(win.shown[grid.currentIndex])
                        Keys.onTabPressed: grid.moveCurrentIndexRight()
                        Keys.onLeftPressed: grid.moveCurrentIndexLeft()
                        Keys.onRightPressed: grid.moveCurrentIndexRight()
                        Keys.onUpPressed: grid.moveCurrentIndexUp()
                        Keys.onDownPressed: grid.moveCurrentIndexDown()
                    }
                }
            }

            GridView {
                id: grid
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true
                cellWidth: Math.floor(width / 4); cellHeight: 118
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationWraps: true
                model: ScriptModel { values: win.shown }
                highlightFollowsCurrentItem: true
                highlightMoveDuration: Theme.animFast
                highlight: Rectangle {
                    radius: Theme.radiusL
                    color: Theme.primarySoft
                    border.width: 1; border.color: Qt.rgba(0.83, 0.91, 0.96, 0.55)
                }

                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    width: grid.cellWidth; height: grid.cellHeight
                    // 0 = dentro del agujero, 1 = en su sitio
                    property real p: 0
                    readonly property real dx: backdrop.holeX - 16 - (x - grid.contentX + width / 2)
                    readonly property real dy: backdrop.holeY - 74 - (y - grid.contentY + height / 2)

                    SequentialAnimation {
                        id: fly
                        PropertyAction { target: cell; property: "p"; value: 0 }
                        PauseAnimation { duration: Math.min(cell.index, 15) * 26 }
                        NumberAnimation { target: cell; property: "p"; to: 1; duration: 640; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveDecel }
                    }
                    NumberAnimation { id: fall; target: cell; property: "p"; to: 0; duration: Theme.anim; easing.type: Easing.InCubic }
                    Component.onCompleted: fly.restart()
                    Connections {
                        target: win
                        function onLaunchStampChanged() { fall.stop(); fly.restart(); }
                        function onOpenChanged() { if (!win.open) { fly.stop(); fall.restart(); } }
                    }

                    Item {
                        id: body
                        anchors.fill: parent
                        opacity: Math.min(1, cell.p * 1.6)
                        scale: (0.25 + 0.75 * cell.p) * (cm.pressed ? 0.92 : cm.containsMouse ? 1.06 : 1)
                        rotation: (1 - cell.p) * -100
                        transform: Translate { x: cell.dx * (1 - cell.p); y: cell.dy * (1 - cell.p) }
                        Behavior on scale { enabled: cell.p >= 1; NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutBack } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width - 12; spacing: 8
                            IconImage {
                                Layout.alignment: Qt.AlignHCenter
                                implicitSize: 52
                                source: {
                                    const i = cell.modelData.icon;
                                    return i && i.startsWith("/") ? "file://" + i : Quickshell.iconPath(i, "application-x-executable");
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: cell.modelData.name
                                horizontalAlignment: Text.AlignHCenter
                                color: Theme.text; font.family: Theme.font; font.pixelSize: 13
                                elide: Text.ElideRight
                                style: Text.Outline; styleColor: "#aa030819"
                            }
                        }
                    }
                    MouseArea {
                        id: cm
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onEntered: grid.currentIndex = cell.index
                        onClicked: win.launch(cell.modelData)
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent; spacing: 6; visible: grid.count === 0
                    MIcon { Layout.alignment: Qt.AlignHCenter; name: "travel_explore"; size: 44; color: Theme.faint }
                    Text { Layout.alignment: Qt.AlignHCenter; text: "Nada a la vista en esta galaxia"; color: Theme.sub; font.family: Theme.font; font.pixelSize: 13 }
                }
            }

            // Todas las apps
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 40; radius: 20
                visible: win.query === ""
                color: am.containsMouse ? Theme.surfaceHover : Theme.card
                border.width: 1; border.color: Theme.outline
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                RowLayout {
                    anchors.centerIn: parent; spacing: 8
                    MIcon { name: win.showAll ? "star" : "apps"; size: 18; color: Theme.primary }
                    Text { text: win.showAll ? "Favoritas" : "Todas las apps · " + win.apps.length; color: Theme.text; font.family: Theme.font; font.pixelSize: 13 }
                }
                MouseArea {
                    id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { win.showAll = !win.showAll; grid.currentIndex = 0; search.forceActiveFocus(); }
                }
            }
        }
    }
}
