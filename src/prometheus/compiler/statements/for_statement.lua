-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- for_statement.lua
--
-- This Script contains the statement handler for the ForStatement
-- Modified: inline native for loop optimization for simple loop bodies

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
    -- Determine if this loop can be inlined as a native for loop
    local canInline = not self:isUpvalue(statement.scope, statement.id)
                  and not hasBreakContinueReturn(statement.body)
                  and not hasControlFlow(statement.body)

    if canInline then
        ---------------------------------------------------------------
        -- INLINE PATH: generate a native Lua for loop in a single block
        ---------------------------------------------------------------
        local scope = self.activeBlock.scope;
        local savedBlock = self.activeBlock;

        local finalBlock = self:createBlock();
        statement.__start_block = finalBlock;
        statement.__final_block = finalBlock;

        -- Prevent POS_REGISTER from being allocated as temp during body compilation
        local posState = self.registers[self.POS_REGISTER];
        self.registers[self.POS_REGISTER] = self.VAR_REGISTER;

        -- Compile init/final/step expressions into registers
        local initialReg = self:compileExpression(statement.initialValue, funcDepth, 1)[1];
        local finalExprReg = self:compileExpression(statement.finalValue, funcDepth, 1)[1];
        local incrementExprReg = self:compileExpression(statement.incrementBy, funcDepth, 1)[1];

        -- Get AST expressions for the register values
        local initExpr = self:register(scope, initialReg);
        local finalExpr = self:register(scope, finalExprReg);
        local stepExpr = self:register(scope, incrementExprReg);

        -- Create for loop scope and variable
        local forScope = Scope:new(self.containerFuncScope);
        local forVarId = forScope:addVariable();
        local forBodyScope = Scope:new(forScope);

        -- Map the original loop variable to a register
        local varReg = self:getVarRegister(statement.scope, statement.id, funcDepth, nil);

        -- Compile body into a temporary (fake) block to collect statements
        local fakeBlock = {
            id = -1,
            statements = {},
            scope = forBodyScope,
            advanceToNextBlock = true,
        };
        self.activeBlock = fakeBlock;

        -- First body statement: set register = native for variable
        forBodyScope:addReferenceToHigherScope(forScope, forVarId);
        table.insert(fakeBlock.statements, {
            statement = self:setRegister(forBodyScope, varReg, Ast.VariableExpression(forScope, forVarId)),
            writes = lookupify({varReg}),
            reads = lookupify({}),
            usesUpvals = false,
        });

        -- Compile the original body
        self:compileBlock(statement.body, funcDepth);

        -- Extract raw statements from fakeBlock and collect all reads/writes
        local bodyStatements = {};
        local allWrites = {varReg};
        local allReads = {initialReg, finalExprReg, incrementExprReg};
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

        -- Build native ForStatement AST node
        local forNode = Ast.ForStatement(
            forScope, forVarId,
            initExpr, finalExpr, stepExpr,
            Ast.Block(bodyStatements, forBodyScope)
        );

        -- Add ForStatement to the current block with ALL body reads/writes to prevent reordering
        self:addStatement(forNode, allWrites, allReads, true);

        -- Free registers
        self:freeRegister(initialReg);
        self:freeRegister(finalExprReg);
        self:freeRegister(incrementExprReg);
        self:freeRegister(varReg, true);

        -- Restore POS_REGISTER state
        self.registers[self.POS_REGISTER] = posState;

        -- Jump to final block
        self:addStatement(self:jmp(scope, Ast.NumberExpression(finalBlock.id)), {self.POS_REGISTER}, {}, false);
        self:setActiveBlock(finalBlock);
        return;
    end

    ---------------------------------------------------------------
    -- ORIGINAL PATH: 3-block dispatch (check → body → check → ...)
    ---------------------------------------------------------------
    local scope = self.activeBlock.scope;
    local checkBlock = self:createBlock();
    local innerBlock = self:createBlock();
    local finalBlock = self:createBlock();

    statement.__start_block = checkBlock;
    statement.__final_block = finalBlock;

    local posState = self.registers[self.POS_REGISTER];
    self.registers[self.POS_REGISTER] = self.VAR_REGISTER;

    local initialReg = self:compileExpression(statement.initialValue, funcDepth, 1)[1];

    local finalExprReg = self:compileExpression(statement.finalValue, funcDepth, 1)[1];
    local finalReg = self:allocRegister(false);
    self:addStatement(self:copyRegisters(scope, {finalReg}, {finalExprReg}), {finalReg}, {finalExprReg}, false);
    self:freeRegister(finalExprReg);

    local incrementExprReg = self:compileExpression(statement.incrementBy, funcDepth, 1)[1];
    local incrementReg = self:allocRegister(false);
    self:addStatement(self:copyRegisters(scope, {incrementReg}, {incrementExprReg}), {incrementReg}, {incrementExprReg}, false);
    self:freeRegister(incrementExprReg);

    local tmpReg = self:allocRegister(false);
    self:addStatement(self:setRegister(scope, tmpReg, Ast.NumberExpression(0)), {tmpReg}, {}, false);
    local incrementIsNegReg = self:allocRegister(false);

    local shouldSwap3 = math.random(1, 2) == 2;
    local shuffledRegs4 = shouldSwap3 and {incrementReg, tmpReg} or {tmpReg, incrementReg};
    self:addStatement(self:setRegister(scope, incrementIsNegReg, Ast[shouldSwap3 and "LessThanExpression" or "GreaterThanExpression"](self:register(scope, shuffledRegs4[1]), self:register(scope, shuffledRegs4[2]))), {incrementIsNegReg}, {shuffledRegs4[1], shuffledRegs4[2]}, false);

    self:freeRegister(tmpReg);

    local currentReg = self:allocRegister(true);
    self:addStatement(self:setRegister(scope, currentReg, Ast.SubExpression(self:register(scope, initialReg), self:register(scope, incrementReg))), {currentReg}, {initialReg, incrementReg}, false);
    self:freeRegister(initialReg);

    self:addStatement(self:jmp(scope, Ast.NumberExpression(checkBlock.id)), {self.POS_REGISTER}, {}, false);

    self:setActiveBlock(checkBlock);

    scope = checkBlock.scope;

    local shuffledRegs = util.shuffle({currentReg, incrementReg});
    self:addStatement(self:setRegister(scope, currentReg, Ast.AddExpression(self:register(scope, shuffledRegs[1]), self:register(scope, shuffledRegs[2]))), {currentReg}, {shuffledRegs[1], shuffledRegs[2]}, false);
    local tmpReg1 = self:allocRegister(false);
    local tmpReg2 = self:allocRegister(false);
    self:addStatement(self:setRegister(scope, tmpReg2, Ast.NotExpression(self:register(scope, incrementIsNegReg))), {tmpReg2}, {incrementIsNegReg}, false);

    local shouldSwap = math.random(1, 2) == 2;
    local shuffledRegs2 = shouldSwap and {currentReg, finalReg} or {finalReg, currentReg};
    self:addStatement(self:setRegister(scope, tmpReg1, Ast[shouldSwap and "LessThanOrEqualsExpression" or "GreaterThanOrEqualsExpression"](self:register(scope, shuffledRegs2[1]), self:register(scope, shuffledRegs2[2]))), {tmpReg1}, {shuffledRegs2[1], shuffledRegs2[2]}, false);
    self:addStatement(self:setRegister(scope, tmpReg1, Ast.AndExpression(self:register(scope, tmpReg2), self:register(scope, tmpReg1))), {tmpReg1}, {tmpReg1, tmpReg2}, false);

    local shouldSwap2 = math.random(1, 2) == 2;
    local shuffledRegs3 = shouldSwap2 and {currentReg, finalReg} or {finalReg, currentReg};
    self:addStatement(self:setRegister(scope, tmpReg2, Ast[shouldSwap2 and "GreaterThanOrEqualsExpression" or "LessThanOrEqualsExpression"](self:register(scope, shuffledRegs3[1]), self:register(scope, shuffledRegs3[2]))), {tmpReg2}, {shuffledRegs3[1], shuffledRegs3[2]}, false);

    self:addStatement(self:setRegister(scope, tmpReg2, Ast.AndExpression(self:register(scope, incrementIsNegReg), self:register(scope, tmpReg2))), {tmpReg2}, {tmpReg2, incrementIsNegReg}, false);
    self:addStatement(self:setRegister(scope, tmpReg1, Ast.OrExpression(self:register(scope, tmpReg2), self:register(scope, tmpReg1))), {tmpReg1}, {tmpReg1, tmpReg2}, false);
    self:freeRegister(tmpReg2);
    tmpReg2 = self:compileExpression(Ast.NumberExpression(innerBlock.id), funcDepth, 1)[1];
    self:addStatement(self:setRegister(scope, self.POS_REGISTER, Ast.AndExpression(self:register(scope, tmpReg1), self:register(scope, tmpReg2))), {self.POS_REGISTER}, {tmpReg1, tmpReg2}, false);
    self:freeRegister(tmpReg2);
    self:freeRegister(tmpReg1);
    tmpReg2 = self:compileExpression(Ast.NumberExpression(finalBlock.id), funcDepth, 1)[1];
    self:addStatement(self:setRegister(scope, self.POS_REGISTER, Ast.OrExpression(self:register(scope, self.POS_REGISTER), self:register(scope, tmpReg2))), {self.POS_REGISTER}, {self.POS_REGISTER, tmpReg2}, false);
    self:freeRegister(tmpReg2);

    self:setActiveBlock(innerBlock);
    scope = innerBlock.scope;
    self.registers[self.POS_REGISTER] = posState;

    local varReg = self:getVarRegister(statement.scope, statement.id, funcDepth, nil);

    if(self:isUpvalue(statement.scope, statement.id)) then
        scope:addReferenceToHigherScope(self.scope, self.allocUpvalFunction);
        self:addStatement(self:setRegister(scope, varReg, Ast.FunctionCallExpression(Ast.VariableExpression(self.scope, self.allocUpvalFunction), {})), {varReg}, {}, false);
        self:addStatement(self:setUpvalueMember(scope, self:register(scope, varReg), self:register(scope, currentReg)), {}, {varReg, currentReg}, true);
    else
        self:addStatement(self:setRegister(scope, varReg, self:register(scope, currentReg)), {varReg}, {currentReg}, false);
    end

    self:compileBlock(statement.body, funcDepth);
    self:addStatement(self:setRegister(scope, self.POS_REGISTER, Ast.NumberExpression(checkBlock.id)), {self.POS_REGISTER}, {}, false);

    self.registers[self.POS_REGISTER] = self.VAR_REGISTER;
    self:freeRegister(finalReg);
    self:freeRegister(incrementIsNegReg);
    self:freeRegister(incrementReg);
    self:freeRegister(currentReg, true);

    self.registers[self.POS_REGISTER] = posState;
    self:setActiveBlock(finalBlock);
end;
