# GuitarTuner Documentation

> **Version:** 1.6.0  
> **Last Updated:** 2026-07-30  
> **Status:** 📸 Screenshots pending - Use placeholder images until captured

---

## 📁 Folder Structure

```
docs/
├── USER_GUIDE_WITH_SCREENSHOTS.md    # Enhanced user guide (needs screenshots)
├── SCREENSHOT_GUIDE.md               # Instructions for capturing screenshots
├── screenshots/                       # Place captured screenshots here (30 total)
│   ├── 01_launch_screen.png          # [ ] TODO: Capture
│   ├── 02_main_tuner.png             # [ ] TODO: Capture
│   └── ... (28 more)                 # [ ] TODO: Capture
├── pdf/                               # Generated PDF files
│   └── (auto-generated)              # Run: ./scripts/convert_to_pdf.sh
├── docx/                              # Generated Word documents
│   └── (auto-generated)              # Run: ./scripts/convert_to_docx.sh
└── scripts/
    ├── README.md                      # Conversion instructions
    ├── convert_to_pdf.sh              # PDF conversion script
    ├── convert_to_docx.sh             # DOCX conversion script
    └── pdf_styles.css                 # PDF styling
```

---

## 🚀 Quick Start

### Step 1: Capture Screenshots

Follow the guide in `SCREENSHOT_GUIDE.md` to capture all 30 required screenshots.

**Time estimate:** 2-3 hours

### Step 2: Replace Placeholders

After capturing, save screenshots to `docs/screenshots/` with exact filenames:

```bash
# Example
cp ~/Downloads/screenshot_01.png docs/screenshots/01_launch_screen.png
```

### Step 3: Generate PDF/DOCX

Run conversion scripts:

```bash
cd docs/scripts
chmod +x *.sh
./convert_to_pdf.sh    # Creates PDF files
./convert_to_docx.sh   # Creates DOCX files
```

**Requirements:** 
- Pandoc (install: `brew install pandoc`)
- wkhtmltopdf (optional, for better PDF quality)

### Step 4: Verify Output

Check generated files:

```bash
ls -lh pdf/
ls -lh docx/
```

Open and review for quality issues.

---

## 📖 Available Documentation

| Document | Purpose | Format | Status |
|----------|---------|--------|--------|
| **User Guide** | Complete app usage instructions | MD/PDF/DOCX | 🟡 Needs screenshots |
| **BPM Detection Guide** | BPM detection features explained | MD/PDF/DOCX | ✅ Complete |
| **Chord Detection Guide** | Chord detection features explained | MD/PDF/DOCX | ✅ Complete |
| **Implementation Status** | Technical verification report | MD/PDF/DOCX | ✅ Complete |
| **Screenshot Guide** | Instructions for capturing screenshots | MD | ✅ Complete |

---

## 🎯 Screenshot Status Checklist

Capture these 30 screenshots (see `SCREENSHOT_GUIDE.md` for details):

### App Interface (4)
- [ ] 01_launch_screen.png
- [ ] 02_main_tuner.png
- [ ] 03_interface_annotated.png
- [ ] 04_toolbar_components.png

### Recording Process (4)
- [x] 05_bpm_control.png *(placeholder)*
- [x] 06_recording_active.png *(placeholder)*
- [x] 07_chord_detection.png *(placeholder)*
- [x] 08_processing_complete.png *(placeholder)*

### Navigation (1)
- [x] 09_horizontal_scroll.png *(placeholder)*

### Key Detection (3)
- [x] 10_key_confidence.png *(placeholder)*
- [x] 11_key_signature.png *(placeholder)*
- [x] 12_pitch_histogram.png *(placeholder/concept)*

### BPM Detection (3)
- [x] 13_bpm_comparison.png *(placeholder)*
- [x] 14_bpm_confidence.png *(placeholder)*
- [ ] 15_beat_grid.png *(future v1.7.0)*

### Chord Detection (3)
- [x] 16_chord_progression.png *(placeholder)*
- [x] 17_chord_accuracy.png *(placeholder)*
- [x] 18_barre_chords.png *(placeholder)*

### Tablature Reading (4)
- [x] 19_dual_staff.png *(placeholder)*
- [x] 20_note_durations.png *(placeholder)*
- [x] 21_articulations.png *(placeholder)*
- [x] 22_scrolling.png *(placeholder)*

### Playback & Editing (3)
- [x] 23_transport_buttons.png *(placeholder)*
- [x] 24_manual_entry.png *(placeholder)*
- [x] 25_clear_dialog.png *(placeholder)*

### Reference (5)
- [ ] 26_mic_position.png *(lifestyle photo)*
- [x] 27_issues_comparison.png *(placeholder)*
- [x] 28_toolbar_legend.png *(placeholder)*
- [x] 29_common_chords.png *(placeholder)*
- [x] 30_fretboard_notes.png *(placeholder)*

**Total:** 10/30 captured, 19 placeholders, 1 future feature

---

## 🛠️ Troubleshooting

### Issue: PDF generation fails
**Solution:** Ensure pandoc is installed and in PATH:
```bash
brew install pandoc
which pandoc  # Should show: /opt/homebrew/bin/pandoc
```

### Issue: Images not appearing in PDF
**Solution:** Check image paths are relative to markdown file:
```markdown
<!-- Correct -->
![Caption](screenshots/01_launch_screen.png)

<!-- Incorrect - absolute path -->
![Caption](/Users/you/project/docs/screenshots/01_launch_screen.png)
```

### Issue: PDF looks pixelated
**Solution:** Use wkhtmltopdf engine:
```bash
brew install wkhtmltopdf
# Then run conversion script again
```

---

## 📝 Adding New Documentation

To add new documentation:

1. Create `docs/YOUR_NEW_DOC.md`
2. Add reference in this README
3. Update conversion scripts to include new file
4. Run conversion scripts

Example:
```markdown
## New Document
- [YOUR_NEW_DOC.md](YOUR_NEW_DOC.md) - Description here
```

---

## 🔄 Automation

### Auto-generate on Commit (Optional)

Add to `.git/hooks/post-commit`:

```bash
#!/bin/bash
cd docs/scripts
./convert_to_pdf.sh
./convert_to_docx.sh
git add pdf/ docx/
git commit -m "docs: auto-generate PDF/DOCX" --no-verify
```

**Note:** Requires pandoc installed in CI/CD environment

---

## 📤 Publishing

After capturing screenshots and generating PDFs:

1. Commit documentation:
   ```bash
   git add docs/
   git commit -m "docs: complete user guide with screenshots"
   git push
   ```

2. Update project README with links:
   ```markdown
   ## Documentation
   - [User Guide (PDF)](docs/pdf/USER_GUIDE_WITH_SCREENSHOTS.pdf)
   - [Chord Detection Guide (PDF)](docs/pdf/CHORD_DETECTION_GUIDE.pdf)
   ```

3. Generate GitHub Pages (optional):
   ```bash
   # Enable in repo settings → Pages
   # Source: docs/ folder
   ```

---

## 📊 Status Legend

| Status | Meaning |
|--------|---------|
| ✅ Complete | Screenshot captured and verified |
| 🟡 Placeholder | Text description in place, awaiting screenshot |
| ⏳ Future | Feature not yet implemented (v1.7.0+) |
| ❌ Missing | Screenshot needed |

---

**Questions?** See `SCREENSHOT_GUIDE.md` for detailed capture instructions or `scripts/README.md` for conversion help.
