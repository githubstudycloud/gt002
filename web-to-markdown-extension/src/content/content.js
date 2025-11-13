/**
 * Content Script
 * Runs in the context of web pages
 * Handles DOM access, conversion, and communication with background script
 */

// Initialize components
const domParser = new DOMParser();
const converter = new HTMLToMarkdownConverter();
const mediaDownloader = new MediaDownloader();
const fileManager = new FileManager();

let isConverting = false;

/**
 * Main conversion function
 */
async function convertPageToMarkdown(options = {}) {
  if (isConverting) {
    console.warn('Conversion already in progress');
    return;
  }

  isConverting = true;

  try {
    // Show progress notification
    showNotification('Starting conversion...', 'info');

    // Extract content
    const contentData = domParser.extractContent();

    // Wait for dynamic content if needed
    if (options.waitForDynamic) {
      showNotification('Waiting for dynamic content...', 'info');
      await domParser.waitForDynamicContent();
    }

    // Load lazy images
    if (options.loadLazyImages) {
      showNotification('Loading lazy images...', 'info');
      await domParser.loadLazyImages();
    }

    // Get element to convert
    const element = options.element || contentData.element;

    // Convert to markdown
    showNotification('Converting to Markdown...', 'info');
    const markdown = converter.convert(element, contentData.url);

    // Get media files
    const mediaFiles = converter.getMediaFiles();

    // Download media files if requested
    let downloadedMedia = [];
    if (options.downloadMedia && mediaFiles.length > 0) {
      showNotification(`Downloading ${mediaFiles.length} media files...`, 'info');

      downloadedMedia = await mediaDownloader.downloadMultiple(
        mediaFiles,
        (current, total) => {
          showNotification(`Downloading media: ${current}/${total}`, 'info');
        }
      );
    }

    // Replace URLs with local paths
    let finalMarkdown = markdown;
    if (downloadedMedia.length > 0) {
      finalMarkdown = fileManager.replaceMediaUrls(markdown, downloadedMedia);
    }

    // Add frontmatter
    const markdownWithFrontmatter = fileManager.generateMarkdownFile(
      finalMarkdown,
      {
        title: contentData.title,
        url: contentData.url,
        author: contentData.metadata.author,
        date: contentData.metadata.date,
        description: contentData.metadata.description,
        keywords: contentData.metadata.keywords
      }
    );

    // Get statistics
    const statistics = domParser.getStatistics(element);

    // Generate metadata
    const metadataJson = fileManager.generateMetadata({
      url: contentData.url,
      title: contentData.title,
      author: contentData.metadata.author,
      date: contentData.metadata.date,
      description: contentData.metadata.description,
      keywords: contentData.metadata.keywords,
      statistics: statistics,
      mediaFiles: downloadedMedia.map(m => ({
        original: m.url,
        local: m.localFilename,
        type: m.type,
        size: m.size
      }))
    });

    // Create file structure
    const fileStructure = fileManager.createFileStructure(
      markdownWithFrontmatter,
      metadataJson,
      downloadedMedia
    );

    // Send to background script for download
    showNotification('Saving files...', 'info');

    chrome.runtime.sendMessage({
      type: 'DOWNLOAD_FILES',
      data: {
        files: fileStructure.files,
        session: fileStructure.session
      }
    }, (response) => {
      if (response && response.success) {
        const stats = mediaDownloader.getStatistics();
        showNotification(
          `Conversion complete! Saved to ${fileStructure.session.directory}\n` +
          `Files: ${fileStructure.files.length}, Size: ${stats.totalSizeMB}MB`,
          'success'
        );
      } else {
        showNotification('Failed to save files', 'error');
      }
    });

    return {
      success: true,
      markdown: finalMarkdown,
      metadata: metadataJson,
      statistics: statistics,
      session: fileStructure.session
    };

  } catch (error) {
    console.error('Conversion error:', error);
    showNotification(`Conversion failed: ${error.message}`, 'error');

    return {
      success: false,
      error: error.message
    };

  } finally {
    isConverting = false;
  }
}

/**
 * Convert selected area only
 */
async function convertSelection(options = {}) {
  const selection = domParser.extractSelection();

  if (!selection) {
    showNotification('No content selected', 'warning');
    return;
  }

  return convertPageToMarkdown({
    ...options,
    element: selection.element
  });
}

/**
 * Interactive element selector
 */
function startElementSelector() {
  showNotification('Click on an element to convert it', 'info');

  domParser.enableElementSelector(async (element) => {
    showNotification('Converting selected element...', 'info');

    await convertPageToMarkdown({
      element: element,
      downloadMedia: true
    });
  });
}

/**
 * Show notification overlay
 */
function showNotification(message, type = 'info') {
  // Remove existing notification
  const existing = document.getElementById('web2md-notification');
  if (existing) {
    existing.remove();
  }

  const notification = document.createElement('div');
  notification.id = 'web2md-notification';
  notification.style.cssText = `
    position: fixed;
    top: 20px;
    right: 20px;
    padding: 15px 20px;
    background: ${getNotificationColor(type)};
    color: white;
    border-radius: 5px;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    z-index: 999999;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    font-size: 14px;
    max-width: 300px;
    animation: slideIn 0.3s ease-out;
  `;

  notification.textContent = message;
  document.body.appendChild(notification);

  // Auto-remove after 3 seconds (except for errors)
  if (type !== 'error') {
    setTimeout(() => {
      notification.style.animation = 'slideOut 0.3s ease-out';
      setTimeout(() => notification.remove(), 300);
    }, 3000);
  }
}

/**
 * Get notification color by type
 */
function getNotificationColor(type) {
  const colors = {
    info: '#007bff',
    success: '#28a745',
    warning: '#ffc107',
    error: '#dc3545'
  };
  return colors[type] || colors.info;
}

/**
 * Add CSS animations
 */
const style = document.createElement('style');
style.textContent = `
  @keyframes slideIn {
    from {
      transform: translateX(400px);
      opacity: 0;
    }
    to {
      transform: translateX(0);
      opacity: 1;
    }
  }

  @keyframes slideOut {
    from {
      transform: translateX(0);
      opacity: 1;
    }
    to {
      transform: translateX(400px);
      opacity: 0;
    }
  }
`;
document.head.appendChild(style);

/**
 * Message listener from popup and background
 */
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  switch (request.type) {
    case 'CONVERT_PAGE':
      convertPageToMarkdown(request.options || {})
        .then(result => sendResponse(result))
        .catch(error => sendResponse({ success: false, error: error.message }));
      return true; // Async response

    case 'CONVERT_SELECTION':
      convertSelection(request.options || {})
        .then(result => sendResponse(result))
        .catch(error => sendResponse({ success: false, error: error.message }));
      return true;

    case 'START_SELECTOR':
      startElementSelector();
      sendResponse({ success: true });
      break;

    case 'GET_PAGE_INFO':
      const info = {
        title: document.title,
        url: window.location.href,
        statistics: domParser.getStatistics(document.body)
      };
      sendResponse(info);
      break;

    default:
      sendResponse({ success: false, error: 'Unknown command' });
  }
});

/**
 * Listen for keyboard shortcut
 */
document.addEventListener('keydown', (e) => {
  // Ctrl+Shift+M (or Cmd+Shift+M on Mac)
  if ((e.ctrlKey || e.metaKey) && e.shiftKey && e.key === 'M') {
    e.preventDefault();
    convertPageToMarkdown({ downloadMedia: true });
  }
});

/**
 * Context menu handler (handled by background script)
 */

console.log('Web to Markdown content script loaded');
