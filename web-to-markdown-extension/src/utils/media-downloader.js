/**
 * Media File Downloader
 * Downloads images, videos, and other media files
 * Handles cross-origin resources and generates local filenames
 */

class MediaDownloader {
  constructor() {
    this.downloadQueue = [];
    this.downloadedFiles = new Map();
    this.maxConcurrent = 5;
    this.downloading = 0;
  }

  /**
   * Download a single media file
   * @param {string} url - URL of the media file
   * @param {Object} options - Download options
   * @returns {Promise<Object>} Download result with local filename
   */
  async downloadMedia(url, options = {}) {
    const {
      type = 'image',
      alt = '',
      filename = null
    } = options;

    try {
      // Check if already downloaded
      if (this.downloadedFiles.has(url)) {
        return this.downloadedFiles.get(url);
      }

      // Fetch the file
      const response = await fetch(url);

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const blob = await response.blob();

      // Check file size (50MB limit)
      const MAX_SIZE = 50 * 1024 * 1024;
      if (blob.size > MAX_SIZE) {
        throw new Error(`File too large: ${(blob.size / 1024 / 1024).toFixed(2)}MB`);
      }

      // Generate filename
      const localFilename = filename || this.generateFilename(url, blob.type);

      const result = {
        url: url,
        localFilename: localFilename,
        blob: blob,
        size: blob.size,
        type: blob.type,
        alt: alt,
        mediaType: type
      };

      this.downloadedFiles.set(url, result);

      return result;

    } catch (error) {
      console.error(`Failed to download ${url}:`, error);
      return {
        url: url,
        error: error.message,
        localFilename: null
      };
    }
  }

  /**
   * Download multiple media files with concurrency control
   * @param {Array} mediaList - Array of {url, type, alt}
   * @param {Function} progressCallback - Progress callback (current, total)
   * @returns {Promise<Array>} Array of download results
   */
  async downloadMultiple(mediaList, progressCallback = null) {
    this.downloadQueue = [...mediaList];
    const results = [];
    let completed = 0;

    const downloadNext = async () => {
      if (this.downloadQueue.length === 0) {
        return;
      }

      const media = this.downloadQueue.shift();
      this.downloading++;

      try {
        const result = await this.downloadMedia(media.url, {
          type: media.type,
          alt: media.alt
        });

        results.push(result);
        completed++;

        if (progressCallback) {
          progressCallback(completed, mediaList.length);
        }

      } finally {
        this.downloading--;
        // Continue with next download
        if (this.downloadQueue.length > 0) {
          await downloadNext();
        }
      }
    };

    // Start concurrent downloads
    const concurrent = Math.min(this.maxConcurrent, mediaList.length);
    const promises = [];

    for (let i = 0; i < concurrent; i++) {
      promises.push(downloadNext());
    }

    await Promise.all(promises);

    return results;
  }

  /**
   * Generate local filename from URL
   * @param {string} url - Original URL
   * @param {string} mimeType - MIME type of the file
   * @returns {string} Local filename
   */
  generateFilename(url, mimeType) {
    try {
      const urlObj = new URL(url);
      let pathname = urlObj.pathname;

      // Remove query parameters and get filename
      let filename = pathname.split('/').pop() || 'file';

      // Remove extension
      const lastDotIndex = filename.lastIndexOf('.');
      const name = lastDotIndex > 0 ? filename.substring(0, lastDotIndex) : filename;
      const extension = lastDotIndex > 0 ? filename.substring(lastDotIndex + 1) : '';

      // Clean filename (remove special characters)
      const cleanName = name
        .replace(/[^a-zA-Z0-9_-]/g, '_')
        .substring(0, 50); // Limit length

      // Determine extension from MIME type if not present
      let ext = extension;
      if (!ext || ext.length > 5) {
        ext = this.getExtensionFromMimeType(mimeType);
      }

      // Generate hash for uniqueness
      const hash = this.hashCode(url).toString(16).substring(0, 4);

      return `${cleanName}_${hash}.${ext}`;

    } catch (error) {
      // Fallback filename
      const hash = this.hashCode(url).toString(16);
      const ext = this.getExtensionFromMimeType(mimeType);
      return `media_${hash}.${ext}`;
    }
  }

  /**
   * Get file extension from MIME type
   */
  getExtensionFromMimeType(mimeType) {
    const mimeMap = {
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'image/gif': 'gif',
      'image/webp': 'webp',
      'image/svg+xml': 'svg',
      'image/bmp': 'bmp',
      'video/mp4': 'mp4',
      'video/webm': 'webm',
      'video/ogg': 'ogv',
      'audio/mpeg': 'mp3',
      'audio/ogg': 'ogg',
      'audio/wav': 'wav',
      'application/pdf': 'pdf'
    };

    return mimeMap[mimeType] || 'bin';
  }

  /**
   * Simple hash function for URLs
   */
  hashCode(str) {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return Math.abs(hash);
  }

  /**
   * Convert blob to data URL (for preview)
   */
  async blobToDataURL(blob) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onloadend = () => resolve(reader.result);
      reader.onerror = reject;
      reader.readAsDataURL(blob);
    });
  }

  /**
   * Save blob using chrome.downloads API
   * This will be called from background script
   */
  async saveBlobWithChrome(blob, filename, subdirectory = '') {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();

      reader.onloadend = () => {
        const dataUrl = reader.result;

        chrome.downloads.download({
          url: dataUrl,
          filename: subdirectory ? `${subdirectory}/${filename}` : filename,
          saveAs: false
        }, (downloadId) => {
          if (chrome.runtime.lastError) {
            reject(new Error(chrome.runtime.lastError.message));
          } else {
            resolve(downloadId);
          }
        });
      };

      reader.onerror = () => reject(new Error('Failed to read blob'));
      reader.readAsDataURL(blob);
    });
  }

  /**
   * Clear downloaded files cache
   */
  clear() {
    this.downloadedFiles.clear();
    this.downloadQueue = [];
  }

  /**
   * Get all downloaded files
   */
  getDownloadedFiles() {
    return Array.from(this.downloadedFiles.values());
  }

  /**
   * Get download statistics
   */
  getStatistics() {
    const files = this.getDownloadedFiles();
    const successful = files.filter(f => !f.error);

    const totalSize = successful.reduce((sum, f) => sum + (f.size || 0), 0);

    const byType = {};
    successful.forEach(f => {
      const type = f.mediaType || 'unknown';
      byType[type] = (byType[type] || 0) + 1;
    });

    return {
      total: files.length,
      successful: successful.length,
      failed: files.length - successful.length,
      totalSize: totalSize,
      totalSizeMB: (totalSize / 1024 / 1024).toFixed(2),
      byType: byType
    };
  }

  /**
   * Extract all media URLs from HTML
   */
  static extractMediaUrls(html, baseUrl) {
    const temp = document.createElement('div');
    temp.innerHTML = html;

    const media = [];

    // Images
    temp.querySelectorAll('img').forEach(img => {
      const src = img.src || img.dataset.src;
      if (src) {
        media.push({
          url: new URL(src, baseUrl).href,
          type: 'image',
          alt: img.alt || ''
        });
      }
    });

    // Videos
    temp.querySelectorAll('video').forEach(video => {
      const src = video.src || (video.querySelector('source') || {}).src;
      if (src) {
        media.push({
          url: new URL(src, baseUrl).href,
          type: 'video',
          poster: video.poster ? new URL(video.poster, baseUrl).href : null
        });
      }
    });

    // Audio
    temp.querySelectorAll('audio').forEach(audio => {
      const src = audio.src || (audio.querySelector('source') || {}).src;
      if (src) {
        media.push({
          url: new URL(src, baseUrl).href,
          type: 'audio'
        });
      }
    });

    return media;
  }

  /**
   * Filter media by type
   */
  static filterMediaByType(mediaList, types = ['image']) {
    return mediaList.filter(m => types.includes(m.type));
  }

  /**
   * Check if URL is an image
   */
  static isImageUrl(url) {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp'];
    try {
      const pathname = new URL(url).pathname.toLowerCase();
      return imageExtensions.some(ext => pathname.endsWith(`.${ext}`));
    } catch {
      return false;
    }
  }

  /**
   * Estimate download time
   * @param {number} totalSize - Total size in bytes
   * @param {number} speed - Download speed in bytes/second (default 1MB/s)
   */
  static estimateDownloadTime(totalSize, speed = 1024 * 1024) {
    const seconds = totalSize / speed;

    if (seconds < 60) {
      return `${Math.ceil(seconds)}s`;
    } else if (seconds < 3600) {
      return `${Math.ceil(seconds / 60)}m`;
    } else {
      return `${Math.ceil(seconds / 3600)}h`;
    }
  }
}

// Export for use in extension
if (typeof module !== 'undefined' && module.exports) {
  module.exports = MediaDownloader;
}
