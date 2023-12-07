local fs = {}

fs.libPath = "tmpLibs/"
fs.progPath = "tmpProg/"

do
    fs.open = function(path, mode)
        assert("string" == type(path), tostring(path) .. "path must be a string")
        assert("string" == type(mode), tostring(mode) .. " mode must be a string")
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
            assert(file, "file could not be opened in : " .. path .. " Mode : " .. mode)
        end
        if not file then
            return nil
        end
        local file2 = {}
        setmetatable(file2, { __index = file })
        file2.base = file
        file2.readAll = function()
            return file2.base:read("*a")
        end
        file2["readLine"] = function()
            return file2.base:read("*l")
        end
        file2["write"] = function(content)
            return file2.base:write(content)
        end
        file2["read"] = function(...)
            return file2.base:read(...)
        end
        file2["close"] = function()
            file2.base:close()
        end
        return file2
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
            print("file " .. src .. " not found")
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
                    print("file" .. dest .. " not found")
                    return false
                end
            end
        end
        file:write(content)
        file:close()
        return true
    end

    fs.makeDir = function(path)
        assert("string" == type(path), "path must be a string")
        path = path .. "/"
        local exists = os.rename(path, path)
        if not exists then
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
        end
    end

    fs.delete = function(path)
        assert("string" == type(path), "path must be a string")
        if fs.exists(path) then
            os.execute("rm -rf " .. path)
        end
    end
    fs.readAll = function(path)
        assert("string" == type(path), "path must be a string")
        local file = io.open(path, "r")
        if not file then
            return nil
        end
        local content = file:read("*a")
        file:close()
        return content
    end
end
return fs
