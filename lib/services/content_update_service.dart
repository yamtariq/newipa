import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../utils/constants.dart';
import '../models/slide.dart';
import '../models/contact_details.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:path/path.dart';
import 'package:collection/collection.dart';

class ContentUpdateService extends ChangeNotifier {
  static String get updateCheckUrl => Constants.masterFetchUrl;
  static const String _lastUpdateKey = 'last_content_update';
  static const String _contentCacheKey = 'content_cache';
  static const String _lastCheckKey = 'last_check_time';
  static const Duration _minimumCheckInterval = Duration(minutes: 1);
  
  // Singleton instance
  static final ContentUpdateService _instance = ContentUpdateService._internal();
  factory ContentUpdateService() => _instance;
  
  // Track if initial content is loaded
  bool _initialLoadDone = false;
  
  // Cache directory
  Directory? _cacheDir;
  
  ContentUpdateService._internal() {
    _initCacheDir();
  }

  Future<void> _initCacheDir() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${directory.path}/content_cache');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
    } catch (e) {
      _log('Error initializing cache directory: $e');
    }
  }

  // In-memory cache
  final Map<String, dynamic> _memoryCache = {};
  
  // Update status tracking
  bool _isUpdating = false;
  bool get isUpdating => _isUpdating;
  
  // Getter for content
  Map<String, dynamic> get updatedContent => _memoryCache;

  // Add timestamp for last update
  DateTime? _lastUpdateTime;
  DateTime? get lastUpdateTime => _lastUpdateTime;

  // Add first run flag
  static const String _firstRunFlagFile = 'first_run_flag';
  bool _isFirstRun = true;

  // 💡 Add missing properties
  bool _hasDefaultContent = false;
  bool _hasCachedContent = false;
  bool get hasAnyContent => _hasDefaultContent || _hasCachedContent;

  // 💡 Add logging method
  void _log(String message) {
    if (foundation.kDebugMode) {
      foundation.debugPrint('TTT_$message');
    }
  }

  // 💡 Modified to use existing static content
  Future<void> _loadDefaultAssets() async {
    try {
      // Load default slides from Constants
      _memoryCache['default_slideshow_content'] = Constants.staticSlides.map((slide) => {
        'slide_id': int.parse(slide['id'] ?? '0'),
        'image_url': slide['imageUrl'],
        'link': slide['link'],
        'leftTitle': slide['leftTitleEn'],
        'rightTitle': slide['rightTitleAr'],
      }).toList();

      _memoryCache['default_slideshow_content_ar'] = Constants.staticSlides.map((slide) => {
        'slide_id': int.parse(slide['id'] ?? '0'),
        'image_url': slide['imageUrl'],
        'link': slide['link'],
        'leftTitle': slide['leftTitleAr'],
        'rightTitle': slide['rightTitleEn'],
      }).toList();
      
      // Load default ads from Constants
      _memoryCache['default_loan_ad'] = Constants.loanAd;
      _memoryCache['default_card_ad'] = Constants.cardAd;
      
      _hasDefaultContent = true;
      notifyListeners();
    } catch (e) {
      _log('TTT_Error loading default assets: $e');
    }
  }

  // 💡 Modified to prioritize cached content
  Future<void> checkAndUpdateContent({bool force = false, bool isInitialLoad = false, bool isResumed = false}) async {
    try {
      _log('\nTTT_=== Content Update Check ===');

      // Load default content first if not loaded
      if (!_hasDefaultContent) {
        await _loadDefaultAssets();
      }

      // Quick load of cached content if not done yet
      if (!_hasCachedContent) {
        final hasCached = await _loadCachedContent();
        if (hasCached) {
          _hasCachedContent = true;
          notifyListeners();
        }
      }

      // Check update interval
      if (!force && !isInitialLoad) {
        final prefs = await SharedPreferences.getInstance();
        final lastCheckStr = prefs.getString(_lastCheckKey);
        if (lastCheckStr != null) {
          final lastCheck = DateTime.parse(lastCheckStr);
          final now = DateTime.now();
          if (now.difference(lastCheck) < _minimumCheckInterval) {
            _log('TTT_Skipping update check - minimum interval not passed');
            return;
          }
        }
      }

      // Check for updates in background without blocking UI
      bool hasUpdates = await _hasContentUpdates();
      if (hasUpdates) {
        _isUpdating = true;
        
        final tempCache = Map<String, dynamic>.from(_memoryCache);
        final success = await _updateAllContent(tempCache);

        if (success) {
          _memoryCache.addAll(tempCache);
          await _saveContentToCache();
          
          if (await _verifySavedContent()) {
            _hasCachedContent = true;
            _isUpdating = false;
            notifyListeners();
          }
        } else {
          _isUpdating = false;
        }
      }
    } catch (e) {
      _log('TTT_Error in content update: $e');
      _isUpdating = false;
    }
  }

  Future<bool> _isAppFirstRun() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final flagFile = File('${directory.path}/$_firstRunFlagFile');
      
      if (!await flagFile.exists()) {
        // Create the flag file to mark that the app has run before
        await flagFile.create();
        _isFirstRun = true;
        return true;
      }
      
      _isFirstRun = false;
      return false;
    } catch (e) {
      _log('Error checking first run: $e');
      return true; // Assume first run on error to be safe
    }
  }

  Future<Map<String, DateTime?>> _getStoredTimestamps() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, DateTime?> timestamps = {};
    
    // Get all keys that start with _lastUpdateKey
    final allKeys = prefs.getKeys();
    final timestampKeys = allKeys.where((key) => key.startsWith(_lastUpdateKey));
    
    for (var key in timestampKeys) {
      final timestampStr = prefs.getString(key);
      if (timestampStr != null) {
        try {
          timestamps[key.replaceFirst('${_lastUpdateKey}_', '')] = DateTime.parse(timestampStr);
        } catch (e) {
          _log('TTT_Error parsing timestamp for $key: $e');
        }
      }
    }
    
    return timestamps;
  }

  Future<bool> _hasContentUpdates() async {
    HttpClient? client;
    try {
      _log('\nTTT_=== Checking for Content Updates ===');
      
      // Get stored timestamps
      final prefs = await SharedPreferences.getInstance();
      final Map<String, DateTime> storedTimestamps = {};
      
      // Get all stored timestamps
      final allKeys = prefs.getKeys();
      final timestampKeys = allKeys.where((key) => key.startsWith(_lastUpdateKey));
      for (var key in timestampKeys) {
        final timestampStr = prefs.getString(key);
        if (timestampStr != null) {
          try {
            final contentKey = key.replaceFirst('${_lastUpdateKey}_', '');
            storedTimestamps[contentKey] = DateTime.parse(timestampStr);
          } catch (e) {
            _log('TTT_Error parsing timestamp for $key: $e');
          }
        }
      }
      
      _log('TTT_Stored timestamps: $storedTimestamps');
      
      // 💡 Create HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      final uri = Uri.parse(Constants.contentTimestampsUrl);
      final request = await client.postUrl(uri);
      
      // Add headers
      Constants.defaultHeaders.forEach((key, value) {
        request.headers.set(key, value);
      });
      request.headers.contentType = ContentType.json;

      // Add body
      request.write('{}');

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode != 200) {
        _log('TTT_API request failed: ${response.statusCode}');
        return false;
      }

      final data = json.decode(responseBody);
      if (!data['success'] || data['data'] == null) {
        _log('TTT_Invalid response format');
        return false;
      }

      final serverTimestamps = data['data'] as Map<String, dynamic>;
      final List<Map<String, String>> needsUpdate = [];

      // Compare timestamps and collect what needs updating
      for (var page in serverTimestamps.keys) {
        final pageData = serverTimestamps[page] as Map<String, dynamic>;
        for (var keyName in pageData.keys) {
          final contentLastUpdateTime = DateTime.parse(pageData[keyName]);
          final storedKey = '${page}_${keyName}';
          final lastCheckTime = storedTimestamps[storedKey];

          // Only update if content was updated after our last check
          if (lastCheckTime == null || contentLastUpdateTime.isAfter(lastCheckTime)) {
            _log('TTT_Update needed for $storedKey - Content updated: ${contentLastUpdateTime.toIso8601String()}');
            needsUpdate.add({
              'page': page,
              'keyName': keyName,
            });
            // Update timestamp for this specific content
            await prefs.setString('${_lastUpdateKey}_$storedKey', contentLastUpdateTime.toIso8601String());
          }
        }
      }

      if (needsUpdate.isEmpty) {
        _log('TTT_No updates needed');
        return false;
      }

      // Store the items that need updating for later use
      _memoryCache['_pending_updates'] = needsUpdate;
      _log('TTT_Updates needed for: ${needsUpdate.map((u) => "${u['page']}/${u['keyName']}").join(", ")}');
      
      return true;
    } catch (e) {
      _log('TTT_Error checking for updates: $e');
      return false;
    } finally {
      client?.close();
    }
  }

  Future<bool> _updateAllContent(Map<String, dynamic> tempCache) async {
    HttpClient? client;
    try {
      _log('\nTTT_=== Updating All Content ===');
      
      // 💡 Get and properly cast the pending updates list
      final dynamic pendingUpdatesRaw = _memoryCache['_pending_updates'];
      if (pendingUpdatesRaw == null) {
        _log('TTT_No pending updates found');
        return false;
      }

      final List<Map<String, String>> pendingUpdates = (pendingUpdatesRaw as List<dynamic>)
          .map((update) => {
                'page': update['page']?.toString() ?? '',
                'keyName': update['keyName']?.toString() ?? '',
              })
          .where((update) => update['page']!.isNotEmpty && update['keyName']!.isNotEmpty)
          .toList();

      if (pendingUpdates.isEmpty) {
        _log('TTT_No valid pending updates found after casting');
        return false;
      }

      bool updateSuccess = true;
      
      // 💡 Copy existing content to tempCache first
      tempCache.addAll(_memoryCache);

      // Fetch each content item that needs updating
      for (final update in pendingUpdates) {
        _log('TTT_Fetching content for page: ${update['page']}, key: ${update['keyName']}');
        
        // 💡 Create HttpClient that accepts self-signed certificates
        client = HttpClient()
          ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

        final uri = Uri.parse(Constants.masterFetchUrl);
        final request = await client.postUrl(uri);
        
        // Add headers
        Constants.defaultHeaders.forEach((key, value) {
          request.headers.set(key, value);
        });
        request.headers.contentType = ContentType.json;

        // Add body
        request.write(json.encode({
          'Page': update['page'],
          'KeyName': update['keyName'],
        }));

        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode != 200) {
          _log('TTT_API request failed: ${response.statusCode}');
          updateSuccess = false;
          continue;
        }

        final data = json.decode(responseBody);
        if (!data['success'] || data['data'] == null) {
          _log('TTT_Invalid response format');
          updateSuccess = false;
          continue;
        }

        final content = data['data'];
        final keyName = update['keyName']!;
          
        // 💡 Remove old content and related files before updating
        _removeOldContent(tempCache, keyName);
          
        if (keyName.startsWith('slideshow_content')) {
          if (content['slides'] != null) {
            tempCache[keyName] = content['slides'];
            if (!await _processSlideImages(keyName, content['slides'], tempCache)) {
              updateSuccess = false;
            }
          }
        } else if (keyName.contains('contact_details')) {
          if (content['contact'] != null) {
            tempCache[keyName] = content['contact'];
            _log('TTT_Saving contact details for key: $keyName');
          }
        } else if (keyName.endsWith('_ad')) {
          if (content['ads'] != null) {
            tempCache[keyName] = content['ads'];
            if (!await _processAdImage(keyName, content['ads'], tempCache)) {
              updateSuccess = false;
            }
          }
        }
        // 💡 Add PDF content handling
        else if (keyName.contains('terms') || keyName.contains('privacy')) {
          if (content['url'] != null) {
            tempCache[keyName] = content['url'];
            if (!await _downloadAndCacheImage(keyName, content['url'], tempCache)) {
              updateSuccess = false;
            }
          }
        }

        // Save the timestamp
        if (content['last_updated'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('${_lastUpdateKey}_${update['page']}_${keyName}', content['last_updated']);
          _log('TTT_Saved timestamp for ${update['page']}_${keyName}: ${content['last_updated']}');
        }

        client?.close();
      }

      // Clear pending updates
      _memoryCache.remove('_pending_updates');
      
      _log('TTT_Content update ${updateSuccess ? 'successful' : 'failed'}');
      _log('TTT_Updated content keys: ${tempCache.keys.join(', ')}');
      
      return updateSuccess && tempCache.isNotEmpty;
    } catch (e) {
      _log('TTT_Error updating content: $e');
      return false;
    } finally {
      client?.close();
    }
  }

  // 💡 Helper method to remove old content and related files
  void _removeOldContent(Map<String, dynamic> cache, String keyName) {
    // Remove the main content
    cache.remove(keyName);
    
    // Remove related image files
    if (keyName.startsWith('slideshow_content')) {
      // Remove all related slide images
      cache.removeWhere((key, _) => 
        key.startsWith('slide_') && 
        (key.contains(keyName.contains('_ar') ? 'ar_' : 'en_')));
    } else if (keyName.endsWith('_ad')) {
      // Remove ad image
      cache.remove('${keyName}_image_bytes');
    } else if (keyName.contains('terms') || keyName.contains('privacy')) {
      // Remove document file
      cache.remove('${keyName}_bytes');
    }
  }

  Future<bool> _processSlideImages(String keyName, List<dynamic> slides, Map<String, dynamic> tempCache) async {
    try {
      for (final slide in slides) {
        if (slide['image_url'] != null && slide['image_url'].toString().startsWith('http')) {
          final imageKey = keyName == 'slideshow_content_ar' 
              ? 'slide_ar_${slide['slide_id']}_image' 
              : 'slide_${slide['slide_id']}_image';
          if (!await _downloadAndCacheImage(imageKey, slide['image_url'], tempCache)) {
            return false;
          }
        }
      }
      return true;
    } catch (e) {
      _log('TTT_Error processing slide images: $e');
      return false;
    }
  }

  Future<bool> _processAdImage(String keyName, Map<String, dynamic> adData, Map<String, dynamic> tempCache) async {
    try {
      if (adData['image_url'] != null && adData['image_url'].toString().startsWith('http')) {
        return await _downloadAndCacheImage('${keyName}_image', adData['image_url'], tempCache);
      }
      return true;
    } catch (e) {
      _log('TTT_Error processing ad image: $e');
      return false;
    }
  }

  Future<bool> _downloadAndCacheImage(String key, String url, [Map<String, dynamic>? targetCache]) async {
    HttpClient? client;
    try {
      // 💡 Create HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      final uri = Uri.parse(url);
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>(
          [],
          (previous, element) => previous..addAll(element),
        );
        final cacheKey = '${key}_bytes';
        
        final cache = targetCache ?? _memoryCache;
        cache[cacheKey] = bytes;
        
        _log('TTT_Downloaded and cached image: $key (${bytes.length} bytes)');
        return true;
      }
      _log('TTT_Failed to download image: $key');
      return false;
    } catch (e) {
      _log('TTT_Error downloading image: $e');
      return false;
    } finally {
      client?.close();
    }
  }

  Future<bool> _verifySavedContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedContent = prefs.getString(_contentCacheKey);
      
      if (savedContent == null) {
        _log('TTT_No saved content found during verification');
        return false;
      }

      final decodedContent = json.decode(savedContent) as Map<String, dynamic>;
      final memoryKeys = _memoryCache.keys.where((k) => !k.endsWith('_bytes')).toSet();
      final savedKeys = decodedContent.keys.toSet();

      if (!const SetEquality().equals(memoryKeys, savedKeys)) {
        _log('TTT_Saved content keys do not match memory cache');
        _log('TTT_Memory: ${memoryKeys.join(', ')}');
        _log('TTT_Saved: ${savedKeys.join(', ')}');
        return false;
      }

      return true;
    } catch (e) {
      _log('TTT_Error verifying saved content: $e');
      return false;
    }
  }

  Future<void> _saveContentToCache() async {
    try {
      _log('\nTTT_=== Saving Content to Cache ===');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Save non-binary content
      final contentToSave = Map<String, dynamic>.from(_memoryCache);
      contentToSave.removeWhere((key, value) => value is Uint8List || key.endsWith('_bytes'));
      
      if (contentToSave.isNotEmpty) {
        final jsonString = json.encode(contentToSave);
        await prefs.setString(_contentCacheKey, jsonString);
        _log('TTT_Saved content keys: ${contentToSave.keys.join(', ')}');
      }
      
      // Save binary content
      if (_cacheDir != null) {
        // Clear old binary files
        if (await _cacheDir!.exists()) {
          await for (var file in _cacheDir!.list()) {
            if (file is File && file.path.endsWith('.bin')) {
              await file.delete();
            }
          }
        }
        
        // Save new binary files
        for (var entry in _memoryCache.entries) {
          if (entry.value is Uint8List) {
            final fileName = entry.key.replaceAll('_bytes', '');
            final file = File('${_cacheDir!.path}/$fileName.bin');
            await file.writeAsBytes(entry.value as Uint8List);
            _log('TTT_Saved binary file: $fileName');
          }
        }
      }
      
      // Update timestamp
      final now = DateTime.now();
      await prefs.setString(_lastUpdateKey, now.toIso8601String());
      _lastUpdateTime = now;
      
      _log('TTT_Cache save completed successfully');
    } catch (e) {
      _log('TTT_Error saving to cache: $e');
    }
  }

  Future<bool> _loadCachedContent() async {
    try {
      _log('\nTTT_=== Loading Cached Content ===');
      
      final prefs = await SharedPreferences.getInstance();
      bool success = false;

      // Load JSON content
      final cachedContentStr = prefs.getString(_contentCacheKey);
      if (cachedContentStr != null) {
        try {
          final cachedContent = json.decode(cachedContentStr) as Map<String, dynamic>;
          _memoryCache.addAll(Map<String, dynamic>.from(cachedContent));
          success = true;
          _log('TTT_Loaded JSON content: ${cachedContent.keys.join(', ')}');
        } catch (e) {
          _log('TTT_Error parsing cached content: $e');
        }
      }

      // Load binary content
      if (_cacheDir != null && await _cacheDir!.exists()) {
        try {
          final files = await _cacheDir!.list().toList();
          for (var file in files) {
            if (file is File && file.path.endsWith('.bin')) {
              final bytes = await file.readAsBytes();
              final fileName = file.path.split('/').last;
              final key = '${fileName.split('.').first}_bytes';
              _memoryCache[key] = bytes;
              success = true;
            }
          }
          _log('TTT_Loaded binary content: ${_memoryCache.keys.where((k) => k.endsWith('_bytes')).join(', ')}');
        } catch (e) {
          _log('TTT_Error loading binary content: $e');
        }
      }

      _log('TTT_Cache load complete. Success: $success');
      return success;
    } catch (e) {
      _log('TTT_Error loading cached content: $e');
      return false;
    }
  }

  // Helper methods to get content
  List<Slide> getSlides({bool isArabic = false}) {
    final key = isArabic ? 'slideshow_content_ar' : 'slideshow_content';
    _log('\nTTT_=== Getting Slides ===');
    _log('TTT_Looking for slides with key: $key');
    
    final slidesData = _memoryCache[key];
    if (slidesData != null && slidesData is List) {
      _log('TTT_Found ${slidesData.length} slides');
      
      return slidesData.map((slideData) {
        final slideId = slideData['slide_id'] ?? 0;
        final imageKey = isArabic 
            ? 'slide_ar_${slideId}_image_bytes' 
            : 'slide_${slideId}_image_bytes';
            
        return Slide(
          id: slideId,
          imageUrl: slideData['image_url'] ?? '',
          link: slideData['link'] ?? '',
          leftTitle: slideData['leftTitle'] ?? '',
          rightTitle: slideData['rightTitle'] ?? '',
          imageBytes: _memoryCache[imageKey] as List<int>?,
        );
      }).toList();
    }
    
    return [];
  }

  ContactDetails? getContactDetails({bool isArabic = false}) {
    final contactData = _memoryCache['contact_details'];
    if (contactData != null && contactData is Map<String, dynamic>) {
      return ContactDetails.fromJson(contactData);
    }
    return null;
  }

  Map<String, dynamic>? getLoanAd({bool isArabic = false}) {
    final adData = _memoryCache['loan_ad'];
    if (adData != null) {
      final imageBytes = _memoryCache['loan_ad_image_bytes'];
      if (imageBytes != null) {
        return {
          ...adData,
          'image_bytes': imageBytes,
        };
      }
      return adData;
    }
    return Constants.loanAd[isArabic ? 'ar' : 'en'];
  }

  Map<String, dynamic>? getCardAd({bool isArabic = false}) {
    final adData = _memoryCache['card_ad'];
    if (adData != null) {
      final imageBytes = _memoryCache['card_ad_image_bytes'];
      if (imageBytes != null) {
        return {
          ...adData,
          'image_bytes': imageBytes,
        };
      }
      return adData;
    }
    return Constants.cardAd[isArabic ? 'ar' : 'en'];
  }
}

// Add copyWith method to Slide class
extension SlideExtension on Slide {
  Slide copyWith({
    int? id,
    String? imageUrl,
    String? link,
    String? leftTitle,
    String? rightTitle,
    List<int>? imageBytes,
  }) {
    return Slide(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      link: link ?? this.link,
      leftTitle: leftTitle ?? this.leftTitle,
      rightTitle: rightTitle ?? this.rightTitle,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }
} 