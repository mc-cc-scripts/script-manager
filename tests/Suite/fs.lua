local fs = {}
fs.libPath = "tmpLibs/"
fs.progPath = "tmpProg/"

do
    fs.open = function(path, mode)
        assert("string" == type(path), tostring(path) .. "path must be a string")
        assert("string" == type(mode), tostring(mode) .." mode must be a string")
        local file = io.open(path, mode)
        if not file then
            -- find all occurences of / in the path
            local dirs = {}
            for i = 1, #path do
                if path:sub(i, i) == "/" then
                    table.insert(dirs, i)
                end
            end
            -- create all directories
            local dir = ""
            for i = 1, #dirs do
                dir = path:sub(1, dirs[i])
                if not fs.exists(dir) then
                    os.execute("mkdir " .. dir)
                end
            end
            file = io.open(path, mode)
        end
        if mode == "w" then
            assert(file, "file could not be opened in : "..path.. " Mode : "..mode)
        end
        return file
    end

    fs.exists = function(path)
        assert("string" == type(path), "path must be a string")
        local file = io.open(path, "r")
        if not file then
            return false
        end
        file:close()
        return true
    end

    fs.copy = function(src, dest)
        assert("string" == type(src), "src must be a string")
        assert("string" == type(dest), "dest must be a string")
        local file = io.open(src, "r")
        if not file then
            print("file "..src.." not found")
            return false
        end
        local content = file:read("*a")
        file:close()
        file = io.open(dest, "w")
        if not file then
            if not file then
                -- find all occurences of / in the path
                local dirs = {}
                for i = 1, #dest do
                    if dest:sub(i, i) == "/" then
                        table.insert(dirs, i)
                    end
                end
                -- create all directories
                local dir = ""
                for i = 1, #dirs do
                    dir = dest:sub(1, dirs[i])
                    if not fs.exists(dir) then
                        os.execute("mkdir " .. dir)
                    end
                end
                file = io.open(dest, "w")
                if not file then
                    print("file"..dest.." not found")
                    return false
                end
            end
        end
        file:write(content)
        file:close()
        return true
    end
end

return fs
