library flutter_webviews;

import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Mixin to provide enhanced webview functionality
mixin EnhancedWebViewHelper {
  List<String>? uploadedFiles = [];

  /// Convert file path to URI string
  Future<String> _convertFileToUri(String filePath) async {
    return File(filePath).uri.toString();
  }

  /// Open file picker dialog for Android
  Future<List<String>> openFilePicker(
    BuildContext context, {
    bool dismissible = true,
    bool enableMultiSelect = false,
  }) async {
    List<String> selectedFiles = [];
    final ImagePicker imagePicker = ImagePicker();

    // Display action sheet for file picking options
    uploadedFiles = await showCupertinoModalPopup<List<String>>(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) {
        return CupertinoActionSheet(
          actions: [
            // Option: Take photo with camera
            CupertinoActionSheetAction(
              onPressed: () async {
                XFile? cameraFile =
                    await imagePicker.pickImage(source: ImageSource.camera);
                if (cameraFile != null) {
                  selectedFiles.add(await _convertFileToUri(cameraFile.path));
                }
                Navigator.pop(context, selectedFiles);
              },
              child: const Text("Capture Photo"),
            ),
            // Option: Pick a photo from gallery
            CupertinoActionSheetAction(
              onPressed: () async {
                XFile? galleryFile =
                    await imagePicker.pickImage(source: ImageSource.gallery);
                if (galleryFile != null) {
                  selectedFiles.add(await _convertFileToUri(galleryFile.path));
                }
                Navigator.pop(context, selectedFiles);
              },
              child: const Text("Choose from Gallery"),
            ),
            // Option: Pick a file using File Picker
            CupertinoActionSheetAction(
              onPressed: () async {
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles();
                if (result != null && result.files.single.path != null) {
                  selectedFiles
                      .add(await _convertFileToUri(result.files.single.path!));
                }
                Navigator.pop(context, selectedFiles);
              },
              child: const Text("Select File"),
            ),
            // Option: Select multiple photos if enabled
            if (enableMultiSelect)
              CupertinoActionSheetAction(
                onPressed: () async {
                  List<XFile> multiPhotos = await imagePicker.pickMultiImage(
                      imageQuality: 50, maxWidth: 600);
                  for (var photo in multiPhotos) {
                    selectedFiles.add(await _convertFileToUri(photo.path));
                  }
                  Navigator.pop(context, selectedFiles);
                },
                child: const Text("Choose Multiple Photos"),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, selectedFiles),
          ),
        );
      },
    );
    return uploadedFiles ?? [];
  }

  /// Check and request geolocation permissions
  Future<bool> requestLocationPermission() async {
    bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    await Geolocator.getCurrentPosition();
    return true;
  }

  /// Get geolocation permissions response for WebView
  Future<GeolocationPermissionsResponse> getGeoPermissionResponse() async {
    bool permissionGranted = await requestLocationPermission();
    return GeolocationPermissionsResponse(
      allow: permissionGranted,
      retain: true,
    );
  }
}
