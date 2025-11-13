/**
 * Background Service Worker (Manifest V3)
 * Handles downloads, context menus, and extension commands
 */

// Install event
chrome.runtime.onInstalled.addListener(() => {
  console.log('Web to Markdown extension installed');

  // Create context menu items
  createContextMenus();

  // Set default options
  chrome.storage.local.set({
    options: {
      downloadMedia: true,
      waitForDynamic: false,
      loadLazyImages: true,
      includeMetadata: true
    }
  });
});

/**
 * Create context menu items
 */
function createContextMenus() {
  // Remove existing menus
  chrome.contextMenus.removeAll(() => {
    // Convert entire page
    chrome.contextMenus.create({
      id: 'convert-page',
      title: 'Convert page to Markdown',
      contexts: ['page']
    });

    // Convert selection
    chrome.contextMenus.create({
      id: 'convert-selection',
      title: 'Convert selection to Markdown',
      contexts: ['selection']
    });

    // Select element
    chrome.contextMenus.create({
      id: 'select-element',
      title: 'Select element to convert',
      contexts: ['page']
    });

    // Separator
    chrome.contextMenus.create({
      id: 'separator-1',
      type: 'separator',
      contexts: ['page']
    });

    // Convert image
    chrome.contextMenus.create({
      id: 'save-image-markdown',
      title: 'Save image as Markdown',
      contexts: ['image']
    });
  });
}

/**
 * Context menu click handler
 */
chrome.contextMenus.onClicked.addListener(async (info, tab) => {
  switch (info.menuItemId) {
    case 'convert-page':
      await convertPage(tab.id);
      break;

    case 'convert-selection':
      await convertSelection(tab.id);
      break;

    case 'select-element':
      await startElementSelector(tab.id);
      break;

    case 'save-image-markdown':
      await saveImageAsMarkdown(info.srcUrl, tab.id);
      break;
  }
});

/**
 * Keyboard command handler
 */
chrome.commands.onCommand.addListener(async (command) => {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });

  if (command === 'convert-to-markdown') {
    await convertPage(tab.id);
  }
});

/**
 * Convert page
 */
async function convertPage(tabId) {
  try {
    const options = await getOptions();

    const response = await chrome.tabs.sendMessage(tabId, {
      type: 'CONVERT_PAGE',
      options: options
    });

    if (response && response.success) {
      showNotification('Conversion started', 'View files in downloads folder');
    } else {
      showNotification('Conversion failed', response?.error || 'Unknown error');
    }

  } catch (error) {
    console.error('Convert page error:', error);
    showNotification('Error', error.message);
  }
}

/**
 * Convert selection
 */
async function convertSelection(tabId) {
  try {
    const options = await getOptions();

    const response = await chrome.tabs.sendMessage(tabId, {
      type: 'CONVERT_SELECTION',
      options: options
    });

    if (response && response.success) {
      showNotification('Selection converted', 'View files in downloads folder');
    } else {
      showNotification('Conversion failed', response?.error || 'Unknown error');
    }

  } catch (error) {
    console.error('Convert selection error:', error);
    showNotification('Error', error.message);
  }
}

/**
 * Start element selector
 */
async function startElementSelector(tabId) {
  try {
    await chrome.tabs.sendMessage(tabId, {
      type: 'START_SELECTOR'
    });
  } catch (error) {
    console.error('Element selector error:', error);
    showNotification('Error', error.message);
  }
}

/**
 * Save single image as markdown
 */
async function saveImageAsMarkdown(imageUrl, tabId) {
  try {
    const timestamp = generateTimestamp();
    const filename = `image_${timestamp}.md`;

    const markdown = `# Image\n\n![Image](${imageUrl})\n\n**Source:** ${imageUrl}\n`;

    // Download markdown file
    const blob = new Blob([markdown], { type: 'text/markdown' });
    const url = URL.createObjectURL(blob);

    await chrome.downloads.download({
      url: url,
      filename: `tmp/${timestamp}/${filename}`,
      saveAs: false
    });

    showNotification('Image saved', 'Markdown file created');

  } catch (error) {
    console.error('Save image error:', error);
    showNotification('Error', error.message);
  }
}

/**
 * Message handler from content script
 */
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.type === 'DOWNLOAD_FILES') {
    downloadFiles(request.data.files, request.data.session)
      .then(() => {
        sendResponse({ success: true });
      })
      .catch(error => {
        console.error('Download files error:', error);
        sendResponse({ success: false, error: error.message });
      });

    return true; // Async response
  }

  if (request.type === 'SHOW_NOTIFICATION') {
    showNotification(request.title, request.message);
    sendResponse({ success: true });
  }
});

/**
 * Download multiple files
 */
async function downloadFiles(files, session) {
  console.log(`Downloading ${files.length} files to ${session.directory}`);

  const downloadPromises = files.map(async (file) => {
    try {
      let dataUrl;

      if (file.blob) {
        // Convert blob to data URL
        dataUrl = await blobToDataURL(file.blob);
      } else {
        // Convert text content to data URL
        const blob = new Blob([file.content], { type: file.type });
        dataUrl = await blobToDataURL(blob);
      }

      // Download file
      const downloadId = await chrome.downloads.download({
        url: dataUrl,
        filename: file.path,
        saveAs: false,
        conflictAction: 'uniquify'
      });

      console.log(`Downloaded: ${file.path} (ID: ${downloadId})`);

      return { success: true, path: file.path, downloadId };

    } catch (error) {
      console.error(`Failed to download ${file.path}:`, error);
      return { success: false, path: file.path, error: error.message };
    }
  });

  const results = await Promise.all(downloadPromises);

  const successful = results.filter(r => r.success).length;
  const failed = results.filter(r => !r.success).length;

  console.log(`Download complete: ${successful} successful, ${failed} failed`);

  return results;
}

/**
 * Convert blob to data URL
 */
function blobToDataURL(blob) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onloadend = () => resolve(reader.result);
    reader.onerror = reject;
    reader.readAsDataURL(blob);
  });
}

/**
 * Show browser notification
 */
function showNotification(title, message) {
  chrome.notifications.create({
    type: 'basic',
    iconUrl: '../icons/icon128.png',
    title: title,
    message: message,
    priority: 2
  });
}

/**
 * Get user options from storage
 */
async function getOptions() {
  const result = await chrome.storage.local.get('options');
  return result.options || {
    downloadMedia: true,
    waitForDynamic: false,
    loadLazyImages: true,
    includeMetadata: true
  };
}

/**
 * Generate timestamp
 */
function generateTimestamp() {
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
 * Handle download completion
 */
chrome.downloads.onChanged.addListener((delta) => {
  if (delta.state && delta.state.current === 'complete') {
    console.log(`Download completed: ${delta.id}`);
  }

  if (delta.error) {
    console.error(`Download error: ${delta.error.current}`);
  }
});

console.log('Web to Markdown background service worker loaded');
