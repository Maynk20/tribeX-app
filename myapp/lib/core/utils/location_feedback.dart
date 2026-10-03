import 'package:flutter/material.dart';

import '../../services/location_service.dart';
import 'app_toast.dart';

/// Shows a location error toast. When the failure can only be fixed in
/// system settings (permission permanently denied, or location services
/// off) a "Settings" action is attached that opens the right OS page.
void showLocationError(BuildContext context, String message) {
  VoidCallback? action;
  if (message == LocationService.msgDeniedForever) {
    action = () => LocationService.openAppSettings();
  } else if (message == LocationService.msgServiceDisabled) {
    action = () => LocationService.openLocationSettings();
  }
  AppToast.show(
    context,
    message,
    isError: true,
    duration: Duration(seconds: action != null ? 5 : 3),
    actionLabel: action != null ? 'Settings' : null,
    onAction: action,
  );
}
