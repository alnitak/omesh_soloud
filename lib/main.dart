import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:mesh/mesh.dart';

void main() async {
  /// Initialize the player.
  await SoLoud.instance.init();

  /// Enable acquisition of audio data.
  SoLoud.instance.setVisualizationEnabled(true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'oMesh SoLoud Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  AudioSource? sound;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AudioMesh(key: UniqueKey(), sound: sound),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await SoLoud.instance.disposeAllSources();
          sound = await SoLoud.instance
              .loadAsset('assets/xtrackture.mp3', mode: LoadMode.disk);
          setState(() {});
        },
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}

class AudioMesh extends StatefulWidget {
  const AudioMesh({super.key, required this.sound});

  final AudioSource? sound;

  @override
  State<AudioMesh> createState() => AudioMeshState();
}

class AudioMeshState extends State<AudioMesh>
    with SingleTickerProviderStateMixin {
  Ticker? ticker;
  OMeshRect? meshRect;
  AudioData? audioData;

  @override
  void initState() {
    super.initState();

    if (widget.sound != null) {
      audioData = AudioData(GetSamplesKind.linear);
      SoLoud.instance.play(widget.sound!, looping: true);
      ticker = createTicker(_onTick);
      ticker?.start();

      meshRect = OMeshRect(
        width: 6,
        height: 3,
        colorSpace: OMeshColorSpace.lab,
        smoothColors: false,
        backgroundColor: Colors.black,
        fallbackColor: Colors.black,
        vertices: [
          (0, 0).v,
          (0.2, 0).v,
          (0.4, 0).v,
          (0.6, 0).v,
          (0.8, 0).v,
          (1, 0).v, // Row 1

          (0, 0.5).v,
          (0.2, 0.5).v,
          (0.4, 0.5).v,
          (0.6, 0.5).v,
          (0.8, 0.5).v,
          (1, 0.5).v, // Row 2

          (0, 1).v,
          (0.2, 1).v,
          (0.4, 1).v,
          (0.6, 1).v,
          (0.8, 1).v,
          (1, 1).v, // Row 3
        ],
        colors: const [
          null,
          null,
          null,
          null,
          null,
          null, // Row 1

          Color(0xffff0000),
          Color(0xffd8d2ba),
          Color(0xff0033ff),
          Color(0xff6aff00),
          Color(0xffba2527),
          Color(0xff6fcf82), // Row 2

          null,
          null,
          null,
          null,
          null,
          null, // Row 3
        ],
      );
    }
  }

  @override
  void dispose() {
    ticker?.stop();
    audioData?.dispose();
    super.dispose();
  }

  void _onTick(Duration time) {
    /// Every ticks update the internal audio samples to be read later on
    /// the `build` with [getLinearFft()].
    audioData?.updateSamples();
    if (context.mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sound == null) return const SizedBox.shrink();

    for (int n = 0; n < 6; n++) {
      /// The FFT data is composed by 256 values. Here only the lower meaningful
      /// set are taken. To get audio data (volume), use [getLinearWave()].
      final fft = audioData!.getLinearFft(SampleLinear(n * 6 + 10));
      OVertex newVertex = OVertex(
        0.2 * n,
        1.0 - fft,
      );
      meshRect = meshRect?.setVertex(newVertex, onIndex: 6 + n);
      meshRect = meshRect?.setColor(
        meshRect?.colors[6 + n]!.withOpacity((fft * 2).clamp(0, 1)),
        onIndex: 6 + n,
      );
    }

    return OMeshGradient(
      tessellation: 6,
      debugMode: DebugMode.dots,
      mesh: meshRect!,
    );
  }
}
