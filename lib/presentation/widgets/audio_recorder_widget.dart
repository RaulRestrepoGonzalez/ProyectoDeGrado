import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

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
  late AudioRecorder _audioRecorder;
  late AudioPlayer _audioPlayer;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _durationTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    final permissions = await [
      Permission.microphone,
      Permission.storage,
    ].request();

    final microphoneGranted = permissions[Permission.microphone] ?? false;
    final storageGranted = permissions[Permission.storage] ?? false;

    if (!microphoneGranted) {
      _showPermissionDialog('microphone');
      return false;
    }

    if (!storageGranted) {
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

  Future<void> _startRecording() async {
    final hasPermissions = await _requestPermissions();
    if (!hasPermissions) return;

    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _recordingPath = path;
        _recordingDuration = 0;
      });

      // Iniciar timer para duración máxima
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });

        if (_recordingDuration >= widget.maxDuration) {
          _stopRecording();
        }
      });

    } catch (e) {
      _showErrorDialog('Error al grabar audio: ${e.toString()}');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _durationTimer?.cancel();
      
      final path = await _audioRecorder.stop();
      
      if (path != null && File(path).existsSync()) {
        final audioFile = File(path);
        widget.onAudioRecorded(audioFile);
        
        setState(() {
          _isRecording = false;
          _recordingPath = null;
          _recordingDuration = 0;
        });
      }
    } catch (e) {
      _showErrorDialog('Error al detener grabación: ${e.toString()}');
    }
  }

  Future<void> _playRecording() async {
    if (_recordingPath == null) return;

    try {
      await _audioPlayer.play(DeviceFileSource(File(_recordingPath!)));
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

  void _deleteRecording() {
    if (_recordingPath == null) return;

    try {
      final file = File(_recordingPath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
      
      setState(() {
        _recordingPath = null;
        _isPlaying = false;
        _recordingDuration = 0;
      });
    } catch (e) {
      _showErrorDialog('Error al eliminar audio: ${e.toString()}');
    }
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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
                _isRecording ? Icons.mic : Icons.audiotrack,
                color: _isRecording ? Colors.redAccent : Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                _isRecording ? 'Grabando audio...' : 'Grabar audio',
                style: TextStyle(
                  color: _isRecording ? Colors.redAccent : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isRecording) ...[
                const Spacer(),
                Text(
                  _formatDuration(_recordingDuration),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '/ ${widget.maxDuration}s',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
          
          if (_isRecording) ...[
            const SizedBox(height: 16),
            // Onda de audio animada
            Container(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(20, (index) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 100 + (index * 50)),
                    width: 3,
                    height: 20 + (_recordingDuration % 20),
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
            
            const SizedBox(height: 16),
            // Botón de detener
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _stopRecording,
                icon: const Icon(Icons.stop, color: Colors.white),
                label: const Text('Detener grabación', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else if (_recordingPath != null) ...[
            const SizedBox(height: 16),
            // Controles de reproducción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isPlaying ? _stopPlaying : _playRecording,
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
                  onPressed: _deleteRecording,
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
            // Botón de iniciar grabación
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startRecording,
                icon: const Icon(Icons.mic, color: Colors.white),
                label: const Text('Iniciar grabación', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
