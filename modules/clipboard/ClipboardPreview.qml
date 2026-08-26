import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs
import qs.services

Item {
    id: root

    property var item: null
    property string decodedText: ""
    property string imagePath: ""

    readonly property bool isImage: item && item.isImage === true
    readonly property bool isCodeItem: decodedText.length > 0 && Clipboard.isCode(decodedText)

    onItemChanged: {
        decodedText = ""
        imagePath = ""
        if (!item) return;
        if (item.isImage) {
            var rl = item.rawLine;
            Clipboard.decodeImage(rl, function(path) {
                if (root.item && root.item.rawLine === rl) {
                    root.imagePath = path;
                }
            });
        } else {
            var rawLine = item.rawLine;
            Clipboard.decodeItem(rawLine, function(text) {
                if (root.item && root.item.rawLine === rawLine) {
                    root.decodedText = text;
                }
            });
        }
    }

    Item {
        id: emptyState
        anchors.fill: parent
        visible: !root.item

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Globals.geometry.spacing.medium

            BaseIcon {
                Layout.alignment: Qt.AlignHCenter
                icon: "content_paste"
                size: Globals.dimensions.iconExtraLarge
                color: Globals.colors.muted
            }
        }
    }

    // ── IMAGE PREVIEW ──────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: root.isImage
        clip: true

        Image {
            id: img
            anchors.fill: parent
            source: root.imagePath ? "file://" + root.imagePath : ""
            visible: status === Image.Ready
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: true

            onStatusChanged: {
                if (status === Image.Ready) {
                    retryTimer.stop();
                } else if (status === Image.Error && root.imagePath !== "") {
                    retryTimer.restart();
                }
            }
        }

        BusyIndicator {
            anchors.centerIn: parent
            running: img.status === Image.Loading
            visible: running
        }

        Timer {
            id: retryTimer
            interval: 1000
            repeat: false
            onTriggered: {
                if (img.status === Image.Error && root.imagePath !== "" && root.item && root.item.isImage) {
                    var rl = root.item.rawLine;
                    root.imagePath = "";
                    Clipboard.decodeImage(rl, function(path) {
                        if (root.item && root.item.rawLine === rl) {
                            root.imagePath = path;
                        }
                    });
                }
            }
        }
    }

    // ── TEXT / CODE PREVIEW ────────────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: !root.isImage && root.item
        clip: true

        Text {
            anchors.fill: parent
            text: root.decodedText
            font.family: root.isCodeItem ? "monospace" : Globals.typography.family
            font.pixelSize: root.isCodeItem ? Globals.typography.size.small : Globals.typography.size.base
            color: Globals.colors.text
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            leftPadding: Globals.geometry.padding.medium
            rightPadding: Globals.geometry.padding.medium
            topPadding: Globals.geometry.padding.medium
        }
    }
}
