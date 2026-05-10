#!/usr/bin/env python3
"""
WeAreDevs / Prometheus Lua VM Devirtualizer
============================================
Static analysis of the Prometheus VM — extracts and decodes ALL blocks including
control flow (if/else, for, while).

This is NOT an env logger. It parses the VM dispatch tree structure to extract
the actual operations performed in each block, then reconstructs the source.

Usage:
    python3 devirtualize.py <obfuscated.lua> [output.lua]
"""

import re
import sys
import os


class LuaTokenizer:
    """Simple Lua tokenizer for parsing if/else/end structure"""

    KEYWORDS = {'if', 'then', 'else', 'elseif', 'end', 'while', 'do',
                'for', 'function', 'local', 'return', 'repeat', 'until',
                'and', 'or', 'not', 'in', 'nil', 'true', 'false', 'break'}

    def __init__(self, code):
        self.code = code
        self.pos = 0
        self.length = len(code)

    def peek_word(self):
        """Look ahead for the next keyword without advancing"""
        save = self.pos
        self.skip_ws()
        word = self._read_word()
        self.pos = save
        return word

    def skip_ws(self):
        while self.pos < self.length and self.code[self.pos] in ' \t\n\r':
            self.pos += 1
        # Skip comments
        if self.pos < self.length - 1 and self.code[self.pos:self.pos+2] == '--':
            # Line comment
            while self.pos < self.length and self.code[self.pos] != '\n':
                self.pos += 1
            self.skip_ws()

    def _read_word(self):
        start = self.pos
        while self.pos < self.length and (self.code[self.pos].isalnum() or self.code[self.pos] == '_'):
            self.pos += 1
        return self.code[start:self.pos]

    def find_matching_end(self, start_pos):
        """Find the 'end' that matches the if/while/for/function at start_pos"""
        self.pos = start_pos
        depth = 0
        while self.pos < self.length:
            # Skip strings
            if self.code[self.pos] == '"':
                self.pos += 1
                while self.pos < self.length and self.code[self.pos] != '"':
                    if self.code[self.pos] == '\\':
                        self.pos += 1
                    self.pos += 1
                self.pos += 1
                continue
            if self.code[self.pos] == "'":
                self.pos += 1
                while self.pos < self.length and self.code[self.pos] != "'":
                    if self.code[self.pos] == '\\':
                        self.pos += 1
                    self.pos += 1
                self.pos += 1
                continue

            # Check for keywords
            if self.code[self.pos].isalpha() or self.code[self.pos] == '_':
                word_start = self.pos
                word = self._read_word()
                if word in ('if', 'while', 'for', 'function', 'repeat'):
                    # 'function' only opens if not followed by assignment pattern
                    depth += 1
                elif word == 'end':
                    depth -= 1
                    if depth == 0:
                        return word_start
                elif word == 'until':
                    if depth > 0:
                        depth -= 1
                    if depth == 0:
                        return word_start
            else:
                self.pos += 1
        return self.length


class PrometheusDevirtualizer:
    def __init__(self, source_path):
        self.source_path = os.path.abspath(source_path)
        with open(source_path, 'r', encoding='utf-8', errors='replace') as f:
            self.source = f.read()
        self.strings = []
        self.decoded_strings = []
        self.mapping = {}
        self.accessor_offset = 0
        self.string_accessor_name = None
        self.pos_var = None
        self.env_var = None
        self.blocks = []  # list of (block_code, transition_type)

    # ========================================================================
    # STRING TABLE DECODING
    # ========================================================================
    def extract_string_table(self):
        pattern = r'local\s+(\w+)\s*=\s*\{'
        match = re.search(pattern, self.source)
        if not match:
            raise ValueError("Could not find string table")
        start = match.end()
        strings = []
        i = start
        while i < len(self.source):
            if self.source[i] == '}':
                break
            if self.source[i] == '"':
                i += 1
                s = []
                while i < len(self.source) and self.source[i] != '"':
                    if self.source[i] == '\\':
                        i += 1
                        digits = ''
                        while i < len(self.source) and self.source[i].isdigit() and len(digits) < 3:
                            digits += self.source[i]
                            i += 1
                        if digits:
                            s.append(chr(int(digits)))
                        else:
                            s.append(self.source[i])
                            i += 1
                    else:
                        s.append(self.source[i])
                        i += 1
                strings.append(''.join(s))
                i += 1
            elif self.source[i:i+2] == '""':
                strings.append('')
                i += 2
            else:
                i += 1
        self.strings = strings

    def extract_swap_operations(self):
        pattern = r'for\s+\w+,\s*(\w+)\s+in\s+ipairs\(\{((?:\{[^}]*\}[,;]?\s*)*)\}\)'
        match = re.search(pattern, self.source)
        if not match:
            return []
        pairs_str = match.group(2)
        pairs = []
        for m in re.finditer(r'\{([^}]+)\}', pairs_str):
            inner = m.group(1)
            nums = re.findall(r'(-?\d+(?:[+\-*]\(?-?\d+\)?)*)', inner)
            if len(nums) >= 2:
                a = self._eval_expr(nums[0])
                b = self._eval_expr(nums[1])
                if a is not None and b is not None:
                    pairs.append((a, b))
        return pairs

    def apply_swaps(self, swaps):
        for a, b in swaps:
            i, j = a - 1, b - 1
            while i < j:
                self.strings[i], self.strings[j] = self.strings[j], self.strings[i]
                i += 1
                j -= 1

    def extract_base64_mapping(self):
        pattern = r'do\s+local\s+(\w+)\s*=\s*\{([^}]+)\}'
        for match in re.finditer(pattern, self.source):
            content = match.group(2)
            mapping = {}
            for m in re.finditer(r'\["\\(\d{1,3})"\]\s*=\s*([^,;}\s]+)', content):
                ch = chr(int(m.group(1)))
                val = self._eval_expr(m.group(2))
                if val is not None:
                    mapping[ch] = val
            for m in re.finditer(r'\["([^"\\])"\]\s*=\s*([^,;}\s]+)', content):
                ch = m.group(1)
                val = self._eval_expr(m.group(2))
                if val is not None:
                    mapping[ch] = val
            for m in re.finditer(r'(?<!["\[\\])(\w+)\s*=\s*(-?\d[^,;}\s]*)', content):
                key = m.group(1)
                val = self._eval_expr(m.group(2))
                if val is not None and len(key) == 1:
                    mapping[key] = val
            if len(mapping) >= 60:
                self.mapping = mapping
                return
        return

    def decode_strings(self):
        decoded = []
        for s in self.strings:
            decoded.append(self._decode_b64(s))
        self.decoded_strings = decoded

    def _decode_b64(self, encoded):
        result = []
        j = 0
        E = 0
        i = 0
        while i < len(encoded):
            ch = encoded[i]
            if ch in self.mapping:
                j = j + self.mapping[ch] * (64 ** (3 - E))
                E += 1
                if E == 4:
                    E = 0
                    result.append(chr(j // 65536))
                    result.append(chr((j % 65536) // 256))
                    result.append(chr(j % 256))
                    j = 0
            elif ch == '=':
                result.append(chr(j // 65536))
                if i >= len(encoded) - 1 or encoded[i + 1] != '=':
                    result.append(chr((j % 65536) // 256))
                break
            i += 1
        return ''.join(result)

    def find_accessor(self):
        pattern = r'local\s+function\s+(\w+)\((\w+)\)\s*return\s+(\w+)\[(\w+)\s*-\s*\(([^)]+)\)\]'
        match = re.search(pattern, self.source)
        if match:
            self.string_accessor_name = match.group(1)
            self.accessor_offset = self._eval_expr(match.group(5)) or 0
            return
        pattern = r'local\s+function\s+(\w+)\((\w+)\)\s*return\s+(\w+)\[\s*\w+\s*-\s*([^]\s]+)\s*\]'
        match = re.search(pattern, self.source)
        if match:
            self.string_accessor_name = match.group(1)
            self.accessor_offset = self._eval_expr(match.group(4)) or 0

    def get_decoded_string(self, idx_expr_val):
        idx = idx_expr_val - self.accessor_offset
        if 0 <= idx < len(self.decoded_strings):
            return self.decoded_strings[idx]
        return None

    # ========================================================================
    # VM DISPATCH TREE PARSER
    # ========================================================================
    def find_vm_dispatcher(self):
        """Find the main VM dispatcher function with the while loop"""
        # The dispatcher is the function containing 'while VAR do if VAR<'
        # Find it by looking for the pattern
        pattern = r'function\((\w+)(?:,\w+)*\)\s*(?:local\s+[\w,]+\s+)?while\s+(\w+)\s+do'
        for m in re.finditer(pattern, self.source):
            first_param = m.group(1)
            while_var = m.group(2)
            # Check if there's an if VAR< right after
            after_while = self.source[m.end():m.end()+100]
            if f'if {while_var}<' in after_while or f'if {while_var}==' in after_while:
                self.pos_var = while_var
                self.dispatcher_start = m.start()
                return m.start()
        return None

    def extract_dispatch_blocks(self):
        """Extract blocks from the dispatch tree by properly parsing if/else/end"""
        if not self.pos_var:
            return

        # Find the while loop
        while_pattern = f'while {re.escape(self.pos_var)} do'
        while_match = re.search(while_pattern, self.source[self.dispatcher_start:])
        if not while_match:
            return

        while_pos = self.dispatcher_start + while_match.end()

        # Now recursively parse the if/else tree to find leaf blocks
        self._parse_if_tree(while_pos)

    def _parse_if_tree(self, start_pos):
        """Recursively parse the if-tree to extract leaf blocks"""
        code = self.source
        pos = start_pos

        # Skip whitespace
        while pos < len(code) and code[pos] in ' \t\n\r':
            pos += 1

        # Check if we have 'if POS_VAR<' or 'if POS_VAR=='
        if_pattern = f'if {re.escape(self.pos_var)}'
        if code[pos:pos+len(if_pattern)] == if_pattern:
            # This is a dispatch branch - find 'then', recurse into branches
            then_pos = code.find(' then ', pos)
            if then_pos < 0:
                then_pos = code.find(' then\n', pos)
            if then_pos < 0:
                return
            then_pos += 6  # skip ' then '

            # Find matching else/end
            else_pos, end_pos = self._find_else_end(then_pos)

            # Recurse into 'then' branch
            self._parse_if_tree(then_pos)

            # Recurse into 'else' branch
            if else_pos and else_pos < end_pos:
                self._parse_if_tree(else_pos + 5)  # skip 'else '
        else:
            # This is a LEAF block - actual code!
            # Find the end of this block (until 'else' or 'end' at the same nesting level)
            block_end = self._find_block_end(pos)
            block_code = code[pos:block_end].strip()
            if block_code:
                self.blocks.append(block_code)

    def _find_else_end(self, start_pos):
        """Find the 'else' and 'end' that close the branch starting at start_pos"""
        code = self.source
        pos = start_pos
        depth = 1  # We're inside one 'if'

        while pos < len(code):
            # Skip strings
            if code[pos] == '"':
                pos += 1
                while pos < len(code) and code[pos] != '"':
                    if code[pos] == '\\':
                        pos += 1
                    pos += 1
                pos += 1
                continue
            if code[pos] == "'":
                pos += 1
                while pos < len(code) and code[pos] != "'":
                    if code[pos] == '\\':
                        pos += 1
                    pos += 1
                pos += 1
                continue
            # Skip long strings [[...]]
            if code[pos:pos+2] == '[[':
                end_ls = code.find(']]', pos + 2)
                if end_ls > 0:
                    pos = end_ls + 2
                else:
                    pos += 2
                continue

            # Check keywords
            if code[pos].isalpha() or code[pos] == '_':
                word_start = pos
                while pos < len(code) and (code[pos].isalnum() or code[pos] == '_'):
                    pos += 1
                word = code[word_start:pos]

                if word in ('if', 'while', 'for', 'repeat'):
                    depth += 1
                elif word == 'function':
                    # Check if it's a function definition (not a reference)
                    # Look ahead for '('
                    lookahead = code[pos:pos+20].lstrip()
                    if lookahead.startswith('('):
                        depth += 1
                elif word == 'do':
                    # 'do' by itself opens a block
                    # But 'while ... do' and 'for ... do' are already counted
                    pass
                elif word == 'end':
                    depth -= 1
                    if depth == 0:
                        return (None, word_start)
                elif word == 'until':
                    depth -= 1
                    if depth == 0:
                        return (None, word_start)
                elif word == 'else' and depth == 1:
                    return (word_start, self._find_end_from(pos))
                elif word == 'elseif' and depth == 1:
                    return (word_start, self._find_end_from(pos))
            else:
                pos += 1

        return (None, len(code))

    def _find_end_from(self, pos):
        """Find the 'end' that closes from this position"""
        code = self.source
        depth = 1
        while pos < len(code):
            if code[pos] == '"':
                pos += 1
                while pos < len(code) and code[pos] != '"':
                    if code[pos] == '\\':
                        pos += 1
                    pos += 1
                pos += 1
                continue
            if code[pos] == "'":
                pos += 1
                while pos < len(code) and code[pos] != "'":
                    if code[pos] == '\\':
                        pos += 1
                    pos += 1
                pos += 1
                continue
            if code[pos].isalpha() or code[pos] == '_':
                word_start = pos
                while pos < len(code) and (code[pos].isalnum() or code[pos] == '_'):
                    pos += 1
                word = code[word_start:pos]
                if word in ('if', 'while', 'for', 'repeat'):
                    depth += 1
                elif word == 'function':
                    lookahead = code[pos:pos+20].lstrip()
                    if lookahead.startswith('('):
                        depth += 1
                elif word == 'end':
                    depth -= 1
                    if depth == 0:
                        return word_start
                elif word == 'until':
                    depth -= 1
                    if depth == 0:
                        return word_start
            else:
                pos += 1
        return len(code)

    def _find_block_end(self, start_pos):
        """Find where a leaf block ends (before 'else' or 'end' at depth 0)"""
        code = self.source
        pos = start_pos
        depth = 0

        while pos < len(code):
            if code[pos] == '"':
                pos += 1
                while pos < len(code) and code[pos] != '"':
                    if code[pos] == '\\':
                        pos += 1
                    pos += 1
                pos += 1
                continue
            if code[pos] == "'":
                pos += 1
                while pos < len(code) and code[pos] != "'":
                    if code[pos] == '\\':
                        pos += 1
                    pos += 1
                pos += 1
                continue

            if code[pos].isalpha() or code[pos] == '_':
                word_start = pos
                while pos < len(code) and (code[pos].isalnum() or code[pos] == '_'):
                    pos += 1
                word = code[word_start:pos]

                if word in ('if', 'while', 'for', 'repeat'):
                    depth += 1
                elif word == 'function':
                    lookahead = code[pos:pos+20].lstrip()
                    if lookahead.startswith('('):
                        depth += 1
                elif word == 'end':
                    if depth == 0:
                        return word_start
                    depth -= 1
                elif word == 'until':
                    if depth == 0:
                        return word_start
                    depth -= 1
                elif word == 'else' and depth == 0:
                    return word_start
                elif word == 'elseif' and depth == 0:
                    return word_start
            else:
                pos += 1

        return len(code)

    # ========================================================================
    # BLOCK DECODING
    # ========================================================================
    def decode_block(self, block_code):
        """Decode a single block: replace string accessors and simplify arithmetic"""
        result = block_code

        # Replace string accessor calls using paren-depth matching
        if self.string_accessor_name:
            result = self._replace_accessor_calls(result)

        # Simplify arithmetic in numeric contexts
        def simplify_arith(m):
            expr = m.group(0)
            val = self._eval_expr(expr)
            if val is not None:
                return str(val)
            return expr

        # Multi-pass simplification
        for _ in range(3):
            prev = result
            result = re.sub(r'-?\d+[+\-]\(?-?\d+\)?', simplify_arith, result)
            result = re.sub(r'\(\s*(-?\d+)\s*\)', r'\1', result)
            if result == prev:
                break

        return result

    def _replace_accessor_calls(self, code):
        """Replace accessor calls handling nested parentheses correctly"""
        accessor = self.string_accessor_name
        pattern = re.escape(accessor) + r'\('
        result_parts = []
        last_end = 0

        for m in re.finditer(pattern, code):
            call_start = m.start()
            paren_start = m.end()  # position after 'y('
            # Find matching closing paren
            depth = 1
            i = paren_start
            while i < len(code) and depth > 0:
                if code[i] == '(':
                    depth += 1
                elif code[i] == ')':
                    depth -= 1
                i += 1
            # expr is between paren_start and i-1
            expr = code[paren_start:i-1]
            val = self._eval_expr(expr)
            if val is not None:
                s = self.get_decoded_string(val)
                if s is not None:
                    result_parts.append(code[last_end:call_start])
                    result_parts.append(f'"{self._escape_str(s)}"')
                    last_end = i
                    continue
            # If we couldn't decode, keep original
            result_parts.append(code[last_end:i])
            last_end = i

        result_parts.append(code[last_end:])
        return ''.join(result_parts)

    def analyze_block_transition(self, block_code):
        """Determine how this block transitions to the next"""
        pv = re.escape(self.pos_var)

        # Find the LAST assignment to pos_var in the block
        # This is the block transition

        # Conditional: POS = COND and EXPR or EXPR
        cond_pattern = rf'{pv}\s*=\s*(\w+)\s+and\s+([^\s]+)\s+or\s+([^\s]+)\s*$'
        m = re.search(cond_pattern, block_code)
        if m:
            cond = m.group(1)
            true_val = self._eval_expr(m.group(2))
            false_val = self._eval_expr(m.group(3))
            return ('cond', cond, true_val, false_val)

        # POS = nil (return/exit)
        nil_pattern = rf'{pv}\s*=\s*nil'
        if re.search(nil_pattern, block_code):
            return ('return',)

        # Find last numeric assignment to POS
        # But only if it's not followed by table access or function call
        last_assign = None
        for m in re.finditer(rf'{pv}\s*=\s*(-?\d[^;\n]*)', block_code):
            val_str = m.group(1).strip()
            # Check it's purely numeric (not table access like POS[x])
            if re.match(r'^-?[\d()+\-*/ ]+$', val_str):
                val = self._eval_expr(val_str)
                if val is not None:
                    last_assign = ('jump', val)

        if last_assign:
            return last_assign

        return ('unknown',)

    # ========================================================================
    # MAIN RECONSTRUCTION
    # ========================================================================
    def reconstruct(self):
        """Full devirtualization pipeline"""
        print(f"[*] Loading: {self.source_path} ({len(self.source)} bytes)", file=sys.stderr)

        # Decode strings
        print("[*] Decoding string table...", file=sys.stderr)
        self.extract_string_table()
        swaps = self.extract_swap_operations()
        self.apply_swaps(swaps)
        self.extract_base64_mapping()
        self.decode_strings()
        self.find_accessor()
        print(f"[+] Decoded {len(self.decoded_strings)} strings, offset={self.accessor_offset}", file=sys.stderr)

        # Find VM dispatcher
        print("[*] Locating VM dispatcher...", file=sys.stderr)
        disp_pos = self.find_vm_dispatcher()
        if disp_pos is None:
            print("[-] Could not find VM dispatcher!", file=sys.stderr)
            return self._fallback_output()

        print(f"[+] Found dispatcher with position var '{self.pos_var}'", file=sys.stderr)

        # Extract blocks
        print("[*] Extracting VM blocks...", file=sys.stderr)
        self.extract_dispatch_blocks()
        print(f"[+] Extracted {len(self.blocks)} blocks", file=sys.stderr)

        # Decode and format blocks
        print("[*] Decoding block operations...", file=sys.stderr)
        output_lines = []
        output_lines.append("-- Devirtualized by WeAreDevs/Prometheus Devirtualizer")
        output_lines.append(f"-- Source: {os.path.basename(self.source_path)} ({len(self.source)} bytes)")
        output_lines.append(f"-- Blocks extracted: {len(self.blocks)}")
        output_lines.append(f"-- Decoded strings: {len(self.decoded_strings)}")
        output_lines.append("")

        # List meaningful decoded strings
        meaningful = []
        for s in self.decoded_strings:
            if s and len(s) > 1 and len(s) < 200:
                if all(32 <= ord(c) < 127 for c in s):
                    if not re.match(r'^[A-Za-z0-9]{10,}$', s):
                        meaningful.append(s)
        if meaningful:
            output_lines.append("-- String constants found:")
            for s in meaningful:
                output_lines.append(f'--   "{self._escape_str(s)}"')
            output_lines.append("")

        output_lines.append("-- " + "=" * 60)
        output_lines.append("-- DEVIRTUALIZED BLOCKS:")
        output_lines.append("-- " + "=" * 60)
        output_lines.append("")

        for i, block_code in enumerate(self.blocks):
            decoded = self.decode_block(block_code)
            transition = self.analyze_block_transition(block_code)

            # Format the block
            output_lines.append(f"-- [Block {i}]")

            # Split into readable statements
            statements = self._split_statements(decoded)
            for stmt in statements:
                output_lines.append(stmt)

            # Show transition
            if transition[0] == 'cond':
                output_lines.append(f"-- BRANCH: if {transition[1]} then goto {transition[2]} else goto {transition[3]}")
            elif transition[0] == 'jump':
                output_lines.append(f"-- GOTO: {transition[1]}")
            elif transition[0] == 'return':
                output_lines.append("-- RETURN")
            output_lines.append("")

        return '\n'.join(output_lines)

    def _split_statements(self, code):
        """Split block code into individual statements for readability"""
        # Simple split: each assignment or function call is a statement
        # Pattern: VAR=EXPR or EXPR(ARGS)
        statements = []
        current = ""
        depth = 0
        i = 0

        while i < len(code):
            ch = code[i]
            if ch == '"':
                current += ch
                i += 1
                while i < len(code) and code[i] != '"':
                    if code[i] == '\\':
                        current += code[i]
                        i += 1
                    current += code[i]
                    i += 1
                if i < len(code):
                    current += code[i]
                    i += 1
                continue
            if ch in '({[':
                depth += 1
            elif ch in ')}]':
                depth -= 1
            elif ch == ' ' and depth == 0:
                # Check if next char starts a new statement
                # New statement starts with: identifier=, identifier(, identifier.
                rest = code[i+1:i+50]
                if re.match(r'[A-Za-z_]\w*\s*[=(]', rest) or re.match(r'[A-Za-z_]\w*\s*,', rest):
                    if current.strip():
                        statements.append(current.strip())
                    current = ""
                    i += 1
                    continue

            current += ch
            i += 1

        if current.strip():
            statements.append(current.strip())

        return statements

    def _fallback_output(self):
        """If VM parsing fails, provide decoded strings at minimum"""
        lines = ["-- Could not parse VM structure"]
        lines.append("-- Decoded string constants:")
        for s in self.decoded_strings:
            if s and len(s) > 1 and all(32 <= ord(c) < 127 for c in s):
                lines.append(f'--   "{self._escape_str(s)}"')
        return '\n'.join(lines)

    # ========================================================================
    # UTILITIES
    # ========================================================================
    def _eval_expr(self, expr):
        if expr is None:
            return None
        try:
            expr = str(expr).strip()
            expr = re.sub(r'\+-', '-', expr)
            expr = re.sub(r'-\(-([^)]+)\)', r'+(\1)', expr)
            if re.match(r'^[\d+\-*/(). ]+$', expr):
                return int(eval(expr))
        except:
            pass
        return None

    def _escape_str(self, s):
        return (s.replace('\\', '\\\\').replace('"', '\\"')
                .replace('\n', '\\n').replace('\r', '\\r')
                .replace('\t', '\\t').replace('\0', '\\0'))


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None

    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found", file=sys.stderr)
        sys.exit(1)

    dev = PrometheusDevirtualizer(input_file)
    result = dev.reconstruct()

    if output_file:
        with open(output_file, 'w') as f:
            f.write(result + '\n')
        print(f"\n[+] Written to: {output_file}", file=sys.stderr)
    else:
        print(result)


if __name__ == '__main__':
    main()
