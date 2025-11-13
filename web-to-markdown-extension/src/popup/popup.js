/**
 * Popup UI Script
 * Handles user interactions in the extension popup
 */

// DOM elements
const elements = {
  pageTitle: document.getElementById('page-title'),
  pageUrl: document.getElementById('page-url'),
  statWords: document.getElementById('stat-words'),
  statImages: document.getElementById('stat-images'),
  statLinks: document.getElementById('stat-links'),
  optDownloadMedia: document.getElementById('opt-download-media'),
  optLazyImages: document.getElementById('opt-lazy-images'),
  optWaitDynamic: document.getElementById('opt-wait-dynamic'),
  optMetadata: document.getElementById('opt-metadata'),
  btnConvertPage: document.getElementById('btn-convert-page'),
  btnConvertSelection: document.getElementById('btn-convert-selection'),
  btnSelectElement: document.getElementById('btn-select-element'),
  status: document.getElementById('status'),
  statusMessage: document.getElementById('status-message'),
  progressFill: document.getElementById('progress-fill')
};

// Initialize
document.addEventListener('DOMContentLoaded', async () => {
  await loadPageInfo();
  await loadOptions();
  attachEventListeners();
});

/**
 * Load current page information
 */
async function loadPageInfo() {
  try {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });

    if (!tab) {
      showError('No active tab found');
      return;
    }

    // Get page info from content script
    const response = await chrome.tabs.sendMessage(tab.id, {
      type: 'GET_PAGE_INFO'
    });

    if (response) {
      elements.pageTitle.textContent = response.title || 'Untitled';
      elements.pageUrl.textContent = response.url || '';
      elements.pageUrl.title = response.url || '';

      if (response.statistics) {
        elements.statWords.textContent = response.statistics.words || 0;
        elements.statImages.textContent = response.statistics.images || 0;
        elements.statLinks.textContent = response.statistics.links || 0;
      }
    }

  } catch (error) {
    console.error('Failed to load page info:', error);
    elements.pageTitle.textContent = 'Error loading page info';
    elements.statWords.textContent = '-';
    elements.statImages.textContent = '-';
    elements.statLinks.textContent = '-';
  }
}

/**
 * Load saved options
 */
async function loadOptions() {
  try {
    const result = await chrome.storage.local.get('options');
    const options = result.options || {};

    elements.optDownloadMedia.checked = options.downloadMedia !== false;
    elements.optLazyImages.checked = options.loadLazyImages !== false;
    elements.optWaitDynamic.checked = options.waitForDynamic === true;
    elements.optMetadata.checked = options.includeMetadata !== false;

  } catch (error) {
    console.error('Failed to load options:', error);
  }
}

/**
 * Save options
 */
async function saveOptions() {
  const options = {
    downloadMedia: elements.optDownloadMedia.checked,
    loadLazyImages: elements.optLazyImages.checked,
    waitForDynamic: elements.optWaitDynamic.checked,
    includeMetadata: elements.optMetadata.checked
  };

  await chrome.storage.local.set({ options });
}

/**
 * Attach event listeners
 */
function attachEventListeners() {
  // Convert buttons
  elements.btnConvertPage.addEventListener('click', handleConvertPage);
  elements.btnConvertSelection.addEventListener('click', handleConvertSelection);
  elements.btnSelectElement.addEventListener('click', handleSelectElement);

  // Save options on change
  elements.optDownloadMedia.addEventListener('change', saveOptions);
  elements.optLazyImages.addEventListener('change', saveOptions);
  elements.optWaitDynamic.addEventListener('change', saveOptions);
  elements.optMetadata.addEventListener('change', saveOptions);

  // Footer links
  document.getElementById('link-help').addEventListener('click', (e) => {
    e.preventDefault();
    chrome.tabs.create({ url: 'https://github.com/your-repo/web-to-markdown' });
  });

  document.getElementById('link-settings').addEventListener('click', (e) => {
    e.preventDefault();
    // Could open a settings page
    alert('Settings page coming soon!');
  });
}

/**
 * Handle convert page button
 */
async function handleConvertPage() {
  try {
    disableButtons();
    showStatus('Converting page...', 10);

    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });

    const options = {
      downloadMedia: elements.optDownloadMedia.checked,
      loadLazyImages: elements.optLazyImages.checked,
      waitForDynamic: elements.optWaitDynamic.checked,
      includeMetadata: elements.optMetadata.checked
    };

    showStatus('Processing content...', 30);

    const response = await chrome.tabs.sendMessage(tab.id, {
      type: 'CONVERT_PAGE',
      options: options
    });

    if (response && response.success) {
      showStatus('Conversion complete!', 100);

      setTimeout(() => {
        hideStatus();
        enableButtons();

        // Show success message
        showSuccessNotification(response);
      }, 1000);

    } else {
      throw new Error(response?.error || 'Conversion failed');
    }

  } catch (error) {
    console.error('Convert page error:', error);
    showError(error.message);
    enableButtons();
  }
}

/**
 * Handle convert selection button
 */
async function handleConvertSelection() {
  try {
    disableButtons();
    showStatus('Converting selection...', 10);

    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });

    const options = {
      downloadMedia: elements.optDownloadMedia.checked,
      loadLazyImages: elements.optLazyImages.checked,
      includeMetadata: elements.optMetadata.checked
    };

    const response = await chrome.tabs.sendMessage(tab.id, {
      type: 'CONVERT_SELECTION',
      options: options
    });

    if (response && response.success) {
      showStatus('Conversion complete!', 100);

      setTimeout(() => {
        hideStatus();
        enableButtons();
        showSuccessNotification(response);
      }, 1000);

    } else {
      throw new Error(response?.error || 'No content selected');
    }

  } catch (error) {
    console.error('Convert selection error:', error);
    showError(error.message);
    enableButtons();
  }
}

/**
 * Handle select element button
 */
async function handleSelectElement() {
  try {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });

    await chrome.tabs.sendMessage(tab.id, {
      type: 'START_SELECTOR'
    });

    // Close popup to allow selection
    window.close();

  } catch (error) {
    console.error('Select element error:', error);
    showError(error.message);
  }
}

/**
 * Show status message
 */
function showStatus(message, progress) {
  elements.status.style.display = 'block';
  elements.statusMessage.textContent = message;
  elements.progressFill.style.width = `${progress}%`;
}

/**
 * Hide status
 */
function hideStatus() {
  elements.status.style.display = 'none';
  elements.progressFill.style.width = '0%';
}

/**
 * Show error
 */
function showError(message) {
  elements.status.style.display = 'block';
  elements.statusMessage.textContent = `Error: ${message}`;
  elements.statusMessage.style.color = '#dc3545';
  elements.progressFill.style.background = '#dc3545';
}

/**
 * Show success notification
 */
function showSuccessNotification(response) {
  const message = document.createElement('div');
  message.style.cssText = `
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    background: #28a745;
    color: white;
    padding: 20px;
    border-radius: 8px;
    text-align: center;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
  `;

  message.innerHTML = `
    <div style="font-size: 32px; margin-bottom: 10px;">✓</div>
    <div style="font-weight: 600; margin-bottom: 5px;">Conversion Complete!</div>
    <div style="font-size: 12px; opacity: 0.9;">Files saved to downloads</div>
  `;

  document.body.appendChild(message);

  setTimeout(() => {
    message.remove();
  }, 2000);
}

/**
 * Disable all buttons
 */
function disableButtons() {
  elements.btnConvertPage.disabled = true;
  elements.btnConvertSelection.disabled = true;
  elements.btnSelectElement.disabled = true;
}

/**
 * Enable all buttons
 */
function enableButtons() {
  elements.btnConvertPage.disabled = false;
  elements.btnConvertSelection.disabled = false;
  elements.btnSelectElement.disabled = false;
}
