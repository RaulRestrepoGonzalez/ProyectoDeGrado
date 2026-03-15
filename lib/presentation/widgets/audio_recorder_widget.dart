import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorderWidget extends StatefulWidget {
  final Function(File audioFile) onAudioRecorded;
  final int maxDuration; // Máximo 60 segundos

  const AudioRecorderWidget({
    super.key,
    required this.onAudioRecorded,
    this.maxDuration = 60,
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  File? _selectedAudioFile;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<bool> _requestPermissions() async {
    final microphoneStatus = await Permission.microphone.request();
    final storageStatus = await Permission.storage.request();

    if (microphoneStatus != PermissionStatus.granted) {
      _showPermissionDialog('microphone');
      return false;
    }

    if (storageStatus != PermissionStatus.granted) {
      _showPermissionDialog('storage');
      return false;
    }

    return true;
  }

  void _showPermissionDialog(String permission) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Permiso de $permission requerido'),
        content: Text('Por favor, habilita el permiso de $permission en la configuración de tu dispositivo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Configurar'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAudioFile() async {
    final hasPermissions = await _requestPermissions();
    if (!hasPermissions) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.single.path!);
        
        setState(() {
          _selectedAudioFile = file;
        });
        
        widget.onAudioRecorded(file);
      }
    } catch (e) {
      _showErrorDialog('Error al seleccionar audio: ${e.toString()}');
    }
  }

  Future<void> _playSelectedAudio() async {
    if (_selectedAudioFile == null) return;

    try {
      await _audioPlayer.play(DeviceFileSource(_selectedAudioFile!.path));
      setState(() => _isPlaying = true);

      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() => _isPlaying = false);
      });
    } catch (e) {
      _showErrorDialog('Error al reproducir audio: ${e.toString()}');
    }
  }

  Future<void> _stopPlaying() async {
    try {
      await _audioPlayer.stop();
      setState(() => _isPlaying = false);
    } catch (e) {
      _showErrorDialog('Error al detener reproducción: ${e.toString()}');
    }
  }

  void _removeSelectedAudio() {
    setState(() {
      _selectedAudioFile = null;
      _isPlaying = false;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                _selectedAudioFile != null ? Icons.audiotrack : Icons.music_note,
                color: _selectedAudioFile != null ? Colors.greenAccent : Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedAudioFile != null ? 'Audio seleccionado' : 'Seleccionar audio',
                style: TextStyle(
                  color: _selectedAudioFile != null ? Colors.greenAccent : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          if (_selectedAudioFile != null) ...[
            const SizedBox(height: 16),
            // Información del archivo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Archivo: ${_selectedAudioFile!.path.split('/').last}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Duración máxima: ${60} segundos',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            // Controles de reproducción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isPlaying ? _stopPlaying : _playSelectedAudio,
                    icon: Icon(
                      _isPlaying ? Icons.stop : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isPlaying ? 'Detener' : 'Reproducir',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _removeSelectedAudio,
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            // Botón para seleccionar audio
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickAudioFile,
                icon: const Icon(Icons.audiotrack, color: Colors.white),
                label: const Text('Seleccionar archivo de audio', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Formatos soportados: MP3, WAV, AAC, M4A',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
