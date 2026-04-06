import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

QtObject {
    id: root

    // Exposed properties
    property string username: ""
    property string hostname: ""
    property string uptime: ""
    property string kernelVersion: ""
    property string cpuModel: "..."
    property string gpuModel: "..."
    property string osName: "..."
    property string de: "..."
    property string wm: "..."

    property FileView osReleaseFile: FileView { path: "/etc/os-release" }
    property FileView uptimeFile: FileView { path: "/proc/uptime" }
    property FileView hostnameFile: FileView { path: "/proc/sys/kernel/hostname" }
    property FileView cpuInfoFile: FileView { path: "/proc/cpuinfo" }

    Component.onDestruction: {
        refreshTimer.stop();
    }

    property Timer refreshTimer: Timer {
        id: refreshTimer
        interval: 1000
        repeat: true
        onTriggered: {
            uptimeFile.reload();
            var upText = uptimeFile.text();
            if (upText) {
                var totalSeconds = parseInt(upText.split(' ')[0]);
                var h = Math.floor(totalSeconds / 3600);
                var m = Math.floor((totalSeconds % 3600) / 60);
                var s = totalSeconds % 60;
                var pad = (n) => n < 10 ? "0" + n : n;
                root.uptime = pad(h) + ":" + pad(m) + ":" + pad(s);
            }
        }
    }

    property Timer startupTimer: Timer {
        interval: 500
        running: true
        repeat: false
        onTriggered: {
            refreshTimer.running = true;
            
            // Initial loads
            osReleaseFile.reload();
            uptimeFile.reload();
            hostnameFile.reload();
            cpuInfoFile.reload();
            
            // Parse OS Name
            var osMatch = osReleaseFile.text().match(/^PRETTY_NAME="?([^"\n]+)"?/m);
            if (osMatch) root.osName = osMatch[1].trim();
            
            // Parse CPU Model
            var cpuMatch = cpuInfoFile.text().match(/^model name\s*:\s*(.*)$/m);
            if (cpuMatch) root.cpuModel = cpuMatch[1].trim();
            
            // Parse Hostname
            root.hostname = hostnameFile.text().trim();
            
            // Fetch Username, Kernel, and GPU via quick one-off processes
            ProcessService.run(["whoami"], (out) => root.username = out.trim());
            ProcessService.run(["uname", "-r"], (out) => root.kernelVersion = out.trim());
            
            // Environment context
            root.de = Quickshell.env("XDG_CURRENT_DESKTOP") || "N/A";
            root.wm = Quickshell.env("XDG_SESSION_DESKTOP") || "N/A";

            // GPU Model - Robust Detection
            ProcessService.run(["sh", "-c", "{ if command -v lspci >/dev/null; then lspci | grep -i 'vga\\|display' | cut -d':' -f3; elif command -v glxinfo >/dev/null; then glxinfo 2>/dev/null | grep -i 'device:' | cut -d':' -f2-; else echo '...'; fi; } | sed 's/^[ \t]*//' | tr '\\n' '|'"], (out) => {
                if (!out) return;
                var gpus = out.split('|').filter(g => g.trim().length > 0);
                if (gpus.length === 0) return;

                var cleanGpu = (name) => {
                    var n = name.trim();
                    var vendor = "";
                    if (n.match(/Advanced Micro Devices|AMD\/ATI/i)) vendor = "AMD";
                    else if (n.match(/NVIDIA/i)) vendor = "NVIDIA";
                    else if (n.match(/Intel/i)) vendor = "Intel";

                    n = n.replace(/\(rev.*?\)/gi, "");
                    n = n.replace(/\(.*?(?:DRM|mesa|ACO|radeonsi|navi).*?\)/gi, "");
                    n = n.replace(/\(0x[0-9a-fA-F]+\)$/gi, "");

                    var matches = n.match(/\[([^\]]+)\]/g);
                    if (matches && matches.length > 0) {
                        var content = matches[matches.length - 1].replace(/^\[|\]$/g, "").trim();
                        if (content.indexOf('/') !== -1) content = content.split('/')[0].trim();
                        if (content.length > 2) n = content;
                    }

                    n = n.replace(/Radeon/g, "").replace(/Corporation/g, "").replace(/Integrated Graphics Controller/g, "IGP").replace(/\s+/g, ' ').trim();
                    if (vendor && !n.toUpperCase().startsWith(vendor)) n = vendor + " " + n;
                    return n;
                };

                var discrete = gpus.find(g => g.includes("NVIDIA")) || 
                               gpus.find(g => g.includes("Radeon") || g.includes("AMD")) || 
                               gpus.find(g => !g.includes("Intel"));
                               
                root.gpuModel = cleanGpu(discrete || gpus[0]);
            });
        }
    }
}
