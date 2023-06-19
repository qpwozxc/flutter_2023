import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //기기에서 사용 가능한 카메라 리스트를 가져온다.
  final cameras = await availableCameras();

  // 카메라 리스트 중 첫번째 카메라를 가져온다.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        camera: firstCamera,
      ),
    ),
  );
}

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  List<String> capturedImages = []; //찍은 사진들을 담는 리스트 생성

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        //카메라 버튼
        onPressed: () async {
          try {
            await _initializeControllerFuture;

            final image = await _controller.takePicture();
            capturedImages.add(image.path); //찍은 사진을 추가

            if (!mounted) return;

            // 찍은 사진을 새 화면에 띄우기
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  imagePath: image.path,
                ),
              ),
            );
          } catch (e) {
            // 에러 발생 시 콘솔에 출력
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt), //카메라 아이콘
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat, //가운데 중앙에 버튼을 배치
      persistentFooterButtons: <Widget>[
        // persistentFooterButtons: 항상 화면의 하단에 위치하며, 기본적으로 오른쪽 정렬
        FloatingActionButton(
          //갤러리 버튼
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CapturedImagesScreen(capturedImages: capturedImages),
              ),
            );
          },
          child: const Icon(Icons.photo_album), //갤러리 아이콘
        ),
      ],
    );
  }
}

class CapturedImagesScreen extends StatefulWidget {
  final List<String> capturedImages;

  const CapturedImagesScreen({Key? key, required this.capturedImages})
      : super(key: key);

  @override
  _CapturedImagesScreenState createState() => _CapturedImagesScreenState();
}

class _CapturedImagesScreenState extends State<CapturedImagesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: widget.capturedImages.isEmpty //찍은 사진이 하나도 없다면
          ? Center(
              child: Text(
                'No Images', //'No Images' 출력
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
            )
          : ListView.builder(
              //찍은 사진이 존재한다면
              itemCount: widget.capturedImages.length,
              itemBuilder: (context, index) {
                final imagePath = widget.capturedImages[index];
                return ListTile(
                  leading: Image.file(File(imagePath)), // 이미지 표시
                  title: Text('Image ${index + 1}'), // 리스트의 인덱스 순서대로 사진을 표시
                  trailing: IconButton(
                    icon: Icon(Icons.delete), //삭제버튼
                    onPressed: () {
                      _deleteImage(imagePath); // 이미지 삭제
                    },
                  ),
                );
              },
            ),
    );
  }

  void _deleteImage(String imagePath) {
    showDialog(
      //showDialog: 다이얼로그를 화면에 나타내고 사용자 입력을 기다리는 동안, 이전 화면과 상호작용을 막는다.
      //barrierDismissible: false, // 다이얼로그 외부 터치로 닫기 비활성화
      context: context,
      builder: (context) => AlertDialog(
        // AlertDialog: 사용자에게 메시지를 전달하고 선택을 받을 수 있는 위젯
        title: Text('Delete Image'), // 다이얼로그 상단에 표시되는 제목
        content: Text(
            'Are you sure you want to delete this image?'), // 다이얼로그에 표시되는 메시지나 내용
        actions: [
          // 다이얼로그 하단에 표시되는 액션 ex)"확인","취소"버튼
          TextButton(
            // 삭제 버튼
            onPressed: () {
              //이미지 지우기
              final file = File(imagePath);
              file.delete();

              // CapturedImage 리스트에서 해당 사진을 삭제
              setState(() {
                widget.capturedImages.remove(imagePath);
              });

              Navigator.pop(context);
            },
            child: Text('Delete'),
          ),
          TextButton(
            //삭제 취소 버튼
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// 찍은 사진을 화면에 표시하는 위젯
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Captured Image')),
      body: Center(child: Image.file(File(imagePath))), // 가운데에 정렬
    );
  }
}
