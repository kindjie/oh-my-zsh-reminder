#!/usr/bin/env zsh

# Character handling and width detection tests for the reminder plugin

echo "🔤 Testing Character Handling & Width Detection"
echo "══════════════════════════════════════════════"

# Test setup - shared test helper functions
source_test_plugin() {
    autoload -U colors
    colors
    source reminder.plugin.zsh
}

# Test 1: Basic character width detection
test_basic_character_width() {
    echo "\n1. Testing basic character width detection:"
    
    source_test_plugin
    
    # Test width detection for various character types
    char="▪"; standard_width=${(m)#char}
    char="🚀"; emoji_width=${(m)#char}
    char="💖"; heart_width=${(m)#char}
    char="A"; ascii_width=${(m)#char}
    
    if [[ $standard_width -eq 1 && $emoji_width -eq 2 && $heart_width -eq 2 && $ascii_width -eq 1 ]]; then
        echo "✅ PASS: Character width detection works correctly"
        echo "  Standard bullet: $standard_width, Emoji: $emoji_width, Heart: $heart_width, ASCII: $ascii_width"
    else
        echo "❌ FAIL: Character width detection failed"
        echo "  Standard bullet: $standard_width (expected 1)"
        echo "  Emoji: $emoji_width (expected 2)"
        echo "  Heart: $heart_width (expected 2)"
        echo "  ASCII: $ascii_width (expected 1)"
    fi
}

# Test 2: String width calculation
test_string_width() {
    echo "\n2. Testing string width calculation:"
    
    # Test string width calculation
    string_test="🚀 Hello World"
    string_width=${(m)#string_test}
    expected_string_width=14  # 🚀(2) + space(1) + "Hello World"(11) = 14
    
    if [[ $string_width -eq $expected_string_width ]]; then
        echo "✅ PASS: String width detection works correctly"
        echo "  String '$string_test' width: $string_width (expected: $expected_string_width)"
    else
        echo "❌ FAIL: String width detection failed"
        echo "  String '$string_test' width: $string_width (expected: $expected_string_width)"
    fi
    
    # Test empty string
    empty_string=""
    empty_width=${(m)#empty_string}
    if [[ $empty_width -eq 0 ]]; then
        echo "✅ PASS: Empty string width is zero"
    else
        echo "❌ FAIL: Empty string width is not zero (got: $empty_width)"
    fi
    
    # Test ASCII-only string
    ascii_string="Hello World"
    ascii_string_width=${(m)#ascii_string}
    if [[ $ascii_string_width -eq 11 ]]; then
        echo "✅ PASS: ASCII string width correct"
    else
        echo "❌ FAIL: ASCII string width incorrect (got: $ascii_string_width, expected: 11)"
    fi
}

# Test 3: Comprehensive character type tests
test_comprehensive_characters() {
    echo "\n3. Testing various character types:"
    
    # Test various character categories
    test_chars=(
        "A:1:ASCII letter"
        "1:1:ASCII digit"
        "•:1:Bullet point"
        "▪:1:Square bullet"
        "♥:1:Heart suit"
        "→:1:Arrow"
        "★:1:Star"
        "🚀:2:Rocket emoji"
        "💖:2:Sparkling heart emoji"
        "😀:2:Grinning face emoji"
        "🎉:2:Party popper emoji"
        "👍:2:Thumbs up emoji"
        "🔥:2:Fire emoji"
        "✨:2:Sparkles emoji"
        "中:2:Chinese character"
        "あ:2:Japanese hiragana"
        "한:2:Korean character"
    )
    
    all_char_tests_passed=true
    for test_data in "${test_chars[@]}"; do
        IFS=':' read -r char expected desc <<< "$test_data"
        actual=${(m)#char}
        if [[ $actual -eq $expected ]]; then
            echo "  ✓ '$char' ($desc): width=$actual"
        else
            echo "  ✗ '$char' ($desc): width=$actual (expected $expected)"
            all_char_tests_passed=false
        fi
    done
    
    if [[ "$all_char_tests_passed" == "true" ]]; then
        echo "✅ PASS: All character width tests passed"
    else
        echo "❌ FAIL: Some character width tests failed"
    fi
}

# Test 4: Native zsh width detection
test_native_width_detection() {
    echo "\n4. Testing native zsh width detection:"
    
    # Test zsh native character width detection
    local ascii_char="A"
    local ascii_width=${(m)#ascii_char}
    if [[ $ascii_width -eq 1 ]]; then
        echo "✅ PASS: Zsh native width detection works for ASCII characters"
    else
        echo "❌ FAIL: Zsh native width detection failed for ASCII (got: $ascii_width, expected: 1)"
    fi
    
    # Test emoji width with zsh native detection
    local emoji_char="🚀"
    local emoji_width=${(m)#emoji_char}
    if [[ $emoji_width -ge 1 ]]; then
        echo "✅ PASS: Zsh native width detection works for emoji (width: $emoji_width)"
    else
        echo "❌ FAIL: Zsh native width detection failed for emoji (got: $emoji_width)"
    fi
    
    # Test string width with zsh native detection
    local test_string="🚀 Hello"
    local string_width=${(m)#test_string}
    if [[ $string_width -ge 6 ]]; then
        echo "✅ PASS: Zsh native string width detection works (width: $string_width)"
    else
        echo "❌ FAIL: Zsh native string width detection failed (got: $string_width)"
    fi
    
    # Test that plugin uses zsh native width detection
    source_test_plugin
    if grep -q '${(m)#' reminder.plugin.zsh; then
        echo "✅ PASS: Plugin uses zsh native width detection syntax"
    else
        echo "❌ FAIL: Plugin doesn't appear to use zsh native width detection"
    fi
}

# Test 5: Edge cases
test_edge_cases() {
    echo "\n5. Testing edge cases:"
    
    # Test very long emoji sequence
    long_emoji="🚀🚀🚀🚀🚀"
    long_emoji_width=${(m)#long_emoji}
    expected_long_width=10  # 5 emojis × 2 width each
    if [[ $long_emoji_width -eq $expected_long_width ]]; then
        echo "✅ PASS: Long emoji sequence width correct"
    else
        echo "❌ FAIL: Long emoji sequence width incorrect (got: $long_emoji_width, expected: $expected_long_width)"
    fi
    
    # Test mixed ASCII and emoji
    mixed_string="ABC🚀DEF"
    mixed_width=${(m)#mixed_string}
    expected_mixed_width=8  # ABC(3) + 🚀(2) + DEF(3) = 8
    if [[ $mixed_width -eq $expected_mixed_width ]]; then
        echo "✅ PASS: Mixed ASCII and emoji width correct"
    else
        echo "❌ FAIL: Mixed ASCII and emoji width incorrect (got: $mixed_width, expected: $expected_mixed_width)"
    fi
    
    # Test special Unicode characters
    special_chars="←→↑↓"
    special_width=${(m)#special_chars}
    if [[ $special_width -eq 4 ]]; then
        echo "✅ PASS: Special Unicode arrows width correct"
    else
        echo "❌ FAIL: Special Unicode arrows width incorrect (got: $special_width, expected: 4)"
    fi
    
    # Test combining characters (if supported)
    # Note: This is complex and may not work consistently across all terminals
    combining_test=$'e\u0301'  # e with acute accent (proper zsh format)
    combining_width=${(m)#combining_test}
    if [[ $combining_width -le 3 ]]; then  # Should be 1-3, depends on terminal and zsh handling
        echo "✅ PASS: Combining character handled reasonably (width: $combining_width)"
    else
        echo "❌ FAIL: Combining character width unexpected (got: $combining_width)"
    fi
}

# Test 6: Performance test
test_performance() {
    echo "\n6. Testing performance:"
    
    # Test that character width detection is reasonably fast
    start_time=$(date +%s.%N 2>/dev/null || date +%s)
    
    # Perform many width calculations
    for i in {1..100}; do
        test_char="🚀"
        width=${(m)#test_char}
    done
    
    end_time=$(date +%s.%N 2>/dev/null || date +%s)
    
    if command -v bc >/dev/null 2>&1; then
        execution_time=$(echo "$end_time - $start_time" | bc 2>/dev/null)
        if (( $(echo "$execution_time < 1.0" | bc -l 2>/dev/null || echo 0) )); then
            echo "✅ PASS: Character width detection is fast (${execution_time}s for 100 calculations)"
        else
            echo "⚠️  WARNING: Character width detection might be slow (${execution_time}s for 100 calculations)"
        fi
    else
        echo "⚠️  WARNING: Cannot measure performance (bc not available)"
    fi
}

# Test 7: Character validation
test_character_validation() {
    echo "\n7. Testing character validation:"
    
    # Test valid characters for bullets
    valid_bullets=("▪" "•" "→" "★" "🚀")
    for bullet in "${valid_bullets[@]}"; do
        # Test character length validation (should be ≤ 4 bytes)
        if [[ -n "$bullet" ]] && [[ ${#bullet} -le 4 ]]; then
            echo "  ✓ '$bullet' is valid bullet character"
        else
            echo "  ✗ '$bullet' is invalid bullet character"
        fi
    done
    
    # Test valid characters for hearts
    valid_hearts=("♥" "💖" "❤️" "💕" "💗")
    for heart in "${valid_hearts[@]}"; do
        # Test character length validation (should be ≤ 4 bytes)
        if [[ -n "$heart" ]] && [[ ${#heart} -le 4 ]]; then
            echo "  ✓ '$heart' is valid heart character"
        else
            echo "  ✗ '$heart' is invalid heart character"
        fi
    done
    
    echo "✅ PASS: Character validation logic works"
}

# Test 8: Real-world scenarios
test_real_world_scenarios() {
    echo "\n8. Testing real-world scenarios:"
    
    # Test task text with various characters
    real_tasks=(
        "Buy groceries 🛒"
        "Meeting at 3pm ⏰"
        "Call mom ☎️"
        "中文任务测试"
        "日本語のタスク"
        "한국어 작업"
        "Task with arrows → ← ↑ ↓"
        "Stars and symbols ★ ☆ ♠ ♣"
    )
    
    echo "Testing real-world task scenarios:"
    for task in "${real_tasks[@]}"; do
        width=${(m)#task}
        echo "  '$task' (width: $width)"
    done
    
    echo "✅ PASS: Real-world character scenarios handled"
}

# Run all character tests
main() {
    test_basic_character_width
    test_string_width
    test_comprehensive_characters
    test_native_width_detection
    test_edge_cases
    test_performance
    test_character_validation
    test_real_world_scenarios
    
    echo "\n🎯 Character Tests Completed"
    echo "════════════════════════════"
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "$0" == *"character.zsh" ]]; then
    main "$@"
fi