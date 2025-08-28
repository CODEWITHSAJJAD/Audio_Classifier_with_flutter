import 'dart:io';
import 'package:http/http.dart' as http; // Add this import
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart ' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

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
  String errorMessage='';
  final String apiUrl='https://10.0.2.2:5000/predict';
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    final bgColor = Colors.white;
    final primaryColor = Colors.blueAccent;
    final secondaryColor = Colors.deepPurpleAccent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title:
          const Text(
            "Audio Classifier",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        backgroundColor:primaryColor,
        shadowColor:secondaryColor,
        elevation: 5,
        iconTheme:const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),

      floatingActionButton: _recordingButton(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [_buildUI(), const SizedBox(height: 10), _Result()],
      ),
    );
  }

  Widget _buildUI() {
    return Card(
      elevation: 4,
      child:Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (recordingPath == null) const Text("No recording Found. :("),
          if (recordingPath != null)
            MaterialButton(
              onPressed: () async {
                if (audioPlayer.playing) {
                  audioPlayer.stop();
                  setState(() {
                    isPlaying = false;
                  });
                } else {
                  await audioPlayer.setFilePath(recordingPath!);
                  audioPlayer.play();
                  setState(() {
                    isPlaying = true;
                  });
                }
              },
              color: Colors.blue,
              child: Text(
                isPlaying
                    ? "Stop Playing Recording"
                    : "Start Playing Recording",
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      ),
    );
  }

  // TODO: implement widget
  Widget _recordingButton() {
    return FloatingActionButton(
      onPressed: () async {
        if (isRecording) {
          String? filePath = await audioRecorder.stop();
          if (filePath != null) {
            setState(() {
              isRecording = false;
              recordingPath = filePath;
            });
          }
        } else {
          if (await audioRecorder.hasPermission()) {
            final Directory appDocumenstDir =
                await getApplicationDocumentsDirectory();
            final String filePath = p.join(
              appDocumenstDir.path,
              "recoding.wav",
            );
            await audioRecorder.start(const RecordConfig(), path: filePath);
            setState(() {
              isRecording = true;
              recordingPath = null;
            });
          }
        }
      },
      child: Icon(isRecording ? Icons.stop : Icons.mic),
    );
  }

  Widget _Result() {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {},
            child: Icon(Icons.send),
          ),
          const SizedBox(height: 10),
          Text("how are You"),
        ],
      ),
    );
  }
}
