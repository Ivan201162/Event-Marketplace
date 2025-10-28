import 'package:event_marketplace_app/services/vk_integration_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Виджет для работы с VK плейлистами
class VkPlaylistWidget extends ConsumerStatefulWidget {
  const VkPlaylistWidget(
      {super.key, this.playlistUrl, this.onUrlChanged, this.readOnly = false,});
  final String? playlistUrl;
  final void Function(String?)? onUrlChanged;
  final bool readOnly;

  @override
  ConsumerState<VkPlaylistWidget> createState() => _VkPlaylistWidgetState();
}

class _VkPlaylistWidgetState extends ConsumerState<VkPlaylistWidget> {
  final TextEditingController _urlController = TextEditingController();
  final VkIntegrationService _vkService = VkIntegrationService();
  bool _isValid = false;
  bool _isLoading = false;
  Map<String, dynamic>? _playlistInfo;

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.playlistUrl ?? '';
    if (widget.playlistUrl != null) {
      _validateUrl(widget.playlistUrl!);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _validateUrl(String url) async {
    if (url.isEmpty) {
      setState(() {
        _isValid = false;
        _playlistInfo = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final validation = _vkService.validateAndProcessUrl(url);
      final isValid = validation['isValid'] as bool;

      if (isValid) {
        final playlistInfo = await _vkService.getPlaylistInfo(url);
        setState(() {
          _isValid = true;
          _playlistInfo = playlistInfo;
        });
      } else {
        setState(() {
          _isValid = false;
          _playlistInfo = null;
        });
      }
    } catch (e) {
      setState(() {
        _isValid = false;
        _playlistInfo = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openPlaylist() async {
    if (_playlistInfo?['url'] != null) {
      final url = Uri.parse(_playlistInfo!['url'] as String);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Поле ввода URL
          if (!widget.readOnly) ...[
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Ссылка на плейлист VK',
                hintText: 'https://vk.com/audio?playlist_id=...',
                prefixIcon: const Icon(Icons.music_note),
                suffixIcon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _isValid ? Icons.check_circle : Icons.error,
                        color: _isValid ? Colors.green : Colors.red,
                      ),
                border: const OutlineInputBorder(),
                errorText:
                    _urlController.text.isNotEmpty && !_isValid && !_isLoading
                        ? 'Неверный формат ссылки на плейлист VK'
                        : null,
              ),
              onChanged: (value) {
                widget.onUrlChanged?.call(value.isEmpty ? null : value);
                _validateUrl(value);
              },
            ),
            const SizedBox(height: 8),

            // Примеры ссылок
            Text('Примеры ссылок:',
                style: Theme.of(context).textTheme.bodySmall,),
            const SizedBox(height: 4),
            ..._vkService.getExampleUrls().map(
                  (url) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• $url',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600], fontFamily: 'monospace',),
                    ),
                  ),
                ),
          ],

          // Информация о плейлисте
          if (_playlistInfo != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.music_note, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (_playlistInfo!['title'] as String?) ?? 'Плейлист VK',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[800],),
                        ),
                      ),
                      if (!widget.readOnly)
                        IconButton(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: _openPlaylist,
                          tooltip: 'Открыть плейлист',
                        ),
                    ],
                  ),
                  if (_playlistInfo!['description'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _playlistInfo!['description'] as String? ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ],
                  if (_playlistInfo!['trackCount'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Треков: ${_playlistInfo!['trackCount']}',
                      style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Отображение URL в режиме только для чтения
          if (widget.readOnly && widget.playlistUrl != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.music_note, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.playlistUrl!,
                      style: TextStyle(
                          color: Colors.grey[700], fontFamily: 'monospace',),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () async {
                      final url = Uri.parse(widget.playlistUrl!);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication,);
                      }
                    },
                    tooltip: 'Открыть плейлист',
                  ),
                ],
              ),
            ),
          ],
        ],
      );
}

/// Виджет для отображения VK плейлиста в чате
class VkPlaylistChatWidget extends StatelessWidget {
  const VkPlaylistChatWidget(
      {required this.playlistUrl, required this.vkService, super.key,});
  final String playlistUrl;
  final VkIntegrationService vkService;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          border: Border.all(color: Colors.blue[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.music_note, color: Colors.blue[600], size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Плейлист VK',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.blue[800],),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Нажмите, чтобы открыть',
                    style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () async {
                final url = Uri.parse(playlistUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              tooltip: 'Открыть плейлист',
            ),
          ],
        ),
      );
}
