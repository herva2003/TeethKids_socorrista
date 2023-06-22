import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:teethkids_socorrista2/wait_page.dart';

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ImagePicker imagePicker = ImagePicker();

  List<File?> imagensSelecionadas = List.generate(3, (_) => null);
  List<String?> urlsImagens = List.generate(3, (_) => null);

  final List<String> nomesFotos = [
    'Adicione a foto da boca',
    'Adicione a foto dos documentos',
    'Adicione a foto sua e da criança'
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_storage.FirebaseStorage _storage =
      firebase_storage.FirebaseStorage.instance;

  TextEditingController nomeCompletoController = TextEditingController();
  TextEditingController numeroTelefoneController = TextEditingController();

  bool isCreatingEmergency = false;
  double progressValue = 0.0;
  bool isProgressVisible = false;

  void enviarDadosParaFirestore(String nomeCompleto, String numeroTelefone) async {
    setState(() {
      isCreatingEmergency = true;
    });

    // Get the current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Create a GeoPoint from the latitude and longitude
    GeoPoint location = GeoPoint(position.latitude, position.longitude);

    Map<String, dynamic> dados = {
      'userId': widget.userId,
      'clientName': nomeCompleto,
      'clientPhone': numeroTelefone,
      'aceitado': false,
      "createdAt": FieldValue.serverTimestamp(),
      'imageUrl1': urlsImagens[0],
      'imageUrl2': urlsImagens[1],
      'imageUrl3': urlsImagens[2],
      'location': location,
    };

    _firestore.collection('emergencias').add(dados).then((value) {
      // Envio bem-sucedido
      setState(() {
        isCreatingEmergency = false;
      });
      print('Dados enviados com sucesso para o Firestore');
      mostrarSnackBar('Emergência criada com sucesso!');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WaitPage(
            emergencyId: value.id,
            numeroTelefone: numeroTelefoneController.text,
            nomeCompleto: nomeCompletoController.text,
            userId: widget.userId,
          ),
        ),
      );
    }).catchError((error) {
      // Ocorreu um erro durante o envio+
      setState(() {
        isCreatingEmergency = false;
      });
      print('Erro ao enviar os dados para o Firestore: $error');
      mostrarSnackBar('Erro ao criar a emergência. Tente novamente mais tarde.');
    });
  }

  void mostrarSnackBar(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.grey[800],
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  void dispose() {
    nomeCompletoController.dispose();
    numeroTelefoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(
                userId: widget.userId,
              ),
            ),
          );
          return Future.value(true); // Permite o pop
        },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Crie uma Emergência'),
          automaticallyImplyLeading: false,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: nomeCompletoController,
                      decoration: const InputDecoration(labelText: 'Nome Completo:'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Digite um nome.';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: numeroTelefoneController,
                      decoration: const InputDecoration(labelText: 'Número de Telefone:'),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      maxLength: 11,
                    ),
                    const SizedBox(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        children: List.generate(3, (index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  nomesFotos[index],
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 5),
                                IconButton(
                                  onPressed: () {
                                    pegarImagemCamera(index);
                                  },
                                  icon: const Icon(Icons.photo_camera_outlined,
                                      size: 45),
                                ),
                                const SizedBox(height: 10),
                                imagensSelecionadas[index] != null
                                    ? Image.file(
                                  imagensSelecionadas[index]!,
                                  height: 600,
                                  width: 600,
                                )
                                    : Container(),
                                const SizedBox(height: 10),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: isCreatingEmergency
                          ? null
                          : () async {
                        String nomeCompleto = nomeCompletoController.text;
                        String numeroTelefone =
                            numeroTelefoneController.text;

                        if (nomeCompleto.isEmpty || numeroTelefone.isEmpty || numeroTelefone.length < 11) {
                          if(numeroTelefone.length < 11){
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Erro'),
                                content: const Text(''
                                    'Insira um número de telefone válido de 11 dígitos.'),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Erro'),
                                content: const Text(''
                                    'Preencha o campo de nome'),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                          return;
                        }

                        bool imagensValidas = true;
                        for (int i = 0; i < imagensSelecionadas.length; i++) {
                          if (imagensSelecionadas[i] == null) {
                            imagensValidas = false;
                            break;
                          }
                        }

                        if (!imagensValidas) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Erro'),
                              content: const Text(
                                  'Selecione todas as imagens antes de enviar.'),
                              actions: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        setState(() {
                          isCreatingEmergency = true;
                        });

                        setState(() {
                          isProgressVisible = true;
                        });

                        for (int i = 0; i < imagensSelecionadas.length; i++) {
                          if (imagensSelecionadas[i] != null) {
                            await enviarImagemFirebaseStorage(
                                imagensSelecionadas[i]!, i);
                          }
                        }

                        enviarDadosParaFirestore(
                            nomeCompleto, numeroTelefone);
                      },
                      child: const Text('Enviar'),
                    ),
                  ],
                ),
              ),
            ),
            Visibility(
              visible: isProgressVisible,
              child: Container(
                alignment: Alignment.center,
                color: Colors.black54,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Criando emergência...',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 320,
                            height: 9,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4.0),
                              child: LinearProgressIndicator(
                                value: progressValue,
                                backgroundColor: Colors.white,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      )
    );
  }


  void pegarImagemCamera(int index) async {
    final pickedFile =
    await imagePicker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        imagensSelecionadas[index] = File(pickedFile.path);
      });
    }
  }

  Future<void> enviarImagemFirebaseStorage(
      File imagem, int index) async {
    String nomeArquivo =
    DateTime.now().millisecondsSinceEpoch.toString();

    try {
      firebase_storage.UploadTask uploadTask = _storage
          .ref('imagens/$nomeArquivo')
          .putFile(imagem);

      uploadTask.snapshotEvents.listen((firebase_storage.TaskSnapshot snapshot) {
        setState(() {
          progressValue = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      await uploadTask.whenComplete(() async {
        String url = await _storage
            .ref('imagens/$nomeArquivo')
            .getDownloadURL();

        setState(() {
          urlsImagens[index] = url;
          progressValue = 0.0;
        });
      });
    } catch (e) {
      print('Erro ao enviar imagem para o Firebase Storage: $e');
    }
  }
}