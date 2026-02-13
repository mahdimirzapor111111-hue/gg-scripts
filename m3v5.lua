-- محدوده حافظه (قابل تنظیم)
local searchRangeStart = 0x10000000
local searchRangeEnd = 0x20000000

-- وضعیت فعال/غیرفعال بودن ایم بات ها، وال هک و اوساس فست
local aimBotEnabled1 = false
local wallHackEnabled = false
local aimBotEnabled2 = false
local aimBotEnabled4 = false -- وضعیت ایم بات ۴
local osasFastEnabled = false -- وضعیت اوساس فست

-- تابع برای جستجو و تغییر مقدار (اصلاح شده برای ایم بات ۴ - تغییر هر دو مقدار)
local function searchAndModifyAimBot4(searchValueRange, searchValueFixed, searchTypeRange, searchTypeFixed, offset, newValue, alertTextSuccess, alertTextFail)
    gg.searchNumber(searchValueRange, searchTypeRange)
    local resultsRange = gg.getResults(-1)
    gg.clearResults()

    gg.searchNumber(searchValueFixed, searchTypeFixed)
    local resultsFixed = gg.getResults(-1)
    gg.clearResults()

    local modifiedResults = {}
    if resultsRange and resultsFixed then
        print("تعداد آدرس های حاوی " .. searchValueRange .. " پیدا شده: " .. #resultsRange)
        print("تعداد آدرس های حاوی " .. searchValueFixed .. " پیدا شده: " .. #resultsFixed)

        local addressesFixed = {}
        for _, resFixed in ipairs(resultsFixed) do
            addressesFixed[resFixed.address] = resFixed.address
        end

        for _, resRange in ipairs(resultsRange) do
            local addrRange = resRange.address
            -- بررسی آدرس با آفست مثبت
            if addressesFixed[addrRange + offset] then
                table.insert(modifiedResults, {address = addrRange, flags = gg.TYPE_FLOAT, value = newValue})
                table.insert(modifiedResults, {address = addrRange + offset, flags = gg.TYPE_FLOAT, value = newValue})
            -- بررسی آدرس با آفست منفی
            elseif addressesFixed[addrRange - offset] then
                table.insert(modifiedResults, {address = addrRange, flags = gg.TYPE_FLOAT, value = newValue})
                table.insert(modifiedResults, {address = addrRange - offset, flags = gg.TYPE_FLOAT, value = newValue})
            end
        end

        if #modifiedResults > 0 then
            gg.alert(alertTextSuccess)
            gg.setValues(modifiedResults)
            gg.alert("مقدار آدرس های احتمالی به " .. newValue .. " تغییر یافت.")
        else
            gg.alert(alertTextFail)
        end
    else
        gg.alert("خطا در جستجو برای " .. searchValueRange .. " یا " .. searchValueFixed .. " در حافظه.")
    end
end

---
-- تابع عمومی برای جستجو و تغییر فقط یک مقدار (Single Value Modification)

-- این تابع `searchAndModifySingleValue` جایگزین `searchAndModify` می‌شود.
-- تفاوت اصلی آن این است که **فقط آدرس `searchValue1` را تغییر می‌دهد**
-- و `searchValue2` صرفاً برای پیدا کردن جفت مرتبط استفاده می‌شود.
local function searchAndModifySingleValue(searchValue1, searchValue2, searchType1, searchType2, offset, newValue, alertTextSuccess, alertTextFail)
    gg.searchNumber(searchValue1, searchType1)
    local results1 = gg.getResults(-1)
    gg.clearResults()

    gg.searchNumber(searchValue2, searchType2)
    local results2 = gg.getResults(-1)
    gg.clearResults()

    local modifiedResults = {}
    if results1 and results2 then
        print("تعداد آدرس های حاوی " .. searchValue1 .. " پیدا شده: " .. #results1)
        print("تعداد آدرس های حاوی " .. searchValue2 .. " پیدا شده: " .. #results2)

        local addresses2_table = {}
        for _, res2 in ipairs(results2) do
            addresses2_table[res2.address] = true
        end

        for _, res1 in ipairs(results1) do
            local addr1 = res1.address
            -- بررسی وجود مقدار دوم با آفست مثبت یا منفی
            if addresses2_table[addr1 - offset] or addresses2_table[addr1 + offset] then
                -- فقط آدرس addr1 (که مربوط به searchValue1 است) را برای تغییر اضافه می‌کنیم.
                -- آدرس مربوط به searchValue2 (addr1 - offset یا addr1 + offset) تغییر نخواهد کرد.
                table.insert(modifiedResults, {address = addr1, flags = gg.TYPE_FLOAT, value = newValue})
            end
        end

        if #modifiedResults > 0 then
            -- جلوگیری از افزودن آدرس های تکراری در modifiedResults
            local seenAddresses = {}
            local uniqueModifiedResults = {}
            for _, res in ipairs(modifiedResults) do
                if not seenAddresses[res.address] then
                    table.insert(uniqueModifiedResults, res)
                    seenAddresses[res.address] = true
                end
            end

            gg.alert(alertTextSuccess)
            gg.setValues(uniqueModifiedResults)
            gg.alert("مقدار آدرس های احتمالی به " .. newValue .. " تغییر یافت.")
        else
            gg.alert(alertTextFail)
        end
    else
        gg.alert("خطا در جستجو برای " .. searchValue1 .. " یا " .. searchValue2 .. " در حافظه.")
    end
end

---
-- توابع Toggle با استفاده از `searchAndModifySingleValue`

-- حالا توابع `toggleAimBot1Func`، `toggleWallHack`، و `toggleAimBot2` از تابع جدید `searchAndModifySingleValue` استفاده می‌کنند.

local function toggleAimBot1Func()
    aimBotEnabled1 = not aimBotEnabled1
    gg.toast("این بات ۱ " .. (aimBotEnabled1 and "فعال شد" or "غیرفعال شد"))
    if aimBotEnabled1 then
        searchAndModifySingleValue(12.0, "0.24~0.25", gg.TYPE_FLOAT, gg.TYPE_FLOAT, 4, 100000.0,
                       "آدرس های احتمالی این بات ۱ پیدا شده بر اساس جستجو برای 12.0 و مقادیر نزدیک به 0.25!",
                       "هیچ آدرس احتمالی این بات ۱ بر اساس جستجو برای 12.0 و مقادیر نزدیک به 0.25 با فاصله 4 بایت پیدا نشد.")
    end
    -- در صورت نیاز، کد برای بازگرداندن مقادیر قبلی در صورت غیرفعال شدن اینجا قرار می گیرد
end

-- تابع فعال/غیرفعال کردن وال هک
local function toggleWallHack()
    wallHackEnabled = not wallHackEnabled
    gg.toast("وال هک " .. (wallHackEnabled and "فعال شد" or "غیرفعال شد"))
    if wallHackEnabled then
        searchAndModifySingleValue(4.0, 2.0, gg.TYPE_FLOAT, gg.TYPE_FLOAT, 4, 100000.0,
                       "آدرس های احتمالی وال هک پیدا شده بر اساس جستجو برای 4.0 و 2.0!",
                       "هیچ آدرس احتمالی وال هک بر اساس جستجو برای 4.0 و 2.0 با فاصله 4 بایت پیدا نشد.")
    end
    -- در صورت نیاز، کد برای بازگرداندن مقادیر قبلی در صورت غیرفعال شدن اینجا قرار می گیرد
end

-- تابع فعال/غیرفعال کردن ایم بات دو (11.1~11.99 و 9.90~11.50)
local function toggleAimBot2()
    aimBotEnabled2 = not aimBotEnabled2
    gg.toast("ایم بات دو (11.1~11.99 و 9.90~11.50) " .. (aimBotEnabled2 and "فعال شد" or "غیرفعال شد"))
    if aimBotEnabled2 then
        searchAndModifySingleValue("11.1~11.99", "9.90~11.50", gg.TYPE_FLOAT, gg.TYPE_FLOAT, 28, 100000.0,
                       "آدرس های احتمالی ایم بات دو پیدا شده بر اساس جستجو برای 11.1~11.99 و 9.90~11.50 با فاصله 28 بایت!",
                       "هیچ آدرس احتمالی ایم بات دو بر اساس جستجو برای 11.1~11.99 و 9.90~11.50 با فاصله 28 بایت پیدا نشد.")
    end
    -- در صورت نیاز، کد برای بازگرداندن مقادیر قبلی در صورت غیرفعال شدن اینجا قرار می گیرد
end

-- تابع فعال/غیرفعال کردن ایم بات ۴ (0.0075~0.0085 و 22.0 با فاصله 4 بایت - تغییر هر دو مقدار)
-- این تابع نیازی به تغییر ندارد زیرا هدف آن تغییر هر دو مقدار است.
local function toggleAimBot4()
    aimBotEnabled4 = not aimBotEnabled4
    gg.toast("ایم بات ۴ (0.0075~0.0085 و 22.0) " .. (aimBotEnabled4 and "فعال شد" or "غیرفعال شد"))
    if aimBotEnabled4 then
        searchAndModifyAimBot4("0.0075~0.0085", 22.0, gg.TYPE_FLOAT, gg.TYPE_FLOAT, 4, 100000.0,
                               "آدرس های احتمالی ایم بات ۴ پیدا شده بر اساس جستجو برای 0.0075~0.0085 و 22.0 با فاصله 4 بایت!",
                               "هیچ آدرس احتمالی ایم بات ۴ بر اساس جستجو برای 0.0075~0.0085 و 22.0 با فاصله 4 بایت پیدا نشد.")
    end
    -- در صورت نیاز، کد برای بازگرداندن مقادیر قبلی در صورت غیرفعال شدن اینجا قرار می گیرد
end

-- تابع فعال/غیرفعال کردن اوساس فست (جستجو 0.33000001311 و تغییر به 0)
local function toggleOsasFast()
    osasFastEnabled = not osasFastEnabled
    gg.toast("اوساس فست " .. (osasFastEnabled and "فعال شد" or "غیرفعال شد"))
    if osasFastEnabled then
        gg.searchNumber(0.33000001311, gg.TYPE_FLOAT)
        local results = gg.getResults(-1)
        gg.clearResults()
        if #results > 0 then
            local modifiedResults = {}
            for _, res in ipairs(results) do
                table.insert(modifiedResults, {address = res.address, flags = gg.TYPE_FLOAT, value = 0.0})
            end
            gg.setValues(modifiedResults)
            gg.alert("مقدار " .. 0.33000001311 .. " به 0 تغییر یافت.")
        else
            gg.alert("هیچ آدرسی با مقدار " .. 0.33000001311 .. " پیدا نشد.")
        end
    else
        -- در صورت نیاز، کد برای بازگرداندن مقادیر قبلی در صورت غیرفعال شدن اینجا قرار می گیرد
    end
end

-- ایجاد منو
local function main()
    local choices = {
        "فعال/غیرفعال کردن این بات ۱: " .. (aimBotEnabled1 and "فعال" or "غیرفعال"),
        "فعال/غیرفعال کردن وال هک: " .. (wallHackEnabled and "فعال" or "غیرفعال"),
        "فعال/غیرفعال کردن ایم بات دو (11.1~11.99 و 9.90~11.50): " .. (aimBotEnabled2 and "فعال" or "غیرفعال"),
        "فعال/غیرفعال کردن ایم بات ۴ (0.0075~0.0085 و 22.0): " .. (aimBotEnabled4 and "فعال" or "غیرفعال"),
        "فعال/غیرفعال کردن اوساس فست (0.33000001311 -> 0): " .. (osasFastEnabled and "فعال" or "غیرفعال"),
        "خروج"
    }
    local choice = gg.choice(choices, nil, "منوی اسکریپت")

    if choice == 1 then
        toggleAimBot1Func()
    elseif choice == 2 then
        toggleWallHack()
    elseif choice == 3 then
        toggleAimBot2()
    elseif choice == 4 then
        toggleAimBot4() -- فراخوانی تابع ایم بات ۴
    elseif choice == 5 then
        toggleOsasFast() -- فراخوانی تابع اوساس فست
    elseif choice == 6 then
        return
    end
    main() -- نمایش مجدد منو
end

main()
