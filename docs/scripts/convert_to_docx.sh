#!/bin/bash
# Convert all markdown documentation files to DOCX (Microsoft Word format)
#
# Usage: ./convert_to_docx.sh
# Requires: pandoc

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(dirname "$SCRIPT_DIR")"
DOCX_DIR="$DOCS_DIR/docx"

# Create output directory
mkdir -p "$DOCX_DIR"

echo "📝 Converting markdown files to DOCX..."
echo "======================================="

# Function to convert single file
convert_to_docx() {
  local input_file="$1"
  local filename=$(basename "$input_file" .md)
  local output_file="$DOCX_DIR/${filename}.docx"
  
  echo "  → $filename.md → $filename.docx"
  
  # Check if pandoc is installed
  if ! command -v pandoc &> /dev/null; then
    echo "    ❌ ERROR: pandoc not found. Install with: brew install pandoc"
    return 1
  fi
  
  pandoc "$input_file" \
    -o "$output_file" \
    --from markdown \
    --toc \
    --toc-depth 3 \
    --metadata title="$filename" \
    --metadata author="GuitarTuner Team" \
    --metadata date="$(date +%Y-%m-%d)"
  
  echo "    ✓ Created: $output_file"
}

# Convert main documentation files
for file in "$DOCS_DIR"/*.md; do
  if [ -f "$file" ]; then
    convert_to_docx "$file"
  fi
done

# Convert root-level documentation
for file in "$DOCS_DIR"/../BPM_DETECTION_GUIDE.md "$DOCS_DIR"/../CHORD_DETECTION_GUIDE.md "$DOCS_DIR"/../USER_GUIDE.md "$DOCS_DIR"/../IMPLEMENTATION_STATUS.md; do
  if [ -f "$file" ]; then
    convert_to_docx "$file"
  fi
done

echo ""
echo "======================================="
echo "✅ DOCX conversion complete!"
echo "Output directory: $DOCX_DIR"
echo ""
echo "📊 Files created:"
ls -lh "$DOCX_DIR"/*.docx
