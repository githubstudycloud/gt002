/**
 * DOM Parser and Text Extractor
 * Bypasses copy restrictions and extracts content directly from DOM
 */

class DOMParser {
  constructor() {
    this.selectedElement = null;
  }

  /**
   * Extract content from the entire page or selected area
   * @param {HTMLElement} rootElement - Root element to extract from (default: document.body)
   * @returns {Object} Extracted content with metadata
   */
  extractContent(rootElement = null) {
    const root = rootElement || this.getMainContent();

    return {
      element: root,
      title: this.extractTitle(),
      url: window.location.href,
      timestamp: new Date().toISOString(),
      metadata: this.extractMetadata()
    };
  }

  /**
   * Get main content area, filtering out headers, footers, navs
   */
  getMainContent() {
    // Try common selectors for main content
    const mainSelectors = [
      'main',
      'article',
      '[role="main"]',
      '.main-content',
      '#main-content',
      '.post-content',
      '.article-content',
      '.entry-content'
    ];

    for (const selector of mainSelectors) {
      const element = document.querySelector(selector);
      if (element) {
        return element;
      }
    }

    // Fallback to body
    return document.body;
  }

  /**
   * Extract page title
   */
  extractTitle() {
    // Try multiple sources
    const h1 = document.querySelector('h1');
    const title = document.title;
    const ogTitle = document.querySelector('meta[property="og:title"]');

    if (h1 && h1.textContent.trim()) {
      return h1.textContent.trim();
    }

    if (ogTitle && ogTitle.content) {
      return ogTitle.content;
    }

    return title;
  }

  /**
   * Extract metadata from page
   */
  extractMetadata() {
    const metadata = {
      author: this.extractAuthor(),
      date: this.extractDate(),
      description: this.extractDescription(),
      keywords: this.extractKeywords(),
      language: document.documentElement.lang || 'en'
    };

    return metadata;
  }

  /**
   * Extract author information
   */
  extractAuthor() {
    // Try meta tags
    const authorMeta = document.querySelector('meta[name="author"]');
    if (authorMeta) {
      return authorMeta.content;
    }

    // Try Open Graph
    const ogAuthor = document.querySelector('meta[property="article:author"]');
    if (ogAuthor) {
      return ogAuthor.content;
    }

    // Try common class names
    const authorElement = document.querySelector('.author, .byline, [rel="author"]');
    if (authorElement) {
      return authorElement.textContent.trim();
    }

    return null;
  }

  /**
   * Extract publication date
   */
  extractDate() {
    // Try meta tags
    const dateMeta = document.querySelector('meta[property="article:published_time"]');
    if (dateMeta) {
      return dateMeta.content;
    }

    // Try time element
    const timeElement = document.querySelector('time[datetime]');
    if (timeElement) {
      return timeElement.getAttribute('datetime');
    }

    return null;
  }

  /**
   * Extract description
   */
  extractDescription() {
    const descMeta = document.querySelector('meta[name="description"]');
    if (descMeta) {
      return descMeta.content;
    }

    const ogDesc = document.querySelector('meta[property="og:description"]');
    if (ogDesc) {
      return ogDesc.content;
    }

    return null;
  }

  /**
   * Extract keywords
   */
  extractKeywords() {
    const keywordsMeta = document.querySelector('meta[name="keywords"]');
    if (keywordsMeta) {
      return keywordsMeta.content.split(',').map(k => k.trim());
    }

    return [];
  }

  /**
   * Extract selected text/element
   * Bypasses user-select: none and other restrictions
   */
  extractSelection() {
    const selection = window.getSelection();

    if (selection.rangeCount > 0) {
      const range = selection.getRangeAt(0);
      const container = document.createElement('div');
      container.appendChild(range.cloneContents());
      return {
        element: container,
        text: container.textContent,
        html: container.innerHTML
      };
    }

    return null;
  }

  /**
   * Remove copy restrictions from element
   * @param {HTMLElement} element - Element to unlock
   */
  removeCopyRestrictions(element) {
    if (!element) return;

    // Remove user-select restrictions
    element.style.userSelect = 'auto';
    element.style.webkitUserSelect = 'auto';
    element.style.mozUserSelect = 'auto';
    element.style.msUserSelect = 'auto';

    // Remove event listeners that prevent copying
    const clone = element.cloneNode(true);
    element.parentNode.replaceChild(clone, element);

    return clone;
  }

  /**
   * Extract all text content bypassing restrictions
   * Uses TreeWalker to traverse all text nodes
   */
  extractTextContent(element) {
    const walker = document.createTreeWalker(
      element,
      NodeFilter.SHOW_TEXT,
      {
        acceptNode: (node) => {
          // Skip script and style content
          const parent = node.parentElement;
          if (parent && ['SCRIPT', 'STYLE', 'NOSCRIPT'].includes(parent.tagName)) {
            return NodeFilter.FILTER_REJECT;
          }

          // Skip hidden elements
          if (parent) {
            const style = window.getComputedStyle(parent);
            if (style.display === 'none' || style.visibility === 'hidden') {
              return NodeFilter.FILTER_REJECT;
            }
          }

          // Skip empty text
          if (!node.textContent.trim()) {
            return NodeFilter.FILTER_REJECT;
          }

          return NodeFilter.FILTER_ACCEPT;
        }
      }
    );

    let textContent = '';
    let node;

    while (node = walker.nextNode()) {
      textContent += node.textContent;
    }

    return textContent;
  }

  /**
   * Wait for dynamic content to load
   * Useful for SPA and lazy-loaded content
   */
  async waitForDynamicContent(timeout = 3000) {
    return new Promise((resolve) => {
      let timeoutId;

      const observer = new MutationObserver(() => {
        clearTimeout(timeoutId);
        timeoutId = setTimeout(() => {
          observer.disconnect();
          resolve();
        }, 500);
      });

      observer.observe(document.body, {
        childList: true,
        subtree: true
      });

      // Maximum timeout
      setTimeout(() => {
        observer.disconnect();
        resolve();
      }, timeout);
    });
  }

  /**
   * Scroll to load lazy images
   */
  async loadLazyImages() {
    const images = document.querySelectorAll('img[loading="lazy"], img[data-src]');

    for (const img of images) {
      // Scroll into view to trigger loading
      img.scrollIntoView({ behavior: 'instant', block: 'nearest' });

      // Handle data-src attribute
      if (img.dataset.src && !img.src) {
        img.src = img.dataset.src;
      }
    }

    // Wait a bit for images to load
    await new Promise(resolve => setTimeout(resolve, 1000));
  }

  /**
   * Get all images with their sources
   */
  getAllImages(element) {
    const images = element.querySelectorAll('img');
    const imageData = [];

    images.forEach(img => {
      const src = img.src || img.dataset.src;
      if (src) {
        imageData.push({
          element: img,
          src: src,
          alt: img.alt || '',
          width: img.naturalWidth || img.width,
          height: img.naturalHeight || img.height
        });
      }
    });

    return imageData;
  }

  /**
   * Get all media elements (video, audio)
   */
  getAllMedia(element) {
    const media = [];

    // Videos
    const videos = element.querySelectorAll('video');
    videos.forEach(video => {
      const src = video.src || (video.querySelector('source') || {}).src;
      if (src) {
        media.push({
          type: 'video',
          element: video,
          src: src,
          poster: video.poster
        });
      }
    });

    // Audio
    const audios = element.querySelectorAll('audio');
    audios.forEach(audio => {
      const src = audio.src || (audio.querySelector('source') || {}).src;
      if (src) {
        media.push({
          type: 'audio',
          element: audio,
          src: src
        });
      }
    });

    return media;
  }

  /**
   * Get statistics about the content
   */
  getStatistics(element) {
    const text = this.extractTextContent(element);

    return {
      characters: text.length,
      words: text.split(/\s+/).filter(w => w.length > 0).length,
      paragraphs: element.querySelectorAll('p').length,
      headings: element.querySelectorAll('h1, h2, h3, h4, h5, h6').length,
      links: element.querySelectorAll('a').length,
      images: element.querySelectorAll('img').length,
      codeBlocks: element.querySelectorAll('pre, code').length,
      tables: element.querySelectorAll('table').length,
      lists: element.querySelectorAll('ul, ol').length
    };
  }

  /**
   * Interactive element selector
   * Allows user to click on an element to select it
   */
  enableElementSelector(callback) {
    const overlay = document.createElement('div');
    overlay.style.cssText = `
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      z-index: 999999;
      cursor: crosshair;
      background: rgba(0, 0, 0, 0.1);
    `;

    let highlightedElement = null;

    const highlight = (element) => {
      if (highlightedElement) {
        highlightedElement.style.outline = '';
      }

      element.style.outline = '3px solid #007bff';
      highlightedElement = element;
    };

    const removeHighlight = () => {
      if (highlightedElement) {
        highlightedElement.style.outline = '';
        highlightedElement = null;
      }
    };

    overlay.addEventListener('mousemove', (e) => {
      const element = document.elementFromPoint(e.clientX, e.clientY);
      if (element && element !== overlay) {
        highlight(element);
      }
    });

    overlay.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();

      const element = document.elementFromPoint(e.clientX, e.clientY);
      removeHighlight();
      overlay.remove();

      if (element && element !== overlay) {
        callback(element);
      }
    });

    document.body.appendChild(overlay);

    // ESC to cancel
    const escHandler = (e) => {
      if (e.key === 'Escape') {
        removeHighlight();
        overlay.remove();
        document.removeEventListener('keydown', escHandler);
      }
    };
    document.addEventListener('keydown', escHandler);
  }
}

// Export for use in extension
if (typeof module !== 'undefined' && module.exports) {
  module.exports = DOMParser;
}
