# Public Test Files Guide

This guide provides a comprehensive list of publicly available files for testing all markdownify MCP tools. These files are free to use and specifically designed for testing and development purposes.

## Overview

The markdownify MCP server provides 10 different tools that convert various file types to markdown. Each tool requires specific file types or URLs as input. This guide organizes public resources by tool type.

## Tool-Specific Test Resources

### 1. Audio-to-Markdown Tool
**Purpose**: Convert audio files to markdown with transcription

**Test Files (Wikipedia/Wikimedia Commons)**:
- **Classical music**: https://upload.wikimedia.org/wikipedia/commons/f/f0/Andalūzijas_romance3470.wav
- **Speech audio**: https://upload.wikimedia.org/wikipedia/commons/8/89/Adolf_Hitler_-_Speech.wav
- **Music composition**: https://upload.wikimedia.org/wikipedia/commons/b/ba/"Quando_le_sere_al_placido"_(Ferruccio_Giannini).wav
- **Spoken audio**: https://upload.wikimedia.org/wikipedia/commons/2/25/'Absent-minded_professor'_from_Wikipedia.ogg
- **Short audio clips**: Various files from https://commons.wikimedia.org/wiki/Category:Audio_files_in_English

**Alternative Sources**:
- More audio files: https://commons.wikimedia.org/wiki/Category:Audio_files
- Learning Container samples: https://www.learningcontainer.com/sample-audio-file/
- SampleLib MP3 files: https://samplelib.com/sample-mp3.html

### 2. PDF-to-Markdown Tool
**Purpose**: Extract text and structure from PDF documents

**Test Files (Wikipedia/Wikimedia Commons)**:
- **Simple test PDF**: https://s24.q4cdn.com/216390268/files/doc_downloads/test.pdf
- **Research paper**: https://upload.wikimedia.org/wikipedia/commons/2/2f/Executive_Order_14150.pdf
- **Historical document**: https://upload.wikimedia.org/wikipedia/commons/3/35/FBI_File_104-10125-10133%2C_Martin_Luther_King_Jr.%2C_A_Current_Analysis.pdf
- **JFK files**: https://upload.wikimedia.org/wikipedia/commons/e/e9/JFK_Assassination_File_104-10332-10023_%282025_release%29.pdf
- **Wikipedia handbook**: https://upload.wikimedia.org/wikipedia/commons/4/49/UploadingImagesHandout.pdf
- **Educational material**: https://upload.wikimedia.org/wikipedia/commons/9/90/Giving_Consent_for_Images_on_Wikipedia.pdf

**Alternative Sources**:
- More PDFs from Wikimedia Commons: https://commons.wikimedia.org/wiki/Category:PDF_files
- PDF Scripting samples: https://www.pdfscripting.com/public/Free-Sample-PDF-Files-with-scripts.cfm
- GitHub PDF samples: https://github.com/py-pdf/sample-files

### 3. DOCX-to-Markdown Tool
**Purpose**: Convert Microsoft Word documents to markdown

**Test Files (Wikipedia/Wikimedia Commons)**:
- **Calibre demo**: https://calibre-ebook.com/downloads/demos/demo.docx
- **Microsoft Office samples**: https://learn.microsoft.com/en-us/office/dev/scripts/tutorials/on-call-rotation.xlsx (Note: This is XLSX but shows Office format availability)

**Alternative Sources**:
- ToolsFairy samples: https://toolsfairy.com/document-test/sample-docx-files
- Learning Container: https://www.learningcontainer.com/sample-docx-file-for-testing/

**Note**: DOCX files are less common on Wikimedia Commons due to format preferences. Consider using the alternative sources or creating test files.

### 4. PPTX-to-Markdown Tool
**Purpose**: Extract content from PowerPoint presentations

**Test Files**:
- **Harvard sample**: https://scholar.harvard.edu/files/torman_personal/files/samplepptx.pptx
- **Oklahoma Senate sample**: https://oksenate.gov/sites/default/files/2020-01/sample_0.ppt
- **File Examples collection**: https://file-examples.com/index.php/sample-documents-download/sample-ppt-file/

**Note**: Some files may be .ppt format (older PowerPoint) rather than .pptx

### 5. XLSX-to-Markdown Tool
**Purpose**: Convert Excel spreadsheets to markdown tables

**Test Files (Wikipedia/Government Sources)**:
- **Educational data**: https://www.nysedregents.org/ghg2/625/glhg2-62025-sk.xlsx
- **Microsoft Learning**: https://learn.microsoft.com/en-us/office/dev/scripts/tutorials/on-call-rotation.xlsx
- **Government data**: https://www.cdc.gov/nhsn/xls/master-organism-com-commensals-lists.xlsx
- **EPA data**: https://pasteur.epa.gov/uploads/10.23719/1532264/Appendix%20B%20-%20PLUTO2010.xlsx
- **Military forms**: https://www.nationalguard.mil/Portals/31/Documents/ARNGpdfs/militarycomp/DA-Form-5501-R.xls

**Alternative Sources**:
- Fragile States Index data: https://fragilestatesindex.org/excel/
- Various business spreadsheets: https://exinfm.com/free_spreadsheets.html

### 6. Image-to-Markdown Tool
**Purpose**: Convert images to markdown with metadata and descriptions

**Test Files (Wikipedia/Wikimedia Commons)**:
- **Random 800x600**: https://picsum.photos/800/600
- **Specific image**: https://picsum.photos/id/237/800/600
- **High-quality images**: Various files from https://commons.wikimedia.org/wiki/Category:Images
- **Wikipedia images**: https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/Alois_Mentasti.jpg/120px-Alois_Mentasti.jpg
- **Various formats**: Browse https://commons.wikimedia.org/wiki/Category:GIF_files and other format categories

**Supported Formats**: JPG, PNG, GIF, TIFF, ICO, SVG, WEBP

**Alternative Sources**:
- Wikimedia Commons images: https://commons.wikimedia.org/wiki/Category:Images
- Sample Videos JPG: https://www.sample-videos.com/download-sample-jpg-image.php

### 7. YouTube-to-Markdown Tool
**Purpose**: Extract video transcripts and metadata

**Test Videos**:
- **Educational content**: https://www.youtube.com/watch?v=7bwkuudEfmc
- **Khan Academy** (any video from): https://www.youtube.com/c/khanacademy
- **TED-Ed** (any video from): https://www.youtube.com/c/TEDEd
- **Crash Course** (any video from): https://www.youtube.com/c/crashcourse

**Best Practices**: Use educational videos with clear speech for better transcription results

### 8. Webpage-to-Markdown Tool
**Purpose**: Convert web pages to clean markdown format

**Test Pages**:
- **Lorem Ipsum generator**: https://www.lipsum.com/
- **Example.com**: https://example.com/
- **File Examples homepage**: https://file-examples.com/
- **Wikipedia article**: https://en.wikipedia.org/wiki/Lorem_ipsum
- **Simple blog posts**: Any well-structured article page

### 9. Bing-Search-to-Markdown Tool
**Purpose**: Convert Bing search results pages to markdown

**Test Search URLs**:
- `https://www.bing.com/search?q=lorem+ipsum`
- `https://www.bing.com/search?q=sample+files+download`
- `https://www.bing.com/search?q=test+documents`
- `https://www.bing.com/search?q=markdown+converter`

**Usage**: Replace the `q=` parameter with any search term

### 10. Get-Markdown-File Tool
**Purpose**: Retrieve existing markdown files by absolute path

**Requirements**: This tool requires local markdown files since it reads from absolute file paths.

**Test Setup**:
1. Create sample .md files in your project
2. Use absolute paths like `d:\tools\markdownify-mcp\README.md`
3. Test with files of various sizes and complexity

## File Size Recommendations

For comprehensive testing, use files of different sizes:

- **Small files** (< 100KB): Quick tests, basic functionality
- **Medium files** (100KB - 1MB): Typical use cases
- **Large files** (> 1MB): Performance and memory testing

## MIME Types Reference

| File Type | Common MIME Types |
|-----------|------------------|
| Audio | `audio/wav`, `audio/mpeg`, `audio/mp3` |
| PDF | `application/pdf` |
| DOCX | `application/vnd.openxmlformats-officedocument.wordprocessingml.document` |
| PPTX | `application/vnd.openxmlformats-officedocument.presentationml.presentation` |
| XLSX | `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` |
| Images | `image/jpeg`, `image/png`, `image/gif`, `image/webp` |

## Testing Best Practices

1. **Start Small**: Begin with smaller files to verify basic functionality
2. **Test Edge Cases**: Try files with special characters, multiple languages, complex formatting
3. **Performance Testing**: Use larger files to test processing speed and memory usage
4. **Error Handling**: Test with corrupted or invalid files
5. **Cross-Platform**: Verify tools work with files from different sources and platforms

## Notes

- All listed URLs were verified as publicly accessible as of July 2025
- **Wikipedia and Wikimedia Commons sources are generally more reliable than commercial file hosting sites**
- File Examples (file-examples.com) was experiencing access restrictions (403 Forbidden errors) as of July 2025
- **Government and educational institutions (.gov, .edu) provide stable, long-term file access**
- Always respect copyright and usage terms when using public files
- Consider creating your own test files for specific edge cases
- **Wikimedia Commons files are under open licenses and ideal for testing**

## Troubleshooting

If any URLs become unavailable:
1. **Check Wikimedia Commons first**: Most file types have reliable examples at https://commons.wikimedia.org
2. **Use government/educational sources**: .gov and .edu domains typically have stable file hosting
3. Check the main site (e.g., file-examples.com) for updated links, but be aware of potential access restrictions
4. Use alternative sources listed for each file type
5. Create your own test files following similar patterns
6. Verify network connectivity and file accessibility
7. **Consider local file testing**: Download files locally to avoid remote access issues

**Known Issues (July 2025)**:
- file-examples.com URLs returning 403 Forbidden errors
- Some commercial file hosting sites have implemented bot protection
- Wikipedia/Wikimedia sources remain consistently accessible

---

*Last updated: July 21, 2025*
*Repository: markdownify-mcp*
