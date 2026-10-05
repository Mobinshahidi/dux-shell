import QtQuick
import qs.Common
import qs.Widgets

DankWindowHeader {
    id: header

    required property var modal

    controls: null
    horizontalPadding: 0
    verticalPadding: 0
    showDivider: false
    title: I18n.tr("Clipboard") + ` (${modal.totalCount})`
    onCloseRequested: modal.hide()

    ClipboardActions {
        modal: header.modal
    }
}
