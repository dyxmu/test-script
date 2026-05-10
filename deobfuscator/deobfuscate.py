#!/usr/bin/env python3
"""
WeAreDevs / Prometheus Lua Deobfuscator v2.0
=============================================
Decodes obfuscated Lua files produced by https://wearedevs.net/obfuscator
which is based on Prometheus (https://github.com/prometheus-lua/Prometheus)

Features:
- Decodes custom base64 string table with shuffled alphabet
- Applies swap/shuffle operations
- Runtime VM tracing with anti-tamper bypass
- Pattern detection (for loops, while loops, variable assignments)
- Cross-references decoded constants to determine value types
- Handles both small and large obfuscated files

Usage:
    python3 deobfuscate.py <obfuscated_file.lua> [output_file.lua]
"""

import re
import sys
import os
import subprocess
import tempfile


class PrometheusDeobfuscator:
    def __init__(self, source_path):
        self.source_path = os.path.abspath(source_path)
        with open(source_path, 'r', encoding='utf-8', errors='replace') as f:
            self.source = f.read()
        self.strings = []
        self.decoded_strings = []
        self.mapping = {}
        self.accessor_offset = 0
        self.var_name = ''
        self.string_constants = set()  # strings that are actual constants in the code

    def extract_string_table(self):
        """Extract the initial string table with octal escape sequences"""
        pattern = r'local\s+(\w+)\s*=\s*\{'
        match = re.search(pattern, self.source)
        if not match:
            raise ValueError("Could not find string table definition")

        self.var_name = match.group(1)
        start = match.end()

        strings = []
        i = start
        brace_depth = 1
        while i < len(self.source) and brace_depth > 0:
            ch = self.source[i]
            if ch == '{':
                brace_depth += 1
                i += 1
            elif ch == '}':
                brace_depth -= 1
                i += 1
            elif ch == '"':
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
                            if i < len(self.source):
                                s.append(self.source[i])
                                i += 1
                    else:
                        s.append(self.source[i])
                        i += 1
                i += 1
                strings.append(''.join(s))
            else:
                i += 1

        self.strings = strings
        return strings

    def extract_swap_operations(self):
        """Extract and evaluate the swap/shuffle pairs"""
        pattern = r'for\s+\w+,\w+\s+in\s+ipairs\(\{((?:\{[^}]+\}[,;]?\s*)+)\}\)\s*do'
        match = re.search(pattern, self.source)
        if not match:
            return []

        inner = match.group(1)
        pairs = []
        for m in re.finditer(r'\{([^}]+)\}', inner):
            content = m.group(1)
            parts = re.split(r'[;,]', content)
            if len(parts) >= 2:
                val1 = self._eval_expr(parts[0].strip())
                val2 = self._eval_expr(parts[1].strip())
                if val1 is not None and val2 is not None:
                    pairs.append((val1, val2))
        return pairs

    def apply_swaps(self, swap_pairs):
        """Apply the reversal-based swap operations (1-indexed in Lua)"""
        for start_idx, end_idx in swap_pairs:
            i, j = start_idx - 1, end_idx - 1
            while i < j:
                if 0 <= i < len(self.strings) and 0 <= j < len(self.strings):
                    self.strings[i], self.strings[j] = self.strings[j], self.strings[i]
                i += 1
                j -= 1

    def extract_base64_mapping(self):
        """Extract the custom base64 character-to-value mapping table"""
        pos = self.source.find('do local')
        if pos < 0:
            raise ValueError("Could not find base64 mapping block")

        brace_start = self.source.find('{', pos)
        depth = 0
        i = brace_start
        while i < len(self.source):
            if self.source[i] == '{':
                depth += 1
            elif self.source[i] == '}':
                depth -= 1
                if depth == 0:
                    break
            i += 1

        mapping_str = self.source[brace_start + 1:i]
        mapping = {}

        # Parse bracket keys with Lua decimal escapes: ["\NNN"]=expr
        for m in re.finditer(r'\["\\(\d{1,3})"\]\s*=\s*([^,;\}\[]+)', mapping_str):
            char_code = int(m.group(1))
            char = chr(char_code)
            val = self._eval_expr(m.group(2).strip())
            if val is not None:
                mapping[char] = val

        # Parse bracket keys with literal chars: ["x"]=expr
        for m in re.finditer(r'\["([^"\\])"\]\s*=\s*([^,;\}\[]+)', mapping_str):
            key = m.group(1)
            val = self._eval_expr(m.group(2).strip())
            if val is not None:
                mapping[key] = val

        # Parse word keys: x=expr (single letter = value)
        for m in re.finditer(r'(?:^|[,;\}\s])([A-Za-z])\s*=\s*(-?[\d+\-() ]+)', mapping_str):
            key = m.group(1)
            val = self._eval_expr(m.group(2).strip())
            if val is not None:
                mapping[key] = val

        self.mapping = mapping
        return mapping

    def decode_strings(self):
        """Decode all strings using the custom base64 mapping"""
        decoded = []
        for s in self.strings:
            if s:
                decoded.append(self._decode_b64(s))
            else:
                decoded.append('')
        self.decoded_strings = decoded

        # Build set of known string constants (non-API strings)
        api_strings = {
            'gsub', 'byte', 'concat', 'table', '__index', 'setmetatable',
            'pcall', 'random', 'math', '__gc', 'unpack', 'string', 'gmatch',
            '__len', '__le', '__lt', '__eq', '__add', '__sub', '__mul', '__div',
            '__mod', '__pow', '__unm', '__concat', '__newindex', '__call',
            '__tostring', 'tonumber', 'print', 'char', 'tostring', '__metatable',
            'error', 'floor', 'len', 'remove', 'insert', 'sort', 'pairs',
            'ipairs', 'next', 'rawget', 'rawset', 'select', 'type',
            'setfenv', 'getfenv', 'loadstring', 'load', 'dofile', 'require',
            'coroutine', 'debug', 'io', 'os', 'sub', 'rep', 'reverse',
            'upper', 'lower', 'find', 'match', 'format', 'abs', 'ceil',
            'sqrt', 'max', 'min', 'huge', 'pi', 'sin', 'cos', 'tan',
            'create', 'resume', 'yield', 'wrap', 'status',
            'collectgarbage', 'newproxy', 'getmetatable', 'rawequal',
            'xpcall', 'assert', 'bit', 'bit32',
        }
        tamper_strings = {'Tamper Detected!', ':(%d*):', ':'}

        for s in decoded:
            if s and s not in api_strings and s not in tamper_strings:
                # Check if it's a readable user string
                if all(32 <= ord(c) < 127 for c in s) and len(s) < 100:
                    # Exclude random-looking strings (likely VM identifiers)
                    if not re.match(r'^[A-Za-z0-9]{10,}$', s):
                        self.string_constants.add(s)

        return decoded

    def extract_accessor_offset(self):
        """Extract the offset used in string accessor: N[y - offset]"""
        pattern = r'local\s+function\s+\w+\(\w+\)\s*return\s+\w+\[\w+\s*-\s*\(([^)]+)\)\]'
        match = re.search(pattern, self.source)
        if match:
            self.accessor_offset = self._eval_expr(match.group(1)) or 0
            return self.accessor_offset

        pattern = r'local\s+function\s+\w+\(\w+\)\s*return\s+\w+\[\w+-([^]\s]+)\]'
        match = re.search(pattern, self.source)
        if match:
            self.accessor_offset = self._eval_expr(match.group(1)) or 0

        return self.accessor_offset

    def execute_and_capture(self):
        """Execute the obfuscated code using full_tracer.lua for complete source reconstruction"""
        tracer_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'full_tracer.lua')

        if not os.path.exists(tracer_path):
            # Try legacy tracer
            tracer_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'tracer.lua')

        if not os.path.exists(tracer_path):
            print("[-] No tracer found, falling back to direct execution", file=sys.stderr)
            return self._direct_execute()

        try:
            # Use temp file for output
            with tempfile.NamedTemporaryFile(mode='w', suffix='.lua', delete=False) as tmp:
                tmp_output = tmp.name

            result = subprocess.run(
                ['lua5.1', tracer_path, self.source_path, tmp_output],
                capture_output=True, text=True, timeout=120
            )

            # Check if output file was created with content
            if os.path.exists(tmp_output):
                with open(tmp_output, 'r') as f:
                    content = f.read()
                os.unlink(tmp_output)
                if content.strip():
                    return content

            # If full_tracer didn't produce output, try legacy tracer
            legacy_tracer = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'tracer.lua')
            if os.path.exists(legacy_tracer) and 'full_tracer' in tracer_path:
                result = subprocess.run(
                    ['lua5.1', legacy_tracer, self.source_path],
                    capture_output=True, text=True, timeout=60
                )
                stdout = result.stdout
                if '__DEOBF_START__' in stdout and '__DEOBF_END__' in stdout:
                    start = stdout.index('__DEOBF_START__') + len('__DEOBF_START__\n')
                    end = stdout.index('__DEOBF_END__')
                    return stdout[start:end].strip()

            return self._direct_execute()
        except subprocess.TimeoutExpired:
            print("[-] Tracer timed out, falling back to direct execution", file=sys.stderr)
            if os.path.exists(tmp_output):
                os.unlink(tmp_output)
            return self._direct_execute()
        except Exception as e:
            print(f"[-] Tracer error: {e}", file=sys.stderr)
            return self._direct_execute()

    def _direct_execute(self):
        """Fallback: execute directly and capture stdout"""
        try:
            result = subprocess.run(
                ['lua5.1', self.source_path],
                capture_output=True, text=True, timeout=30
            )
            output = result.stdout.strip()
            if not output:
                return ""
            # Basic reconstruction from stdout only
            lines = []
            for line in output.split('\n'):
                lines.append(f'print("{self._escape_lua_string(line)}")')
            return '\n'.join(lines)
        except:
            return ""

    def reconstruct_source(self, traced_output):
        """Use tracer output (already reconstructed) or fall back to analysis"""
        if traced_output:
            return traced_output

        # No traced output - code doesn't produce output (e.g., UI framework)
        # Provide analysis based on decoded strings instead
        return self._analyze_from_strings()

    def _has_roblox_apis(self):
        """Check if the script uses Roblox APIs"""
        roblox_keywords = ['GetService', 'Instance', 'workspace', 'game', 'Players',
                           'RunService', 'UDim2', 'Vector3', 'CFrame', 'TweenService']
        for s in self.decoded_strings:
            if s in roblox_keywords:
                return True
        return False

    def _analyze_from_strings(self):
        """For code that doesn't produce output, analyze from decoded strings"""
        # Categorize decoded strings
        api_funcs = []
        roblox_api = []
        user_strings = []
        metamethods = []

        known_lua_api = {
            'gsub', 'byte', 'concat', 'table', 'setmetatable', 'pcall',
            'random', 'math', 'unpack', 'string', 'gmatch', 'tonumber',
            'print', 'char', 'tostring', 'error', 'floor', 'len', 'remove',
            'insert', 'sort', 'pairs', 'ipairs', 'next', 'rawget', 'rawset',
            'select', 'type', 'sub', 'rep', 'find', 'match', 'format',
            'abs', 'ceil', 'sqrt', 'max', 'min', 'upper', 'lower',
            'coroutine', 'debug', 'io', 'os', 'require', 'load', 'loadstring',
        }
        known_roblox = {
            'game', 'workspace', 'Instance', 'Enum', 'Vector2', 'Vector3',
            'CFrame', 'UDim2', 'UDim', 'Color3', 'TweenInfo', 'Drawing',
            'tick', 'wait', 'spawn', 'delay', 'warn', 'typeof',
        }

        for s in self.decoded_strings:
            if not s:
                continue
            if s in known_lua_api:
                api_funcs.append(s)
            elif s in known_roblox:
                roblox_api.append(s)
            elif s.startswith('__'):
                metamethods.append(s)
            elif all(32 <= ord(c) < 127 for c in s) and len(s) < 100:
                if not re.match(r'^[A-Za-z0-9]{10,}$', s):
                    user_strings.append(s)

        lines = []
        lines.append("-- WARNING: This code does not produce console output.")
        lines.append("-- Full source reconstruction requires VM bytecode analysis.")
        lines.append("-- Below is a structural analysis of the decoded constants.")
        lines.append("")
        lines.append("--[[ ANALYSIS RESULTS")
        lines.append("")

        if roblox_api:
            lines.append("Roblox API used:")
            for s in sorted(set(roblox_api)):
                lines.append(f"  - {s}")
            lines.append("")

        if api_funcs:
            lines.append("Lua standard library calls:")
            for s in sorted(set(api_funcs)):
                lines.append(f"  - {s}")
            lines.append("")

        if metamethods:
            lines.append("Metamethods used:")
            for s in sorted(set(metamethods)):
                lines.append(f"  - {s}")
            lines.append("")

        if user_strings:
            lines.append("User string constants (identifiers, messages, keys):")
            for s in sorted(set(user_strings)):
                lines.append(f'  - "{self._escape_lua_string(s)}"')
            lines.append("")

        lines.append("]]")
        lines.append("")
        lines.append("-- Reconstructed API usage (partial):")

        # Generate pseudo-code based on identified APIs
        if roblox_api:
            lines.append("-- This appears to be a Roblox script using:")
            if 'Drawing' in roblox_api:
                lines.append("-- - Drawing API (ESP/visuals)")
            if 'Instance' in roblox_api:
                lines.append("-- - Instance creation/manipulation")
            if 'TweenInfo' in roblox_api:
                lines.append("-- - Tween animations")

        # Check for exploit loader patterns
        exploit_checks = [s for s in user_strings if '_LOADED' in s]
        if exploit_checks:
            lines.append("")
            lines.append("-- Exploit environment detection:")
            for ec in exploit_checks:
                name = ec.replace('_LOADED', '')
                lines.append(f"-- if {ec} then return end  -- {name} already loaded")

        return '\n'.join(lines)

    def deobfuscate(self):
        """Full deobfuscation pipeline"""
        print(f"[*] Loading: {self.source_path} ({len(self.source)} bytes)", file=sys.stderr)

        # Step 1: Extract string table
        print("[*] Extracting string table...", file=sys.stderr)
        self.extract_string_table()
        print(f"[+] Found {len(self.strings)} encoded strings", file=sys.stderr)

        # Step 2: Apply swaps
        print("[*] Applying swap operations...", file=sys.stderr)
        swaps = self.extract_swap_operations()
        self.apply_swaps(swaps)
        print(f"[+] Applied {len(swaps)} swap operations", file=sys.stderr)

        # Step 3: Decode strings
        print("[*] Decoding string table...", file=sys.stderr)
        self.extract_base64_mapping()
        self.decode_strings()
        print(f"[+] Mapping has {len(self.mapping)} chars, decoded {len(self.decoded_strings)} strings", file=sys.stderr)

        # Print user-relevant constants
        if self.string_constants:
            print(f"[+] User string constants found: {self.string_constants}", file=sys.stderr)

        # Step 4: Get accessor offset
        self.extract_accessor_offset()

        # Step 5: Execute and capture output
        print("[*] Executing obfuscated code...", file=sys.stderr)
        output = self.execute_and_capture()
        if output:
            print(f"[+] Captured {len(output)} bytes of output", file=sys.stderr)
        else:
            print("[-] No output captured", file=sys.stderr)

        # Step 6: Reconstruct source
        print("[*] Reconstructing source code...", file=sys.stderr)
        reconstructed = self.reconstruct_source(output)

        # Step 7: Build final output
        header = "-- Deobfuscated by WeAreDevs/Prometheus Deobfuscator\n"
        header += f"-- Original file: {os.path.basename(self.source_path)}\n"
        header += f"-- String constants: {len(self.decoded_strings)}\n"
        api_names = [s for s in self.decoded_strings if s and s.isalpha() and 3 <= len(s) <= 15 and s[0].islower() and s.isascii()]
        # Filter out random-looking strings
        api_names = [s for s in api_names if not (len(s) > 8 and any(c.isupper() for c in s[1:]))]
        header += f"-- Decoded API calls: {', '.join(api_names)}\n"
        header += "\n"

        return header + reconstructed

    def _decode_b64(self, encoded):
        """Decode a string using the custom base64 mapping"""
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
                    n1 = j // 65536
                    n2 = (j % 65536) // 256
                    n3 = j % 256
                    result.append(chr(n1))
                    result.append(chr(n2))
                    result.append(chr(n3))
                    j = 0
            elif ch == '=':
                result.append(chr(j // 65536))
                if i >= len(encoded) - 1 or encoded[i + 1] != '=':
                    result.append(chr((j % 65536) // 256))
                break
            i += 1
        return ''.join(result)

    def _eval_expr(self, expr):
        """Evaluate a Lua arithmetic expression"""
        try:
            expr = expr.strip()
            expr = re.sub(r'\+-', '-', expr)
            expr = re.sub(r'-\(\-([^)]+)\)', r'+(\1)', expr)
            return int(eval(expr))
        except:
            return None

    def _escape_lua_string(self, s):
        """Escape a string for Lua source"""
        return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '\\r').replace('\t', '\\t')


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        print("\nUsage: python3 deobfuscate.py <obfuscated_file.lua> [output_file.lua]")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None

    if not os.path.exists(input_file):
        print(f"Error: File not found: {input_file}", file=sys.stderr)
        sys.exit(1)

    deobf = PrometheusDeobfuscator(input_file)
    result = deobf.deobfuscate()

    if output_file:
        with open(output_file, 'w') as f:
            f.write(result + '\n')
        print(f"\n[+] Output written to: {output_file}", file=sys.stderr)
    else:
        print("\n" + "=" * 60, file=sys.stderr)
        print(result)


if __name__ == '__main__':
    main()
