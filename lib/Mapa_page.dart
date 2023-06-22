import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapaPage extends StatefulWidget {
  final String consultaId;
  final String emergencyId;

  const MapaPage({
    Key? key,
    required this.consultaId,
    required this.emergencyId,
  }) : super(key: key);

  @override
  _MapaPageState createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  Stream<DocumentSnapshot>? consultaStream;
  bool isLoading = true;
  Timer? timeoutTimer;

  @override
  void initState() {
    super.initState();
    consultaStream = FirebaseFirestore.instance
        .collection('consulta')
        .doc(widget.consultaId)
        .snapshots();

    timeoutTimer = Timer(const Duration(seconds: 20), () {
      Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    timeoutTimer?.cancel();
    deleteConsulta();
    super.dispose();
  }

  void deleteConsulta() async {
    await FirebaseFirestore.instance
        .collection('consulta')
        .doc(widget.consultaId)
        .delete();

    await FirebaseFirestore.instance
        .collection('emergencias')
        .doc(widget.emergencyId)
        .update({
      'aceitado': false,
      'aceitadoPor': FieldValue.delete(),
    });
  }

  void _openMaps(String address) async {
    if (address.isNotEmpty) {

      String googleMaps =
          'https://www.google.com/maps/search/?api=1&query=$address';
      String googleMapsNavegador =
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';

      await launch(googleMapsNavegador);

      if (await canLaunch(googleMaps)) {
        await canLaunch(googleMaps);
      } else if(await canLaunch(googleMapsNavegador)) {
        await canLaunch(googleMapsNavegador);
      } else{
        throw 'Não foi possível abrir o Google Maps';
      }
    }
  }

  void _enviarEnderecoParaFirebase() async {
    Completer<void> completer = Completer<void>(); // Create a completer

    // Verifique se o usuário concedeu permissão para acessar a localização
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // Caso a permissão não tenha sido concedida, solicite-a
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      // Obtenha as coordenadas do dispositivo
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Obtenha o endereço a partir das coordenadas
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String enderecoAtual = placemark.street ?? '';

        // Atualize o documento de consulta no Firebase com o novo endereço
        await FirebaseFirestore.instance
            .collection('consulta')
            .doc(widget.consultaId)
            .update({
          'endereco': enderecoAtual,
          'latitude': position.latitude,
          'longitude': position.longitude,
        });

        completer.complete(); // Resolve the completer
      } else {
        completer.completeError('Não foi possível obter o endereço.'); // Reject the completer with an error
      }
    } else {
      completer.completeError('Permissão de localização negada.'); // Reject the completer with an error
    }

    completer.future.then((_) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Endereço enviado'),
            content: const Text('O endereço foi enviado com sucesso.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // Use the dialogContext to close the dialog
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }).catchError((error) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Erro'),
            content: Text('Ocorreu um erro ao enviar o endereço: $error'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // Use the dialogContext to close the dialog
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Endereço do Dentista'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: consultaStream,
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            if (data.containsKey('endereco')) {
              String address = data['endereco'];
              isLoading = false;

              // Cancelar o timer quando o endereço for encontrado
              timeoutTimer?.cancel();

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Endereço de encontro:',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      address,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _openMaps(address),
                      child: const Text('Abrir no Google Maps'),
                    ),
                  ],
                ),
              );
            } else {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 10),
                    const Text(
                      'Aguarde enquanto o dentista envia a localização...',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _enviarEnderecoParaFirebase(),
                      child: const Text('Envie seu endereço ao dentista'),
                    ),
                  ],
                ),
              );
            }
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                  'Erro ao obter o endereço do Firebase: ${snapshot.error}'),
            );
          } else {
            return Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Endereço não encontrado'),
            );
          }
        },
      ),
      floatingActionButton: Visibility(
        visible: isLoading,
        child: FloatingActionButton(
          onPressed: () {
            deleteConsulta();
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back),
        ),
      ),
    );
  }
}
