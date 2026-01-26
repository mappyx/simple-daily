import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/constants.dart';

class GitSyncService {
  // Placeholder for real Git implementation
  // In a production app, use 'git' package or Process.run to execute git commands
  // Requires 'git' installed on user system
  
  Future<void> syncData() async {
    final directory = await getApplicationDocumentsDirectory();
    final dataDir = '${directory.path}/${AppConstants.appName}_Data';
    
    // Check if it's a git repo
    final isRepo = await Directory('$dataDir/.git').exists();
    if (!isRepo) {
      print("Not a git repository. Please initialize git in $dataDir manually for now.");
      return;
    }
    
    // Auto-commit and Push
    try {
      await _runGit(dataDir, ['add', '.']);
      await _runGit(dataDir, ['commit', '-m', 'Auto-sync: ${DateTime.now()}']);
      await _runGit(dataDir, ['push']);
      print("Git Sync successful");
    } catch (e) {
      print("Git Sync error: $e");
    }
  }
  
  Future<void> _runGit(String workingDir, List<String> args) async {
    final result = await Process.run('git', args, workingDirectory: workingDir);
    if (result.exitCode != 0) {
      // Ignore "nothing to commit" errors ideally
      if (!result.stdout.toString().contains("nothing to commit")) {
         throw Exception(result.stderr);
      }
    }
  }
}
