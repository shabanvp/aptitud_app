import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme.dart';

class MatchWebViewScreen extends StatefulWidget {
  final String url;
  final String opponentName;

  const MatchWebViewScreen({
    super.key,
    required this.url,
    required this.opponentName,
  });

  @override
  State<MatchWebViewScreen> createState() => _MatchWebViewScreenState();
}

class _MatchWebViewScreenState extends State<MatchWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onProgress: (p) => setState(() => _loadingProgress = p),
          onPageFinished: (_) {
            setState(() => _loading = false);
            // Inject JS to skip screen-share step on mobile (not supported)
            _controller.runJavaScript('''
              (function() {
                // Auto-mark screenStream as "done" so the proctoring step is bypassed
                if (typeof window.screenStream !== 'undefined' || window.screenStream === null) {
                  // Override the functions that are unavailable on mobile
                  if (navigator.mediaDevices) {
                    var originalGetDisplayMedia = navigator.mediaDevices.getDisplayMedia;
                    if (!originalGetDisplayMedia) {
                      // getDisplayMedia not supported — auto-pass the screen share step
                      window.screenStream = { active: true, getVideoTracks: function() { return [{ getSettings: function() { return {}; }, onended: null }]; } };
                      if (typeof updateStepUI === 'function') {
                        updateStepUI('proctor', true);
                      }
                      if (typeof checkSteps === 'function') checkSteps();
                    }
                  } else {
                    // No mediaDevices at all — auto-pass both proctor and fullscreen
                    window.fsBypassed = true;
                    window.screenStream = { active: true, getVideoTracks: function() { return [{ getSettings: function() { return {}; }, onended: null }]; } };
                    if (typeof checkSteps === 'function') checkSteps();
                  }
                }
              })();
            ''');
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() => _loading = false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return await _showExitDialog();
  }

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text(
              'Leave Match?',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            content: const Text(
              'Leaving now will forfeit the match. Are you sure?',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                ),
                child: const Text('Leave'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VS Match',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'vs ${widget.opponentName}',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textPrimary),
            onPressed: () async {
              final shouldPop = await _showExitDialog();
              if (shouldPop && mounted) Navigator.of(context).pop();
            },
          ),
          bottom: _loading
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _loadingProgress / 100,
                    backgroundColor: AppTheme.surface,
                    color: AppTheme.primary,
                  ),
                )
              : null,
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
