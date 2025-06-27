#!/usr/bin/env zsh
# dev-tools/improve-docs.zsh - Automated documentation quality improvement - Refactored with Templates

set -e

# Load shared prompt templates
script_dir="${0:A:h}"
source "$script_dir/../tests/claude_prompt_templates.zsh"

echo "🔍 Analyzing documentation quality..."
echo "🤖 Using model: $CLAUDE_MODEL"

# Check Claude availability
if ! command -v claude >/dev/null 2>&1; then
    echo "❌ Claude Code CLI not available"
    echo "Please install Claude Code CLI to use documentation improvement"
    exit 1
fi

# Find all markdown files
local md_files=($(find . -name "*.md" -not -path "./node_modules/*" 2>/dev/null))

for md_file in $md_files; do
    echo "\n📄 Evaluating: $md_file"
    
    # Evaluate quality using template system
    local evaluation=$(claude_evaluate_documentation "$md_file" "$md_file")
    
    if [[ "$evaluation" == *"QUALITY_PASS:"* ]]; then
        echo "✅ $md_file already achieves 5-star quality"
    else
        echo "📝 Quality issues found in $md_file:"
        echo "$evaluation"
        echo "\n🔧 Improving documentation..."
        
        # Use template for improvement
        local improvement_result=$(claude_improve_documentation "$evaluation" "$md_file")
        
        # Check if improvement was successful by re-evaluating
        local reevaluation=$(claude_evaluate_documentation "$md_file" "$md_file")
        if [[ "$reevaluation" == *"QUALITY_PASS:"* ]]; then
            echo "✅ Successfully improved: $md_file"
            echo "💡 REMINDER: If this modified CLAUDE.md or other memory files, Claude Code should re-read them to see the changes."
        else
            echo "❌ Failed to improve: $md_file"
            echo "Improvement result: $improvement_result"
        fi
    fi
done

echo "\n🎉 Documentation quality analysis and improvement complete!"