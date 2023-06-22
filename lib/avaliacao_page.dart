import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';

class AvaliacaoPage extends StatefulWidget {
  final String emergencyId;
  final String nomeCompleto;
  final String? dentistId;
  final String userId;

  const AvaliacaoPage({
    Key? key,
    required this.emergencyId,
    required this.nomeCompleto,
    this.dentistId,
    required this.userId,

  }) : super(key: key);

  @override
  _AvaliacaoPageState createState() => _AvaliacaoPageState();
}

class _AvaliacaoPageState extends State<AvaliacaoPage> {
  double _notaAtendimento = 0.0;
  String _comentarioAtendimento = '';
  double _notaApp = 0.0;
  String _comentarioApp = '';

  void enviarAvaliacao() {

    if (_notaAtendimento == 0.0 || _comentarioAtendimento.isEmpty || _notaApp == 0.0 || _comentarioApp.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Campos obrigatórios vazios'),
            content: const Text('Por favor, preencha todos os campos.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );
    } else {
      FirebaseFirestore.instance.collection('avaliacoes').doc().set({
        'notaAtendimento': _notaAtendimento,
        'dentistId': widget.dentistId,
        'comentarioAtendimento': _comentarioAtendimento,
        'notaApp': _notaApp,
        'comentarioApp': _comentarioApp,
        'userName': widget.nomeCompleto,
        'createdAt': FieldValue.serverTimestamp(),
      }).then((_) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Avaliação enviada'),
              content: const Text('Obrigado por enviar sua avaliação!'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomePage(
                          userId: widget.userId,
                        ),
                      ),
                    );
                  },
                  child: const Text('Fechar'),
                ),
              ],
            );
          },
        );
      });
    }
  }

  void atualizarAvaliacao() {
    FirebaseFirestore.instance
        .collection('emergencias')
        .doc(widget.emergencyId)
        .update({
      'avaliado': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliação'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'De uma nota de 0 a 5 estrelas pelo atendimento do profissional que lhe atendeu:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _notaAtendimento = 1.0;
                      });
                    },
                    child: Icon(
                      Icons.star,
                      size: 40,
                      color: _notaAtendimento >= 1.0 ? Colors.amber : Colors.grey,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _notaAtendimento = 2.0;
                      });
                    },
                    child: Icon(
                      Icons.star,
                      size: 40,
                      color: _notaAtendimento >= 2.0 ? Colors.amber : Colors.grey,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _notaAtendimento = 3.0;
                      });
                    },
                    child: Icon(
                      Icons.star,
                      size: 40,
                      color: _notaAtendimento >= 3.0 ? Colors.amber : Colors.grey,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _notaAtendimento = 4.0;
                      });
                    },
                    child: Icon(
                      Icons.star,
                      size: 40,
                      color: _notaAtendimento >= 4.0 ? Colors.amber : Colors.grey,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _notaAtendimento = 5.0;
                      });
                    },
                    child: Icon(
                      Icons.star,
                      size: 40,
                      color: _notaAtendimento >= 5.0 ? Colors.amber : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Comente o que achou do atendimento em geral:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                onChanged: (value) {
                  setState(() {
                    _comentarioAtendimento = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Dê uma nota para o TeethKids aplicativo:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _notaApp = 1.0;
                      });
                    },
                    child: Icon(
                      Icons.star,
                      size: 40,
                      color: _notaApp >= 1.0 ? Colors.amber : Colors.grey,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _notaApp = 2.0;
                      });
                    },
                    child: Icon(
                      Icons.star,
                      size: 40,
                      color: _notaApp >= 2.0 ? Colors.amber : Colors.grey,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _notaApp = 3.0;
                      });
                    },
                    child: Icon(
                      Icons.star,
                      size: 40,
                      color: _notaApp >= 3.0 ? Colors.amber : Colors.grey,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _notaApp = 4.0;
                      });
                    },
                    child: Icon(
                      Icons.star,
                      size: 40,
                      color: _notaApp >= 4.0 ? Colors.amber : Colors.grey,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _notaApp = 5.0;
                      });
                    },
                    child: Icon(
                      Icons.star,
                      size: 40,
                      color: _notaApp >= 5.0 ? Colors.amber : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Comente o que você achou do aplicativo:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                onChanged: (value) {
                  setState(() {
                    _comentarioApp = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  enviarAvaliacao();
                  atualizarAvaliacao();
                },
                child: const Text('Enviar Avaliação'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}