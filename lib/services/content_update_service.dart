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
  
  ContentUpdateService._internal();

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

  void _log(String message) {
    if (foundation.kDebugMode) {
      foundation.debugPrint('TTT_$message');
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
    try {
      _log('\nTTT_=== Checking for Content Updates ===');
      _log('TTT_Making API call to check for updates...');
      
      // Get stored timestamps
      final storedTimestamps = await _getStoredTimestamps();
      _log('TTT_Stored timestamps: ${storedTimestamps.map((k, v) => MapEntry(k, v?.toIso8601String() ?? 'Never'))}');
      
      // Get all content update timestamps in one call
      final response = await http.get(
        Uri.parse(updateCheckUrl).replace(
          queryParameters: {
            'action': 'checkupdate'
          },
        ),
        headers: Constants.defaultHeaders,
      );
      
      _log('TTT_API Request URL: ${response.request?.url.toString()}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log('TTT_API Response: ${json.encode(data)}');
        
        if (data['success'] == true && data['data'] != null) {
          final updates = data['data'] as Map<String, dynamic>;
          bool hasAnyUpdates = false;
          
          _log('\nTTT_Checking timestamps for each content type:');
          
          for (var entry in updates.entries) {
            final keyName = entry.key;
            final serverTimestamp = DateTime.parse(entry.value);
            final storedTimestamp = storedTimestamps[keyName];
            
            _log('TTT_$keyName:');
            _log('TTT_  Server timestamp: ${serverTimestamp.toString()}');
            _log('TTT_  Stored timestamp: ${storedTimestamp?.toString() ?? 'Never'}');
            
            if (storedTimestamp == null || serverTimestamp.isAfter(storedTimestamp)) {
              _log('TTT_  Update needed for $keyName');
              hasAnyUpdates = true;
            } else {
              _log('TTT_  No update needed for $keyName');
            }
          }

          if (hasAnyUpdates) {
            _log('TTT_Server has newer content - updates needed');
            return true;
          }
        }
      }
      
      _log('TTT_Content is up to date - no updates needed');
      return false;
    } catch (e, stackTrace) {
      _log('TTT_Error checking for updates: $e');
      _log('TTT_Stack trace: $stackTrace');
      return false;
    }
  }

  Future<void> _updateAllContent() async {
    try {
      _log('\nTTT_=== Updating All Content ===');
      
      final response = await http.get(
        Uri.parse(updateCheckUrl).replace(
          queryParameters: {
            'action': 'fetchdata'
          },
        ),
        headers: Constants.defaultHeaders,
      );
      
      _log('TTT_API Request URL: ${response.request?.url.toString()}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log('TTT_API Response received');
        
        if (data['success'] == true && data['data'] != null) {
          final content = data['data'] as Map<String, dynamic>;
          final prefs = await SharedPreferences.getInstance();
          
          // Clear existing cache before updating
          _memoryCache.clear();
          
          // Process each content type
          for (var entry in content.entries) {
            final keyName = entry.key;
            final contentData = entry.value;
            _log('\nTTT_Processing $keyName:');
            
            if (contentData['data'] != null) {
              // Save the timestamp for this content type
              if (contentData['last_updated'] != null) {
                await prefs.setString('${_lastUpdateKey}_$keyName', contentData['last_updated']);
                _log('TTT_Saved timestamp for $keyName: ${contentData['last_updated']}');
              }
              
              // Store the content data first
              _memoryCache[keyName] = contentData['data'];
              
              // Handle images for slides
              if (keyName.startsWith('slideshow_content')) {
                final slides = contentData['data'] as List;
                _log('TTT_Processing ${slides.length} slides for $keyName');
                
                for (var i = 0; i < slides.length; i++) {
                  if (slides[i]['image_url'] != null) {
                    final imageUrl = slides[i]['image_url'];
                    if (imageUrl.startsWith('http')) {
                      final slideId = slides[i]['slide_id'];
                      final imageKey = keyName == 'slideshow_content_ar' 
                          ? 'slide_ar_${slideId}_image' 
                          : 'slide_${slideId}_image';
                      _log('TTT_Downloading slide image: $imageUrl');
                      await _downloadAndCacheImage(imageKey, imageUrl);
                      
                      // Verify the image was cached
                      final cachedImageKey = '${imageKey}_bytes';
                      if (_memoryCache[cachedImageKey] == null) {
                        _log('TTT_Warning: Failed to cache image for slide $slideId');
                      } else {
                        _log('TTT_Successfully cached image for slide $slideId');
                      }
                    }
                  }
                }
              }
              
              // Handle images for ads
              if (keyName.endsWith('_ad')) {
                if (contentData['data']['image_url'] != null) {
                  final imageUrl = contentData['data']['image_url'];
                  _log('TTT_Downloading ad image: $imageUrl');
                  await _downloadAndCacheImage('${keyName}_image', imageUrl);
                }
              }
              
              _log('TTT_Updated $keyName');
            }
          }
          
          // Save all updated content to cache
          await _saveContentToCache();
          _log('TTT_All content updated successfully');
          
          // Force notify listeners to update UI
          notifyListeners();
        } else {
          _log('TTT_API Response missing success or data: ${json.encode(data)}');
        }
      } else {
        _log('TTT_API request failed with status: ${response.statusCode}');
        _log('TTT_Response body: ${response.body}');
      }
      
      _log('TTT_=== Content Update Complete ===\n');
    } catch (e, stackTrace) {
      _log('TTT_Error updating content: $e');
      _log('TTT_Stack trace: $stackTrace');
    }
  }

  Future<void> checkAndUpdateContent({bool force = false, bool isInitialLoad = false, bool isResumed = false}) async {
    try {
      _log('\nTTT_=== Content Update Check ===');
      _log('TTT_Force update: $force, Initial load: $isInitialLoad, Resumed: $isResumed');
      
      // Always load cached content first if not done yet
      if (!_initialLoadDone) {
        await _loadCachedContent();
        _initialLoadDone = true;
      }

      // Check if this is first run
      if (await _isAppFirstRun()) {
        _log('TTT_First run detected - forcing content update');
        // Show loading only if we're not in splash screen
        if (!isInitialLoad) {
          _isUpdating = true;
          notifyListeners();
        }
        await _updateAllContent();
        return;
      }

      // For resume/background scenarios, check the interval first
      if (isResumed && !force) {
        final prefs = await SharedPreferences.getInstance();
        final lastCheckStr = prefs.getString(_lastCheckKey);
        final lastCheck = lastCheckStr != null ? DateTime.parse(lastCheckStr) : null;
        final now = DateTime.now();

        // If minimum check interval hasn't passed, skip update check completely
        if (lastCheck != null && now.difference(lastCheck) < _minimumCheckInterval) {
          _log('TTT_Skipping update check - last check was too recent (${now.difference(lastCheck).inSeconds}s ago)');
          return;
        }

        // Update last check time before making the API call
        await prefs.setString(_lastCheckKey, now.toIso8601String());

        // Check for updates if cache is empty or enough time has passed
        _log('TTT_Checking for updates on resume');
        final hasUpdates = await _hasContentUpdates();
        if (hasUpdates) {
          // Show loading screen before starting updates
          _isUpdating = true;
          notifyListeners();
          
          // Update all content
          await _updateAllContent();
        } else {
          _log('TTT_No updates available');
        }
        return;
      }

      // Handle initial load or forced update
      if (!isResumed) {
        // First check if we need to check for updates based on interval
        final prefs = await SharedPreferences.getInstance();
        final lastCheckStr = prefs.getString(_lastCheckKey);
        final lastCheck = lastCheckStr != null ? DateTime.parse(lastCheckStr) : null;
        final now = DateTime.now();

        // If within minimum check interval and we have cached data, use cache
        // Don't skip if it's a forced update (but ignore force if it's initial load)
        if ((!force || isInitialLoad) && lastCheck != null && 
            now.difference(lastCheck) < _minimumCheckInterval && 
            _memoryCache.isNotEmpty) {
          _log('TTT_Using cached data - last check was too recent (${now.difference(lastCheck).inSeconds}s ago)');
          return;
        }

        // Update last check time before making API call
        await prefs.setString(_lastCheckKey, now.toIso8601String());
        
        // Only check for updates if forced (and not initial load) or interval passed
        if ((force && !isInitialLoad) || lastCheck == null || now.difference(lastCheck) >= _minimumCheckInterval) {
          _log('TTT_Checking for content updates...');
          final hasUpdates = await _hasContentUpdates();
          if (hasUpdates || (force && !isInitialLoad)) {
            // Show loading only if we're not in splash screen
            if (!isInitialLoad) {
              _isUpdating = true;
              notifyListeners();
            }
            
            // Update all content
            await _updateAllContent();
          } else {
            _log('TTT_No updates available - using cached content');
          }
        }
      }
    } catch (e) {
      _log('TTT_Error checking for content updates: $e');
    } finally {
      // Clear updating status if it was set
      if (_isUpdating) {
        _isUpdating = false;
        notifyListeners();
      }
    }
  }

  Future<bool> _updateAds() async {
    try {
      bool updated = false;
      _log('Updating ads...');
      
      // Update loan ad
      _log('Checking loan ad updates...');
      final loanAdResponse = await http.get(
        Uri.parse(updateCheckUrl).replace(
          queryParameters: {
            'page': 'loans',
            'key_name': 'loan_ad',
            'action': 'fetchdata'
          },
        ),
        headers: Constants.defaultHeaders,
      );
      
      if (loanAdResponse.statusCode == 200) {
        final data = json.decode(loanAdResponse.body);
        if (data['success'] == true && data['data'] != null) {
          // Download and cache the image before updating the ad data
          if (data['data']['image_url'] != null) {
            _log('Downloading loan ad image: ${data['data']['image_url']}');
            await _downloadAndCacheImage('loan_ad_image', data['data']['image_url']);
          }
          _memoryCache['loan_ad'] = data['data'];
          updated = true;
          _log('Loan ad updated');
        }
      }

      // Update card ad
      _log('Checking card ad updates...');
      final cardAdResponse = await http.get(
        Uri.parse(updateCheckUrl).replace(
          queryParameters: {
            'page': 'cards',
            'key_name': 'card_ad',
            'action': 'fetchdata'
          },
        ),
        headers: Constants.defaultHeaders,
      );
      
      if (cardAdResponse.statusCode == 200) {
        final data = json.decode(cardAdResponse.body);
        if (data['success'] == true && data['data'] != null) {
          // Download and cache the image before updating the ad data
          if (data['data']['image_url'] != null) {
            _log('Downloading card ad image: ${data['data']['image_url']}');
            await _downloadAndCacheImage('card_ad_image', data['data']['image_url']);
          }
          _memoryCache['card_ad'] = data['data'];
          updated = true;
          _log('Card ad updated');
        }
      }
      
      return updated;
    } catch (e) {
      _log('Error updating ads: $e');
      return false;
    }
  }

  Future<bool> _updateSlides() async {
    try {
      _log('Updating slides...');
      final response = await http.get(
        Uri.parse(updateCheckUrl).replace(
          queryParameters: {
            'page': 'home',
            'key_name': 'slideshow_content',
            'action': 'fetchdata'
          },
        ),
        headers: Constants.defaultHeaders,
      );

      bool updated = false;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // Download and cache all slide images before updating the slides data
          final List<dynamic> slides = data['data'];
          for (var i = 0; i < slides.length; i++) {
            if (slides[i]['image_url'] != null) {
              final imageUrl = slides[i]['image_url'];
              // Only download if it's a URL, not an asset path
              if (imageUrl.startsWith('http')) {
                _log('Downloading slide image ${i + 1}: $imageUrl');
                await _downloadAndCacheImage('slide_${slides[i]['slide_id']}_image', imageUrl);
              } else {
                _log('Slide ${i + 1} uses asset path: $imageUrl');
              }
            }
          }
          _memoryCache['slides'] = data['data'];
          updated = true;
          _log('Slides updated');
          
          // Also fetch Arabic slides
          final arResponse = await http.get(
            Uri.parse(updateCheckUrl).replace(
              queryParameters: {
                'page': 'home',
                'key_name': 'slideshow_content_ar',
                'action': 'fetchdata'
              },
            ),
            headers: Constants.defaultHeaders,
          );
          
          if (arResponse.statusCode == 200) {
            final arData = json.decode(arResponse.body);
            if (arData['success'] == true && arData['data'] != null) {
              // Download and cache all Arabic slide images
              final List<dynamic> arSlides = arData['data'];
              for (var i = 0; i < arSlides.length; i++) {
                if (arSlides[i]['image_url'] != null) {
                  final imageUrl = arSlides[i]['image_url'];
                  // Only download if it's a URL, not an asset path
                  if (imageUrl.startsWith('http')) {
                    _log('Downloading Arabic slide image ${i + 1}: $imageUrl');
                    await _downloadAndCacheImage('slide_ar_${arSlides[i]['slide_id']}_image', imageUrl);
                  } else {
                    _log('Arabic slide ${i + 1} uses asset path: $imageUrl');
                  }
                }
              }
              _memoryCache['slides_ar'] = arData['data'];
              _log('Arabic slides updated');
            }
          }
        }
      }
      
      return updated;
    } catch (e) {
      _log('Error updating slides: $e');
      return false;
    }
  }

  Future<bool> _updateContactDetails() async {
    try {
      _log('Updating contact details...');
      final response = await http.get(
        Uri.parse(updateCheckUrl).replace(
          queryParameters: {
            'page': 'home',
            'key_name': 'contact_details',
            'action': 'fetchdata'
          },
        ),
        headers: Constants.defaultHeaders,
      );

      bool updated = false;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          _memoryCache['contact_details'] = data['data'];
          updated = true;
          _log('Contact details updated');
          
          // Also fetch Arabic contact details
          final arResponse = await http.get(
            Uri.parse(updateCheckUrl).replace(
              queryParameters: {
                'page': 'home',
                'key_name': 'contact_details_ar',
                'action': 'fetchdata'
              },
            ),
            headers: Constants.defaultHeaders,
          );
          
          if (arResponse.statusCode == 200) {
            final arData = json.decode(arResponse.body);
            if (arData['success'] == true && arData['data'] != null) {
              _memoryCache['contact_details_ar'] = arData['data'];
              _log('Arabic contact details updated');
            }
          }
        }
      }
      
      return updated;
    } catch (e) {
      _log('Error updating contact details: $e');
      return false;
    }
  }

  Future<void> _loadCachedContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedContentStr = prefs.getString(_contentCacheKey);
      final lastUpdateStr = prefs.getString(_lastUpdateKey);
      
      _log('\nTTT_=== Loading Cached Content ===');
      _log('TTT_Current in-memory update time: ${_lastUpdateTime?.toIso8601String() ?? 'Never'}');
      _log('TTT_Found stored update time: ${lastUpdateStr ?? 'Never'}');
      
      if (lastUpdateStr != null) {
        _lastUpdateTime = DateTime.parse(lastUpdateStr);
        _log('TTT_Loaded last update time: ${_lastUpdateTime?.toIso8601String()}');
      }
      
      // First load binary content from file system
      await _loadBinaryContent();
      _log('TTT_Loaded binary content keys: ${_memoryCache.keys.where((k) => k.endsWith('_bytes')).join(', ')}');
      
      // Then load JSON content from SharedPreferences
      if (cachedContentStr != null) {
        final cachedContent = json.decode(cachedContentStr);
        _memoryCache.addAll(Map<String, dynamic>.from(cachedContent));
        _log('TTT_Loaded JSON content keys: ${cachedContent.keys.join(', ')}');
      }
      
      _log('TTT_=== Cache Load Complete ===\n');
    } catch (e) {
      _log('TTT_Error loading cached content: $e');
    }
  }

  Future<void> _loadBinaryContent() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final contentDir = Directory('${directory.path}/content_cache');
      
      if (await contentDir.exists()) {
        _log('Loading binary content from: ${contentDir.path}');
        final files = await contentDir.list().toList();
        for (var file in files) {
          if (file is File && file.path.endsWith('.bin')) {
            final fileName = file.path.split('/').last;
            final key = '${fileName.split('.').first}_bytes';  // Add _bytes suffix to match our cache keys
            final bytes = await file.readAsBytes();
            _memoryCache[key] = bytes;
            _log('Loaded binary file: $key (${bytes.length} bytes)');
          }
        }
      } else {
        _log('Content cache directory does not exist');
      }
    } catch (e) {
      _log('Error loading binary content: $e');
    }
  }

  Future<void> _saveContentToCache() async {
    try {
      _log('\nTTT_=== Saving Content to Cache ===');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Create a copy of memory cache without binary data
      final cacheCopy = Map<String, dynamic>.from(_memoryCache);
      cacheCopy.removeWhere((key, value) => value is Uint8List);
      
      // Save JSON content
      await prefs.setString(_contentCacheKey, json.encode(cacheCopy));
      
      // Save timestamps for each content type
      for (var entry in cacheCopy.entries) {
        if (entry.value is Map && entry.value['last_updated'] != null) {
          final timestamp = entry.value['last_updated'];
          await prefs.setString('${_lastUpdateKey}_${entry.key}', timestamp);
          _log('TTT_Saved timestamp for ${entry.key}: $timestamp');
        }
      }
      
      _log('TTT_Saved JSON content keys: ${cacheCopy.keys.join(', ')}');
      
      // Save binary content
      await _saveBinaryContent();
      
      _log('TTT_=== Cache Save Complete ===\n');
      
      // Notify listeners that content has been updated
      notifyListeners();
    } catch (e) {
      _log('TTT_Error saving content to cache: $e');
    }
  }

  Future<void> _saveBinaryContent() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final contentDir = Directory('${directory.path}/content_cache');
      
      if (!await contentDir.exists()) {
        await contentDir.create(recursive: true);
      }

      // First, clear old binary files
      final existingFiles = await contentDir.list().toList();
      for (var file in existingFiles) {
        if (file is File && file.path.endsWith('.bin')) {
          await file.delete();
        }
      }

      // Save binary content to files
      for (var entry in _memoryCache.entries) {
        if (entry.key.endsWith('_bytes') && entry.value is Uint8List) {
          final fileName = entry.key.replaceAll('_bytes', '');  // Remove _bytes suffix for file name
          final file = File('${contentDir.path}/$fileName.bin');
          await file.writeAsBytes(entry.value as Uint8List);
          _log('Saved binary file: ${file.path} (${(entry.value as Uint8List).length} bytes)');
        }
      }
    } catch (e) {
      _log('Error saving binary content: $e');
    }
  }

  Future<void> _processUpdates(Map<String, dynamic> updates) async {
    for (var entry in updates.entries) {
      final String key = entry.key;
      final Map<String, dynamic> content = entry.value;
      
      if (content['update_status'] == true) {
        switch (content['type']) {
          case 'image':
            await _downloadAndSaveImage(key, content['url']);
            break;
          case 'animation':
            await _downloadAndSaveAnimation(key, content['url']);
            break;
          case 'text':
            _memoryCache[key] = content['value'];
            break;
          case 'link':
            _memoryCache[key] = content['url'];
            break;
        }
      }
    }
  }

  Future<void> _downloadAndSaveImage(String key, String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        _memoryCache[key] = response.bodyBytes;
      }
    } catch (e) {
      _log('Error downloading image $key: $e');
    }
  }

  Future<void> _downloadAndSaveAnimation(String key, String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        _memoryCache[key] = response.bodyBytes;
      }
    } catch (e) {
      _log('Error downloading animation $key: $e');
    }
  }

  Future<void> _downloadAndCacheImage(String key, String url) async {
    try {
      _log('Downloading image for $key from $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final cacheKey = '${key}_bytes';
        _memoryCache[cacheKey] = bytes;
        _log('Downloaded image size: ${bytes.length} bytes');
        _log('Cached with key: $cacheKey');
        
        // Save to file system immediately
        final directory = await getApplicationDocumentsDirectory();
        final contentDir = Directory('${directory.path}/content_cache');
        if (!await contentDir.exists()) {
          await contentDir.create(recursive: true);
        }
        
        final file = File('${contentDir.path}/$key.bin');
        await file.writeAsBytes(bytes);
        _log('Image cached successfully for $key at: ${file.path}');
        
        // Save updated cache state
        await _saveContentToCache();
        
        // Verify the cached data
        final cachedBytes = _memoryCache[cacheKey];
        if (cachedBytes != null) {
          _log('Verified cached image size: ${(cachedBytes as Uint8List).length} bytes');
        } else {
          _log('Warning: Image bytes not found in memory cache after saving');
        }
      } else {
        _log('Failed to download image for $key: ${response.statusCode}');
      }
    } catch (e) {
      _log('Error downloading image for $key: $e');
    }
  }

  // Helper methods to get updated content
  Map<String, dynamic>? getLoanAd({bool isArabic = false}) {
    final adData = _memoryCache['loan_ad'];
    if (adData != null) {
      final imageUrl = adData['image_url'];
      if (imageUrl != null && imageUrl.startsWith('http')) {
        final imageBytes = _memoryCache['loan_ad_image_bytes'];
        _log('TTT_Looking for loan ad image bytes');
        if (imageBytes != null) {
          _log('TTT_Found loan ad image: ${(imageBytes as Uint8List).length} bytes');
          return {
            ...adData,
            'image_bytes': imageBytes,
          };
        } else {
          _log('TTT_No cached image found for loan ad - will trigger download');
          // If we don't have the image cached, trigger a download
          _downloadAndCacheImage('loan_ad_image', imageUrl);
        }
      }
      return adData;
    }
    return Constants.loanAd[isArabic ? 'ar' : 'en'];
  }

  Map<String, dynamic>? getCardAd({bool isArabic = false}) {
    final adData = _memoryCache['card_ad'];
    if (adData != null) {
      final imageUrl = adData['image_url'];
      if (imageUrl != null && imageUrl.startsWith('http')) {
        final imageBytes = _memoryCache['card_ad_image_bytes'];
        _log('TTT_Looking for card ad image bytes');
        if (imageBytes != null) {
          _log('TTT_Found card ad image: ${(imageBytes as Uint8List).length} bytes');
          return {
            ...adData,
            'image_bytes': imageBytes,
          };
        } else {
          _log('TTT_No cached image found for card ad - will trigger download');
          // If we don't have the image cached, trigger a download
          _downloadAndCacheImage('card_ad_image', imageUrl);
        }
      }
      return adData;
    }
    return Constants.cardAd[isArabic ? 'ar' : 'en'];
  }

  List<Slide> getSlides({bool isArabic = false}) {
    final key = isArabic ? 'slideshow_content_ar' : 'slideshow_content';
    final slidesData = _memoryCache[key];
    if (slidesData != null) {
      _log('\nTTT_=== Getting Slides ===');
      _log('TTT_Available cache keys: ${_memoryCache.keys.where((k) => k.contains('bytes')).join(', ')}');
      
      return (slidesData as List).map((item) {
        final slideData = Map<String, dynamic>.from(item);
        final imageUrl = slideData['image_url'];
        final slideId = slideData['slide_id'];
        
        // Create the slide with all data
        final slide = Slide(
          id: slideId ?? 0,
          imageUrl: imageUrl ?? '',
          link: slideData['link'] ?? '',
          leftTitle: slideData['leftTitle'] ?? '',
          rightTitle: slideData['rightTitle'] ?? '',
          imageBytes: null, // Will be updated if cached image is found
        );
        
        // Only look for cached image if it's a URL
        if (imageUrl != null && imageUrl.startsWith('http')) {
          final imageKey = isArabic ? 'slide_ar_${slideId}_image_bytes' : 'slide_${slideId}_image_bytes';
          final imageBytes = _memoryCache[imageKey];
          _log('TTT_Looking for cached image with key: $imageKey');
          
          if (imageBytes != null) {
            _log('TTT_Found cached image: ${(imageBytes as Uint8List).length} bytes');
            return slide.copyWith(imageBytes: (imageBytes as Uint8List).toList());
          } else {
            _log('TTT_No cached image found for $imageKey - will trigger download');
            // If we don't have the image cached, trigger a download
            _downloadAndCacheImage(
              isArabic ? 'slide_ar_${slideId}_image' : 'slide_${slideId}_image',
              imageUrl
            );
          }
        }
        return slide;
      }).toList();
    }
    
    _log('TTT_No slides data found - using static slides');
    return Constants.staticSlides.map((slideData) => Slide(
      id: int.parse(slideData['id']!),
      imageUrl: slideData['imageUrl']!,
      leftTitle: isArabic ? slideData['leftTitleAr']! : slideData['leftTitleEn']!,
      rightTitle: isArabic ? slideData['rightTitleAr']! : slideData['rightTitleEn']!,
      link: slideData['link']!,
    )).toList();
  }

  ContactDetails getContactDetails({bool isArabic = false}) {
    final contactData = _memoryCache[isArabic ? 'contact_details_ar' : 'contact_details'];
    if (contactData != null) {
      return ContactDetails.fromJson(contactData);
    }
    final staticData = Constants.staticContactDetails;
    return ContactDetails(
      phone: staticData['phone'],
      email: staticData['email'],
      workHours: staticData['workHours'],
      socialLinks: Map<String, String>.from(staticData['socialLinks']),
    );
  }

  // Clear cache
  Future<void> clearCache() async {
    try {
      _log('\n=== Clearing Cache ===');
      _log('Current update time before clear: ${_lastUpdateTime?.toIso8601String() ?? 'Never'}');
      
      final prefs = await SharedPreferences.getInstance();
      final storedUpdateTime = prefs.getString(_lastUpdateKey);
      _log('Stored update time before clear: ${storedUpdateTime ?? 'Never'}');
      
      _memoryCache.clear();
      _lastUpdateTime = null;
      
      await prefs.remove(_contentCacheKey);
      await prefs.remove(_lastUpdateKey);
      await prefs.remove(_lastCheckKey);
      
      _log('Update times after clear:');
      _log('In-memory update time: ${_lastUpdateTime?.toIso8601String() ?? 'Never'}');
      _log('Stored update time: ${prefs.getString(_lastUpdateKey) ?? 'Never'}');
      
      final directory = await getApplicationDocumentsDirectory();
      final contentDir = Directory('${directory.path}/content_cache');
      if (await contentDir.exists()) {
        await contentDir.delete(recursive: true);
        _log('Deleted content cache directory');
      }
      _log('=== Cache Clear Complete ===\n');
    } catch (e) {
      _log('Error clearing cache: $e');
    }
  }

  // Add this method to force refresh content
  Future<void> forceRefresh() async {
    try {
      _log('\n=== Force Refreshing Content ===');
      
      // Clear all caches first
      await clearCache();
      
      // Force update all content
      await checkAndUpdateContent(force: true);
      
      _log('=== Force Refresh Complete ===\n');
    } catch (e) {
      _log('Error during force refresh: $e');
    }
  }

  // Update the test function to include cache testing
  Future<void> testContentUpdate() async {
    _log('\n=== Testing Content Update System ===');
    
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getString(_lastCheckKey);
    final lastUpdate = prefs.getString(_lastUpdateKey);
    
    _log('Last check time: ${lastCheck ?? 'Never'}');
    _log('Last update time: ${lastUpdate ?? 'Never'}');
    
    _log('\nCache State Before Update:');
    _log('Memory cache keys: ${_memoryCache.keys.join(', ')}');
    _log('Binary cache keys: ${_memoryCache.keys.where((k) => k.endsWith('_bytes')).join(', ')}');
    
    _log('\nForcing content update check...');
    await checkAndUpdateContent(force: true);
    
    _log('\nCache State After Update:');
    _log('Memory cache keys: ${_memoryCache.keys.join(', ')}');
    _log('Binary cache keys: ${_memoryCache.keys.where((k) => k.endsWith('_bytes')).join(', ')}');
    
    // Add cache content details
    if (_memoryCache.containsKey('slides')) {
      _log('\nSlides content: ${json.encode(_memoryCache['slides'])}');
    }
    if (_memoryCache.containsKey('contact_details')) {
      _log('\nContact details content: ${json.encode(_memoryCache['contact_details'])}');
    }
    
    _log('=== Test Complete ===\n');
  }

  // Add a method to force refresh slides
  Future<void> refreshSlides({bool isArabic = false}) async {
    try {
      _log('\nTTT_=== Refreshing Slides ===');
      
      final key = isArabic ? 'slideshow_content_ar' : 'slideshow_content';
      final response = await http.get(
        Uri.parse(updateCheckUrl).replace(
          queryParameters: {
            'page': 'home',
            'key_name': key,
            'action': 'fetchdata'
          },
        ),
        headers: Constants.defaultHeaders,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final slides = data['data'] as List;
          
          // Clear existing slides and their images from cache
          _memoryCache.removeWhere((k, v) => 
            k == key || 
            (k.contains('_bytes') && k.contains(isArabic ? 'slide_ar_' : 'slide_'))
          );
          
          // Store new slides data
          _memoryCache[key] = slides;
          
          // Download and cache all images
          for (var slide in slides) {
            if (slide['image_url'] != null && slide['image_url'].startsWith('http')) {
              final slideId = slide['slide_id'];
              final imageKey = isArabic ? 'slide_ar_${slideId}_image' : 'slide_${slideId}_image';
              await _downloadAndCacheImage(imageKey, slide['image_url']);
            }
          }
          
          // Save updated cache
          await _saveContentToCache();
          
          // Notify listeners to update UI
          notifyListeners();
          _log('TTT_Slides refreshed successfully');
        }
      }
    } catch (e) {
      _log('TTT_Error refreshing slides: $e');
    }
  }

  // Add methods to force refresh ads
  Future<void> refreshLoanAd() async {
    try {
      _log('\nTTT_=== Refreshing Loan Ad ===');
      
      final response = await http.get(
        Uri.parse(updateCheckUrl).replace(
          queryParameters: {
            'page': 'loans',
            'key_name': 'loan_ad',
            'action': 'fetchdata'
          },
        ),
        headers: Constants.defaultHeaders,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final adData = data['data'];
          
          // Clear existing ad and its image from cache
          _memoryCache.removeWhere((k, v) => 
            k == 'loan_ad' || k == 'loan_ad_image_bytes'
          );
          
          // Store new ad data
          _memoryCache['loan_ad'] = adData;
          
          // Download and cache image if it's a URL
          if (adData['image_url'] != null && adData['image_url'].startsWith('http')) {
            await _downloadAndCacheImage('loan_ad_image', adData['image_url']);
          }
          
          // Save updated cache
          await _saveContentToCache();
          
          // Notify listeners to update UI
          notifyListeners();
          _log('TTT_Loan ad refreshed successfully');
        }
      }
    } catch (e) {
      _log('TTT_Error refreshing loan ad: $e');
    }
  }

  Future<void> refreshCardAd() async {
    try {
      _log('\nTTT_=== Refreshing Card Ad ===');
      
      final response = await http.get(
        Uri.parse(updateCheckUrl).replace(
          queryParameters: {
            'page': 'cards',
            'key_name': 'card_ad',
            'action': 'fetchdata'
          },
        ),
        headers: Constants.defaultHeaders,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final adData = data['data'];
          
          // Clear existing ad and its image from cache
          _memoryCache.removeWhere((k, v) => 
            k == 'card_ad' || k == 'card_ad_image_bytes'
          );
          
          // Store new ad data
          _memoryCache['card_ad'] = adData;
          
          // Download and cache image if it's a URL
          if (adData['image_url'] != null && adData['image_url'].startsWith('http')) {
            await _downloadAndCacheImage('card_ad_image', adData['image_url']);
          }
          
          // Save updated cache
          await _saveContentToCache();
          
          // Notify listeners to update UI
          notifyListeners();
          _log('TTT_Card ad refreshed successfully');
        }
      }
    } catch (e) {
      _log('TTT_Error refreshing card ad: $e');
    }
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