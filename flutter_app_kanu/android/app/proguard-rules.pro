# Flutter / Android R8 & resource shrinking rules for KANU Rencontres.
# Flutter embeds the Dart/engine code; the generated plugins are registered in
# GeneratedPluginRegistrant, which is referenced by reflection in some cases.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
