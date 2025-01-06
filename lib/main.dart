import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// ThemeProvider class
class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = ThemeData.light();

  ThemeData get themeData => _themeData;

  void setTheme(ThemeData theme) {
    _themeData = theme;
    notifyListeners();
  }
}

// Main function
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

// MyApp widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini Chat',
      theme: Provider.of<ThemeProvider>(context).themeData,
      home: ChatScreen(),
    );
  }
}

// ChatScreen widget
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();

  static Map<String, Object?> setThemeValues(
      BuildContext context, Map<String, Object?> args) {
    final brightnessValue = args['brightness'];
    double? brightness;

    if (brightnessValue is int) {
      brightness = brightnessValue.toDouble();
    } else if (brightnessValue is double) {
      brightness = brightnessValue;
    }
    final colorTemperature = args['colorTemperature'] as String?;

    Color? color;
    if (colorTemperature == 'warm') {
      color = Colors.orange;
    } else if (colorTemperature == 'cool') {
      color = Colors.blue;
    } else if (colorTemperature == 'daylight') {
      color = Colors.white;
    }

    Provider.of<ThemeProvider>(context, listen: false).setTheme(
      ThemeData(
        brightness: brightness == 0 ? Brightness.dark : Brightness.light,
        primaryColor: color,
      ),
    );

    return args;
  }

// controlThemeFunction declaration
  static final controlThemeFunction = FunctionDeclaration(
    'controlTheme',
    'Set the brightness and color temperature of the app theme.',
    Schema.object(
      properties: {
        'brightness': Schema.number(
          description:
              'Brightness level from 0 to 100. Zero is dark and 100 is full brightness.',
          nullable: false,
        ),
        'colorTemperature': Schema.string(
          description:
              'Color temperature which can be `warm`, `cool`, or `daylight`.',
          nullable: false,
        ),
      },
      //60
    ),
  );

// functions map and dispatchFunctionCall
  final functions = {
    controlThemeFunction.name: setThemeValues,
  };

  FunctionResponse dispatchFunctionCall(FunctionCall call) {
    final function = functions[call.name]!;
    final result = function(context, call.args);
    return FunctionResponse(call.name, result);
  }

  final _messages = <String>[];
  final model = GenerativeModel(
    model: 'gemini-1.5-pro',
    apiKey: 'Add Your API Key',
    tools: [
      Tool(functionDeclarations: [controlThemeFunction]),
    ],
  );

  void _sendMessage(String message) {
    setState(() {
      _messages.add('You: $message');
    });

    final prompt = message;
    final content = [Content.text(prompt)];
    model.generateContent(content).then((response) async {
      while ((response.functionCalls.toList()).isNotEmpty) {
        var resonses;
        if (response.functionCalls.isNotEmpty) {
          resonses = <FunctionResponse>[
            for (final call in response.functionCalls)
              dispatchFunctionCall(call)
          ];
        }
        content
          ..add(response.candidates.first.content)
          ..add(Content.functionResponses(resonses));
        response = await model.generateContent(content);
      }
      setState(() {
        _messages.add('Gemini: ${response.text}');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gemini Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_messages[index]),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (value) {
                      _sendMessage(value);
                      _controller.clear();
                    },
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    _sendMessage(_controller.text);
                    //change theme
                    _controller.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
