Locales = Locales or {}

function L(key, ...)
    local lang = Locales[Config.Locale] or Locales.en or {}
    local text = lang[key] or (Locales.en and Locales.en[key]) or key

    if select('#', ...) > 0 then
        return text:format(...)
    end

    return text
end