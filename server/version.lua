if not Config.VersionCheck or not Config.VersionCheck.enabled then
    return
end

local RESOURCE_NAME = 'cb-backpacks'
local CURRENT_VERSION = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '0.0.0'

local VERSION_URL = Config.VersionCheck.url

local CHECK_DELAY = Config.VersionCheck.delay or 5000

local COLORS = {
    reset = '^7',
    primary = '^3',
    text = '^7',
    muted = '^8',
    success = '^2',
    warning = '^3',
    error = '^1'
}

local function printLine(char, length)
    print(('%s%s%s'):format(
        COLORS.muted,
        string.rep(char or '─', length or 64),
        COLORS.reset
    ))
end

local function printHeader()
    print('')

    printLine('═', 64)

    print(('%s  CB STUDIOS%s'):format(
        COLORS.primary,
        COLORS.reset
    ))

    print(('%s  BACKPACKS • VERSION CHECKER%s'):format(
        COLORS.muted,
        COLORS.reset
    ))

    printLine('═', 64)
end

local function printInfo(label, value)
    print(('%s  %-12s %s%s'):format(
        COLORS.muted,
        label,
        COLORS.text,
        tostring(value)
    ))
end

local function printStatus(status, message)
    local icon = '•'
    local color = COLORS.text

    if status == 'OK' then
        icon = '✓'
        color = COLORS.success
    elseif status == 'WARN' then
        icon = '!'
        color = COLORS.warning
    elseif status == 'ERROR' then
        icon = '✕'
        color = COLORS.error
    elseif status == 'UPDATE' then
        icon = '↑'
        color = COLORS.primary
    end

    print(('%s  %s%s%s %s'):format(
        COLORS.muted,
        color,
        icon,
        COLORS.reset,
        message
    ))
end

local function parseVersion(version)
    if type(version) ~= 'string' then
        return nil
    end

    local major, minor, patch = version:match('^(%d+)%.(%d+)%.(%d+)$')

    if not major or not minor or not patch then
        return nil
    end

    return {
        major = tonumber(major),
        minor = tonumber(minor),
        patch = tonumber(patch)
    }
end

local function compareVersions(current, latest)
    local currentVersion = parseVersion(current)
    local latestVersion = parseVersion(latest)

    if not currentVersion or not latestVersion then
        return nil
    end

    if latestVersion.major > currentVersion.major then
        return 1
    elseif latestVersion.major < currentVersion.major then
        return -1
    end

    if latestVersion.minor > currentVersion.minor then
        return 1
    elseif latestVersion.minor < currentVersion.minor then
        return -1
    end

    if latestVersion.patch > currentVersion.patch then
        return 1
    elseif latestVersion.patch < currentVersion.patch then
        return -1
    end

    return 0
end

local function getUpdateType(current, latest)
    local currentVersion = parseVersion(current)
    local latestVersion = parseVersion(latest)

    if not currentVersion or not latestVersion then
        return 'UPDATE'
    end

    if latestVersion.major ~= currentVersion.major then
        return 'MAJOR'
    elseif latestVersion.minor ~= currentVersion.minor then
        return 'MINOR'
    elseif latestVersion.patch ~= currentVersion.patch then
        return 'PATCH'
    end

    return 'UPDATE'
end
local function printUpdateInfo(latestVersion, updateType, data)
    print('')
    printLine('─', 64)

    print(('%s  UPDATE AVAILABLE%s'):format(
        COLORS.primary,
        COLORS.reset
    ))

    printLine('─', 64)

    printInfo('Resource', RESOURCE_NAME)
    printInfo('Installed', CURRENT_VERSION)
    printInfo('Latest', latestVersion)
    printInfo('Release', updateType)

    if type(data.changelog) == 'string' and data.changelog ~= '' then
        printInfo('Changelog', data.changelog)
    end

    if type(data.store) == 'string' and data.store ~= '' then
        printInfo('Store', data.store)
    end

    printLine('─', 64)

    print('')
end

local function checkVersion()
    PerformHttpRequest(
        VERSION_URL,
        function(statusCode, response)
            if statusCode ~= 200 or not response or response == '' then
                printStatus(
                    'WARN',
                    ('Unable to check for updates (HTTP %s).'):format(
                        tostring(statusCode)
                    )
                )

                return
            end

            local success, data = pcall(json.decode, response)

            if not success or type(data) ~= 'table' then
                printStatus(
                    'WARN',
                    'Received invalid version metadata.'
                )

                return
            end

            if data.resource ~= RESOURCE_NAME then
                printStatus(
                    'WARN',
                    'Remote version metadata does not match this resource.'
                )

                return
            end

            local latestVersion = data.version

            if type(latestVersion) ~= 'string' or not parseVersion(latestVersion) then
                printStatus(
                    'WARN',
                    'Remote version information is missing or invalid.'
                )

                return
            end

            local comparison = compareVersions(
                CURRENT_VERSION,
                latestVersion
            )

            if comparison == nil then
                printStatus(
                    'WARN',
                    'Unable to compare installed and remote versions.'
                )

                return
            end

            if comparison == 0 then
                printStatus(
                    'OK',
                    ('Version %s is up to date.'):format(
                        CURRENT_VERSION
                    )
                )

                return
            end

            if comparison > 0 then
                local updateType = getUpdateType(
                    CURRENT_VERSION,
                    latestVersion
                )

                printUpdateInfo(
                    latestVersion,
                    updateType,
                    data
                )

                return
            end

            printStatus(
                'WARN',
                ('Installed version %s is newer than the published version %s.'):format(
                    CURRENT_VERSION,
                    latestVersion
                )
            )
        end,
        'GET',
        '',
        {
            ['Content-Type'] = 'application/json',
            ['User-Agent'] = 'CB-Studios-Version-Checker'
        }
    )
end

CreateThread(function()
    Wait(CHECK_DELAY)

    printHeader()

    printInfo('Resource', RESOURCE_NAME)
    printInfo('Version', CURRENT_VERSION)

    printLine('─', 64)

    printStatus(
        'OK',
        'Checking for updates...'
    )

    Wait(1000)

    checkVersion()
end)