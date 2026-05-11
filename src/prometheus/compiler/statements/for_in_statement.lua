-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- for_in_statement.lua
--
-- This Script contains the statement handler for the ForInStatement
-- Modified: inline native for-in loop optimization for simple loop bodies

local Ast = require("prometheus.ast");
local Scope = require("prometheus.scope");
local util = require("prometheus.util");
local AstKind = Ast.AstKind;
local lookupify = util.lookupify;

-- Check if AST node contains break, continue, or return (recursive, skips nested functions)
local function hasBreakContinueReturn(node)
    if not node or type(node) ~= "table" then return false end
    local kind = node.kind
    if kind == AstKind.BreakStatement
    or kind == AstKind.ContinueStatement
    or kind == AstKind.ReturnStatement then
        return true
    end
    if kind == AstKind.FunctionLiteralExpression
    or kind == AstKind.FunctionDeclaration
    or kind == AstKind.LocalFunctionDeclaration then
        return false
    end
    if node.body and hasBreakContinueReturn(node.body) then return true end
    if node.elseBody and hasBreakContinueReturn(node.elseBody) then return true end
    if node.elseifs then
        for _, e in ipairs(node.elseifs) do
            if e.body and hasBreakContinueReturn(e.body) then return true end
        end
    end
    if node.statements then
        for _, s in ipairs(node.statements) do
            if hasBreakContinueReturn(s) then return true end
        end
    end
    return false
end

-- Check if body contains control flow statements that create additional blocks
local function hasControlFlow(body)
    if not body or not body.statements then return false end
    for _, stat in ipairs(body.statements) do
        local kind = stat.kind
        if kind == AstKind.IfStatement
        or kind == AstKind.WhileStatement
        or kind == AstKind.RepeatStatement
        or kind == AstKind.ForStatement
        or kind == AstKind.ForInStatement then
            return true
        end
        if kind == AstKind.DoStatement and hasControlFlow(stat.body) then
            return true
        end
    end
    return false
end

return function(self, statement, funcDepth)
    -- Check if we can inline this for-in loop
    local canInline = not hasBreakContinueReturn(statement.body)
                  and not hasControlFlow(statement.body)

    if canInline then
        for i, id in ipairs(statement.ids) do
            if self:isUpvalue(statement.scope, id) then
                canInline = false
                break
            end
        end
    end

    if canInline then
        ---------------------------------------------------------------
        -- INLINE PATH: generate a native for-in loop in a single block
        ---------------------------------------------------------------
        local scope = self.activeBlock.scope;
        local savedBlock = self.activeBlock;

        local finalBlock = self:createBlock();
        statement.__start_block = finalBlock;
        statement.__final_block = finalBlock;

        -- Prevent POS_REGISTER from being allocated as temp
        local posState = self.registers[self.POS_REGISTER];
        self.registers[self.POS_REGISTER] = self.VAR_REGISTER;

        -- Compile iterator expressions
        local expressionsLength = #statement.expressions;
        local exprregs = {};
        for i, expr in ipairs(statement.expressions) do
            if(i == expressionsLength and expressionsLength < 3) then
                local regs = self:compileExpression(expr, funcDepth, 4 - expressionsLength);
                for j = 1, 4 - expressionsLength do
                    table.insert(exprregs, regs[j]);
                end
            else
                if i <= 3 then
                    table.insert(exprregs, self:compileExpression(expr, funcDepth, 1)[1])
                else
                    self:freeRegister(self:compileExpression(expr, funcDepth, 1)[1], false);
                end
            end
        end

        -- Get AST expressions for the iterator registers
        local iterExprs = {};
        for i, reg in ipairs(exprregs) do
            table.insert(iterExprs, self:register(scope, reg));
        end

        -- Create for-in scope with loop variables
        local forScope = Scope:new(self.containerFuncScope);
        local forVarIds = {};
        for i = 1, #statement.ids do
            forVarIds[i] = forScope:addVariable();
        end
        local forBodyScope = Scope:new(forScope);

        -- Get registers for loop variables
        local varRegs = {};
        for i, id in ipairs(statement.ids) do
            varRegs[i] = self:getVarRegister(statement.scope, id, funcDepth);
        end

        -- Compile body into fakeBlock
        local fakeBlock = {
            id = -1,
            statements = {},
            scope = forBodyScope,
            advanceToNextBlock = true,
        };
        self.activeBlock = fakeBlock;

        -- Set register = native for-in variable for each loop var
        for i, varReg in ipairs(varRegs) do
            forBodyScope:addReferenceToHigherScope(forScope, forVarIds[i]);
            table.insert(fakeBlock.statements, {
                statement = self:setRegister(forBodyScope, varReg, Ast.VariableExpression(forScope, forVarIds[i])),
                writes = lookupify({varReg}),
                reads = lookupify({}),
                usesUpvals = false,
            });
        end

        -- Compile body
        self:compileBlock(statement.body, funcDepth);

        -- Extract statements and collect all reads/writes
        local bodyStatements = {};
        local allWrites = {};
        local allReads = {};
        for _, reg in ipairs(exprregs) do
            allReads[#allReads + 1] = reg;
        end
        for _, reg in ipairs(varRegs) do
            allWrites[#allWrites + 1] = reg;
        end
        for _, s in ipairs(fakeBlock.statements) do
            table.insert(bodyStatements, s.statement);
            if s.writes then
                for r, _ in pairs(s.writes) do
                    allWrites[#allWrites + 1] = r;
                end
            end
            if s.reads then
                for r, _ in pairs(s.reads) do
                    allReads[#allReads + 1] = r;
                end
            end
        end

        -- Restore active block
        self.activeBlock = savedBlock;
        scope = savedBlock.scope;

        -- Create native ForInStatement AST node
        local forInNode = Ast.ForInStatement(
            forScope, forVarIds, iterExprs,
            Ast.Block(bodyStatements, forBodyScope)
        );

        -- Add to current block with ALL body reads/writes to prevent reordering
        self:addStatement(forInNode, allWrites, allReads, true);

        -- Free registers
        for _, reg in ipairs(exprregs) do
            self:freeRegister(reg, true);
        end
        for _, reg in ipairs(varRegs) do
            self:freeRegister(reg, true);
        end

        -- Restore POS_REGISTER state
        self.registers[self.POS_REGISTER] = posState;

        -- Jump to final block
        self:addStatement(self:jmp(scope, Ast.NumberExpression(finalBlock.id)), {self.POS_REGISTER}, {}, false);
        self:setActiveBlock(finalBlock);
        return;
    end

    ---------------------------------------------------------------
    -- ORIGINAL PATH: 3-block dispatch
    ---------------------------------------------------------------
    local scope = self.activeBlock.scope;
    local expressionsLength = #statement.expressions;
    local exprregs = {};
    for i, expr in ipairs(statement.expressions) do
        if(i == expressionsLength and expressionsLength < 3) then
            local regs = self:compileExpression(expr, funcDepth, 4 - expressionsLength);
            for i = 1, 4 - expressionsLength do
                table.insert(exprregs, regs[i]);
            end
        else
            if i <= 3 then
                table.insert(exprregs, self:compileExpression(expr, funcDepth, 1)[1])
            else
                self:freeRegister(self:compileExpression(expr, funcDepth, 1)[1], false);
            end
        end
    end

    for i, reg in ipairs(exprregs) do
        if reg and self.registers[reg] ~= self.VAR_REGISTER and reg ~= self.POS_REGISTER and reg ~= self.RETURN_REGISTER then
            self.registers[reg] = self.VAR_REGISTER;
        else
            exprregs[i] = self:allocRegister(true);
            self:addStatement(self:copyRegisters(scope, {exprregs[i]}, {reg}), {exprregs[i]}, {reg}, false);
        end
    end

    local checkBlock = self:createBlock();
    local bodyBlock = self:createBlock();
    local finalBlock = self:createBlock();

    statement.__start_block = checkBlock;
    statement.__final_block = finalBlock;

    self:addStatement(self:setPos(scope, checkBlock.id), {self.POS_REGISTER}, {}, false);

    self:setActiveBlock(checkBlock);
    local scope = self.activeBlock.scope;

    local varRegs = {};
    for i, id in ipairs(statement.ids) do
        varRegs[i] = self:getVarRegister(statement.scope, id, funcDepth)
    end

    self:addStatement(Ast.AssignmentStatement({
        self:registerAssignment(scope, exprregs[3]),
        varRegs[2] and self:registerAssignment(scope, varRegs[2]),
    }, {
        Ast.FunctionCallExpression(self:register(scope, exprregs[1]), {
            self:register(scope, exprregs[2]),
            self:register(scope, exprregs[3]),
        })
    }), {exprregs[3], varRegs[2]}, {exprregs[1], exprregs[2], exprregs[3]}, true);

    self:addStatement(Ast.AssignmentStatement({
        self:posAssignment(scope)
    }, {
        Ast.OrExpression(Ast.AndExpression(self:register(scope, exprregs[3]), Ast.NumberExpression(bodyBlock.id)), Ast.NumberExpression(finalBlock.id))
    }), {self.POS_REGISTER}, {exprregs[3]}, false);

    self:setActiveBlock(bodyBlock);
    local scope = self.activeBlock.scope;

    self:addStatement(self:copyRegisters(scope, {varRegs[1]}, {exprregs[3]}), {varRegs[1]}, {exprregs[3]}, false);

    for i=3, #varRegs do
        self:addStatement(self:setRegister(scope, varRegs[i], Ast.NilExpression()), {varRegs[i]}, {}, false);
    end

    for i, id in ipairs(statement.ids) do
        if(self:isUpvalue(statement.scope, id)) then
            local varreg = varRegs[i];
            local tmpReg = self:allocRegister(false);
            scope:addReferenceToHigherScope(self.scope, self.allocUpvalFunction);
            self:addStatement(self:setRegister(scope, tmpReg, Ast.FunctionCallExpression(Ast.VariableExpression(self.scope, self.allocUpvalFunction), {})), {tmpReg}, {}, false);
            self:addStatement(self:setUpvalueMember(scope, self:register(scope, tmpReg), self:register(scope, varreg)), {}, {tmpReg, varreg}, true);
            self:addStatement(self:copyRegisters(scope, {varreg}, {tmpReg}), {varreg}, {tmpReg}, false);
            self:freeRegister(tmpReg, false);
        end
    end

    self:compileBlock(statement.body, funcDepth);
    self:addStatement(self:setPos(scope, checkBlock.id), {self.POS_REGISTER}, {}, false);
    self:setActiveBlock(finalBlock);

    for i, _ in ipairs(exprregs) do
        self:freeRegister(exprregs[i], true)
    end
end;
