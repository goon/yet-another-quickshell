import QtQuick
import Quickshell
import qs
pragma Singleton

QtObject {
    id: root

    property string latitude: Preferences.weather.lat
    property string longitude: Preferences.weather.long
    property var currentWeather: null
    property var dailyForecast: null
    property var hourlyForecast: null
    property bool loading: false
    property string error: ""
    // derived properties for easy access
    property string temperature: currentWeather ? Math.round(currentWeather.temperature_2m ?? currentWeather.temperature) + "°" : "--"
    property string feelsLike: currentWeather ? Math.round(currentWeather.apparent_temperature) + "°" : "--"
    property string windSpeed: currentWeather ? Math.round(currentWeather.wind_speed_10m) + " mph" : "--"
    property string humidity: currentWeather ? Math.round(currentWeather.relative_humidity_2m) + "%" : "--"
    property int weatherCode: currentWeather ? (currentWeather.weather_code ?? currentWeather.weathercode) : -1
    property bool isDay: currentWeather ? currentWeather.is_day === 1 : true
    // Auto-refresh every 30 minutes
    property Timer autoRefreshTimer
    property Timer fetchDebounce

    function setClosestLocation(query) {
        if (!query) return;
        var xhr = new XMLHttpRequest();
        var url = "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(query) + "&count=1&language=en&format=json";
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var json = JSON.parse(xhr.responseText);
                    var results = json.results || [];
                    if (results.length > 0) {
                        var item = results[0];
                        item.full_name = item.name + (item.admin1 ? (", " + item.admin1) : "") + (item.country ? (", " + item.country) : "");
                        Preferences.weather.lat = item.latitude.toString();
                        Preferences.weather.long = item.longitude.toString();
                        Preferences.weather.locationName = item.full_name;
                    }
                } catch (e) {
                }
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function fetchWeather() {
        if (!latitude || !longitude)
            return ;

        loading = true;
        error = "";
        // Fetch Weather
        var xhr = new XMLHttpRequest();
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + latitude + "&longitude=" + longitude + 
                 "&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m" + 
                 "&hourly=temperature_2m,weather_code" +
                 "&daily=weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,precipitation_probability_max,wind_speed_10m_max&timezone=auto" + 
                 "&past_days=1" +
                 "&temperature_unit=celsius&wind_speed_unit=mph";
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                loading = false;
                if (xhr.status === 200) {
                    try {
                        var json = JSON.parse(xhr.responseText);
                        root.currentWeather = json.current || json.current_weather;
                        root.dailyForecast = json.daily;
                        root.hourlyForecast = json.hourly;
                    } catch (e) {
                        root.error = "Parse Error";
                    }
                }
            }
        };
        xhr.open("GET", url);
        xhr.send();
        // Fetch Location Name (Reverse Geocoding)
        var geoXhr = new XMLHttpRequest();
        // Using Nominatim (OpenStreetMap) Geocoding API
        var geoUrl = "https://nominatim.openstreetmap.org/reverse?lat=" + latitude + "&lon=" + longitude + "&format=json";
        geoXhr.onreadystatechange = function() {
            if (geoXhr.readyState === XMLHttpRequest.DONE) {
                if (geoXhr.status === 200) {
                    try {
                        var json = JSON.parse(geoXhr.responseText);
                        if (json.address) {
                            var addr = json.address;
                            // Prefer city, then town, then village, then suburb
                            var name = addr.city || addr.town || addr.village || addr.suburb || addr.municipality || "Unknown Location";
                            if (name && name !== "Unknown Location")
                                Preferences.weather.locationName = name;

                        }
                    } catch (e) {
                    }
                }
            }
        };
        geoXhr.open("GET", geoUrl);
        // Nominatim requires a SystemInfo-Agent
        geoXhr.setRequestHeader("SystemInfo-Agent", "AntigravQs/1.0");
        geoXhr.send();
    }

    // Only re-fetch on coord changes if preferences are already loaded
    // (avoids a spurious fetch with hardcoded defaults on first load)
    onLatitudeChanged: { if (Preferences.loaded) fetchDebounce.restart(); }
    onLongitudeChanged: { if (Preferences.loaded) fetchDebounce.restart(); }

    // Wait for Preferences to finish loading before doing the initial fetch.
    // This ensures we use the user's saved coordinates, not the hardcoded defaults.
    property Connections prefConnections: Connections {
        target: Preferences
        function onLoadedChanged() {
            if (Preferences.loaded) root.fetchWeather();
        }
    }

    Component.onCompleted: {
        // Only fetch immediately if Preferences is already loaded (e.g. fast load / empty file)
        if (Preferences.loaded) fetchWeather();
    }

    autoRefreshTimer: Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.fetchWeather()
    }

    fetchDebounce: Timer {
        id: fetchDebounce

        interval: 1000
        repeat: false
        onTriggered: root.fetchWeather()
    }

}
