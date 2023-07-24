import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/services.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? path;
  int port = 8080;
  bool showQRCode = false;
  bool authenticationRequired = false;
  bool uploading = false;
  bool showHiddenFiles = false;
  bool zip = false;
  String? username;
  String? password;
  String colorScheme = 'squirrel';
  static int? runPid;
  static bool dialogShown = false;
  static List<String> supportedImageFormats = [
    "jpg",
    "jpeg",
    "png",
    "gif",
    "bmp",
    "tiff",
    "tga",
    "pvr",
    "ico",
    "psd",
    "webp",
    "exr",
  ];

  // when the app is closed, make sure to kill miniserve
  @override
  void dispose() {
    Process.killPid(runPid!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: () => _pickFiles(),
                          child: const Text('Select a File or Folder'),
                        ),
                        const SizedBox(height: 16.0),
                        if (path != null) ...[
                          const Text('Selected File or Folder:'),
                          const SizedBox(height: 16.0),
                          Text(path!),
                          // check if image of supported format (supportedImageFormats)
                          if (supportedImageFormats.contains(
                              path!.split('.').last.toLowerCase())) ...[
                            const SizedBox(height: 16.0),
                            Image.file(File(path!)),
                          ],
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Settings',
                            style: TextStyle(
                                decoration: TextDecoration.underline,
                                fontSize: 32.0,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16.0),
                        const Text('Show QR Code'),
                        Switch(
                          value: showQRCode,
                          onChanged: (value) {
                            setState(() {
                              showQRCode = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16.0),
                        const Text('Show Hidden Files'),
                        Switch(
                          value: showHiddenFiles,
                          onChanged: (value) {
                            setState(() {
                              showHiddenFiles = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16.0),
                        const Text('Upload Files'),
                        Switch(
                          value: uploading,
                          onChanged: (value) {
                            setState(() {
                              uploading = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16.0),
                        const Text('Zip Files'),
                        Switch(
                          value: zip,
                          onChanged: (value) {
                            setState(() {
                              zip = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16.0),
                        const Text('Port:'),
                        TextField(
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            port = int.tryParse(value) ?? 8080;
                            setState(() {});
                          },
                          decoration: const InputDecoration(
                            hintText: 'Default: 8080',
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        // choose color scheme (squirrel (default), archlinux, zenburn, monokai)
                        const Text('Color Scheme:'),
                        DropdownButton<String>(
                          value: colorScheme.toLowerCase(),
                          onChanged: (value) {
                            setState(() {
                              colorScheme = value!;
                            });
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'squirrel',
                              child: Text('Squirrel'),
                            ),
                            DropdownMenuItem(
                              value: 'archlinux',
                              child: Text('Arch Linux'),
                            ),
                            DropdownMenuItem(
                              value: 'zenburn',
                              child: Text('Zenburn'),
                            ),
                            DropdownMenuItem(
                              value: 'monokai',
                              child: Text('Monokai'),
                            ),
                          ],
                        ),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          // add padding
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Authentication Required'),
                                Switch(
                                  value: authenticationRequired,
                                  onChanged: (value) {
                                    setState(() {
                                      authenticationRequired = value;
                                    });
                                  },
                                ),
                                if (authenticationRequired) ...[
                                  const SizedBox(height: 16.0),
                                  const Text('Username:'),
                                  TextField(
                                    onChanged: (value) {
                                      username = value;
                                      setState(() {});
                                    },
                                    decoration: const InputDecoration(
                                      hintText: 'Username',
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  const Text('Password:'),
                                  TextField(
                                    onChanged: (value) {
                                      password = value;
                                      setState(() {});
                                    },
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Password',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 64.0),
              ),
              onPressed: () {
                _serveFilesInIsolate(
                    path,
                    port,
                    showQRCode,
                    authenticationRequired,
                    uploading,
                    zip,
                    username,
                    password,
                    showHiddenFiles,
                    colorScheme,
                    context);
              },
              child:
                  const Text('Serve Files', style: TextStyle(fontSize: 24.0)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    debugPrint('pick files');
    Directory rootDirectory = Directory('~/');
    // check if windows
    if (Platform.isWindows) {
      // users home directory
      rootDirectory = Directory(Platform.environment['UserProfile']!);
    }
    // check if macos
    if (Platform.isMacOS) {
      // users home directory
      rootDirectory = Directory(Platform.environment['HOME']!);
    }
    // check if linux
    if (Platform.isLinux) {
      // users home directory
      rootDirectory = Directory(Platform.environment['HOME']!);
    }
    path = await FilesystemPicker.open(
      title: 'Select a file or folder',
      context: context,
      rootDirectory: rootDirectory,
      pickText: 'Select',
      folderIconColor: Colors.teal,
      fileTileSelectMode: FileTileSelectMode.wholeTile,
    );
    debugPrint(path);
    setState(() {});
  }

  static Future<void> _serveFilesInIsolate(
    String? path,
    int port,
    bool showQRCode,
    bool authenticationRequired,
    bool uploading,
    bool zip,
    String? username,
    String? password,
    bool showHiddenFiles,
    String colorScheme,
    BuildContext context,
  ) async {
    // miniserve command is in assets folder (that will be compiled with the app)
    String command = "miniserve";
    List<String> args = [];
    Map<String, String> env = {};
    String os = Platform.operatingSystem;
    String output = '';
    // check if windows
    if (os == 'windows') {
      command = 'miniserve.exe';
    }
    // check if macos
    if (os == 'macos') {
      command = 'miniserve';
    }
    // check if linux
    if (os == 'linux') {
      command = 'miniserve';
    }

    if (path != null) {
      args.add(path);
    }
    if (port != 8080) {
      env['MINISERVE_PORT'] = port.toString();
    }
    // if (showQRCode) {
    //   args.add('--qrcode');
    // }
    if (authenticationRequired) {
      args.add('--auth $username:$password');
    }
    if (uploading) {
      args.add('--upload-files');
    }
    if (showHiddenFiles) {
      args.add('--hidden');
    }
    if (zip) {
      args.add('--enable-zip');
    }
    if (colorScheme != 'squirrel') {
      env['MINISERVE_COLOR_SCHEME'] = colorScheme;
    }
    args.add('-v');
    debugPrint(command);

    // Start the process.
    Process process =
        await Process.start(command, args, environment: env, runInShell: true);

    // Listen to stdout and stderr streams.
    process.stdout.transform(utf8.decoder).listen((String data) {
      // This callback is called as new data is received from the stdout stream.
      debugPrint("Output: $data");
      output += data;

      // Process the real-time output here (e.g., extract IP or update UI).
      // You can add your logic based on the streaming output data.

      // For example, if you want to extract the first line that contains '192.168.',
      String ip = output.split('\n').firstWhere(
            (element) => element.contains('192.168.'),
            orElse: () => '',
          );
      if (ip.isNotEmpty && !dialogShown) {
        dialogShown = true;
        runPid = process.pid;
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              contentPadding: const EdgeInsets.all(10),
              // set height to 1/3 of screen
              title: const Text('Server running at:'),
              content: Container(
                width: MediaQuery.of(context).size.width / 3,
                height: MediaQuery.of(context).size.height / 3,
                alignment: Alignment.center,
                child: Column(
                  children: [
                    // make ip address selectable and copyable
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SelectableText(
                          ip,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20),
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: ip));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied to clipboard'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                    if (showQRCode) ...[
                      // show qr code (barcode package)
                      const SizedBox(
                        height: 10,
                      ),
                      BarcodeWidget(
                        barcode: Barcode.qrCode(),
                        data: ip,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        width: MediaQuery.of(context).size.width,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    dialogShown = false;
                    Navigator.pop(context);
                    process.kill();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    });

    process.stderr.transform(utf8.decoder).listen((String data) {
      // This callback is called as new data is received from the stderr stream (error output).
      debugPrint("Error: $data");
      output += data;
      // display error in snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data),
        ),
      );
    });

    // Wait for the process to complete.
    await process.exitCode;

    // After the process has completed, you can perform any final actions here.
    debugPrint('Process completed.');
    debugPrint('Final output:');
    debugPrint(output);
  }
}

void main() {
  runApp(MaterialApp(
      home: const MyHomePage(title: 'Miniserve'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
        brightness: Brightness.dark,
      )));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Miniserve',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
