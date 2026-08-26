import QtQuick
import Quickshell
import Quickshell.Io
import qs
pragma Singleton

QtObject {
    id: root

    // Power state capabilities
    readonly property bool canShutdown: true
    readonly property bool canReboot: true
    readonly property bool canSuspend: true
    readonly property bool canHibernate: true
    readonly property bool canLogout: true

    signal powerOperationStarted(string operation)

    // Shutdown the system
    function poweroff() {
        powerOperationStarted("poweroff");
        ProcessService.runDetached(["systemctl", "poweroff"]);
    }

    function shutdown() {
        poweroff();
    }

    // Reboot the system
    function reboot() {
        powerOperationStarted("reboot");
        ProcessService.runDetached(["systemctl", "reboot"]);
    }

    // Suspend the system
    function suspend() {
        powerOperationStarted("suspend");
        ProcessService.runDetached(["systemctl", "suspend"]);
    }

    // Logout the current user
    function logout() {
        powerOperationStarted("logout");
        Compositor.quit();
    }

}
