import 'package:flutter_test/flutter_test.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:nayifat_app/services/auth_service.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('iOS Platform Specific Tests', () {
    late AuthService authService;

    setUp(() {
      // Setup platform channel mock for device info
      const MethodChannel('dev.fluttercommunity.plus/device_info')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'getIosDeviceInfo') {
          return {
            'name': 'iPhone',
            'systemName': 'iOS',
            'systemVersion': '15.0',
            'model': 'iPhone12,1',
            'localizedModel': 'iPhone',
            'identifierForVendor': 'test-identifier',
            'isPhysicalDevice': true,
            'utsname': {
              'sysname': 'Darwin',
              'nodename': 'iPhone',
              'release': '21.0.0',
              'version': 'Darwin Kernel Version 21.0.0',
              'machine': 'iPhone12,1'
            }
          };
        }
        return null;
      });

      authService = AuthService();
    });

    test('iOS Info.plist contains required permissions', () {
      final File infoPlist = File('ios/Runner/Info.plist');
      expect(infoPlist.existsSync(), true, reason: 'Info.plist should exist');

      final String content = infoPlist.readAsStringSync();
      
      // Check for required permission keys
      expect(content.contains('NSFaceIDUsageDescription'), true,
          reason: 'Face ID permission missing');
      expect(content.contains('NSCameraUsageDescription'), true,
          reason: 'Camera permission missing');
      expect(content.contains('NSPhotoLibraryUsageDescription'), true,
          reason: 'Photo Library permission missing');
      expect(content.contains('NSLocationWhenInUseUsageDescription'), true,
          reason: 'Location permission missing');
      expect(content.contains('NSMicrophoneUsageDescription'), true,
          reason: 'Microphone permission missing');
    });

    test('iOS entitlements file contains required capabilities', () {
      final File entitlements = File('ios/Runner/Runner.entitlements');
      expect(entitlements.existsSync(), true,
          reason: 'Entitlements file should exist');

      final String content = entitlements.readAsStringSync();
      
      // Check for required capabilities
      expect(content.contains('keychain-access-groups'), true,
          reason: 'Keychain access capability missing');
      expect(content.contains('aps-environment'), true,
          reason: 'Push notifications capability missing');
      expect(content.contains('com.apple.security.application-groups'), true,
          reason: 'App groups capability missing');
    });

    test('Podfile contains required configurations', () {
      final File podfile = File('ios/Podfile');
      expect(podfile.existsSync(), true, reason: 'Podfile should exist');

      final String content = podfile.readAsStringSync();
      
      // Check for required configurations
      expect(content.contains("platform :ios, '12.0'"), true,
          reason: 'iOS platform version should be set to 12.0');
      expect(content.contains('pod \'GoogleMaps\''), true,
          reason: 'GoogleMaps pod should be included');
    });

    test('AppDelegate.swift contains required setup', () {
      final File appDelegate = File('ios/Runner/AppDelegate.swift');
      expect(appDelegate.existsSync(), true,
          reason: 'AppDelegate.swift should exist');

      final String content = appDelegate.readAsStringSync();
      
      // Check for required imports and configurations
      expect(content.contains('import GoogleMaps'), true,
          reason: 'GoogleMaps import missing');
      expect(content.contains('GMSServices.provideAPIKey'), true,
          reason: 'Google Maps initialization missing');
      expect(content.contains('UNUserNotificationCenter'), true,
          reason: 'Notification setup missing');
    });
  });
} 