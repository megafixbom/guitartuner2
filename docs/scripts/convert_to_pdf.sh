#!/bin/bash
# Convert all markdown documentation files to PDF
#
# Usage: ./convert_to_pdf.sh
# Requires: pandoc, wkhtmltopdf (optional, for better quality)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(dirname "$SCRIPT_DIR")"
PDF_DIR="$DOCS_DIR/pdf"
SCREENSHOTS_DIR="$DOCS_DIR/screenshots"

# Create output directory
mkdir -p "$PDF_DIR"

echo "📄 Converting markdown files to PDF..."
echo "======================================"

# Function to convert single file
convert_to_pdf() {
  local input_file="$1"
  local filename=$(basename "$input_file" .md)
  local output_file="$PDF_DIR/${filename}.pdf"
  
  echo "  → $filename.md → $filename.pdf"
  
  # Check if pandoc is installed
  if ! command -v pandoc &> /dev/null; then
    echo "    ❌ ERROR: pandoc not found. Install with: brew install pandoc"
    return 1
  fi
  
  # Try with wkhtmltopdf for better quality, fallback to default
  if command -v wkhtmltopdf &> /dev/null; then
    pandoc "$input_file" \
      -o "$output_file" \
      --pdf-engine=wkhtmltopdf \
      --from markdown \
      --toc \
      --toc-depth 3 \
      --css "$SCRIPT_DIR/pdf_styles.css" \
      --metadata title="$filename" \
      --metadata author="GuitarTuner Team" \
      --metadata date="$(date +%Y-%m-%d)"
  else
    pandoc "$input_file" \
      -o "$output_file" \
      --from markdown \
      --toc \
      --toc-depth 3 \
      --metadata title="$filename" \
      --metadata author="GuitarTuner Team" \
      --metadata date="$(date +%Y-%m-%d)"
  fi
  
  echo "    ✓ Created: $output_file"
}

# Convert main documentation files
for file in "$DOCS_DIR"/*.md; do
  if [ -f "$file" ]; then
    convert_to_pdf "$file"
  fi
done

# Convert root-level documentation
for file in "$DOCS_DIR"/../BPM_DETECTION_GUIDE.md "$DOCS_DIR"/../CHORD_DETECTION_GUIDE.md "$DOCS_DIR"/../USER_GUIDE.md "$DOCS_DIR"/../IMPLEMENTATION_STATUS.md; do
  if [ -f "$file" ]; then
    convert_to_pdf "$file"
  fi
done

echo ""
echo "======================================"
echo "✅ PDF conversion complete!"
echo "Output directory: $PDF_DIR"
echo ""
echo "📊 Files created:"
ls -lh "$PDF_DIR"/*.pdf
