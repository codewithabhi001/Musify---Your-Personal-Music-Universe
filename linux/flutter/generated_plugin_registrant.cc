//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <audiotags/audiotags_plugin.h>
#include <awesome_notifications/awesome_notifications_plugin.h>
#include <flutter_audio_capture/flutter_audio_capture_plugin.h>
#include <url_launcher_linux/url_launcher_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) audiotags_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "AudiotagsPlugin");
  audiotags_plugin_register_with_registrar(audiotags_registrar);
  g_autoptr(FlPluginRegistrar) awesome_notifications_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "AwesomeNotificationsPlugin");
  awesome_notifications_plugin_register_with_registrar(awesome_notifications_registrar);
  g_autoptr(FlPluginRegistrar) flutter_audio_capture_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterAudioCapturePlugin");
  flutter_audio_capture_plugin_register_with_registrar(flutter_audio_capture_registrar);
  g_autoptr(FlPluginRegistrar) url_launcher_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "UrlLauncherPlugin");
  url_launcher_plugin_register_with_registrar(url_launcher_linux_registrar);
}
