pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking
import qs

QtObject {
    id: root

    // ── NATIVE NETWORKING SINGLETONS ──────────────────────────────────
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled

    // ── DEVICE DISCOVERY ──────────────────────────────────────────────
    property WifiDevice wifiDevice: {
        var devs = Networking.devices.values;
        for (var i = 0; i < devs.length; i++) {
            if (devs[i] && devs[i].type === DeviceType.Wifi) return devs[i];
        }
        return null;
    }

    property WiredDevice wiredDevice: {
        var devs = Networking.devices.values;
        for (var i = 0; i < devs.length; i++) {
            if (devs[i] && devs[i].type === DeviceType.Wired) return devs[i];
        }
        return null;
    }

    // ── ETHERNET (WIRED) ──────────────────────────────────────────────
    readonly property bool ethernetEnabled: wiredDevice !== null
    readonly property bool ethernetConnected: wiredDevice ? wiredDevice.connected : false
    readonly property string ethernetName: wiredDevice ? wiredDevice.name : ""
    // address is the IP provided directly by the native API
    readonly property string ipv4: {
        if (wiredDevice && wiredDevice.connected && wiredDevice.address !== "")
            return wiredDevice.address;
        if (wifiDevice && wifiDevice.connected && wifiDevice.address !== "")
            return wifiDevice.address;
        return "";
    }

    // ── WI-FI PROPERTIES ──────────────────────────────────────────────
    readonly property bool connected: wifiDevice ? wifiDevice.connected : false
    readonly property string ssid: {
        if (!wifiDevice || !wifiDevice.connected) return "Disconnected";
        return _getConnectedSsid();
    }
    readonly property int signalStrength: {
        if (!wifiDevice || !wifiDevice.connected) return 0;
        return _getConnectedSignal();
    }

    // ── SCANNING & NETWORKS ───────────────────────────────────────────
    property var availableNetworks: []
    readonly property bool scanning: wifiDevice ? wifiDevice.scannerEnabled : false
    readonly property bool loading: false

    // ── INTERNAL HELPERS ──────────────────────────────────────────────
    function _getConnectedSsid() {
        if (!wifiDevice) return "Disconnected";
        var nets = wifiDevice.networks.values;
        for (var i = 0; i < nets.length; i++) {
            if (nets[i].connected) return nets[i].name;
        }
        return "Disconnected";
    }

    function _getConnectedSignal() {
        if (!wifiDevice) return 0;
        var nets = wifiDevice.networks.values;
        for (var i = 0; i < nets.length; i++) {
            if (nets[i].connected) return Math.round(nets[i].signalStrength * 100);
        }
        return 0;
    }

    function _buildNetworksList() {
        if (!wifiDevice) {
            root.availableNetworks = [];
            return;
        }
        var nativeNets = wifiDevice.networks.values;
        
        var nets = [];
        var seenSsids = {};

        for (var i = 0; i < nativeNets.length; i++) {
            var net = nativeNets[i];
            if (net.name) seenSsids[net.name] = true;
            
            // Reset pending connect if it succeeded
            if (net.connected && pendingConnectSsid === net.name) {
                pendingConnectSsid = "";
            }
            // Reset pending disconnect if it succeeded
            if (!net.connected && pendingDisconnectSsid === net.name) {
                pendingDisconnectSsid = "";
            }
            // Reset pending forget if it succeeded
            if (!net.known && pendingForgetSsid === net.name) {
                pendingForgetSsid = "";
            }
            
            nets.push({
                "ssid": net.name,
                "signal": Math.round(net.signalStrength * 100),
                "security": net.security,
                "active": net.connected,
                "secured": net.security !== WifiSecurityType.Open,
                "known": net.known,
                "native": net
            });
        }

        // If scanning is disabled, NetworkManager often drops unconnected networks.
        // We preserve them here so the UI doesn't suddenly empty out.
        if (!scanning) {
            for (var j = 0; j < root.availableNetworks.length; j++) {
                var oldNet = root.availableNetworks[j];
                if (oldNet.ssid && !seenSsids[oldNet.ssid]) {
                    oldNet.active = false; // It's definitely not connected if it was dropped
                    nets.push(oldNet);
                }
            }
        }

        nets.sort((a, b) => b.signal - a.signal);
        root.availableNetworks = nets;
    }

    // ── OPTIMISTIC UI STATE ───────────────────────────────────────────
    property string pendingConnectSsid: ""
    property string pendingDisconnectSsid: ""
    property string pendingForgetSsid: ""

    // ── PUBLIC API ────────────────────────────────────────────────────
    function scan() {
        if (!wifiDevice) return;
        // Toggle scanner to trigger a fresh scan
        wifiDevice.scannerEnabled = false;
        wifiDevice.scannerEnabled = true;
    }

    function toggleScan() {
        if (!wifiDevice) return;
        wifiDevice.scannerEnabled = !wifiDevice.scannerEnabled;
    }

    function connect(ssid, password) {
        if (!wifiDevice) return;
        pendingConnectSsid = ssid;
        pendingDisconnectSsid = "";
        var nets = wifiDevice.networks.values;
        for (var i = 0; i < nets.length; i++) {
            var net = nets[i];
            if (net.name === ssid) {
                if (password && password !== "") {
                    net.connectWithPsk(password);
                } else {
                    net.connect();
                }
                return;
            }
        }
    }

    function disconnect() {
        if (!wifiDevice) return;
        var nets = wifiDevice.networks.values;
        for (var i = 0; i < nets.length; i++) {
            var net = nets[i];
            if (net.connected) {
                pendingDisconnectSsid = net.name;
                pendingConnectSsid = "";
                // Disconnect logic varies, sometimes it's net.disconnect(), sometimes it's through the device.
                // Assuming Quickshell has disconnect() on WifiNetwork or WifiDevice.
                if (typeof net.disconnect === "function") {
                    net.disconnect();
                } else if (typeof wifiDevice.disconnect === "function") {
                    wifiDevice.disconnect();
                }
                return;
            }
        }
    }

    function forget(ssid) {
        if (!wifiDevice) return;
        pendingForgetSsid = ssid;
        var nets = wifiDevice.networks.values;
        for (var i = 0; i < nets.length; i++) {
            if (nets[i].name === ssid) {
                nets[i].forget();
                return;
            }
        }
    }



    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    // ── REACTIVE UPDATES ──────────────────────────────────────────────
    // QtObject has no default property, so Connections must be declared as a named property.
    property Connections _networksWatcher: Connections {
        target: root.wifiDevice ? root.wifiDevice.networks : null
        function onValuesChanged() { root._buildNetworksList(); }
    }

    Component.onCompleted: { 
        _buildNetworksList();
        if (wifiDevice) {
            wifiDevice.scannerEnabled = true;
        }
    }
}
