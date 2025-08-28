import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:record/record.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioRecorder audioRecorder = AudioRecorder();
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isRecording = false, isPlaying = false;
  String? recordingPath;
  String? selectedFileName;
  Map<String, dynamic>? predictionResult;
  bool isLoading = false;
  String errorMessage = '';
  final String apiUrl = 'http://192.168.18.107:5000/predict';
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    final bgColor = Colors.white;
    final primaryColor = Colors.blueAccent;
    final secondaryColor = Colors.deepPurpleAccent;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Audio Classifier",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        shadowColor: secondaryColor,
        elevation: 5,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRecordingSection(),
            const SizedBox(height: 20),
            _buildPlaySection(),
            const SizedBox(height: 20),
            _buildPredictionSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingSection() {
    return Card(
      color: Colors.white70,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Record Audio",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isRecording
                        ? "Recording in progress..."
                        : "Record a new audio sample",
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
                FloatingActionButton(
                  onPressed: _toggleRecording,
                  backgroundColor: isRecording ? Colors.red : Colors.blueAccent,
                  child: Icon(
                    isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                  ),
                  mini: true,
                ),
              ],
            ),
            if (isRecording)
              const LinearProgressIndicator(
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaySection() {
    return Card(
      color: Colors.white70,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Play Audio",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    recordingPath != null
                        ? p.basename(recordingPath!)
                        : "No Audio Available",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                FloatingActionButton(
                  onPressed: _togglePlay,
                  backgroundColor: isPlaying ? Colors.red : Colors.blueAccent,
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  mini: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionSection() {
    return Card(
      color: Colors.white70,
      elevation: 4,
      child: Padding(
        padding: EdgeInsetsGeometry.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Prediction Result",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (errorMessage.isNotEmpty) ...[
                        Text(
                          "Error: $errorMessage",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else if (predictionResult != null) ...[
                        Text(
                          "Class: ${predictionResult!['predicted_class']}",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "Confidence: ${predictionResult!['confidence']}",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ] else ...[
                        const Text(
                          "No audio recorded yet",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  backgroundColor: Colors.blueAccent,
                  onPressed: _resetAll,
                  child: const Icon(Icons.refresh, color: Colors.white),
                  mini: true,
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  backgroundColor: Colors.blueAccent,
                  onPressed: _sendAudio,
                  child: const Icon(Icons.send, color: Colors.white),
                  mini: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleRecording() async {
    try {
      if (isRecording) {
        // Stop recording
        final path = await audioRecorder.stop();
        setState(() {
          isRecording = false;
          recordingPath = path;
          selectedFileName = path != null ? p.basename(path) : null;
          predictionResult = null;
          errorMessage = '';
        });
      } else {
        final hasPermission = await audioRecorder.hasPermission();
        if (hasPermission) {
          final appDir = await getApplicationDocumentsDirectory();
          final filePath = p.join(
            appDir.path,
            'recording_${DateTime.now().millisecondsSinceEpoch}.wav',
          );

          await audioRecorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: filePath);

          setState(() {
            isRecording = true;
            predictionResult = null;
            errorMessage = '';
          });
        } else {
          setState(() {
            errorMessage = 'Recording permission denied';
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Recording error: $e';
        isRecording = false;
      });
    }
  }

  void _togglePlay() async {
    if (isPlaying) {
      await audioPlayer.stop();
      setState(() {
        isPlaying = false;
      });
    } else if (recordingPath != null) {
      try {
        await audioPlayer.setFilePath(recordingPath!);
        audioPlayer.play();
        setState(() {
          isPlaying = true;
        });
        audioPlayer.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            setState(() {
              isPlaying = false;
            });
          }
        });
      } catch (e) {
        setState(() {
          errorMessage = 'Playing error:$e';
        });
      }
    }
  }

  void _resetAll() {
    if (isPlaying) {
      audioPlayer.stop();
    }
    setState(() {
      isRecording = false;
      isPlaying = false;
      recordingPath = null;
      selectedFileName = null;
      predictionResult = null;
      errorMessage = '';
    });
  }

  void _sendAudio() async {
    print("send pressed");
    if (recordingPath == null) {
      setState(() {
        errorMessage = 'No audio recorded to send';
      });
      return;
    }

    setState(() {
      errorMessage = '';
      isLoading = true; // show loading if you want
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      var file = await http.MultipartFile.fromPath('file', recordingPath!);
      request.files.add(file);

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // ✅ API returned prediction
        var jsonResponse = json.decode(responseData);
        setState(() {
          predictionResult = jsonResponse;
          errorMessage = '';
        });
      } else {
        // ✅ API returned error JSON
        var jsonResponse = json.decode(responseData);
        setState(() {
          predictionResult = null;
          errorMessage = jsonResponse['error'] ??
              jsonResponse['message'] ??
              'Unknown server error';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error sending audio: $e';
        predictionResult = null;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

}
