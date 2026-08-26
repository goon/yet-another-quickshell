import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs

BaseBento {
    id: weather
    hoverEnabled: true
    clip: true

    RowLayout {
        id: weatherWidget
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Globals.geometry.spacing.large


        readonly property bool isDay: Weather.isDay
        readonly property int code: Weather.weatherCode

        function getIcon(code, isDay) {
            if (code === 0)
                return isDay ? "clear_day" : "clear_night";
            if (code >= 1 && code <= 3)
                return isDay ? "partly_cloudy_day" : "partly_cloudy_night";
            if (code >= 45 && code <= 48)
                return "foggy";
            if (code >= 51 && code <= 67)
                return "rainy";
            if (code >= 71 && code <= 77)
                return "weather_snowy";
            if (code >= 80 && code <= 82)
                return "rainy";
            if (code >= 85 && code <= 86)
                return "weather_snowy";
            if (code >= 95 && code <= 99)
                return "thunderstorm";
            return "question_mark";
        }

        function getDayName(dateString) {
            var d = new Date(dateString);
            var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
            return days[d.getDay()];
        }

        // LEFT COLUMN: Current Weather
        ColumnLayout {
            Layout.preferredWidth: 210
            Layout.maximumWidth: 250
            Layout.fillHeight: true
            spacing: Globals.geometry.spacing.medium

            // CURRENT Label
            BaseText {
                text: "CURRENT"
                font.pixelSize: 10
                font.letterSpacing: 1.5
                weight: Globals.typography.weights.bold
                opacity: 0.7
                Layout.fillWidth: true
            }

            // Editorial Overlap Hero + Stats
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Perfectly centered foreground content
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Globals.geometry.spacing.large

                    // Icon and Condition String
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Globals.geometry.spacing.small

                        Item {
                            Layout.preferredWidth: 84
                            Layout.preferredHeight: 84
                            Layout.alignment: Qt.AlignHCenter

                            BaseIcon {
                                id: mainIcon
                                anchors.centerIn: parent
                                icon: weatherWidget.getIcon(weatherWidget.code, weatherWidget.isDay)
                                size: 84
                                color: Globals.colors.primary
                            }

                            RotationAnimation {
                                id: sunRotation
                                target: mainIcon
                                property: "rotation"
                                from: 0; to: 360
                                duration: 25000
                                loops: Animation.Infinite
                                running: mainIcon.icon === "clear_day"
                                onRunningChanged: { if (!running) mainIcon.rotation = 0; }
                            }
                            SequentialAnimation {
                                id: cloudFloat
                                running: mainIcon.icon !== "clear_day" && mainIcon.icon !== ""
                                loops: Animation.Infinite
                                NumberAnimation { target: mainIcon; property: "anchors.verticalCenterOffset"; from: 0; to: -3; duration: 2500; easing.type: Easing.OutCubic }
                                NumberAnimation { target: mainIcon; property: "anchors.verticalCenterOffset"; from: -3; to: 0; duration: 2500; easing.type: Easing.OutCubic }
                                onRunningChanged: { if (!running) mainIcon.anchors.verticalCenterOffset = 0; }
                            }
                        }

                        // Removed current temperature
                        BaseText {
                            text: {
                                var code = weatherWidget.code;
                                if (code === 0) return "CLEAR SKY";
                                if (code >= 1 && code <= 3) return "PARTLY CLOUDY";
                                if (code >= 45 && code <= 48) return "FOGGY";
                                if (code >= 51 && code <= 67) return "RAINY";
                                if (code >= 71 && code <= 77) return "SNOWING";
                                if (code >= 80 && code <= 82) return "SHOWERS";
                                if (code >= 85 && code <= 86) return "HEAVY SNOW";
                                if (code >= 95 && code <= 99) return "THUNDERSTORM";
                                return "UNKNOWN";
                            }
                            font.pixelSize: Globals.typography.size.small
                            font.letterSpacing: 2.0
                            weight: Globals.typography.weights.bold
                            color: Globals.colors.primary
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    // Stats row (Feels like, Humidity, Wind)
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Globals.geometry.spacing.large
                        
                        RowLayout {
                            spacing: Globals.geometry.spacing.small
                            BaseIcon { icon: "device_thermostat"; size: 18 }
                            BaseText { text: Weather.feelsLike; font.pixelSize: Globals.typography.size.medium; weight: Globals.typography.weights.bold }
                        }

                        BaseSeparator { orientation: BaseSeparator.Vertical; Layout.fillHeight: true; opacity: 0.1 }
                        
                        RowLayout {
                            spacing: Globals.geometry.spacing.small
                            BaseIcon { icon: "water_drop"; size: 18 }
                            BaseText { text: Weather.humidity; font.pixelSize: Globals.typography.size.medium; weight: Globals.typography.weights.bold }
                        }

                        BaseSeparator { orientation: BaseSeparator.Vertical; Layout.fillHeight: true; opacity: 0.1 }

                        RowLayout {
                            spacing: Globals.geometry.spacing.small
                            BaseIcon { icon: "air"; size: 18 }
                            BaseText { text: Weather.windSpeed; font.pixelSize: Globals.typography.size.medium; weight: Globals.typography.weights.bold }
                        }
                    }
                }
            }
        }

        BaseSeparator { orientation: BaseSeparator.Vertical; Layout.fillHeight: true; opacity: 0.1 }

        // MIDDLE COLUMN: 24-Hour Sparkline Curve
        Item {
            id: sparklineContainer
            Layout.fillWidth: true
            Layout.preferredWidth: 200
            Layout.minimumWidth: 100
            Layout.fillHeight: true
            clip: true

            property real drawProgress: 0.0
            SequentialAnimation on drawProgress {
                PauseAnimation { duration: 100 }
                NumberAnimation { from: 0.0; to: 1.0; duration: 1000; easing.type: Easing.OutCubic }
            }

            property int hoverIndex: {
                if (!graphHover.hovered || sparkline.calculatedPoints.length === 0) return -1;
                var x = graphHover.point.position.x;
                var stepX = sparkline.width / 23;
                var idx = Math.round(x / stepX);
                if (idx < 0) return 0;
                if (idx > 23) return 23;
                return idx;
            }

            HoverHandler {
                id: graphHover
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            }

            BaseText {
                text: "24 HOUR TREND"
                font.pixelSize: 10
                font.letterSpacing: 1.5
                weight: Globals.typography.weights.bold
                opacity: 0.7
                anchors.top: parent.top
                anchors.left: parent.left
            }

            Item {
                id: graphClip
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: sparklineContainer.width * sparklineContainer.drawProgress
                clip: true

                Canvas {
                    id: sparkline
                    width: sparklineContainer.width
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 24
                    anchors.bottomMargin: 0
                
                property var temps: {
                    if (!Weather.hourlyForecast || !Weather.currentWeather) return [];
                    var curTime = Weather.currentWeather.time;
                    var times = Weather.hourlyForecast.time;
                    var idx = times.indexOf(curTime);
                    if (idx === -1) idx = 24;
                    var start = Math.max(0, idx - 23);
                    return Weather.hourlyForecast.temperature_2m.slice(start, start + 24);
                }
                property var timesArr: {
                    if (!Weather.hourlyForecast || !Weather.currentWeather) return [];
                    var curTime = Weather.currentWeather.time;
                    var times = Weather.hourlyForecast.time;
                    var idx = times.indexOf(curTime);
                    if (idx === -1) idx = 24;
                    var start = Math.max(0, idx - 23);
                    return times.slice(start, start + 24);
                }
                property var calculatedPoints: []
                
                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: sparkline.requestPaint()
                }
                
                onTempsChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    if (!temps || temps.length < 24) return;
                    
                    var points = [];
                    var maxT = -999;
                    var minT = 999;
                    
                    for (var i = 0; i < 24; i++) {
                        var t = temps[i];
                        if (t > maxT) maxT = t;
                        if (t < minT) minT = t;
                    }
                    
                    var range = maxT - minT;
                    if (range === 0) range = 1;
                    
                    var stepX = width / 23;
                    
                    for (var i = 0; i < 24; i++) {
                        var x = i * stepX;
                        var normY = (temps[i] - minT) / range;
                        var y = 10 + (1 - normY) * (height - 12); 
                        points.push({x: x, y: y});
                    }
                    
                    sparkline.calculatedPoints = points;
                    
                    // Draw fill
                    ctx.beginPath();
                    ctx.moveTo(points[0].x, height);
                    ctx.lineTo(points[0].x, points[0].y);
                    
                    for (var i = 1; i < points.length - 2; i++) {
                        var xc = (points[i].x + points[i + 1].x) / 2;
                        var yc = (points[i].y + points[i + 1].y) / 2;
                        ctx.quadraticCurveTo(points[i].x, points[i].y, xc, yc);
                    }
                    ctx.quadraticCurveTo(points[i].x, points[i].y, points[i+1].x, points[i+1].y);
                    
                    ctx.lineTo(width, height);
                    ctx.closePath();
                    
                    var grad = ctx.createLinearGradient(0, 0, 0, height);
                    grad.addColorStop(0, Globals.alpha(Globals.colors.primary, 0.4));
                    grad.addColorStop(1, Globals.alpha(Globals.colors.transparent, 0.0));
                    ctx.fillStyle = grad;
                    ctx.fill();
                }
            }

            Canvas {
                id: sparklineLine
                anchors.fill: sparkline
                anchors.bottomMargin: 0
                
                SequentialAnimation on opacity {
                    running: sparklineContainer.hoverIndex !== -1
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.6; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                }
                
                Behavior on opacity {
                    enabled: sparklineContainer.hoverIndex === -1
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
                
                onPaint: {
                    var points = sparkline.calculatedPoints;
                    if (!points || points.length < 24) return;
                    
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    
                    ctx.beginPath();
                    ctx.moveTo(points[0].x, points[0].y);
                    for (var i = 1; i < points.length - 2; i++) {
                        var xc = (points[i].x + points[i + 1].x) / 2;
                        var yc = (points[i].y + points[i + 1].y) / 2;
                        ctx.quadraticCurveTo(points[i].x, points[i].y, xc, yc);
                    }
                    ctx.quadraticCurveTo(points[i].x, points[i].y, points[i+1].x, points[i+1].y);
                    
                    ctx.lineWidth = 3;
                    ctx.strokeStyle = Globals.colors.primary;
                    ctx.stroke();
                }
                
                Connections {
                    target: sparkline
                    function onCalculatedPointsChanged() {
                        sparklineLine.requestPaint();
                    }
                }
            }
            }

            Rectangle {
                id: hoverDot
                visible: sparklineContainer.hoverIndex !== -1 && sparkline.calculatedPoints[sparklineContainer.hoverIndex] !== undefined
                width: 8
                height: 8
                radius: 4
                color: Globals.colors.primary
                border.color: Globals.colors.surface
                border.width: 2
                x: visible ? sparkline.calculatedPoints[sparklineContainer.hoverIndex].x - 4 : 0
                y: visible ? sparkline.calculatedPoints[sparklineContainer.hoverIndex].y - 4 + 24 : 0
                
                Behavior on x { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                id: hoverTooltip
                visible: sparklineContainer.hoverIndex !== -1 && sparkline.calculatedPoints[sparklineContainer.hoverIndex] !== undefined
                color: Globals.colors.surface
                border.color: Globals.colors.border
                border.width: 1
                radius: Globals.geometry.innerRadius.small
                width: tooltipRow.implicitWidth + 16
                height: tooltipRow.implicitHeight + 8
                
                x: {
                    if (!visible) return 0;
                    var dotX = sparkline.calculatedPoints[sparklineContainer.hoverIndex].x;
                    var ttX = dotX - width / 2;
                    if (ttX < 0) return 0;
                    if (ttX + width > sparklineContainer.width) return sparklineContainer.width - width;
                    return ttX;
                }
                
                y: {
                    if (!visible) return 0;
                    var dotY = sparkline.calculatedPoints[sparklineContainer.hoverIndex].y + 24;
                    var ttY = dotY - height - 8;
                    if (ttY < 0) return dotY + 16;
                    return ttY;
                }
                
                Behavior on x { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                
                RowLayout {
                    id: tooltipRow
                    anchors.centerIn: parent
                    spacing: 8
                    
                    BaseText {
                        text: {
                            if (!hoverTooltip.visible || sparkline.timesArr.length === 0) return "";
                            var tStr = sparkline.timesArr[sparklineContainer.hoverIndex];
                            if (!tStr) return "";
                            var d = new Date(tStr);
                            var hrs = d.getHours();
                            var ampm = hrs >= 12 ? "PM" : "AM";
                            hrs = hrs % 12;
                            if (hrs === 0) hrs = 12;
                            return hrs + " " + ampm;
                        }
                        font.pixelSize: 10
                    }
                    
                    BaseText {
                        text: {
                            if (!hoverTooltip.visible || sparkline.temps.length === 0) return "";
                            return Math.round(sparkline.temps[sparklineContainer.hoverIndex]) + "°";
                        }
                        font.pixelSize: 11
                        weight: Globals.typography.weights.bold
                        color: Globals.colors.primary
                    }
                }
            }
        }

        BaseSeparator { orientation: BaseSeparator.Vertical; Layout.fillHeight: true; opacity: 0.1 }

            // RIGHT COLUMN: Multi-Day Forecast
            Item {
                id: rightColumnItem
                Layout.preferredWidth: 260
                Layout.fillHeight: true

                readonly property Item activeHover: {
                    for (var i = 0; i < forecastRepeater.count; i++) {
                        var item = forecastRepeater.itemAt(i);
                        if (item && item.hovered) return item;
                    }
                    return null;
                }

                Item {
                    anchors.fill: forecastColumn
                    BaseIndicator {
                        hoverPredicate: function() { return rightColumnItem.activeHover; }
                        anchors.left: parent.left
                        anchors.leftMargin: -12
                    }
                }

                BaseText {
                    id: upcomingLabel
                    text: "UPCOMING"
                    font.pixelSize: 10
                    font.letterSpacing: 1.5
                    weight: Globals.typography.weights.bold
                    opacity: 0.7
                    anchors.top: parent.top
                    anchors.left: parent.left
                }

                ColumnLayout {
                    id: forecastColumn
                    anchors.top: upcomingLabel.bottom
                    anchors.topMargin: Globals.geometry.spacing.medium
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    Repeater {
                        id: forecastRepeater
                        model: Weather.dailyForecast ? Math.min(5, Weather.dailyForecast.time.length - 2) : 0
                        
                        delegate: Item {
                            id: delegateItem
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            
                            property int dayIdx: index + 2
                            property bool hovered: rowHover.hovered
                            property alias contentRow: innerRow
                            
                            HoverHandler {
                                id: rowHover
                                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            }
                            
                            opacity: 0
                            Layout.leftMargin: 10
                            
                            SequentialAnimation on opacity {
                                PauseAnimation { duration: 100 + (index * 50) }
                                NumberAnimation { from: 0; to: 1; duration: Globals.animations.normal; easing.type: Easing.OutCubic }
                            }
                            SequentialAnimation on Layout.leftMargin {
                                PauseAnimation { duration: 100 + (index * 50) }
                                NumberAnimation { from: 10; to: 0; duration: Globals.animations.normal; easing.type: Easing.OutCubic }
                            }
                            
                            RowLayout {
                                id: innerRow
                                anchors.fill: parent
                                spacing: Globals.geometry.spacing.medium
                                
                                BaseText {
                                    text: weatherWidget.getDayName(Weather.dailyForecast.time[delegateItem.dayIdx]).toUpperCase()
                                    Layout.preferredWidth: 36
                                    font.pixelSize: Globals.typography.size.base
                                    font.letterSpacing: 1.0
                                    weight: Globals.typography.weights.bold
                                    color: index === 0 ? Globals.colors.primary : Globals.colors.text
                                }
                                
                                BaseIcon {
                                    icon: weatherWidget.getIcon(Weather.dailyForecast.weather_code[delegateItem.dayIdx], true)
                                    size: 18
                                    color: index === 0 ? Globals.colors.primary : Globals.colors.text
                                }
                                
                                Item { Layout.fillWidth: true } // Spacer

                                RowLayout {
                                    Layout.preferredWidth: 54
                                    spacing: Globals.geometry.spacing.small
                                    BaseIcon { icon: "device_thermostat"; size: 18 }
                                    BaseText { 
                                        text: Math.round(Weather.dailyForecast.apparent_temperature_max[delegateItem.dayIdx]) + "°"
                                        font.pixelSize: Globals.typography.size.base
                                        font.letterSpacing: 1.0
                                        weight: Globals.typography.weights.bold 
                                        Layout.fillWidth: true
                                    }
                                }

                                RowLayout {
                                    Layout.preferredWidth: 64
                                    spacing: Globals.geometry.spacing.small
                                    BaseIcon { icon: "water_drop"; size: 18 }
                                    BaseText { 
                                        text: Weather.dailyForecast.precipitation_probability_max[delegateItem.dayIdx] + "%"
                                        font.pixelSize: Globals.typography.size.base
                                        font.letterSpacing: 1.0
                                        weight: Globals.typography.weights.bold 
                                        Layout.fillWidth: true
                                    }
                                }

                                RowLayout {
                                    Layout.preferredWidth: 46
                                    spacing: Globals.geometry.spacing.small
                                    BaseIcon { icon: "air"; size: 18 }
                                    BaseText { 
                                        text: Math.round(Weather.dailyForecast.wind_speed_10m_max[delegateItem.dayIdx])
                                        font.pixelSize: Globals.typography.size.base
                                        font.letterSpacing: 1.0
                                        weight: Globals.typography.weights.bold 
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
