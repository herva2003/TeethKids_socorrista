import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Mapa_page.dart';
import 'avaliacao_page.dart';
import 'home_page.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class WaitPage extends StatefulWidget {
  final String emergencyId;
  final String numeroTelefone;
  final String nomeCompleto;
  final String userId;
  bool isModalOpen;

  WaitPage({
    Key? key,
    required this.emergencyId,
    required this.numeroTelefone,
    required this.nomeCompleto,
    required this.userId,
    this.isModalOpen = false,
  }) : super(key: key);

  @override
  _WaitPageState createState() => _WaitPageState();
}

class _WaitPageState extends State<WaitPage> {
  late Stream<DocumentSnapshot> _emergencyStream;
  late List<dynamic> _campoList;
  String? fcmToken;
  late String avaliacaoId;

  @override
  void initState() {
    super.initState();
    _campoList = [];
    _emergencyStream = FirebaseFirestore.instance
        .collection('emergencias')
        .doc(widget.emergencyId)
        .snapshots();
  }

  @override
  void didUpdateWidget(WaitPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.emergencyId != oldWidget.emergencyId) {
      _campoList = [];
      _emergencyStream = FirebaseFirestore.instance
          .collection('emergencias')
          .doc(widget.emergencyId)
          .snapshots();
    }
  }

  Future<void> atualizarEmergencia(String dentistId) async {
    Completer<void> completer = Completer<void>();

    await FirebaseFirestore.instance
        .collection('emergencias')
        .doc(widget.emergencyId)
        .update({
      'aceitado': true,
      'aceitadoPor': dentistId,
    }).then((_) {
      completer.complete();
    }).catchError((error) {
      completer.completeError(error);
    });
    return completer.future;
  }

  Future<String> createNewConsultaCollection(
      String dentistId, String? fcmToken) async {
    DocumentReference docRef =
    await FirebaseFirestore.instance.collection('consulta').add({
      'dentistId': dentistId,
      'userPhoneNumber': widget.numeroTelefone,
      'createdAt': FieldValue.serverTimestamp(),
      'fcmToken': fcmToken,
    });

    String documentId = docRef.id;
    return documentId;
  }

  void goToAvaliacao(String dentistId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AvaliacaoPage(
          emergencyId: widget.emergencyId,
          nomeCompleto: widget.nomeCompleto,
          userId: widget.userId,
          dentistId: dentistId,
        ),
      ),
    );
  }

  void checkAndNavigateToAvaliacaoPage(
      String dentistId, String nomeCompleto) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('emergencias')
        .doc(widget.emergencyId)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      final avaliado = data['avaliado'];

      if (avaliado != null && avaliado is bool && !avaliado) {
        goToAvaliacao(dentistId);
      }
    }
  }

  void goToMapa(String consultaId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapaPage(
          consultaId: consultaId,
          emergencyId: widget.emergencyId,
        ),
      ),
    ).then((value) {
      // Ao voltar da página MapaPage, verifica se o modal deve ser fechado
      if (value == true) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showConfirmationModal(String dentistId, String nomeCompleto) async {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Deseja escolher este dentista?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Sim'),
              onPressed: () {
                atualizarEmergencia(dentistId).then((_) {
                  createNewConsultaCollection(dentistId, fcmToken)
                      .then((consultaId) {
                    goToMapa(consultaId);
                  });
                }).catchError((error) {
                  // Handle error
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Não'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteEmergency() async {
    await FirebaseFirestore.instance
        .collection('emergencias')
        .doc(widget.emergencyId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WaitPage(
              emergencyId: widget.emergencyId,
              numeroTelefone: widget.numeroTelefone,
              nomeCompleto: widget.nomeCompleto,
              userId: widget.userId,
              isModalOpen: false,
            ),
          ),
        );
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Dentistas próximos a você'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: StreamBuilder<DocumentSnapshot>(
            stream: _emergencyStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final data =
                snapshot.data!.data() as Map<String, dynamic>;
                final campo = data['dentistId'];

                if (campo != null && campo is String) {
                  _campoList = [campo];
                } else if (campo != null && campo is List<dynamic>) {
                  _campoList = campo;
                }

                if (_campoList.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Esperando por dentistas...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  );
                }

                String campoString = campo.toString();
                String campoSemColchetes = campoString
                    .replaceAll('[', '')
                    .replaceAll(']', '');

                checkAndNavigateToAvaliacaoPage(
                    campoSemColchetes, widget.nomeCompleto);

                return ListView.builder(
                  itemCount: _campoList.length,
                  itemBuilder: (context, index) {
                    final itemId = _campoList[index];

                    final itemStream = FirebaseFirestore.instance
                        .collection('users')
                        .doc(itemId)
                        .snapshots();

                    return StreamBuilder<DocumentSnapshot>(
                      stream: itemStream,
                      builder: (context, itemSnapshot) {
                        if (itemSnapshot.hasData) {
                          final itemData =
                          itemSnapshot.data!.data() as Map<String, dynamic>;
                          final nomeDentista = itemData['name'];
                          final notaDentista = double.parse(itemData['nota']);
                          final notaDentistaInt = notaDentista.toStringAsFixed(1);
                          final curriculo = itemData['curriculo'];
                          final qtdAvaliacoes = itemData['quantidadeAvaliacoes'];

                          fcmToken = itemData['fcmToken'];

                          return InkWell(
                            onTap: () {
                              _showConfirmationModal(
                                  itemId.toString(), widget.nomeCompleto);
                            },
                            child: Card(
                              elevation: 5,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage:
                                      NetworkImage(itemData['selfie']),
                                      radius: 40,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$nomeDentista',
                                            style:
                                            const TextStyle(fontSize: 20),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '$curriculo',
                                            style:
                                            const TextStyle(fontSize: 16),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              RatingBar.builder(
                                                initialRating: notaDentista,
                                                minRating: 1,
                                                direction: Axis.horizontal,
                                                allowHalfRating: true,
                                                itemCount: 5,
                                                itemSize: 20,
                                                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                                                itemBuilder: (context, _) => const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                ),
                                                onRatingUpdate: (rating) {
                                                  print(rating);
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '$notaDentistaInt   ($qtdAvaliacoes)',
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        } else if (itemSnapshot.hasError) {
                          return Text('Error: ${itemSnapshot.error}');
                        }

                        return const CircularProgressIndicator();
                      },
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              return const CircularProgressIndicator();
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog<void>(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirmar exclusão'),
                  content: const Text(
                      'Tem certeza de que deseja excluir esta emergência?'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Sim'),
                      onPressed: () {
                        deleteEmergency();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomePage(
                              userId: widget.userId,
                            ),
                          ),
                        );
                      },
                    ),
                    TextButton(
                      child: const Text('Não'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          },
          child: const Icon(Icons.delete),
        ),
      ),
    );
  }
}
