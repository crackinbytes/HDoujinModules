-- MangaStream is a WordPress theme.
-- https://themesia.com/mangastream-wordpress-theme/

function Register()

    module.Name = 'MangaStream'
    module.Language = 'English'

    module.Domains.Add('asura.gg', 'Asura Scans')
    module.Domains.Add('asura.nacm.xyz', 'Asura Scans')
    module.Domains.Add('asurascans.com', 'Asura Scans')
    module.Domains.Add('asuracomics.com', 'Asura Scans')
    module.Domains.Add('www.asurascans.com', 'Asura Scans')

    if(API_VERSION >= 20230823) then      
        module.DeferHttpRequests = true
    end

end

function GetInfo()

    RedirectToNewMangaUrl()

    info.Url = url
    info.Title = dom.SelectValue('//h1[contains(@class,"entry-title")]')
    info.Description = dom.SelectValue('//div[contains(@itemprop,"description")]')
    info.DateReleased = CleanMetadataFieldValue(dom.SelectValue('//b[contains(text(),"Released")]/following-sibling::span'))
    info.Author = CleanMetadataFieldValue(dom.SelectValue('//b[contains(text(),"Author")]/following-sibling::span'))
    info.Tags = dom.SelectValues('//b[contains(text(),"Genres")]/following-sibling::span//a')
    info.Status = dom.SelectValue('//div[contains(text(),"Status")]/i')
    info.Type = dom.SelectValue('//div[contains(text(),"Type")]/a')

    if(module.GetName(url):endsWith('Scans')) then
        info.Scanlator = module.GetName(url)
    end

end

function GetChapters()

    RedirectToNewMangaUrl()

    for chapterNode in dom.SelectElements('//div[@id="chapterlist"]//a') do

        local chapterUrl = chapterNode.SelectValue('@href')
        local chapterTitle = chapterNode.SelectValue('span')

        chapters.Add(chapterUrl, chapterTitle)

    end

    chapters.Reverse()

end

function GetPages()

    pages.AddRange(dom.SelectValues('//div[@id="readerarea"]//img/@data-src'))

    -- asurascans.com
    -- Make sure to ignore any ad GIFs, and skip the broken image at the beginning of each chapter.

    if(isempty(pages)) then
        pages.AddRange(dom.SelectValues('//div[@id="readerarea"]//img[@class and not(ancestor::div[contains(@class,"asurascans.rights")])]/@src'))
    end

end

function CleanMetadataFieldValue(value)

    -- Empty metadata fields have the value " - ", which should be blanked out.

    if(tostring(value):trim() == '-') then
        return ""
    end

    return value

end

function RedirectToNewMangaUrl()

    -- For some manga, the path looks like like this: 
    -- /manga/title/
    -- But some other manga can only be accessed with a numeric prefix: 
    -- /manga/1901917615-title/
    -- That numeric prefix changes occassionally, breaking existing URLs in bookmarks or the download queue.
    -- If we hit a 404 page for a manga URL, attempt to find the current numeric ID and update the URL.
    -- See https://github.com/HDoujinDownloader/HDoujinDownloader/issues/238

    if(url:contains('/manga/')) then
   
        if(isempty(module.Data['NumericPrefix'])) then
            
            -- If we haven't gotten the prefix yet, extract it from a URL on the home page and save it.

            local homePageDom = Dom.New(http.Get(GetRoot(url)))
            local numericPrefix = homePageDom.SelectValue('//div[contains(@class,"listupd")]//a[contains(@href,"/manga/")]/@href')
                :regex('\\/manga\\/(\\d+)', 1)
    
            module.Data['NumericPrefix'] = numericPrefix

        end

        if(not isempty(module.Data['NumericPrefix'])) then
            
            -- Apply the prefix to the URL.

            url = RegexReplace(url, '\\/manga\\/\\d*-?', '/manga/' .. module.Data['NumericPrefix'] .. '-')
            dom = Dom.New(http.Get(url))
            
        end

    end

end
