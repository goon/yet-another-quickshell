.pragma library

/**
 * Pure gowall conversion. No QML state, no signals, no side effects.
 *
 * The argv builder keeps all user-controlled values (paths, theme ids) out of the
 * shell parser — they flow as positional arguments after `--` and are referenced
 * via `$1`/`$2`/`$3` inside a single-quoted shell template.
 */

function buildConvertCommand(inputPath, themeId, targetPath) {
    return [
        "sh", "-c",
        'gowall convert "$1" - --theme "$2" > "$3"',
        "--",
        inputPath, themeId, targetPath
    ];
}

function buildConfigWriteCommand(yaml, configPath) {
    return ["sh", "-c", 'printf \'%s\' "$1" > "$2"', "--", yaml, configPath];
}

function buildCleanupCommand(cacheDir, baseName, keepName) {
    return [
        "sh", "-c",
        'find "$1" -type f -name \'"$2"_*\' -not -name \'"$3"\' -not -name \'*_temp.*\' -delete',
        "--",
        cacheDir, baseName, keepName
    ];
}