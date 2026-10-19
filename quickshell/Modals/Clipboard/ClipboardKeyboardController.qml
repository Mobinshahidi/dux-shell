import QtQuick
import qs.Common
import qs.Services

QtObject {
    id: keyboardController

    required property var modal

    function reset() {
        ClipboardService.selectedIndex = 0;
        ClipboardService.keyboardNavigationActive = true;
        modal.showKeyboardHints = false;
    }

    function selectNext() {
        const entries = ClipboardService.clipboardEntries;
        if (!entries || entries.length === 0) {
            return;
        }
        ClipboardService.keyboardNavigationActive = true;
        ClipboardService.selectedIndex = Math.min(ClipboardService.selectedIndex + 1, entries.length - 1);
    }

    function selectPrevious() {
        const entries = ClipboardService.clipboardEntries;
        if (!entries || entries.length === 0) {
            return;
        }
        ClipboardService.keyboardNavigationActive = true;
        ClipboardService.selectedIndex = Math.max(ClipboardService.selectedIndex - 1, 0);
    }

    function copySelected() {
        const entries = ClipboardService.clipboardEntries;
        if (!entries || entries.length === 0 || ClipboardService.selectedIndex < 0 || ClipboardService.selectedIndex >= entries.length) {
            return;
        }
        const selectedEntry = entries[ClipboardService.selectedIndex];
        modal.copyEntry(selectedEntry);
    }

    function deleteSelected() {
        const entries = ClipboardService.clipboardEntries;
        if (!entries || entries.length === 0 || ClipboardService.selectedIndex < 0 || ClipboardService.selectedIndex >= entries.length) {
            return;
        }
        const selectedEntry = entries[ClipboardService.selectedIndex];
        modal.deleteEntry(selectedEntry);
    }

    function togglePinSelected() {
        const entries = ClipboardService.clipboardEntries;
        if (!entries || entries.length === 0 || ClipboardService.selectedIndex < 0 || ClipboardService.selectedIndex >= entries.length) {
            return;
        }
        const selectedEntry = entries[ClipboardService.selectedIndex];
        if (selectedEntry.pinned) {
            modal.unpinEntry(selectedEntry);
            return;
        }
        const pinnedDuplicate = ClipboardService.getPinnedEntryByHash(selectedEntry.hash);
        if (pinnedDuplicate) {
            modal.unpinEntry(pinnedDuplicate);
        } else {
            modal.pinEntry(selectedEntry);
        }
    }

    function editSelected() {
        const entries = ClipboardService.clipboardEntries;
        if (!entries || entries.length === 0) {
            return;
        }
        const index = ClipboardService.selectedIndex >= 0 && ClipboardService.selectedIndex < entries.length ? ClipboardService.selectedIndex : 0;
        modal.editEntry(entries[index]);
    }

    function handleKey(event) {
        if (modal.mode === "editor") {
            if (event.key === Qt.Key_Escape) {
                modal.mode = "history";
                event.accepted = true;
            }
            return;
        }

        if (modal.contextMenuActive) {
            if (event.key === Qt.Key_Escape)
                modal.closeContextMenu();
            event.accepted = true;
            return;
        }

        switch (event.key) {
        case Qt.Key_Escape:
            modal.hide();
            event.accepted = true;
            return;
        case Qt.Key_Down:
        case Qt.Key_Tab:
            if (!ClipboardService.keyboardNavigationActive) {
                ClipboardService.keyboardNavigationActive = true;
                ClipboardService.selectedIndex = 0;
            } else {
                selectNext();
            }
            event.accepted = true;
            return;
        case Qt.Key_Up:
        case Qt.Key_Backtab:
            if (!ClipboardService.keyboardNavigationActive) {
                ClipboardService.keyboardNavigationActive = true;
                ClipboardService.selectedIndex = 0;
            } else {
                selectPrevious();
            }
            event.accepted = true;
            return;
        case Qt.Key_F10:
            modal.showKeyboardHints = !modal.showKeyboardHints;
            event.accepted = true;
            return;
        }

        if (event.modifiers & Qt.ControlModifier) {
            switch (event.key) {
            case Qt.Key_N:
            case Qt.Key_J:
                if (!ClipboardService.keyboardNavigationActive) {
                    ClipboardService.keyboardNavigationActive = true;
                    ClipboardService.selectedIndex = 0;
                } else {
                    selectNext();
                }
                event.accepted = true;
                return;
            case Qt.Key_P:
            case Qt.Key_K:
                if (!ClipboardService.keyboardNavigationActive) {
                    ClipboardService.keyboardNavigationActive = true;
                    ClipboardService.selectedIndex = 0;
                } else {
                    selectPrevious();
                }
                event.accepted = true;
                return;
            case Qt.Key_C:
                if (ClipboardService.keyboardNavigationActive) {
                    copySelected();
                    event.accepted = true;
                }
                return;
            case Qt.Key_S:
                if (ClipboardService.keyboardNavigationActive) {
                    togglePinSelected();
                    event.accepted = true;
                }
                return;
            case Qt.Key_E:
                editSelected();
                event.accepted = true;
                return;
            case Qt.Key_G:
                if (ClipboardService.keyboardNavigationActive) {
                    modal.moveMode = true;
                    event.accepted = true;
                }
                return;
            case Qt.Key_Up:
                if (ClipboardService.keyboardNavigationActive) {
                    ClipboardService.moveEntry(ClipboardService.selectedIndex, ClipboardService.selectedIndex - 1);
                    ClipboardService.selectedIndex = Math.max(0, ClipboardService.selectedIndex - 1);
                    event.accepted = true;
                }
                return;
            case Qt.Key_Down:
                if (ClipboardService.keyboardNavigationActive) {
                    ClipboardService.moveEntry(ClipboardService.selectedIndex, ClipboardService.selectedIndex + 1);
                    ClipboardService.selectedIndex = Math.min(ClipboardService.clipboardEntries.length - 1, ClipboardService.selectedIndex + 1);
                    event.accepted = true;
                }
                return;
            }
        }

        if (event.modifiers & Qt.ShiftModifier) {
            switch (event.key) {
            case Qt.Key_Delete:
                modal.confirmClearAll();
                event.accepted = true;
                return;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (ClipboardService.keyboardNavigationActive) {
                    if (SettingsData.clipboardEnterToPaste) {
                        copySelected();
                    } else {
                        modal.pasteSelected();
                    }
                    event.accepted = true;
                }
                return;
            case Qt.Key_Up:
                if (ClipboardService.keyboardNavigationActive && (event.modifiers & Qt.ControlModifier)) {
                    ClipboardService.moveEntry(ClipboardService.selectedIndex, 0);
                    ClipboardService.selectedIndex = 0;
                    event.accepted = true;
                }
                return;
            case Qt.Key_Down:
                if (ClipboardService.keyboardNavigationActive && (event.modifiers & Qt.ControlModifier)) {
                    ClipboardService.moveEntry(ClipboardService.selectedIndex, ClipboardService.clipboardEntries.length - 1);
                    ClipboardService.selectedIndex = ClipboardService.clipboardEntries.length - 1;
                    event.accepted = true;
                }
                return;
            }
        }

        if (ClipboardService.keyboardNavigationActive) {
            switch (event.key) {
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (SettingsData.clipboardEnterToPaste) {
                    modal.pasteSelected();
                } else {
                    copySelected();
                }
                event.accepted = true;
                return;
            case Qt.Key_Delete:
                deleteSelected();
                event.accepted = true;
                return;
            }
        }
    }
}
