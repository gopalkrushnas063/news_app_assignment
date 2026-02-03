// lib/core/app_initializer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:news_app/data/adapters/article_adapter.dart';
import 'package:path_provider/path_provider.dart';

class AppInitializer extends ConsumerWidget {
  final Widget child;

  const AppInitializer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return child;
  }
}

Future<void> initializeApp() async {
  try {
    // 1. Load environment variables
    await dotenv.load(fileName: '.env');
    
    // 2. Initialize Hive for caching
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    
    // 3. Register Hive adapters
    Hive.registerAdapter(ArticleModelAdapter());
    
    // 4. Open Hive boxes
    await Hive.openBox('articles_box');
    
    // 5. You can add more initialization here
    // - Check connectivity
    // - Load user preferences
    // - Initialize analytics
    // - Setup error reporting
    // etc.
    
  } catch (error) {
    // Handle initialization errors gracefully
    debugPrint('App initialization error: $error');
    rethrow;
  }
}