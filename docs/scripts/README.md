# Documentation Scripts

This folder contains scripts for converting markdown documentation to PDF and DOCX formats.

## Prerequisites

### Option 1: Pandoc (Recommended)

Pandoc is a universal document converter supporting 50+ formats.

**Install on macOS:**
```bash
brew install pandoc
```

**Install on Windows:**
```powershell
choco install pandoc
```

**Install on Linux:**
```bash
sudo apt-get install pandoc
```

### Option 2: wkhtmltopdf

For PDF generation with CSS support.

**Install:**
```bash
# macOS
brew install wkhtmltopdf

# Ubuntu/Debian
sudo apt-get install wkhtmltopdf

# Windows
# Download from https://wkhtmltopdf.org/
```

## Conversion Scripts

### Convert to PDF (Using Pandoc)

```bash
./convert_to_pdf.sh
```

This converts all markdown files in `docs/` to PDF format with proper styling.

### Convert to DOCX (Using Pandoc)

```bash
./convert_to_docx.sh
```

This converts all markdown files to Microsoft Word DOCX format.

### Convert with Screenshots (After capturing)

```bash
./convert_with_screenshots.sh
```

This processes the user guide with embedded screenshots for final documentation.

## Custom Styles

### PDF Styling

Edit `pdf_styles.css` to customize:
- Font family and size
- Page margins
- Header/footer content
- Color scheme
- Code block styling

### DOCX Reference Document

Pandoc can use a reference DOCX file for styling:

```bash
pandoc input.md -o output.docx --reference-doc=custom_styles.docx
```

Edit `custom_styles.docx` in Microsoft Word to set:
- Heading styles (H1, H2, H3)
- Body text font
- Table styles
- Image captions

## Batch Conversion

To convert all markdown files at once:

```bash
for file in *.md; do
  # Convert to PDF
  pandoc "$file" -o "${file%.md}.pdf" --pdf-engine=wkhtmltopdf
  
  # Convert to DOCX
  pandoc "$file" -o "${file%.md}.docx"
done
```

## Troubleshooting

### Issue: Pandoc not found
**Solution:** Ensure pandoc is in your PATH:
```bash
export PATH=$PATH:/opt/homebrew/bin  # macOS with Homebrew
```

### Issue: PDF rendering poor quality
**Solution:** Use wkhtmltopdf engine instead of default:
```bash
pandoc input.md -o output.pdf --pdf-engine=wkhtmltopdf
```

### Issue: Images not appearing in DOCX
**Solution:** Ensure image paths are relative and files exist:
```bash
# Check image exists
ls -la screenshots/*.png

# Use absolute paths if needed
pandoc input.md -o output.docx --extract-media=./media
```

### Issue: Table of Contents missing
**Solution:** Add `--toc` flag:
```bash
pandoc input.md -o output.pdf --toc
```

## Output Structure

After conversion, files will be organized as:

```
docs/
├── pdf/
│   ├── USER_GUIDE_WITH_SCREENSHOTS.pdf
│   ├── BPM_DETECTION_GUIDE.pdf
│   ├── CHORD_DETECTION_GUIDE.pdf
│   └── IMPLEMENTATION_STATUS.pdf
├── docx/
│   ├── USER_GUIDE_WITH_SCREENSHOTS.docx
│   ├── BPM_DETECTION_GUIDE.docx
│   ├── CHORD_DETECTION_GUIDE.docx
│   └── IMPLEMENTATION_STATUS.docx
├── screenshots/
│   └── (30 screenshot images)
└── scripts/
    ├── convert_to_pdf.sh
    ├── convert_to_docx.sh
    ├── pdf_styles.css
    └── README.md (this file)
```

## Automation

To automate conversion after each documentation update:

```bash
#!/bin/bash
# Post-commit hook script

# Convert updated docs
for file in docs/*.md; do
  pandoc "$file" -o "docs/pdf/$(basename ${file%.md}.pdf)" --pdf-engine=wkhtmltopdf
  pandoc "$file" -o "docs/docx/$(basename ${file%.md}.docx)"
done

# Optional: Commit generated files
git add docs/pdf/*.pdf docs/docx/*.docx
git commit -m "docs: auto-generated PDF/DOCX from markdown"
```

## Performance Tips

- **Large documents**: Use `--chunk-div` for better PDF navigation
- **Many images**: Compress images before conversion with `pngquant`
- **Fast preview**: Use `--pdf-engine=prince` for high-quality commercial PDFs

---

**For more information:** https://pandoc.org/
