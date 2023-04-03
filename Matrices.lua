local function MultiplyCF(CF1, CF2)
    local a14, a24, a34, a11, a12, a13, a21, a22, a23, a31, a32, a33 = CF1:GetComponents()
    local b14, b24, b34, b11, b12, b13, b21, b22, b23, b31, b32, b33 = CF2:GetComponents()
    local ProductMatrix = {
        {a11 * b11 + a12 * b21 + a13 * b31, a11 * b12 + a12 * b22 + a13 * b32, a11 * b13 + a12 * b23 + a13 * b33, a11 * b14 + a12 * b24 + a13 * b34 + a14},
        {a21 * b11 + a22 * b21 + a23 * b31, a21 * b12 + a22 * b22 + a23 * b32, a21 * b13 + a22 * b23 + a23 * b33, a21 * b14 + a22 * b24 + a23 * b34 + a24},
        {a31 * b11 + a32 * b21 + a33 * b31, a31 * b12 + a32 * b22 + a33 * b32, a31 * b13 + a32 * b23 + a33 * b33, a31 * b14 + a32 * b24 + a33 * b34 + a34}
    }
    return CFrame.new(
        ProductMatrix[1][4], ProductMatrix[2][4], ProductMatrix[3][4],
        ProductMatrix[1][1], ProductMatrix[1][2], ProductMatrix[1][3],
        ProductMatrix[2][1], ProductMatrix[2][2], ProductMatrix[2][3],
        ProductMatrix[3][1], ProductMatrix[3][2], ProductMatrix[3][3]
    )
end

local Matrix = {}

function Matrix.new(RowCount)
    local NewMatrix = {}
    for i = 1, RowCount do
        table.insert(NewMatrix, {})
    end
    return NewMatrix
end

function Matrix.GetColumnCount(M)
    return #M[1]
end

function Matrix.GetRowCount(M)
    return #M
end

function Matrix.GetComponentsInRow(M, RowNumber)
    return M[RowNumber]
end

function Matrix.GetComponentsInColumn(M, Column)
    -- Should return a column vector
    local ColumnComponents = {}
    local RowCount = Matrix.GetRowCount(M)
    for Row = 1, RowCount do
        table.insert(ColumnComponents, M[Row][Column])
    end
    return ColumnComponents
end

function Matrix.Transpose(M)
    -- iterate over all components and switch row number with column number
    local TransposedMatrix = Matrix.new(Matrix.GetRowCount(M))
    for Row, ColumnData in ipairs(M) do
        for Column, Component in ipairs(M[Row]) do
            -- Switch row number with column number
            TransposedMatrix[Column][Row] = M[Row][Column]
        end
    end
    return TransposedMatrix
end

function Matrix.ConvertCF(CF)
    local m14, m24, m34, m11, m12, m13, m21, m22, m23, m31, m32, m33 = CF:GetComponents()
    local NewMatrix = {
        {m11, m12, m13, m14},
        {m21, m22, m23, m24},
        {m31, m32, m33, m34},
        {0, 0, 0, 1}
    }
    return NewMatrix
end

function Matrix.Multiply(M1, M2)
    local RowsM1, ColumnsM1 = Matrix.GetRowCount(M1), Matrix.GetColumnCount(M1)
    local RowsM2, ColumnsM2 = Matrix.GetRowCount(M2), Matrix.GetColumnCount(M2)
    local ProductMatrix = Matrix.new(RowsM1) -- should end up having the same number of columns as M2

    -- ensure the numbers of rows in one matrix equals the number of rows in product and number of columns
    -- ensure the numbers of columns in m1 equals number of rows in m2
    if Matrix.GetColumnCount(M1) == Matrix.GetRowCount(M2) then

    else
        return "Undefined - Matrix Dimensions Incompatible"
    end
end
