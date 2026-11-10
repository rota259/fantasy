import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// شيت صغير فيه Cloudflare Turnstile — غالبًا بيعدّي لوحده في ثانية، ولو شاكك بيطلب ضغطة.
/// بيرجّع الكود، أو null لو اليوزر قفله / فشل / عدّى ٤٥ ثانية.
Future<String?> showCaptchaSheet(BuildContext context, {required String siteKey, required String domain}) =>
    showModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      backgroundColor: AppColors.bg,
      builder: (_) => _CaptchaSheet(siteKey: siteKey, domain: domain),
    );

class _CaptchaSheet extends StatefulWidget {
  const _CaptchaSheet({required this.siteKey, required this.domain});
  final String siteKey, domain;

  @override
  State<_CaptchaSheet> createState() => _CaptchaSheetState();
}

class _CaptchaSheetState extends State<_CaptchaSheet> {
  late final WebViewController _web;
  Timer? _timeout;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel('Captcha', onMessageReceived: (m) => _finish(m.message))
      ..setNavigationDelegate(
        // الصفحة متتنقلش لأي حتة تانية (Turnstile بس)
        NavigationDelegate(
          onNavigationRequest: (r) =>
              r.url.startsWith('https://${widget.domain}/') ||
                  r.url.startsWith('https://challenges.cloudflare.com/') ||
                  r.url == 'about:blank'
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      )
      ..loadHtmlString(_html(widget.siteKey), baseUrl: 'https://${widget.domain}/');
    _timeout = Timer(const Duration(seconds: 45), () => _finish('err:timeout'));
  }

  void _finish(String message) {
    if (_done || !mounted) return;
    _done = true;
    _timeout?.cancel();
    Navigator.pop(context, message.startsWith('ok:') ? message.substring(3) : null);
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('بنتأكد إنك مش روبوت…', style: AppText.h(15)),
          const SizedBox(height: 4),
          Text('ثانية واحدة — ولو ظهر مربع، دوس عليه', style: AppText.body(12, color: AppColors.neutral600)),
          const SizedBox(height: 12),
          SizedBox(height: 80, width: 310, child: WebViewWidget(controller: _web)),
        ],
      ),
    ),
  );
}

/// الصفحة: Turnstile بيرندر ويبعت الكود للأبلكيشن عن طريق القناة «Captcha».
String _html(String siteKey) =>
    '''
<!doctype html><html><head>
<meta name="viewport" content="width=device-width,initial-scale=1">
<script src="https://challenges.cloudflare.com/turnstile/v0/api.js?onload=ready&render=explicit" async defer></script>
<style>html,body{margin:0;background:transparent;display:flex;justify-content:center;align-items:center;height:100%}</style>
</head><body><div id="w"></div><script>
function ready(){turnstile.render('#w',{sitekey:'$siteKey',language:'ar',appearance:'interaction-only',
callback:function(t){Captcha.postMessage('ok:'+t)},
'error-callback':function(e){Captcha.postMessage('err:'+e)},
'expired-callback':function(){Captcha.postMessage('err:expired')}});}
</script></body></html>''';
