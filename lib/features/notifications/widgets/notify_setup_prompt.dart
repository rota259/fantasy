import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/notifications/device_notify.dart';
import '../view/notify_setup_screen.dart';

/// بعد الدخول: لو الموبايل مانع الإشعارات أو صوتها، أو شركته بتقفل الأبلكيشنات في الخلفية (شاومي وأخواتها)
/// → رسالة واحدة بتفتح شاشة «الإشعارات على موبايلك». بتظهر مرة واحدة، وتاني لو حاجة اتقفلت بعدها.
abstract final class NotifySetupPrompt {
  static const _key = 'notify_setup_prompted';
  static bool _checked = false;

  static Future<void> maybeShow(BuildContext context) async {
    if (_checked) return;
    _checked = true;
    await Future<void>.delayed(const Duration(seconds: 3)); // بعد ما الرئيسية تتبني
    final s = await DeviceNotify.status();
    final broken = !s.enabled || s.broken.isNotEmpty;
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_key) ?? false;
      if (!broken && (seen || !s.strictMaker)) return;
      await prefs.setBool(_key, true);
    } catch (_) {
      if (!broken) return;
    }
    if (!context.mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('خلّي الإشعارات توصلك بصوت'),
        content: Text(
          broken
              ? 'موبايلك مانع إشعارات الخماسي أو صوتها — هتفوّتك الأهداف وقفل لاعيبتك. نظبطها في دقيقة؟'
              : 'موبايلات ${s.manufacturer} بتقفل الأبلكيشنات في الخلفية، فالإشعار ممكن ميوصلش والأبلكيشن مقفول. '
                    'نفعّل «التشغيل التلقائي» في دقيقة؟',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('بعدين')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('يلا')),
        ],
      ),
    );
    if (go == true && context.mounted) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotifySetupScreen()));
    }
  }
}
