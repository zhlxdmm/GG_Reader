-- 簡單到爆的閱讀器
-- 裡面的格式可自行調整，如有需要
-- Made by Sam
-- Version: 0.1

-- 如有bug請開issuse，我會盡快處理

-- 初始版本: 8小時 (2020/2/6 22:00 - 2/7 06:00)

--[[--

MIT License

Copyright (c) 2020 samsamlausam

Permission is hereby granted, free of charge, to any person obtaining a copy

of this software and associated documentation files (the "Software"), to deal

in the Software without restriction, including without limitation the rights

to use, copy, modify, merge, publish, distribute, sublicense, and/or sell

copies of the Software, and to permit persons to whom the Software is

furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all

copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR

IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,

FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE

AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER

LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,

OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE

SOFTWARE.

--]]--

local S = { ver = "0.1" }
S.createFunction =
function(api, ...)local _=...;return function()return api(_)end end

local g = gg
-- gg
local sel = g.choice
local mulsel = g.multiChoice
local prompt = g.prompt
-- box is moved to below
local toast = g.toast
local save = g.saveVariable
local ui = {
 click = nil; -- Define in below.
 show = S.createFunction(g.setVisible,true);
 hide = S.createFunction(g.setVisible,false);
}
local box = (function(msg,btn1,btn2,btn3,showui)local _=g.alert(msg,btn1,btn2,btn3) if showui then S.lastMenu(1) end return _ end)

local file = io
-- io
local open = file.input



-- Pre-use data / function
S.ignoredFunction = {
 click = true;
 show = true;
 hide = true;
 createFunction = true;
 LastMenu = true;
 manuallySethook = true;
 InitBook = true;
 UpdateConfig = true;
}
local line = g.getLine();
local currFile = g.getFile();
S.initBinaryMode = function()
 if line ~= -1 then
  io.open(currFile.."c", "w+"):write(string.dump(loadfile(currFile),true)):close()
  dofile(currFile.."c");
 else
  currFile = currFile:match("(.*)c")
 end
end
--S.initBinaryMode(); -- If you need debug comment this
local cfgFile = currFile .. ".cfg";
local tryConfig = loadfile(cfgFile);
S.config = tryConfig and pcall(tryConfig) and tryConfig() or {};
tryConfig = nil;
local path = currFile:match("(.*)/").."/"
ui.click = function()
 local func = S.createFunction(g.isVisible,true)()
 if func then
  ui.hide()
 end
 return func
end
S.manuallySethook = function()
 for name, func in pairs(S) do
  if type(func) == "function" and not S.ignoredFunction[name] then
   S[name] = function(...)
    if S.currUI ~= name then
     S.lastUI = S.currUI
     S.currUI = name
    end
    return func(...)
   end
  end
 end
end
S.lastMenu = function(which)
 local selUI = ({S.currUI, S.lastUI})[which]
 if (selUI) then return S[selUI]() else S.mainMenu() end
end
S.updateConfig = function()
 local tryConfig = loadfile(cfgFile);
 S.config = tryConfig and pcall(tryConfig) and tryConfig() or S.config or {};
 tryConfig = nil;
end
-- UI

-- Main menu
S.mainMenu = function()
 local UI={}
 for i in pairs(S.config.book or {}) do
  if type(i) == "number" then
   UI[i] = "📖 "..S.config.book[i].name
   local read_process = S.config.book[i].reading
   if read_process and read_process.index and read_process.subIndex then
    UI[#UI] = UI[#UI] .. "\n" .. 
     "目前進度: 第" .. read_process.index .. "章 - 第" .. read_process.subIndex .. "節" .. (S.config.book.lastReading==i and ", 上次閱讀" or "")
    end
   end
 end
 UI[#UI+1], UI[#UI+2] = "- 添加小說", "- 離開";
 local act = sel(UI, nil, "閱讀器 v".. S.ver .. "\n- Sam");
 if act == #UI then
  os.exit()
 elseif act == #UI-1 then
  S.addBook()
 elseif act then
  S.this = nil
  S.readBook(act);
 end
end

-- Add Book
S.addBook = function()
 local UI = {
  "請選擇小說: ",
  "返回"
 }
 local defaultInput = {path, false}
 local promptType = {"file", "checkbox"}
 local book = prompt(UI, S.input or defaultInput, promptType)
 if type(book) == "table" then
  S.input = book
  if book[#UI] then
   S.lastMenu(2)
  else
   S.book = file.open(book[1])
   if S.book then
    local tree = S.initBook();
    if box(
     "📖 名稱: " .. tree.name .. "\n\n" ..
     "簡介: \n" .. tree.info .. "\n" ..
     "封面鏈接: " .. tree.photo .. "\n\n" ..
     "請問資料是否正確？", "是", "否"
    ) == 1 then
     S.config.book = S.config.book or {}
     S.config.book[#S.config.book+1] = tree;
     save(S.config, cfgFile);
     S.updateConfig();
     toast("保存成功");
     S.lastMenu(2);
    else
     S.lastMenu(1)
    end
    
   else
    box("你所選擇的文件並不存在", "",nil,nil,true)
   end
  end
 else
  S.input = nil;
 end
end

--Book initialisation
S.initBook = function(book)
 local this = {}
 S.subIndex = {};
 toast("讀取中...")
 for line in S.book:lines() do
  local ret = line
  if ret:find("－－－－－－－－－－－－－－－") then
   local types = ret:match("－－－－－－－－－－－－－－－(.+)")
    local GetString = function(num)
     local tmp
     num = num or -1
     for _ = 1, num, (num>0 and 1 or 0) do
      local str = S.book:read("*l");
      if str:find("－－－－－－－－－－－－－－－") and num<0 then
       S.debug = str:find("－－－－－－－－－－－－－－－")
       break
      elseif str then
       tmp = (tmp or "")..str..(tmp and "\n" or "");
      end
     end
     return tmp
    end
    local GetIndex = function()
     local index = {}
     local indexZero = "序"
     while true do
      local str = GetString(1);
      if str:find("－－－－－－－－－－－－－－－") then
       break
      elseif str and str ~= '' then
       local str, indexType = str:gsub("- ","")
       if indexType == 1 then -- Main
        local indexNumber, name = str:match("(.+)章(.*)");
        indexNumber = (indexNumber==indexZero and 0 or indexNumber)+0
        if name and name ~= '' then
         name = name:match("　(.+)");
        else
         name = '(空)';
        end
        index[#index+1] = { name = name, sub_Index = {}}
        S.currIndex = #index
       elseif indexType == 2 then -- sub
        index[S.currIndex].sub_Index[#index[S.currIndex].sub_Index+1] = { name = str }
        S.subIndex[str] = #index[S.currIndex].sub_Index;
       end
      end
     end
     return index
    end
    local GetHeader = function()
     local str = GetString(1);
     GetString(1);
     local str = str:match("第%d+話：(.+)");
     return S.subIndex[str]
    end
    local GetBody = function()
     local r = GetString()
     this.index[S.currIndex].sub_Index[S.currSubIndex].content = r
    end
    if types == "NAME" then
     this.name = GetString();
    elseif types == "PHOTO" then
     this.photo = GetString();
    elseif types == "INFO" then
     this.info = GetString();
    elseif types == "OTHER" then
     this.other = GetString();
    elseif types == "INDEX" then
     this.index = GetIndex();
    elseif types == "BEGIN" then
     S.currSubIndex = GetHeader();
    elseif types == "BODY" then
     GetBody();
--    elseif types == "END" then -- Not possible
     
    elseif types == "OTHERNAME" then
     
    elseif types == "CREATOR" then
     this.creator = GetString();
    elseif types == "OTHER" then
     
    elseif types == "" then
     
    elseif types then
     error("無效類型 `"..tostring(types or "").."` ("..tostring(types)..")")
    end
  elseif ret:find("＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝") then
   local types = ret:match("＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝(.+)")
    local GetString = function(num)
     local tmp
     num = num or -1
     for _ = 1, num do
      local str = S.book:read("*l");
      if str == "＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝" and num<0 then
       break
      elseif str then
       tmp = (tmp or "")..str..(tmp and "\n" or "");
      end
     end
     return tmp
    end
    local GetTitle = function()
     local indexZero = "序"
     local str = GetString(1);
     GetString(1);
     local indexNumber = str:match("第%d+章：(.+)章");
     indexNumber = (indexNumber==indexZero and 0 or indexNumber)+1
     S.currIndex = indexNumber
    end
    if types == "START" then
    elseif types == "CHECK" then
     GetTitle();
    elseif types == "" then
    elseif not types then
    else
     error("無效類型 `"..tostring(types or "").."` ("..tostring(types)..")")
    end
  end
 end
 toast("讀取完成")
 return this;
end

-- ReadBook
S.readBook = function(number)
 local this = S.this or S.config.book[number]
 this.book_number = this.book_number or number
 this.reading = S.config.book[this.book_number].reading or {}
 local subTitle
 local UI = {
  "簡介",
  "閱讀",
  "本書製作名單",
  "刪除本書",
  "返回主目錄"
 }
 ::UIBack::
 subTitle = this.name .. "\n\n" ..
  "- 章節: " .. (this.reading.index and this.reading.index.."/" or "") .. #this.index
 local act = sel(UI, nil, subTitle)
 S.this = this
 if act == #UI then
  S.mainMenu()
 elseif act == 1 then
  local text = this.info and "本書簡介:\n\n" .. this.info or "本書並沒有簡介"
  box(text,"返回",nil,nil,true)
 elseif act == 2 then
  if this.reading.index and this.reading.subIndex then
   local act = box("上次閱讀的章節: "..this.reading.index.. " - "..this.reading.subIndex,("從 "..this.reading.index.. " - "..this.reading.subIndex.." 的章節開始"), "返回"..("\t"):rep(7), "手動選擇")
   if act == 1 then
    S.index, S.subIndex = this.reading.index, this.reading.subIndex
   elseif act ~= 3 then
    goto UIBack
   end
  end
  S.display();
 elseif act == 3 then
  local text = this.creator and "本書製作名單\n\n" .. this.creator or "本書並沒有製作名單"
  box(text,"返回",nil,nil,true)
  box(text,"返回",nil,nil,true)
 elseif act == 4 then
  if box("你確定要刪除“"..this.name.."”嗎？","是","否")==1 then
   S.config.book[this.book_number] = nil
   save(S.config, cfgFile)
   S.updateConfig();
   toast("已刪除“"..this.name.."”.")
   S.mainMenu()
  else
   ui.show()
  end
 end
end

-- Display
S.display = function()
 local this = S.this or S.config.book[number]
 this.book_number = this.book_number or number
 this.reading = S.config.book[this.book_number].reading or {}
 ::IndexBack::
 subTitle = "請選擇一個章節以開始閱讀"
 UI = {}
 for i in pairs(this.index) do
  if type(i) == "number" then
   UI[#UI + 1] = i..": "..this.index[i].name
  end
 end
 UI[#UI+1] = "返回"
 local IndexReading = S.config.book[this.book_number].reading.index or 0
 S.index = S.index or sel(UI,IndexReading,subTitle)
 if S.index == #UI then
  S.index = nil;
  S.lastMenu(2)
 elseif S.index and S.index > 0 then
  ::SubIndexBack::
  this.Index = this.index[S.index]
  subTitle = "目前章節: " .. this.Index.name
  UI = {}
  for i in pairs(this.Index.sub_Index) do
   if type(i) == "number" then
    UI[#UI+1] = i.." - "..this.Index.sub_Index[i].name
   end
  end
  UI[#UI+1] = "返回"
  local subIndexReading = S.index == S.config.book[this.book_number].reading.index and S.config.book[this.book_number].reading.subIndex or 0
  S.subIndex = S.subIndex or sel(UI, subIndexReading, subTitle)
  if S.subIndex == #UI then
   S.index, S.subIndex = nil, nil;
   goto IndexBack
  elseif S.subIndex and S.subIndex > 0 then
   ::PageChange::
   this.Index = this.index[S.index]
   this.subIndex = this.Index.sub_Index[S.subIndex]
   toast("加載中... 如果加載較慢請等待！")
   S.config.book[this.book_number].reading={ index = S.index, subIndex = S.subIndex }
   S.config.book.lastReading = this.book_number
   save(S.config, cfgFile)
   S.updateConfig();
   local readAct = box(
    this.subIndex.content,
    "下一頁", "返回次章節選擇", "上一頁")
   if readAct == 1 then
    if S.index == #this.index then
     if S.subIndex == #this.Index.sub_Index then
      box("已經是最後一頁咯","")
     else -- sub_index
      S.subIndex = S.subIndex + 1
     end
    else -- index + sub_index
     if S.subIndex == #this.Index.sub_Index then -- index + start of sub_index
      S.index = S.index + 1
      S.subIndex = 1
     else -- sub_index
      S.subIndex = S.subIndex + 1
     end
    end
    goto PageChange
   elseif readAct == 2 then
    S.subIndex = nil;
    goto SubIndexBack
   elseif readAct == 3 then
    if S.index == 1 then
     if S.subIndex == 1 then
      box("已經是最前一頁咯","")
     else -- sub_index
      S.subIndex = S.subIndex - 1
     end
    else -- index + sub_index
     if S.subIndex == 1 then -- index + end of sub_index
      S.index = S.index - 1
      S.subIndex = #this.index[S.index].sub_Index
     else -- sub_index
      S.subIndex = S.subIndex - 1
     end
    end
    goto PageChange
   end
  end
 end
end

-- Bootloader
S.manuallySethook();

-- Default loop
while true do
 repeat
 until ui.click()
 S.lastMenu(1)
end