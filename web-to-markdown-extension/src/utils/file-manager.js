/**
 * File Manager
 * Manages file organization in timestamp directories
 * Handles markdown file creation and metadata generation
 */

class FileManager {
  constructor() {
    this.currentSession = null;
  }

  /**
   * Create a new session with timestamp directory
   * @returns {Object} Session information
   */
  createSession() {
    const timestamp = this.generateTimestamp();

    this.currentSession = {
      timestamp: timestamp,
      directory: `tmp/${timestamp}`,
      mediaDirectory: `tmp/${timestamp}/media`,
      files: [],
      metadata: {
        created: new Date().toISOString(),
        url: window.location.href,
        title: document.title
      }
    };

    return this.currentSession;
  }

  /**
   * Generate timestamp in YYYYMMDD_HHMMSS format
   */
  generateTimestamp() {
    const now = new Date();

    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');

    return `${year}${month}${day}_${hours}${minutes}${seconds}`;
  }

  /**
   * Generate metadata JSON for the conversion
   * @param {Object} data - Conversion data
   * @returns {string} JSON string
   */
  generateMetadata(data) {
    const {
      url,
      title,
      author,
      date,
      description,
      keywords,
      statistics,
      mediaFiles
    } = data;

    const metadata = {
      version: '1.0',
      timestamp: new Date().toISOString(),
      source: {
        url: url,
        title: title,
        author: author || null,
        publishDate: date || null,
        description: description || null,
        keywords: keywords || []
      },
      content: {
        statistics: statistics || {}
      },
      media: {
        total: mediaFiles ? mediaFiles.length : 0,
        files: mediaFiles || []
      },
      conversion: {
        tool: 'Web to Markdown Extension',
        version: '1.0.0',
        date: new Date().toISOString()
      }
    };

    return JSON.stringify(metadata, null, 2);
  }

  /**
   * Generate markdown file with frontmatter
   * @param {string} content - Markdown content
   * @param {Object} metadata - Page metadata
   * @returns {string} Complete markdown with frontmatter
   */
  generateMarkdownFile(content, metadata = {}) {
    const frontmatter = this.generateFrontmatter(metadata);

    return `${frontmatter}\n\n${content}`;
  }

  /**
   * Generate YAML frontmatter
   */
  generateFrontmatter(metadata) {
    const {
      title,
      url,
      author,
      date,
      description,
      keywords
    } = metadata;

    const frontmatter = ['---'];

    if (title) {
      frontmatter.push(`title: "${this.escapeYaml(title)}"`);
    }

    if (url) {
      frontmatter.push(`source: ${url}`);
    }

    if (author) {
      frontmatter.push(`author: "${this.escapeYaml(author)}"`);
    }

    if (date) {
      frontmatter.push(`date: ${date}`);
    }

    if (description) {
      frontmatter.push(`description: "${this.escapeYaml(description)}"`);
    }

    if (keywords && keywords.length > 0) {
      frontmatter.push(`keywords:`);
      keywords.forEach(keyword => {
        frontmatter.push(`  - ${keyword}`);
      });
    }

    frontmatter.push(`created: ${new Date().toISOString()}`);
    frontmatter.push('---');

    return frontmatter.join('\n');
  }

  /**
   * Escape special characters in YAML
   */
  escapeYaml(str) {
    return str.replace(/"/g, '\\"').replace(/\n/g, ' ');
  }

  /**
   * Replace media URLs with local paths in markdown
   * @param {string} markdown - Original markdown
   * @param {Array} mediaFiles - Downloaded media files
   * @returns {string} Updated markdown
   */
  replaceMediaUrls(markdown, mediaFiles) {
    let updatedMarkdown = markdown;

    mediaFiles.forEach(media => {
      if (media.localFilename && !media.error) {
        const localPath = `media/${media.localFilename}`;

        // Replace in markdown image syntax
        const imageRegex = new RegExp(
          `!\\[([^\\]]*)\\]\\(${this.escapeRegex(media.url)}\\)`,
          'g'
        );
        updatedMarkdown = updatedMarkdown.replace(
          imageRegex,
          `![$1](${localPath})`
        );

        // Replace in markdown link syntax
        const linkRegex = new RegExp(
          `\\[([^\\]]*)\\]\\(${this.escapeRegex(media.url)}\\)`,
          'g'
        );
        updatedMarkdown = updatedMarkdown.replace(
          linkRegex,
          `[$1](${localPath})`
        );
      }
    });

    return updatedMarkdown;
  }

  /**
   * Escape special regex characters
   */
  escapeRegex(str) {
    return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  /**
   * Create file structure object for download
   */
  createFileStructure(markdownContent, metadata, mediaFiles) {
    const session = this.currentSession || this.createSession();

    const files = [
      {
        path: `${session.directory}/content.md`,
        content: markdownContent,
        type: 'text/markdown'
      },
      {
        path: `${session.directory}/metadata.json`,
        content: metadata,
        type: 'application/json'
      }
    ];

    // Add media files
    mediaFiles.forEach(media => {
      if (media.blob && !media.error) {
        files.push({
          path: `${session.mediaDirectory}/${media.localFilename}`,
          blob: media.blob,
          type: media.type
        });
      }
    });

    return {
      session: session,
      files: files
    };
  }

  /**
   * Generate README for the output directory
   */
  generateReadme(metadata) {
    const parsed = JSON.parse(metadata);

    const readme = `# ${parsed.source.title || 'Converted Content'}

**Source:** ${parsed.source.url}
**Converted:** ${new Date(parsed.timestamp).toLocaleString()}
**Tool:** ${parsed.conversion.tool} v${parsed.conversion.version}

## Statistics

- **Characters:** ${parsed.content.statistics.characters || 'N/A'}
- **Words:** ${parsed.content.statistics.words || 'N/A'}
- **Images:** ${parsed.media.total || 0}
- **Links:** ${parsed.content.statistics.links || 'N/A'}

## Files

- \`content.md\` - Main content in Markdown format
- \`metadata.json\` - Complete metadata
- \`media/\` - Downloaded images and media files

## Usage

Open \`content.md\` in any Markdown editor or viewer.

Media files are referenced with relative paths and stored in the \`media/\` directory.
`;

    return readme;
  }

  /**
   * Download all files using chrome.downloads API
   * This should be called from background script
   */
  async downloadFiles(files) {
    const downloadPromises = files.map(file => {
      return this.downloadFile(file);
    });

    return Promise.all(downloadPromises);
  }

  /**
   * Download a single file
   */
  async downloadFile(file) {
    return new Promise((resolve, reject) => {
      let dataUrl;

      if (file.blob) {
        // Convert blob to data URL
        const reader = new FileReader();
        reader.onloadend = () => {
          dataUrl = reader.result;
          initiateDownload();
        };
        reader.onerror = reject;
        reader.readAsDataURL(file.blob);
      } else {
        // Convert text content to data URL
        const blob = new Blob([file.content], { type: file.type });
        const reader = new FileReader();
        reader.onloadend = () => {
          dataUrl = reader.result;
          initiateDownload();
        };
        reader.onerror = reject;
        reader.readAsDataURL(blob);
      }

      function initiateDownload() {
        chrome.downloads.download({
          url: dataUrl,
          filename: file.path,
          saveAs: false
        }, (downloadId) => {
          if (chrome.runtime.lastError) {
            reject(new Error(chrome.runtime.lastError.message));
          } else {
            resolve({ downloadId, path: file.path });
          }
        });
      }
    });
  }

  /**
   * Create a ZIP file with all content (future feature)
   * For V1, we'll use individual downloads
   */
  async createZipArchive(files) {
    // Placeholder for future ZIP functionality
    // Could use JSZip library
    console.log('ZIP creation not implemented in V1');
    return null;
  }

  /**
   * Get session info
   */
  getSession() {
    return this.currentSession;
  }

  /**
   * Clear current session
   */
  clearSession() {
    this.currentSession = null;
  }

  /**
   * Validate markdown content
   */
  validateMarkdown(markdown) {
    const issues = [];

    // Check for common issues
    if (!markdown || markdown.trim().length === 0) {
      issues.push('Markdown content is empty');
    }

    // Check for unescaped HTML
    const htmlTagRegex = /<(?!br|hr|img|a|code|pre|strong|em|del)[^>]+>/g;
    const htmlTags = markdown.match(htmlTagRegex);
    if (htmlTags) {
      issues.push(`Found ${htmlTags.length} unescaped HTML tags`);
    }

    // Check for broken links
    const brokenLinkRegex = /\[([^\]]*)\]\(\s*\)/g;
    const brokenLinks = markdown.match(brokenLinkRegex);
    if (brokenLinks) {
      issues.push(`Found ${brokenLinks.length} empty links`);
    }

    // Check for broken images
    const brokenImageRegex = /!\[([^\]]*)\]\(\s*\)/g;
    const brokenImages = markdown.match(brokenImageRegex);
    if (brokenImages) {
      issues.push(`Found ${brokenImages.length} empty image sources`);
    }

    return {
      valid: issues.length === 0,
      issues: issues
    };
  }

  /**
   * Calculate total size of all files
   */
  calculateTotalSize(files) {
    let total = 0;

    files.forEach(file => {
      if (file.blob) {
        total += file.blob.size;
      } else if (file.content) {
        total += new Blob([file.content]).size;
      }
    });

    return {
      bytes: total,
      kb: (total / 1024).toFixed(2),
      mb: (total / 1024 / 1024).toFixed(2)
    };
  }
}

// Export for use in extension
if (typeof module !== 'undefined' && module.exports) {
  module.exports = FileManager;
}
