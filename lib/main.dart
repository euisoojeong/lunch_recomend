// 필요한 패키지들을 임포트합니다.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

// 메인 함수입니다.
void main() {
  runApp(MyApp());
}

// 앱의 상태를 관리하는 클래스입니다.
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

// 앱의 상태를 구현하는 클래스입니다.
class _MyAppState extends State<MyApp> {
  // 텍스트를 음성으로 변환하는 객체입니다.
  FlutterTts flutterTts = FlutterTts();

  // 음성을 텍스트로 변환하는 객체입니다.
  SpeechToText speechToText = SpeechToText();

  // 챗봇의 응답을 저장하는 변수입니다.
  String chatResponse = '';

  // 챗봇에게 보낼 프롬프트를 저장하는 변수입니다.
  String chatPrompt = '';

  // 챗봇 API의 기본 URL입니다.
  final String baseUrl = 'https://api.openai.com/v1/chatgpt';

  // 챗봇 API의 인증 토큰입니다. 본인의 토큰으로 변경해야 합니다.
  final String token = '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';

  // 챗봇 API에 http 요청을 보내고 응답을 받는 메서드입니다.
  Future<void> requestChatGpt(String prompt) async {
    // 요청 헤더를 설정합니다.
    Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // 요청 바디를 설정합니다.
    Map<String, dynamic> body = {
      'prompt': prompt, // 챗봇에게 보낼 프롬프트입니다.
      'model': 'gpt-3.5', // 챗봇의 모델 이름입니다.
      'temperature': 0.9, // 챗봇의 응답의 다양성을 조절하는 파라미터입니다. 0에서 1 사이의 값이며, 높을수록 다양한 응답을 생성합니다.
      'max_tokens': 100, // 챗봇이 생성할 최대 토큰 수입니다. 토큰은 단어나 구두점과 같은 문자열의 단위입니다.
      'stop': '\n', // 챗봇이 응답을 끝내는 신호입니다. 이 경우에는 줄바꿈 문자로 설정합니다.
    };

    // http post 메서드를 사용하여 요청을 보냅니다.
    http.Response response = await http.post(
      Uri.parse(baseUrl), // 요청 URL입니다.
      headers: headers, // 요청 헤더입니다.
      body: jsonEncode(body), // 요청 바디입니다. json 형식으로 인코딩합니다.
    );

    // 응답 상태 코드가 200이면 성공적인 요청입니다.
    if (response.statusCode == 200) {
      // 응답 바디를 json 형식으로 디코딩합니다.
      Map<String, dynamic> data = jsonDecode(response.body);

      // 응답 바디에서 챗봇의 응답을 추출합니다.
      chatResponse = data['response'];

      // 상태를 업데이트합니다.
      setState(() {});
    } else {
      // 응답 상태 코드가 200이 아니면 실패한 요청입니다.
      throw Exception('Failed to request ChatGpt API');
    }
  }

  // 텍스트를 음성으로 재생하는 메서드입니다.
  Future<void> playText(String text) async {
    await flutterTts.setLanguage('ko-KR'); // 언어를 한국어로 설정합니다.
    await flutterTts.speak(text); // 텍스트를 음성으로 재생합니다.
  }

  // 음성을 텍스트로 변환하는 메서드입니다.
  Future<void> listenSpeech() async {
    bool available = await speechToText.initialize( // 음성 인식 서비스를 초기화합니다.
      onStatus: (status) {}, // 음성 인식의 상태가 변경될 때 호출되는 콜백 함수입니다.
      onError: (error) {}, // 음성 인식에 에러가 발생할 때 호출되는 콜백 함수입니다.
    );
    if (available) { // 음성 인식 서비스가 사용 가능하면
      await speechToText.listen( // 음성을 듣습니다.
        onResult: (result) { // 음성 인식의 결과가 나올 때 호출되는 콜백 함수입니다.
          chatPrompt = result.recognizedWords; // 인식된 단어들을 프롬프트로 저장합니다.
          setState(() {}); // 상태를 업데이트합니다.
        },
      );
    } else { // 음성 인식 서비스가 사용 불가능하면
      throw Exception('Speech to text service is not available');
    }
  }

  // 음성 인식을 중지하는 메서드입니다.
  Future<void> stopListening() async {
    await speechToText.stop(); // 음성 인식을 중지합니다.
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter STT and TTS Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('ChatGpt Response: $chatResponse'), // 챗봇의 응답을 표시합니다.
              Text('ChatGpt Prompt: $chatPrompt'), // 챗봇에게 보낼 프롬프트를 표시합니다.
              ElevatedButton( // 버튼을 생성합니다.
                child: Text('Request ChatGpt and Play TTS'), // 버튼의 텍스트를 설정합니다.
                onPressed: () async { // 버튼이 눌렸을 때 실행할 코드를 작성합니다.
                  await requestChatGpt(chatPrompt); // 챗봇 API에 요청을 보내고 응답을 받습니다.
                  await playText(chatResponse); // 챗봇의 응답을 음성으로 재생합니다.
                },
              ),
              ElevatedButton( // 버튼을 생성합니다.
                child: Text('Listen Speech and Send Prompt'), // 버튼의 텍스트를 설정합니다.
                onPressed: () async { // 버튼이 눌렸을 때 실행할 코드를 작성합니다.
                  await listenSpeech(); // 음성을 듣고 텍스트로 변환합니다.
                  await stopListening(); // 음성 인식을 중지합니다.
                  await requestChatGpt(chatPrompt); // 챗봇 API에 요청을 보내고 응답을 받습니다.
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
