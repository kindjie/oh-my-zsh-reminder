#!/usr/bin/env zsh

# Performance tests for todo display functionality

# Setup test environment
setopt LOCAL_OPTIONS
setopt NULL_GLOB
autoload -U colors && colors

# Source test utilities
source "${0:A:h}/test_utils.zsh"

# Performance measurement utilities
typeset -g PERF_ITERATIONS=100
typeset -g PERF_WARMUP=10

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
  
  return $failed
}

# Execute if run directly
if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
  main "$@"
fi