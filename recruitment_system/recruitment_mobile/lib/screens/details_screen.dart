import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/offre.dart';
import '../services/api_service.dart';
import '../api_config.dart';

class DetailsScreen extends StatelessWidget {
  final Offre offre;
  final ApiService api = ApiService();

  DetailsScreen({super.key, required this.offre});

  void _handlePostuler(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      String? token = await api.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connectez-vous d'abord")));
        return;
      }

      bool success = await api.postuler(
        offre.id,
        result.files.single.bytes!,
        result.files.single.name,
        token,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? "Postulation réussie !" : "Erreur lors de l'envoi")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApiConfig.kBgMain,
      appBar: AppBar(title: Text(offre.titre), backgroundColor: ApiConfig.kBgCard),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(offre.titre, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(offre.enterprise, style: const TextStyle(fontSize: 18, color: ApiConfig.kPrimary)),
            const Divider(height: 40, color: Colors.white10),
            Expanded(child: SingleChildScrollView(child: Text(offre.description, style: const TextStyle(color: Colors.white70, height: 1.5)))),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _handlePostuler(context),
                style: ElevatedButton.styleFrom(backgroundColor: ApiConfig.kPrimary),
                child: const Text("Upload CV & Postuler"),
              ),
            )
          ],
        ),
      ),
    );
  }
}