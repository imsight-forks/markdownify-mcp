# Public Test Files Guide

This guide provides a comprehensive list of publicly available files for testing all markdownify MCP tools. These files are free to use and specifically designed for testing and development purposes.

## Overview

The markdownify MCP server provides 10 different tools that convert various file types to markdown. Each tool requires specific file types or URLs as input. This guide organizes public resources by tool type.

## Tool-Specific Test Resources

### 1. Audio-to-Markdown Tool
**Purpose**: Convert audio files to markdown with transcription

**Test Files**:
- **1MB WAV**: https://file-examples.com/wp-content/storage/2017/11/file_example_WAV_1MG.wav
- **2MB WAV**: https://file-examples.com/wp-content/storage/2017/11/file_example_WAV_2MG.wav
- **5MB WAV**: https://file-examples.com/wp-content/storage/2017/11/file_example_WAV_5MG.wav
- **10MB WAV**: https://file-examples.com/wp-content/storage/2017/11/file_example_WAV_10MG.wav

**Alternative Sources**:
- Learning Container samples: https://www.learningcontainer.com/sample-audio-file/
- SampleLib MP3 files: https://samplelib.com/sample-mp3.html

### 2. PDF-to-Markdown Tool
**Purpose**: Extract text and structure from PDF documents

**Test Files**:
- **150KB PDF**: https://file-examples.com/wp-content/storage/2017/10/file-sample_150kB.pdf
- **500KB PDF**: https://file-examples.com/wp-content/storage/2017/10/file-sample_500kB.pdf
- **1MB PDF**: https://file-examples.com/wp-content/storage/2017/10/file-sample_1MB.pdf
- **Simple test PDF**: https://s24.q4cdn.com/216390268/files/doc_downloads/test.pdf

**Alternative Sources**:
- PDF Scripting samples: https://www.pdfscripting.com/public/Free-Sample-PDF-Files-with-scripts.cfm
- GitHub PDF samples: https://github.com/py-pdf/sample-files

### 3. DOCX-to-Markdown Tool
**Purpose**: Convert Microsoft Word documents to markdown

**Test Files**:
- **100KB DOCX**: https://file-examples.com/wp-content/storage/2017/02/file-sample_100kB.docx
- **500KB DOCX**: https://file-examples.com/wp-content/storage/2017/02/file-sample_500kB.docx
- **1MB DOCX**: https://file-examples.com/wp-content/storage/2017/02/file-sample_1MB.docx
- **Calibre demo**: https://calibre-ebook.com/downloads/demos/demo.docx

**Alternative Sources**:
- ToolsFairy samples: https://toolsfairy.com/document-test/sample-docx-files
- Learning Container: https://www.learningcontainer.com/sample-docx-file-for-testing/

### 4. PPTX-to-Markdown Tool
**Purpose**: Extract content from PowerPoint presentations

**Test Files**:
- **Harvard sample**: https://scholar.harvard.edu/files/torman_personal/files/samplepptx.pptx
- **Oklahoma Senate sample**: https://oksenate.gov/sites/default/files/2020-01/sample_0.ppt
- **File Examples collection**: https://file-examples.com/index.php/sample-documents-download/sample-ppt-file/

**Note**: Some files may be .ppt format (older PowerPoint) rather than .pptx

### 5. XLSX-to-Markdown Tool
**Purpose**: Convert Excel spreadsheets to markdown tables

**Test Files**:
- **CMU test file**: https://www.cmu.edu/blackboard/files/evaluate/tests-example.xls
- **File Examples collection**: https://file-examples.com/index.php/sample-documents-download/sample-xls-download/

**Alternative Sources**:
- Fragile States Index data: https://fragilestatesindex.org/excel/
- Various business spreadsheets: https://exinfm.com/free_spreadsheets.html

### 6. Image-to-Markdown Tool
**Purpose**: Convert images to markdown with metadata and descriptions

**Test Files**:
- **Random 800x600**: https://picsum.photos/800/600
- **Specific image**: https://picsum.photos/id/237/800/600
- **File Examples collection**: https://file-examples.com/index.php/sample-images-download/
- **Sample Videos JPG**: https://www.sample-videos.com/download-sample-jpg-image.php

**Supported Formats**: JPG, PNG, GIF, TIFF, ICO, SVG, WEBP

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
- Some files may require direct download before use with certain tools
- File Examples (file-examples.com) is particularly reliable for consistent test files
- Always respect copyright and usage terms when using public files
- Consider creating your own test files for specific edge cases

## Troubleshooting

If any URLs become unavailable:
1. Check the main site (e.g., file-examples.com) for updated links
2. Use alternative sources listed for each file type
3. Create your own test files following similar patterns
4. Verify network connectivity and file accessibility

---

*Last updated: July 21, 2025*
*Repository: markdownify-mcp*
