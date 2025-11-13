/**
 * HTML to Markdown Converter
 * Core conversion engine using custom rules for text-first output
 */

class HTMLToMarkdownConverter {
  constructor(options = {}) {
    this.options = {
      headingStyle: 'atx', // # style headings
      bulletListMarker: '-',
      codeBlockStyle: 'fenced',
      emDelimiter: '*',
      strongDelimiter: '**',
      linkStyle: 'inlined',
      preserveNewlines: true,
      ...options
    };

    this.mediaFiles = []; // Track downloaded media
    this.baseUrl = '';
  }

  /**
   * Convert HTML to Markdown
   * @param {string|HTMLElement} html - HTML string or DOM element
   * @param {string} baseUrl - Base URL for resolving relative paths
   * @returns {string} Markdown string
   */
  convert(html, baseUrl = '') {
    this.baseUrl = baseUrl || window.location.href;
    this.mediaFiles = [];

    let element;
    if (typeof html === 'string') {
      const temp = document.createElement('div');
      temp.innerHTML = html;
      element = temp;
    } else {
      element = html;
    }

    // Clean up the DOM before conversion
    this.cleanDOM(element);

    // Convert to markdown
    const markdown = this.processNode(element);

    // Clean up extra blank lines
    return this.cleanMarkdown(markdown);
  }

  /**
   * Clean DOM before conversion
   */
  cleanDOM(element) {
    // Remove script and style tags
    const unwantedTags = element.querySelectorAll('script, style, noscript, iframe');
    unwantedTags.forEach(tag => tag.remove());

    // Remove hidden elements
    const allElements = element.querySelectorAll('*');
    allElements.forEach(el => {
      const style = window.getComputedStyle(el);
      if (style.display === 'none' || style.visibility === 'hidden') {
        el.remove();
      }
    });
  }

  /**
   * Process a DOM node recursively
   */
  processNode(node, context = {}) {
    if (node.nodeType === Node.TEXT_NODE) {
      return this.processTextNode(node, context);
    }

    if (node.nodeType !== Node.ELEMENT_NODE) {
      return '';
    }

    const tagName = node.tagName.toLowerCase();
    const handler = this.tagHandlers[tagName];

    if (handler) {
      return handler.call(this, node, context);
    }

    // Default: process children
    return this.processChildren(node, context);
  }

  /**
   * Process text node
   */
  processTextNode(node, context) {
    let text = node.textContent;

    // Preserve whitespace in pre/code blocks
    if (context.preserveWhitespace) {
      return text;
    }

    // Collapse whitespace
    text = text.replace(/\s+/g, ' ');

    // Trim if at start or end of block
    if (context.trimStart) {
      text = text.trimStart();
    }
    if (context.trimEnd) {
      text = text.trimEnd();
    }

    return text;
  }

  /**
   * Process all children of a node
   */
  processChildren(node, context = {}) {
    let result = '';
    const children = Array.from(node.childNodes);

    children.forEach((child, index) => {
      const childContext = {
        ...context,
        isFirst: index === 0,
        isLast: index === children.length - 1
      };
      result += this.processNode(child, childContext);
    });

    return result;
  }

  /**
   * Tag handlers for each HTML element
   */
  tagHandlers = {
    // Headings
    h1: (node) => `\n# ${this.processChildren(node).trim()}\n\n`,
    h2: (node) => `\n## ${this.processChildren(node).trim()}\n\n`,
    h3: (node) => `\n### ${this.processChildren(node).trim()}\n\n`,
    h4: (node) => `\n#### ${this.processChildren(node).trim()}\n\n`,
    h5: (node) => `\n##### ${this.processChildren(node).trim()}\n\n`,
    h6: (node) => `\n###### ${this.processChildren(node).trim()}\n\n`,

    // Paragraphs
    p: (node) => {
      const content = this.processChildren(node).trim();
      return content ? `\n${content}\n\n` : '';
    },

    // Line breaks
    br: () => '  \n',
    hr: () => '\n---\n\n',

    // Text formatting
    strong: (node) => `**${this.processChildren(node).trim()}**`,
    b: (node) => `**${this.processChildren(node).trim()}**`,
    em: (node) => `*${this.processChildren(node).trim()}*`,
    i: (node) => `*${this.processChildren(node).trim()}*`,
    del: (node) => `~~${this.processChildren(node).trim()}~~`,
    s: (node) => `~~${this.processChildren(node).trim()}~~`,

    // Code
    code: (node, context) => {
      const text = node.textContent;
      if (context.inPre) {
        return text;
      }
      return `\`${text}\``;
    },

    pre: (node) => {
      const code = node.querySelector('code');
      const text = code ? code.textContent : node.textContent;
      const language = code ? this.detectLanguage(code) : '';
      return `\n\`\`\`${language}\n${text}\n\`\`\`\n\n`;
    },

    // Links
    a: (node) => {
      const href = node.getAttribute('href');
      const text = this.processChildren(node).trim();

      if (!href) {
        return text;
      }

      const absoluteUrl = this.resolveUrl(href);
      return `[${text}](${absoluteUrl})`;
    },

    // Images
    img: (node) => {
      const src = node.getAttribute('src');
      const alt = node.getAttribute('alt') || '';

      if (!src) {
        return '';
      }

      const absoluteUrl = this.resolveUrl(src);

      // Track for download
      this.mediaFiles.push({
        type: 'image',
        url: absoluteUrl,
        alt: alt
      });

      return `![${alt}](${absoluteUrl})`;
    },

    // Lists
    ul: (node) => {
      const items = Array.from(node.children)
        .filter(child => child.tagName === 'LI')
        .map(li => this.processListItem(li, '-', 0))
        .join('');
      return `\n${items}\n`;
    },

    ol: (node) => {
      const items = Array.from(node.children)
        .filter(child => child.tagName === 'LI')
        .map((li, index) => this.processListItem(li, `${index + 1}.`, 0))
        .join('');
      return `\n${items}\n`;
    },

    li: (node) => {
      // Handled by ul/ol
      return this.processChildren(node);
    },

    // Blockquotes
    blockquote: (node) => {
      const content = this.processChildren(node).trim();
      return '\n' + content.split('\n')
        .map(line => `> ${line}`)
        .join('\n') + '\n\n';
    },

    // Tables
    table: (node) => {
      return this.processTable(node);
    },

    // Divs and spans - just process children
    div: (node) => this.processChildren(node),
    span: (node) => this.processChildren(node),
    article: (node) => this.processChildren(node),
    section: (node) => this.processChildren(node),
    main: (node) => this.processChildren(node),
    header: (node) => this.processChildren(node),
    footer: (node) => this.processChildren(node),
    aside: (node) => this.processChildren(node),
    nav: (node) => '', // Skip navigation

    // Other elements
    details: (node) => {
      const summary = node.querySelector('summary');
      const summaryText = summary ? summary.textContent.trim() : 'Details';
      const content = this.processChildren(node).trim();
      return `\n**${summaryText}**\n\n${content}\n\n`;
    }
  };

  /**
   * Process list item with indentation
   */
  processListItem(li, marker, depth) {
    const indent = '  '.repeat(depth);
    let content = '';

    // Process direct children
    Array.from(li.childNodes).forEach(child => {
      if (child.tagName === 'UL' || child.tagName === 'OL') {
        // Nested list
        const nestedMarker = child.tagName === 'UL' ? '-' : '1.';
        const nestedItems = Array.from(child.children)
          .filter(c => c.tagName === 'LI')
          .map(nestedLi => this.processListItem(nestedLi, nestedMarker, depth + 1))
          .join('');
        content += nestedItems;
      } else {
        content += this.processNode(child);
      }
    });

    return `${indent}${marker} ${content.trim()}\n`;
  }

  /**
   * Process table
   */
  processTable(table) {
    const rows = Array.from(table.querySelectorAll('tr'));

    if (rows.length === 0) {
      return '';
    }

    let markdown = '\n';
    const hasHeader = table.querySelector('thead') || rows[0].querySelector('th');

    rows.forEach((row, rowIndex) => {
      const cells = Array.from(row.querySelectorAll('th, td'));
      const cellContents = cells.map(cell => this.processChildren(cell).trim());

      markdown += '| ' + cellContents.join(' | ') + ' |\n';

      // Add separator after header
      if (rowIndex === 0 && hasHeader) {
        markdown += '| ' + cells.map(() => '---').join(' | ') + ' |\n';
      }
    });

    return markdown + '\n';
  }

  /**
   * Detect code language from class name
   */
  detectLanguage(codeElement) {
    const className = codeElement.className || '';
    const match = className.match(/language-(\w+)/);
    return match ? match[1] : '';
  }

  /**
   * Resolve relative URLs to absolute
   */
  resolveUrl(url) {
    try {
      return new URL(url, this.baseUrl).href;
    } catch (e) {
      return url;
    }
  }

  /**
   * Clean up markdown output
   */
  cleanMarkdown(markdown) {
    return markdown
      // Remove excessive blank lines
      .replace(/\n{3,}/g, '\n\n')
      // Trim whitespace
      .trim()
      // Add final newline
      + '\n';
  }

  /**
   * Get list of media files found during conversion
   */
  getMediaFiles() {
    return this.mediaFiles;
  }
}

// Export for use in extension
if (typeof module !== 'undefined' && module.exports) {
  module.exports = HTMLToMarkdownConverter;
}
