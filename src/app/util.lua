--
-- Author: yjun
-- Date: 2014-09-24 11:02:00
--
function split(str, reps)
    local resultStrsList = {};
    string.gsub(str, '[^' .. reps ..']+', function(w) table.insert(resultStrsList, w) end );
    return resultStrsList;
end

function loadCsvFile(file_name) 
    -- 读取文件
    -- local data = io.readfile(filePath)
    local fileUtil = cc.FileUtils:getInstance()
    local fullPath = fileUtil:fullPathForFilename(file_name)
    local data = fileUtil:getStringFromFile(fullPath)
    -- print(data)
    -- 按行划分
    local lineStr = split(data, '\n\r')

    --[[
		从第3行开始保存（第一行是标题，第二行是注释，后面的行才是内容） 
		
		用二维数组保存：arr[ID][属性标题字符串]
	]]--
	local titles = string.split(lineStr[1], ',')
	
	local arrs = {};
	for i = 3, #lineStr, 1 do
	    -- 一行中，每一列的内容
	    local content = string.split(lineStr[i], ',')
		-- cclog(content)
	    -- 以标题作为索引，保存每一列的内容，取值的时候这样取：arrs[ID].Title
	    arrs[content[1]] = {};
	    for j = 1, #titles, 1 do
	    	local num = tonumber(content[j])
	    	if num then
	    		arrs[content[1]][titles[j]] = num
	    	elseif content[j] == "" then
	    		arrs[content[1]][titles[j]] = nil
	    	else
	    		arrs[content[1]][titles[j]] = content[j]
	    	end
	    end
	end
	return arrs
end

-- 判断值是否存在
function KeyExist(t, k)
	for key, value in pairs(t) do
		if key == k then
			return true
		end
	end

	return false
end

-- 判断值是否存在
function ValueExist(t, v)
	for key, value in pairs(t) do
		if value == v then
			return true
		end
	end

	return false
end

-- 获取随机数
function random(...)
	math.randomseed(os.time())
    return math.random(...)
end

cclog = function( ... )
    local tv = "\n"
    local xn = 0
    local function tvlinet(xn)
        -- body
        for i=1,xn do
            tv = tv.."\t"
        end
    end

    local function printTab(i,v)
        -- body
        if type(v) == "table" then
            tvlinet(xn)
            xn = xn + 1
            tv = tv..""..i..":Table{\n"
            table.foreach(v,printTab)
            tvlinet(xn)
            tv = tv.."}\n"
            xn = xn - 1
        elseif type(v) == nil then
            tvlinet(xn)
            tv = tv..i..":nil\n"
        else
            tvlinet(xn)
            tv = tv..i..":"..tostring(v).."\n" 
        end
    end
    local function dumpParam(tab)
        for i=1, #tab do  
            if tab[i] == nil then 
                tv = tv.."nil\t"
            elseif type(tab[i]) == "table" then 
                xn = xn + 1
                tv = tv.."\ntable{\n"
                table.foreach(tab[i],printTab)
                tv = tv.."\t}\n"
            else
                tv = tv..tostring(tab[i]).."\t"
            end
        end
    end
    local x = ...
    if type(x) == "table" then
        table.foreach(x,printTab)
    else
        dumpParam({...})
        -- table.foreach({...},printTab)
    end
    print(tv)
end