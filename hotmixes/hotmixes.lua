function write_hotmixes()
    local lfs = require 'lfs_ffi'
    local template = require "resty.template"

    local files, dirs, images = {}, {}, {}
    local request_uri = ngx.var.request_uri
    request_uri = ngx.unescape_uri(request_uri)

    if request_uri ~= '/' then
        request_uri = request_uri .. '/'
    end

    local data_dir = '/mnt/mixes'
    local path = data_dir .. request_uri

    -- we want to know if something is an image
    function match_image( file )
        local filext = file:match("[^.]+$")
        local extensions = {jpg=true, jpeg=true, png=true, gif=true}

        if extensions[filext:lower()] then
            return true
        else
            return false
        end
    end

    -- lfs.dir() doesn't work, so we use this function to list contents of a path
    function scandir(directory)
        local i, t, popen = 0, {}, io.popen
        local pfile = popen('ls "'..directory..'" -I "*.filepart"')
        for filename in pfile:lines() do
            i = i + 1
            t[i] = filename
        end
        pfile:close()
        return t
    end

    for i, file in ipairs( scandir( path ) ) do
        if lfs.attributes( path .. file,"mode" ) == "file" then
            if match_image( file ) then
                table.insert( images, file )
            else
                table.insert( files, file )
            end
        elseif lfs.attributes( path .. file,"mode" ) == "directory" then
            table.insert( dirs, file )
        end
    end

    -- list last 10 modified files in our directory
    function latest_files(directory)
        local i, t, popen = 0, {}, io.popen
        local pfile = popen('find "'..directory..'" -type f ! -name \'*.filepart\' -printf \'%C@ %p\n\'| sort -n -r | head -10 | cut -f2- -d" "| sed s:"'..directory..'/"::')
        for filename in pfile:lines() do
            i = i + 1
            t[i] = filename
        end
        pfile:close()
        return t
    end

    local latest_path, latest_name = {}, {}

    for i, file_path in ipairs( latest_files( data_dir ) ) do
        table.insert( latest_path, file_path )

        local temp = ""
        local result = ""
        for i = file_path:len(), 1, -1 do
            if file_path:sub(i,i) ~= "/" then
                temp = temp..file_path:sub(i,i)
            else
                break
            end
        end

        for j = temp:len(), 1, -1 do
            result = result..temp:sub(j,j)
        end

        table.insert( latest_name, result )
    end

    local path_uri = '/mixes' .. request_uri

    function total_files_dir( path )
        local i, t, popen = 0, {}, io.popen
        local pfile = popen('find "'..path..'" -type f | wc -l')
        for total in pfile:lines() do
            t[i] = total
            i = i + 1
        end
        pfile:close()
        return t
    end

    if request_uri == '/' then
        template.render("viewroot.html", {
            local_total = total_files_dir( data_dir ),
            local_uri = request_uri,
            local_path = path_uri,
            local_dirs = dirs,
            local_images = images,
            local_latestpath = latest_path,
            local_latestname = latest_name
        })
    else
        template.render("view.html", {
            local_total = total_files_dir( data_dir ),
            local_uri = request_uri,
            local_path = path_uri,
            local_files = files,
            local_dirs = dirs,
            local_images = images,
            local_latestpath = latest_path,
            local_latestname = latest_name
        })
    end
end

return write_hotmixes
