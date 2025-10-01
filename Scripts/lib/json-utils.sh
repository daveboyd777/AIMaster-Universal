#!/bin/bash
# AIMaster Universal Orchestrator - JSON Utilities Library
# Cross-platform JSON parsing and manipulation utilities

# JSON utility configuration
JSON_TOOL=""
JSON_TEMP_DIR=""

function init_json_utils() {
    local temp_dir="${1:-/tmp}"
    JSON_TEMP_DIR="$temp_dir"
    
    # Detect available JSON tool
    if command -v jq >/dev/null 2>&1; then
        JSON_TOOL="jq"
    elif command -v python3 >/dev/null 2>&1; then
        JSON_TOOL="python3"
    elif command -v python >/dev/null 2>&1; then
        JSON_TOOL="python"
    elif command -v node >/dev/null 2>&1; then
        JSON_TOOL="node"
    else
        JSON_TOOL="bash"  # Fallback to bash-based parsing
        log_warn "No advanced JSON tools found, using basic bash parsing"
    fi
    
    log_debug "JSON utilities initialized with tool: $JSON_TOOL"
}

function json_validate() {
    local json_input="$1"
    local input_type="${2:-string}"  # string, file
    
    case "$JSON_TOOL" in
        "jq")
            if [[ "$input_type" == "file" ]]; then
                jq empty "$json_input" 2>/dev/null
            else
                echo "$json_input" | jq empty 2>/dev/null
            fi
            ;;
        "python3"|"python")
            local python_cmd="import json, sys; json.loads(sys.stdin.read() if '$input_type' == 'string' else open('$json_input').read())"
            if [[ "$input_type" == "file" ]]; then
                $JSON_TOOL -c "$python_cmd" < /dev/null
            else
                echo "$json_input" | $JSON_TOOL -c "$python_cmd"
            fi
            ;;
        "node")
            local node_cmd="JSON.parse(require('fs').readFileSync('$json_input', 'utf8'))"
            if [[ "$input_type" == "file" ]]; then
                node -e "$node_cmd" 2>/dev/null
            else
                echo "$json_input" | node -e "JSON.parse(require('fs').readFileSync(0, 'utf8'))" 2>/dev/null
            fi
            ;;
        "bash")
            # Basic validation - check for balanced braces
            local content="$json_input"
            [[ "$input_type" == "file" ]] && content="$(cat "$json_input")"
            
            local brace_count=0
            local bracket_count=0
            local i
            
            for ((i=0; i<${#content}; i++)); do
                case "${content:$i:1}" in
                    '{') ((brace_count++)) ;;
                    '}') ((brace_count--)) ;;
                    '[') ((bracket_count++)) ;;
                    ']') ((bracket_count--)) ;;
                esac
            done
            
            [[ $brace_count -eq 0 && $bracket_count -eq 0 ]]
            ;;
    esac
}

function json_get_value() {
    local json_input="$1"
    local json_path="$2"
    local input_type="${3:-string}"  # string, file
    local default_value="${4:-}"
    
    case "$JSON_TOOL" in
        "jq")
            local result
            if [[ "$input_type" == "file" ]]; then
                result=$(jq -r "$json_path // \"$default_value\"" "$json_input" 2>/dev/null)
            else
                result=$(echo "$json_input" | jq -r "$json_path // \"$default_value\"" 2>/dev/null)
            fi
            [[ "$result" == "null" ]] && result="$default_value"
            echo "$result"
            ;;
        "python3"|"python")
            local python_script="
import json, sys
try:
    if '$input_type' == 'file':
        data = json.load(open('$json_input'))
    else:
        data = json.loads(sys.stdin.read())
    
    # Simple path parsing (supports dot notation)
    path_parts = '$json_path'.split('.')
    value = data
    for part in path_parts:
        if part.startswith('[') and part.endswith(']'):
            # Array access
            index = int(part[1:-1])
            value = value[index]
        else:
            # Object access
            value = value.get(part, '$default_value')
            if value == '$default_value':
                break
    
    print(value if value is not None else '$default_value')
except:
    print('$default_value')
"
            if [[ "$input_type" == "file" ]]; then
                $JSON_TOOL -c "$python_script"
            else
                echo "$json_input" | $JSON_TOOL -c "$python_script"
            fi
            ;;
        "node")
            local node_script="
try {
    let data;
    if ('$input_type' === 'file') {
        data = JSON.parse(require('fs').readFileSync('$json_input', 'utf8'));
    } else {
        data = JSON.parse(require('fs').readFileSync(0, 'utf8'));
    }
    
    // Simple path parsing
    const pathParts = '$json_path'.split('.');
    let value = data;
    for (const part of pathParts) {
        if (part.startsWith('[') && part.endsWith(']')) {
            const index = parseInt(part.slice(1, -1));
            value = value[index];
        } else {
            value = value[part];
        }
        if (value === undefined) {
            value = '$default_value';
            break;
        }
    }
    console.log(value !== undefined ? value : '$default_value');
} catch (e) {
    console.log('$default_value');
}
"
            if [[ "$input_type" == "file" ]]; then
                node -e "$node_script"
            else
                echo "$json_input" | node -e "$node_script"
            fi
            ;;
        "bash")
            # Very basic bash JSON parsing - only works for simple cases
            local content="$json_input"
            [[ "$input_type" == "file" ]] && content="$(cat "$json_input")"
            
            # Simple key extraction (only works for top-level string values)
            if [[ "$json_path" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                local pattern="\"$json_path\"[[:space:]]*:[[:space:]]*\"([^\"]*)\""
                if [[ $content =~ $pattern ]]; then
                    echo "${BASH_REMATCH[1]}"
                else
                    echo "$default_value"
                fi
            else
                echo "$default_value"
            fi
            ;;
    esac
}

function json_set_value() {
    local json_input="$1"
    local json_path="$2"
    local new_value="$3"
    local input_type="${4:-string}"  # string, file
    local output_file="${5:-}"
    
    case "$JSON_TOOL" in
        "jq")
            local updated_json
            if [[ "$input_type" == "file" ]]; then
                updated_json=$(jq "$json_path = \"$new_value\"" "$json_input" 2>/dev/null)
            else
                updated_json=$(echo "$json_input" | jq "$json_path = \"$new_value\"" 2>/dev/null)
            fi
            
            if [[ -n "$output_file" ]]; then
                echo "$updated_json" > "$output_file"
            else
                echo "$updated_json"
            fi
            ;;
        "python3"|"python")
            local python_script="
import json, sys
try:
    if '$input_type' == 'file':
        with open('$json_input', 'r') as f:
            data = json.load(f)
    else:
        data = json.loads(sys.stdin.read())
    
    # Simple path setting (supports dot notation)
    path_parts = '$json_path'.split('.')
    current = data
    for i, part in enumerate(path_parts[:-1]):
        if part not in current:
            current[part] = {}
        current = current[part]
    
    # Set the final value
    final_key = path_parts[-1]
    current[final_key] = '$new_value'
    
    result = json.dumps(data, indent=2)
    if '$output_file':
        with open('$output_file', 'w') as f:
            f.write(result)
    else:
        print(result)
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
"
            if [[ "$input_type" == "file" ]]; then
                $JSON_TOOL -c "$python_script"
            else
                echo "$json_input" | $JSON_TOOL -c "$python_script"
            fi
            ;;
        *)
            log_error "JSON set operation not supported with tool: $JSON_TOOL"
            return 1
            ;;
    esac
}

function json_add_to_array() {
    local json_input="$1"
    local array_path="$2"
    local new_item="$3"
    local input_type="${4:-string}"
    
    case "$JSON_TOOL" in
        "jq")
            if [[ "$input_type" == "file" ]]; then
                jq "$array_path += [\"$new_item\"]" "$json_input"
            else
                echo "$json_input" | jq "$array_path += [\"$new_item\"]"
            fi
            ;;
        "python3"|"python")
            local python_script="
import json, sys
try:
    if '$input_type' == 'file':
        with open('$json_input', 'r') as f:
            data = json.load(f)
    else:
        data = json.loads(sys.stdin.read())
    
    # Navigate to array
    path_parts = '$array_path'.split('.')
    current = data
    for part in path_parts:
        current = current[part]
    
    # Add item to array
    current.append('$new_item')
    
    print(json.dumps(data, indent=2))
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
"
            if [[ "$input_type" == "file" ]]; then
                $JSON_TOOL -c "$python_script"
            else
                echo "$json_input" | $JSON_TOOL -c "$python_script"
            fi
            ;;
        *)
            log_error "JSON array operations not supported with tool: $JSON_TOOL"
            return 1
            ;;
    esac
}

function json_get_keys() {
    local json_input="$1"
    local object_path="${2:-.}"
    local input_type="${3:-string}"
    
    case "$JSON_TOOL" in
        "jq")
            if [[ "$input_type" == "file" ]]; then
                jq -r "$object_path | keys[]" "$json_input" 2>/dev/null
            else
                echo "$json_input" | jq -r "$object_path | keys[]" 2>/dev/null
            fi
            ;;
        "python3"|"python")
            local python_script="
import json, sys
try:
    if '$input_type' == 'file':
        with open('$json_input', 'r') as f:
            data = json.load(f)
    else:
        data = json.loads(sys.stdin.read())
    
    if '$object_path' != '.':
        path_parts = '$object_path'.split('.')
        for part in path_parts:
            data = data[part]
    
    for key in data.keys():
        print(key)
except Exception as e:
    pass
"
            if [[ "$input_type" == "file" ]]; then
                $JSON_TOOL -c "$python_script"
            else
                echo "$json_input" | $JSON_TOOL -c "$python_script"
            fi
            ;;
        *)
            log_error "JSON key extraction not supported with tool: $JSON_TOOL"
            return 1
            ;;
    esac
}

function json_pretty_print() {
    local json_input="$1"
    local input_type="${2:-string}"
    
    case "$JSON_TOOL" in
        "jq")
            if [[ "$input_type" == "file" ]]; then
                jq . "$json_input"
            else
                echo "$json_input" | jq .
            fi
            ;;
        "python3"|"python")
            local python_script="
import json, sys
try:
    if '$input_type' == 'file':
        with open('$json_input', 'r') as f:
            data = json.load(f)
    else:
        data = json.loads(sys.stdin.read())
    
    print(json.dumps(data, indent=2, sort_keys=True))
except Exception as e:
    print(f'Invalid JSON: {e}', file=sys.stderr)
"
            if [[ "$input_type" == "file" ]]; then
                $JSON_TOOL -c "$python_script"
            else
                echo "$json_input" | $JSON_TOOL -c "$python_script"
            fi
            ;;
        "node")
            local node_script="
try {
    let data;
    if ('$input_type' === 'file') {
        data = JSON.parse(require('fs').readFileSync('$json_input', 'utf8'));
    } else {
        data = JSON.parse(require('fs').readFileSync(0, 'utf8'));
    }
    console.log(JSON.stringify(data, null, 2));
} catch (e) {
    console.error('Invalid JSON:', e.message);
}
"
            if [[ "$input_type" == "file" ]]; then
                node -e "$node_script"
            else
                echo "$json_input" | node -e "$node_script"
            fi
            ;;
        *)
            # Just output as-is for bash fallback
            if [[ "$input_type" == "file" ]]; then
                cat "$json_input"
            else
                echo "$json_input"
            fi
            ;;
    esac
}

function json_minify() {
    local json_input="$1"
    local input_type="${2:-string}"
    
    case "$JSON_TOOL" in
        "jq")
            if [[ "$input_type" == "file" ]]; then
                jq -c . "$json_input"
            else
                echo "$json_input" | jq -c .
            fi
            ;;
        "python3"|"python")
            local python_script="
import json, sys
try:
    if '$input_type' == 'file':
        with open('$json_input', 'r') as f:
            data = json.load(f)
    else:
        data = json.loads(sys.stdin.read())
    
    print(json.dumps(data, separators=(',', ':')))
except Exception as e:
    print(f'Invalid JSON: {e}', file=sys.stderr)
"
            if [[ "$input_type" == "file" ]]; then
                $JSON_TOOL -c "$python_script"
            else
                echo "$json_input" | $JSON_TOOL -c "$python_script"
            fi
            ;;
        *)
            # Remove whitespace for bash fallback
            local content="$json_input"
            [[ "$input_type" == "file" ]] && content="$(cat "$json_input")"
            echo "$content" | tr -d '\n\t ' | sed 's/[[:space:]]*//g'
            ;;
    esac
}

function json_merge() {
    local json1="$1"
    local json2="$2"
    local input1_type="${3:-string}"
    local input2_type="${4:-string}"
    
    case "$JSON_TOOL" in
        "jq")
            local cmd1 cmd2
            [[ "$input1_type" == "file" ]] && cmd1="cat '$json1'" || cmd1="echo '$json1'"
            [[ "$input2_type" == "file" ]] && cmd2="cat '$json2'" || cmd2="echo '$json2'"
            
            eval "$cmd1" | jq -s '.[0] * .[1]' - <(eval "$cmd2")
            ;;
        "python3"|"python")
            local python_script="
import json, sys
try:
    if '$input1_type' == 'file':
        with open('$json1', 'r') as f:
            data1 = json.load(f)
    else:
        data1 = json.loads('$json1')
    
    if '$input2_type' == 'file':
        with open('$json2', 'r') as f:
            data2 = json.load(f)
    else:
        data2 = json.loads('$json2')
    
    # Merge dictionaries
    if isinstance(data1, dict) and isinstance(data2, dict):
        merged = {**data1, **data2}
    else:
        merged = data2  # Override if not both dicts
    
    print(json.dumps(merged, indent=2))
except Exception as e:
    print(f'Error merging JSON: {e}', file=sys.stderr)
"
            $JSON_TOOL -c "$python_script"
            ;;
        *)
            log_error "JSON merge not supported with tool: $JSON_TOOL"
            return 1
            ;;
    esac
}

function json_create_object() {
    local -n json_data=$1  # Pass associative array by reference
    
    local json_string="{"
    local first=true
    
    for key in "${!json_data[@]}"; do
        [[ "$first" == "true" ]] && first=false || json_string+=","
        json_string+="\"$key\":\"${json_data[$key]}\""
    done
    
    json_string+="}"
    echo "$json_string"
}

function json_create_array() {
    local -a array_items=("$@")
    
    local json_string="["
    local first=true
    
    for item in "${array_items[@]}"; do
        [[ "$first" == "true" ]] && first=false || json_string+=","
        json_string+="\"$item\""
    done
    
    json_string+="]"
    echo "$json_string"
}

function json_escape_string() {
    local input="$1"
    
    # Escape JSON special characters
    input="${input//\\/\\\\}"  # Backslash
    input="${input//\"/\\\"}"  # Quote
    input="${input//$'\n'/\\n}"  # Newline
    input="${input//$'\r'/\\r}"  # Carriage return
    input="${input//$'\t'/\\t}"  # Tab
    
    echo "$input"
}

function json_write_config() {
    local config_file="$1"
    shift
    
    # Create JSON config from key=value pairs
    local json_content="{\n"
    local first=true
    
    for arg in "$@"; do
        if [[ "$arg" =~ ^([^=]+)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            [[ "$first" == "true" ]] && first=false || json_content+=",\n"
            json_content+="  \"$key\": \"$(json_escape_string "$value")\""
        fi
    done
    
    json_content+="\n}"
    
    echo -e "$json_content" > "$config_file"
    
    # Validate and pretty-print if possible
    if json_validate "$config_file" "file"; then
        local pretty_json
        pretty_json=$(json_pretty_print "$config_file" "file")
        echo "$pretty_json" > "$config_file"
        log_success "JSON config written: $config_file"
    else
        log_error "Generated invalid JSON config: $config_file"
        return 1
    fi
}

# Initialize JSON utilities when loaded
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being run directly, not sourced
    init_json_utils
else
    # Script is being sourced - delay initialization
    :
fi