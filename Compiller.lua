io.write("\n\nEnter File Name:") -- Gets User input for the file name \n adds a new line

local filename = io.read() --Reads userinput and stores it as varible
local appendfile = ".olc"  --Stores file type to later look if filename leads to a .olc file

if not filename:match("%.olc$") then --Checks if filename already has .olc in the extension
    filename = filename .. appendfile --If not add's .olc to the end 
end



local opcodes = {
    --[[
    shapes Definition
    A = Read Ram Address on Bus A
    B = Read Ram Address on Bus B
    W = Write address
    D = Data

    ]]
    add = {"01", shapes = "ABW"},
    sub = {"02", shapes = "ABW"},
    mul = {"03", shapes = "ABW"},
    div = {"04", shapes = "ABW"},
    print = {"07", shapes = "A"},
    load = {"00", shapes = "WD"},
    jump = {"06", shapes = "D"},
    jumpE = {"08", shapes = "ABD"},
    jumpG = {"09", shapes = "ABD"},
    jumpL = {"09", shapes = "BAD"},
    mov = {"10", shapes = "AW"}
}

local WriteFilename = filename .. "c"
local WriteFile = io.open(WriteFilename, "w")
local file = io.open(filename, "r") --attempts to open the file

if not file then  --Throws Error when it can't open it
    print("\ncould not open: " .. filename)
    print("Please check if the file exist or if you made a typo\n\n")
end


function WriteOut(WriteFile, Compiled)
    
    WriteFile:write(Compiled)
end

    
function GetTable(fileline)  -- spilts the lines into words to find the opcodes
    local op = {}
    for fileline in fileline:gmatch("%S+") do
        table.insert(op, fileline)
    end
    return op
end

function JumpResolve(opcode, jumps)-- detects if jump is a label or a direct address
    local n = tonumber(opcode)
    local Check = ""
    if n then
        Check = PadNum(opcode)
    elseif jumps[opcode] then
        Check = PadNum(jumps[opcode])
    else
        print("ERROR undefinded label or address: ")
    end
    if Check ~= "" then
        return Check
    end
end

function RegNum(Register)-- Converts Register number like R1 or R13 to 01 and 13
    local digits = Register:gsub("R", "")
    return string.format("%02d", tonumber(digits))
end

function PadNum(Num)-- Ensures each instruction letter has 2 digits ie 02 10 03 you write 3 it adds a 0 so its 03
    return string.format("%02d", tonumber(Num))
end

function StripComment(line)
    return line:gsub("%-%-.*$", "")
end

function whitespace(line)
    if line:find("^%s*$") or line:match("^(.-)%s*%-%-") then
        return true
    else
        return false
    end
end

function IsJumpLabel(opcode)
    return opcode:match("^(%w+):%s*$")
end

function Encode(Tabled, op, jumps)
local fields = {}
    if op.shapes == "ABW" then 
        fields.write = RegNum(Tabled[04])
        fields.readb = RegNum(Tabled[03])
        fields.reada = RegNum(Tabled[2])
        fields.opC = op[1]
        fields.data = "00"
        return fields
    end

    if op.shapes == "A" then
       fields.write = "00"
       fields.readb = "00"
       fields.reada = RegNum(Tabled[2])
       fields.opC = op[1]
       fields.data = "00"
    end

    if op.shapes == "WD" then
        fields.write = RegNum(Tabled[02])
        fields.readb = "00"
        fields.reada = "00"
        fields.opC = op[1]
        fields.data = PadNum(Tabled[3])
    end

    if op.shapes == "D" then
        fields.write = "00"
        fields.readb = "00"
        fields.reada = "00"
        fields.opC = op[1]
        fields.data = JumpResolve(Tabled[2], jumps)
    end

    if op.shapes == "ABD" then
        fields.write = "00"
        fields.readb = RegNum(Tabled[3])
        fields.reada = RegNum(Tabled[2])
        fields.opC = op[1]
        fields.data = JumpResolve(Tabled[4], jumps)
    end

    if op.shapes == "BAD" then
        fields.write = "00"
        fields.readb = RegNum(Tabled[2])
        fields.reada = RegNum(Tabled[3])
        fields.opC = op[1]
        fields.data = JumpResolve(Tabled[4], jumps)
    end

    if op.shapes == "AW" then
        fields.write = RegNum(Tabled[3])
        fields.readb = "00"
        fields.reada = RegNum(Tabled[2])
        fields.opC = op[1]
        fields.data = "00"
    end

return fields
end

local lines = {}


if file then
    local LineNumber = 1
    local jumpaddress = 1
    local jumps = {}
    
    for line in file:lines() do
        table.insert(lines, line)
    end

    for index = 1, #lines do  --Tables jump labels from .olc file
        local line = lines[index]
        line = StripComment(line)
        local jump = IsJumpLabel(line)
        local isCode = not whitespace(line)

        if isCode then  
            if jump then
            jumps[jump] = jumpaddress
            else
                jumpaddress = jumpaddress + 1
            end  
        end 
    end

    for index = 1, #lines do
        local line = lines[index]
        line = StripComment(line)
        local jump = IsJumpLabel(line)
        local isCode = not whitespace(line)
        
        if isCode then
          if not jump then
            local opcode = GetTable(line) --Contains Real data ie compare if its the add varible
            local op = opcodes[opcode[1]]
            print("DEBUG line:", LineNumber, "tokens:", #opcode, "shape:", op.shapes)
            local packed = Encode(opcode, op, jumps)
            

            local fileout = packed.write .. packed.readb .. packed.reada .. packed.opC .. packed.data
            print(fileout)
            
            WriteOut(WriteFile, fileout .. "\n")

          end
        end

        
       -- print(packed.opC, packed.reada, packed.readb, packed.write)


        LineNumber = LineNumber + 1
    end
    -- THE END
    if WriteFile then
        WriteFile:close()
    end
    file:close()
    print("Saved to " .. WriteFilename)
    print("with " .. jumpaddress - 1 .. " lines of ROM writen")
end

