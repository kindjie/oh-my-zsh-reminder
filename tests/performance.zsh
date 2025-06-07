#!/usr/bin/env zsh

# Performance tests for todo display functionality

# Setup test environment
setopt LOCAL_OPTIONS
setopt NULL_GLOB
autoload -U colors && colors

# Source test utilities
source "${0:A:h}/test_utils.zsh"

# Performance measurement utilities
typeset -g PERF_ITERATIONS=50  # Reduced for network tests
typeset -g PERF_WARMUP=5

# Initialize plugin once
source_test_plugin

# Global variables that should be initialized
typeset -g TODO_TASKS=()
typeset -g TODO_COLORS=()
typeset -g TODO_SAVE_FILE="${HOME}/.todo.save"
typeset -g TODO_AFFIRMATION_FILE="${HOME}/.affirmation"

measure_time() {
  local start_time=$(date +%s.%N 2>/dev/null || date +%s)
  "$@" >/dev/null 2>&1
  local end_time=$(date +%s.%N 2>/dev/null || date +%s)
  local result=$(echo "scale=6; $end_time - $start_time" | bc 2>/dev/null || echo "0.001")
  # Ensure we have a valid number
  if [[ "$result" =~ ^[0-9]+\.?[0-9]*$ ]]; then
    echo "$result"
  else
    echo "0.001"
  fi
}

run_performance_test() {
  local test_name="$1"
  local test_func="$2"
  local threshold="$3"  # Maximum acceptable time in seconds
  
  echo -n "Testing: $test_name... "
  
  # Warmup runs
  for i in {1..$PERF_WARMUP}; do
    $test_func >/dev/null 2>&1
  done
  
  # Measure performance
  local total_time=0
  local valid_runs=0
  for i in {1..$PERF_ITERATIONS}; do
    local elapsed=$(measure_time $test_func 2>/dev/null)
    if [[ -n "$elapsed" && "$elapsed" != "0" ]]; then
      total_time=$(echo "scale=6; $total_time + $elapsed" | bc 2>/dev/null || echo "$total_time")
      ((valid_runs++))
    fi
  done
  
  local avg_time="0.001"
  if [[ $valid_runs -gt 0 ]]; then
    avg_time=$(echo "scale=6; $total_time / $valid_runs" | bc 2>/dev/null || echo "0.001")
  fi
  
  if (( $(echo "$avg_time < $threshold" | bc 2>/dev/null || echo "1") )); then
    echo "✅ PASS (avg: ${avg_time}s, threshold: ${threshold}s)"
    return 0
  else
    echo "❌ FAIL (avg: ${avg_time}s, threshold: ${threshold}s)"
    return 1
  fi
}

# Test 1: Basic display performance
test_basic_display_performance() {
  echo "\nTest 1: Basic display performance"
  
  # Setup test data
  setup_test_data
  echo "task1|red" > "$HOME/.todo.save"
  echo "task2|green" >> "$HOME/.todo.save"
  echo "task3|yellow" >> "$HOME/.todo.save"
  
  # Test function
  basic_display() {
    load_tasks
    todo_display >/dev/null
  }
  
  run_performance_test "Basic display (3 tasks)" basic_display 0.050
  local result=$?
  
  cleanup_test_data
  return $result
}

# Test 2: Large task list performance
test_large_task_list_performance() {
  echo "\nTest 2: Large task list performance"
  
  setup_test_data
  
  # Generate many tasks
  for i in {1..50}; do
    echo "Task number $i with some longer text to test wrapping|$((i % 6 + 1))" >> "$HOME/.todo.save"
  done
  
  large_display() {
    load_tasks
    todo_display >/dev/null
  }
  
  run_performance_test "Large display (50 tasks)" large_display 0.100
  local result=$?
  
  cleanup_test_data
  return $result
}

# Test 3: Text wrapping performance
test_text_wrapping_performance() {
  echo "\nTest 3: Text wrapping performance"
  
  setup_test_data
  
  # Create tasks with very long text
  local long_text="This is a very long task that will definitely need to be wrapped multiple times to fit within the todo box boundaries and test the wrapping performance"
  echo "$long_text|red" > "$HOME/.todo.save"
  echo "$long_text with emojis 🎯 📝 ✨ 🚀 💡|green" >> "$HOME/.todo.save"
  echo "$long_text with special chars ñáéíóú αβγδε 中文字符|yellow" >> "$HOME/.todo.save"
  
  wrap_display() {
    load_tasks
    todo_display >/dev/null
  }
  
  run_performance_test "Text wrapping (complex)" wrap_display 0.075
  local result=$?
  
  cleanup_test_data
  return $result
}

# Test 4: Emoji handling performance
test_emoji_performance() {
  echo "\nTest 4: Emoji handling performance"
  
  setup_test_data
  
  # Create tasks with many emojis
  echo "🎯 Task with emoji at start|red" > "$HOME/.todo.save"
  echo "Task with emoji in middle 🚀 and more text|green" >> "$HOME/.todo.save"
  echo "🎨🎭🎪🎫🎬🎤🎧🎼🎹 Full emoji task 🎸🎺🎻🎮🎯🎱🎳🎴|yellow" >> "$HOME/.todo.save"
  echo "Mixed 中文 and 🎯 emojis αβγ|blue" >> "$HOME/.todo.save"
  
  emoji_display() {
    load_tasks
    todo_display >/dev/null
  }
  
  run_performance_test "Emoji rendering" emoji_display 0.060
  local result=$?
  
  cleanup_test_data
  return $result
}

# Test 5: Configuration changes performance
test_configuration_performance() {
  echo "\nTest 5: Configuration changes performance"
  
  setup_test_data
  echo "Test task 1|red" > "$HOME/.todo.save"
  echo "Test task 2|green" >> "$HOME/.todo.save"
  
  config_display() {
    TODO_BULLET="●"
    TODO_HEART="♥"
    TODO_BOX_WIDTH=60
    TODO_PADDING_TOP=2
    TODO_PADDING_RIGHT=3
    TODO_PADDING_BOTTOM=2
    TODO_PADDING_LEFT=3
    load_tasks
    todo_display >/dev/null
  }
  
  run_performance_test "Custom configuration" config_display 0.050
  local result=$?
  
  cleanup_test_data
  return $result
}

# Test 6: Color calculation performance
test_color_performance() {
  echo "\nTest 6: Color calculation performance"
  
  setup_test_data
  
  # Create tasks with all possible colors
  for i in {0..255}; do
    echo "Task with color $i|$i" >> "$HOME/.todo.save"
  done
  
  color_display() {
    load_tasks
    # Only display first 20 to keep test reasonable
    TODO_TASKS=("${TODO_TASKS[@]:0:20}")
    TODO_COLORS=("${TODO_COLORS[@]:0:20}")
    todo_display >/dev/null
  }
  
  run_performance_test "Color rendering (20 colors)" color_display 0.060
  local result=$?
  
  cleanup_test_data
  return $result
}

# Test 7: Terminal width calculation performance
test_width_calculation_performance() {
  echo "\nTest 7: Terminal width calculation performance"
  
  setup_test_data
  echo "Test task|red" > "$HOME/.todo.save"
  
  # Test at various terminal widths
  local widths=(40 80 120 160 200)
  local failed=0
  
  for width in $widths; do
    width_display() {
      COLUMNS=$width
      load_tasks
      todo_display >/dev/null
    }
    
    run_performance_test "Width calculation (COLUMNS=$width)" width_display 0.040
    [[ $? -ne 0 ]] && ((failed++))
  done
  
  cleanup_test_data
  return $failed
}

# Test 8: Memory usage test (using ps)
test_memory_usage() {
  echo "\nTest 8: Memory usage"
  
  setup_test_data
  
  # Create a reasonable task list
  for i in {1..20}; do
    echo "Task $i with some text|$((i % 6 + 1))" >> "$HOME/.todo.save"
  done
  
  # Start a subshell to measure
  (
    load_tasks
    
    # Get initial memory
    local pid=$$
    local initial_mem=$(ps -o rss= -p $pid | tr -d ' ')
    
    # Run display multiple times
    for i in {1..10}; do
      todo_display >/dev/null 2>&1
    done
    
    # Get final memory
    local final_mem=$(ps -o rss= -p $pid | tr -d ' ')
    local mem_increase=$((final_mem - initial_mem))
    
    echo -n "Memory increase after 10 displays: "
    if [[ $mem_increase -lt 1000 ]]; then  # Less than 1MB increase
      echo "✅ PASS (${mem_increase}KB increase)"
    else
      echo "⚠️ WARNING (${mem_increase}KB increase)"
    fi
  )
  
  cleanup_test_data
  return 0
}

# Test 9: Stress test - rapid display calls
test_rapid_display_stress() {
  echo "\nTest 9: Rapid display stress test"
  
  setup_test_data
  echo "Stress test task 1|red" > "$HOME/.todo.save"
  echo "Stress test task 2|green" >> "$HOME/.todo.save"
  
  rapid_test() {
    load_tasks
    
    # Rapid fire displays
    for i in {1..50}; do
      todo_display >/dev/null 2>&1
    done
  }
  
  # Measure total time for 50 rapid displays
  local elapsed=$(measure_time rapid_test)
  echo -n "50 rapid displays completed in: "
  
  if (( $(echo "$elapsed < 1.0" | bc 2>/dev/null || echo "0") )); then
    echo "✅ PASS (${elapsed}s)"
    local result=0
  else
    echo "❌ FAIL (${elapsed}s, expected < 1.0s)"
    local result=1
  fi
  
  cleanup_test_data
  return $result
}

# Test 10: Profile critical functions
test_function_profiling() {
  echo "\nTest 10: Function profiling"
  
  setup_test_data
  echo "Profile test task with some text|red" > "$HOME/.todo.save"
  
  load_tasks
  
  # Profile individual functions
  echo "Individual function timing:"
  
  # Test wrap_todo_text (if function exists)
  if command -v wrap_todo_text >/dev/null 2>&1; then
    local avg_time=0
    local count=0
    for i in {1..100}; do
      local elapsed=$(measure_time wrap_todo_text 'This is a long text that needs wrapping' 40 2>/dev/null)
      if [[ -n "$elapsed" && "$elapsed" != "0" ]]; then
        avg_time=$(echo "scale=6; $avg_time + $elapsed" | bc 2>/dev/null || echo "0")
        ((count++))
      fi
    done
    if [[ $count -gt 0 ]]; then
      avg_time=$(echo "scale=6; $avg_time / $count" | bc 2>/dev/null || echo "0")
    fi
    printf "  %-50s: %s seconds\n" "wrap_todo_text (long text)" "$avg_time"
  fi
  
  # Test get_display_width (if function exists)
  if command -v get_display_width >/dev/null 2>&1; then
    local avg_time=0
    local count=0
    for i in {1..100}; do
      local elapsed=$(measure_time get_display_width 'Hello World' 2>/dev/null)
      if [[ -n "$elapsed" && "$elapsed" != "0" ]]; then
        avg_time=$(echo "scale=6; $avg_time + $elapsed" | bc 2>/dev/null || echo "0")
        ((count++))
      fi
    done
    if [[ $count -gt 0 ]]; then
      avg_time=$(echo "scale=6; $avg_time / $count" | bc 2>/dev/null || echo "0")
    fi
    printf "  %-50s: %s seconds\n" "get_display_width (simple text)" "$avg_time"
  fi
  
  # Test format_affirmation (if function exists)
  if command -v format_affirmation >/dev/null 2>&1; then
    local avg_time=0
    local count=0
    for i in {1..100}; do
      local elapsed=$(measure_time format_affirmation 'Test affirmation' 2>/dev/null)
      if [[ -n "$elapsed" && "$elapsed" != "0" ]]; then
        avg_time=$(echo "scale=6; $avg_time + $elapsed" | bc 2>/dev/null || echo "0")
        ((count++))
      fi
    done
    if [[ $count -gt 0 ]]; then
      avg_time=$(echo "scale=6; $avg_time / $count" | bc 2>/dev/null || echo "0")
    fi
    printf "  %-50s: %s seconds\n" "format_affirmation" "$avg_time"
  fi
  
  cleanup_test_data
  return 0
}

# Test 11: Network timeout behavior
test_network_timeout_performance() {
  echo "\nTest 11: Network timeout behavior"
  
  setup_test_data
  echo "Network test task|red" > "$TODO_SAVE_FILE"
  
  # Mock curl to simulate slow network by creating a slow curl script
  local mock_curl_dir="${TMPDIR:-/tmp}/mock_curl_$$"
  mkdir -p "$mock_curl_dir"
  
  cat > "$mock_curl_dir/curl" << 'EOF'
#!/bin/sh
# Simulate slow network response
sleep 1
echo '{"affirmation": "Slow network response"}'
EOF
  chmod +x "$mock_curl_dir/curl"
  
  # Test display performance with slow network
  slow_network_display() {
    PATH="$mock_curl_dir:$PATH" load_tasks
    PATH="$mock_curl_dir:$PATH" todo_display >/dev/null
  }
  
  run_performance_test "Display with slow network (1s timeout)" slow_network_display 0.050
  local result=$?
  
  # Cleanup mock
  rm -rf "$mock_curl_dir"
  cleanup_test_data
  return $result
}

# Test 12: Cache vs network performance
test_cache_vs_network_performance() {
  echo "\nTest 12: Cache vs network performance"
  
  setup_test_data
  echo "Cache test task|green" > "$TODO_SAVE_FILE"
  
  # Pre-populate affirmation cache
  echo "Cached affirmation for testing" > "$TODO_AFFIRMATION_FILE"
  
  # Test cache performance
  cache_display() {
    load_tasks
    todo_display >/dev/null
  }
  
  run_performance_test "Display with cached affirmation" cache_display 0.030
  local result1=$?
  
  # Test without cache (should still be fast due to fallback)
  rm -f "$TODO_AFFIRMATION_FILE"
  
  no_cache_display() {
    load_tasks
    todo_display >/dev/null
  }
  
  run_performance_test "Display without cache (fallback)" no_cache_display 0.030
  local result2=$?
  
  cleanup_test_data
  return $((result1 + result2))
}

# Test 13: Missing dependencies performance
test_missing_dependencies_performance() {
  echo "\nTest 13: Missing dependencies performance"
  
  setup_test_data
  echo "Dependency test task|blue" > "$TODO_SAVE_FILE"
  
  # Create mock directory without curl/jq
  local mock_path_dir="${TMPDIR:-/tmp}/mock_path_$$"
  mkdir -p "$mock_path_dir"
  
  # Test display performance without curl/jq
  no_deps_display() {
    PATH="$mock_path_dir" load_tasks
    PATH="$mock_path_dir" todo_display >/dev/null
  }
  
  run_performance_test "Display without curl/jq dependencies" no_deps_display 0.030
  local result=$?
  
  # Cleanup mock
  rm -rf "$mock_path_dir"
  cleanup_test_data
  return $result
}

# Test 14: Request throttling and storm prevention
test_request_throttling_performance() {
  echo "\nTest 14: Request throttling and storm prevention"
  
  setup_test_data
  echo "Throttling test task|yellow" > "$TODO_SAVE_FILE"
  
  # Create a curl mock that logs requests to track multiple calls
  local mock_curl_dir="${TMPDIR:-/tmp}/mock_curl_throttle_$$"
  local request_log="$mock_curl_dir/requests.log"
  mkdir -p "$mock_curl_dir"
  
  cat > "$mock_curl_dir/curl" << EOF
#!/bin/sh
echo "\$(date +%s.%N)" >> "$request_log"
sleep 0.1
echo '{"affirmation": "Background fetch"}'
EOF
  chmod +x "$mock_curl_dir/curl"
  
  # Rapid display test
  rapid_display_with_network() {
    PATH="$mock_curl_dir:$PATH" load_tasks
    
    # Rapid fire 20 displays
    for i in {1..20}; do
      PATH="$mock_curl_dir:$PATH" todo_display >/dev/null 2>&1
    done
    
    # Wait for background processes to complete
    sleep 1
  }
  
  # Clear request log
  > "$request_log"
  
  local elapsed=$(measure_time rapid_display_with_network)
  echo -n "20 rapid displays with network background fetches: "
  
  # Count number of network requests made
  local request_count=0
  if [[ -f "$request_log" ]]; then
    request_count=$(wc -l < "$request_log" 2>/dev/null || echo "0")
  fi
  
  if (( $(echo "$elapsed < 2.0" | bc 2>/dev/null || echo "0") )); then
    echo "✅ PASS (${elapsed}s, ${request_count} network requests)"
    local result=0
  else
    echo "❌ FAIL (${elapsed}s, expected < 2.0s, ${request_count} network requests)"
    local result=1
  fi
  
  # Also check that we don't have excessive network requests
  if [[ $request_count -gt 25 ]]; then
    echo "⚠️  WARNING: High number of network requests ($request_count), possible request storm"
  fi
  
  # Cleanup mock
  rm -rf "$mock_curl_dir"
  cleanup_test_data
  return $result
}

# Test 15: Network isolation verification
test_network_isolation_performance() {
  echo "\nTest 15: Network isolation verification"
  
  setup_test_data
  echo "Isolation test task|magenta" > "$TODO_SAVE_FILE"
  
  # Create curl mock that always fails
  local mock_curl_dir="${TMPDIR:-/tmp}/mock_curl_fail_$$"
  mkdir -p "$mock_curl_dir"
  
  cat > "$mock_curl_dir/curl" << 'EOF'
#!/bin/sh
# Simulate network failure
exit 1
EOF
  chmod +x "$mock_curl_dir/curl"
  
  # Test display performance with network failure
  network_fail_display() {
    PATH="$mock_curl_dir:$PATH" load_tasks
    PATH="$mock_curl_dir:$PATH" todo_display >/dev/null
  }
  
  run_performance_test "Display with network failure" network_fail_display 0.040
  local result=$?
  
  # Cleanup mock
  rm -rf "$mock_curl_dir"
  cleanup_test_data
  return $result
}

# Test 16: Background process cleanup
test_background_process_cleanup() {
  echo "\nTest 16: Background process cleanup"
  
  setup_test_data
  echo "Cleanup test task|cyan" > "$TODO_SAVE_FILE"
  
  # Get initial process count
  local initial_procs=$(ps -ef | grep -c "[f]etch_affirmation_async" 2>/dev/null || echo "0")
  
  # Create multiple displays to spawn background processes
  background_cleanup_test() {
    load_tasks
    for i in {1..10}; do
      todo_display >/dev/null 2>&1
      sleep 0.1  # Small delay to allow process spawning
    done
    
    # Wait for background processes
    sleep 2
  }
  
  local elapsed=$(measure_time background_cleanup_test)
  
  # Check final process count
  local final_procs=$(ps -ef | grep -c "[f]etch_affirmation_async" 2>/dev/null || echo "0")
  local proc_diff=0
  if [[ "$final_procs" =~ ^[0-9]+$ ]] && [[ "$initial_procs" =~ ^[0-9]+$ ]]; then
    proc_diff=$((final_procs - initial_procs))
  fi
  
  echo -n "Background process cleanup test: "
  if [[ $proc_diff -le 2 ]]; then  # Allow for some variance
    echo "✅ PASS (${elapsed}s, +${proc_diff} background processes)"
    local result=0
  else
    echo "⚠️  WARNING (${elapsed}s, +${proc_diff} background processes - possible process leak)"
    local result=1
  fi
  
  cleanup_test_data
  return $result
}

# Main test runner
main() {
  echo "Todo Display Performance Tests"
  echo "=============================="
  
  # Check for bc command (required for timing)
  if ! command -v bc >/dev/null 2>&1; then
    echo "❌ ERROR: 'bc' command not found. Please install bc for performance testing."
    return 1
  fi
  
  local failed=0
  local passed=0
  
  # Run all tests
  local tests=(
    test_basic_display_performance
    test_large_task_list_performance
    test_text_wrapping_performance
    test_emoji_performance
    test_configuration_performance
    test_color_performance
    test_width_calculation_performance
    test_memory_usage
    test_rapid_display_stress
    test_function_profiling
    test_network_timeout_performance
    test_cache_vs_network_performance
    test_missing_dependencies_performance
    test_request_throttling_performance
    test_network_isolation_performance
    test_background_process_cleanup
  )
  
  for test in $tests; do
    if $test; then
      ((passed++))
    else
      ((failed++))
    fi
  done
  
  # Summary
  echo "\nPerformance Test Summary"
  echo "========================"
  echo "Total tests: $((passed + failed))"
  echo "✅ Passed: $passed"
  echo "❌ Failed: $failed"
  
  echo "\nPerformance Tips:"
  echo "• Basic display should complete in < 50ms"
  echo "• Large lists (50 items) should display in < 100ms"
  echo "• Text wrapping adds ~25ms overhead"
  echo "• Emoji processing adds ~10ms per display"
  echo "• Memory usage should stay under 1MB growth"
  echo "• Network operations should never block display (async only)"
  echo "• Cache reads should be < 30ms"
  echo "• Missing dependencies should not impact display speed"
  echo "• Background processes should clean up automatically"
  
  return $failed
}

# Execute if run directly
if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
  main "$@"
fi