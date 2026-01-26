import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Keep for fallback
import '../utils/constants.dart';

class UpdateService {
  // Placeholder URL - Real app would point to GitHub API or specific JSON
  static const String versionCheckUrl = "https://raw.githubusercontent.com/YourUser/SimpleDaily/main/version.json";
  
  // Platform specific download links (Mocked)
  String get _downloadUrl {
     if (Platform.isWindows) {
       return "https://github.com/YourUser/SimpleDaily/releases/latest/download/simple_daily_setup.exe";
     } else if (Platform.isLinux) {
       return "https://github.com/YourUser/SimpleDaily/releases/latest/download/simple-daily-linux.deb";
     }
     return AppConstants.repoUrl;
  }

  Future<bool> isUpdateAvailable() async {
    try {
      final response = await http.get(Uri.parse(versionCheckUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String remoteVersion = data['version'];
        return _compareVersions(remoteVersion, AppConstants.currentVersion) > 0;
      }
    } catch (e) {
      print("Error checking updates: $e");
    }
    return false;
  }
  
  Future<void> performUpdate(BuildContext context) async {
    try {
      if (Platform.isLinux) {
        await _updateLinux(context);
      } else if (Platform.isWindows) {
        await _updateWindows(context);
      } else {
        // Fallback for others
        launchUrl(Uri.parse(_downloadUrl));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update Failed: $e")),
      );
    }
  }

  Future<void> _updateLinux(BuildContext context) async {
    // 1. Download .deb
    final file = await _downloadFile(_downloadUrl, "simple-daily-update.deb");
    if (file == null) throw Exception("Download failed");

    // 2. Install using pkexec
    // We launch a terminal or run process directly. pkexec requires interactivity if no agent.
    // Ideally, we run: pkexec dpkg -i <file>
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Requesting root permissions to install update...")),
    );

    try {
      await Process.start('pkexec', ['dpkg', '-i', file.path], mode: ProcessStartMode.detached);
      // App might need to close or will be killed by update
    } catch (e) {
      throw Exception("Could not run installer: $e");
    }
  }

  Future<void> _updateWindows(BuildContext context) async {
    // 1. Download .exe
    final file = await _downloadFile(_downloadUrl, "simple_daily_setup.exe");
    if (file == null) throw Exception("Download failed");

    // 2. Run Installer
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Launching installer...")),
    );
    
    try {
      await Process.start(file.path, [], mode: ProcessStartMode.detached);
      exit(0); // Exit to allow replacement
    } catch (e) {
      throw Exception("Could not launch installer: $e");
    }
  }

  Future<File?> _downloadFile(String url, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      return file;
    }
    return null;
  }

  int _compareVersions(String v1, String v2) {
    var v1Parts = v1.split('.').map(int.parse).toList();
    var v2Parts = v2.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
        int p1 = i < v1Parts.length ? v1Parts[i] : 0;
        int p2 = i < v2Parts.length ? v2Parts[i] : 0;
        if (p1 > p2) return 1;
        if (p1 < p2) return -1;
    }
    return 0;
  }
}
