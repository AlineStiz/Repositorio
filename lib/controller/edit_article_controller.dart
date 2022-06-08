import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:projeto_tcc/models/article.dart';

class EditController extends ChangeNotifier {
  String? archiveSelected;
  String? uploadedPdfUrl;
  final _storage = FirebaseStorage.instance;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final formKey = GlobalKey<FormState>();
  String? articleId;
  double total = 0;
  Uint8List? file;
  Uint8List? imageFile;
  String? imageUploaded;
  String? imageSelected;
  String? imageUploadedName;
  final firestore = FirebaseFirestore.instance;
  TextEditingController titleController = TextEditingController();
  TextEditingController yearController = TextEditingController();
  TextEditingController resumeController = TextEditingController();
  TextEditingController courseController = TextEditingController();
  TextEditingController authorController = TextEditingController();
  TextEditingController advisorController = TextEditingController();

  Future pickImageFromGallery() async {
    imageSelected = null;
    
    notifyListeners();
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      imageSelected = result.files.single.name;
      if (imageFile != result.files.single.bytes) total = 0;
      imageFile = result.files.single.bytes;
      notifyListeners();
    }
    notifyListeners();
    uploadImage();
  }

  Future uploadImage() async {
    final BuildContext context = scaffoldKey.currentContext!;
    if (imageFile != null) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          actions: [
            TextButton(
              onPressed: () {
                notifyListeners();
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                uploadImagetoFireBase();
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
          title: const Text('Deseja enviar o arquivo?'),
        ),
      );
    }
  }

  Future uploadImagetoFireBase() async {
    notifyListeners();
    final Uint8List file = imageFile!;
    final Reference _reference = _storage.ref('images').child(imageSelected!);
    final UploadTask task = _reference.putData(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    task.snapshotEvents.listen((snapshot) async {
      if (snapshot.state == TaskState.running) {
        notifyListeners();
      } else if (snapshot.state == TaskState.success) {
        imageUploaded = await snapshot.ref.getDownloadURL();
        imageUploadedName = imageSelected;

        notifyListeners();
      }
    });
    notifyListeners();
  }

  void openEditPage(Article article) {
    articleId = article.id;
    titleController.text = article.title;
    yearController.text = article.year;
    resumeController.text = article.description;
    courseController.text = article.course;
    authorController.text = article.author;
    advisorController.text = article.advisor;
    uploadedPdfUrl = article.url;
    imageUploaded = article.imageUploaded;
    imageSelected = article.imageUploadedName;

    notifyListeners();
  }

  Future pickAndUploadFile() async {
    final BuildContext context = scaffoldKey.currentContext!;
    await filePicker();
    if (file != null) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          actions: [
            TextButton(
              onPressed: () {
                total = 0;
                file = null;
                archiveSelected = null;
                notifyListeners();
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await uploadDocument();
              },
              child: const Text('OK'),
            ),
          ],
          content: total == 100
              ? const Text('Arquivo enviado com sucesso!')
              : total == 0
                  ? Text(
                      'O arquivo selecionado foi: $archiveSelected',
                    )
                  : Text('Arquivo enviado $total %'),
          title: const Text('Deseja enviar o arquivo?'),
        ),
      );
    }
  }

  Future uploadDocument() async {
    final Reference _reference =
        _storage.ref('articles').child(archiveSelected!);
    final UploadTask task = _reference.putData(
      file!,
    );
    task.snapshotEvents.listen((snapshot) async {
      if (snapshot.state == TaskState.running) {
        total = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        notifyListeners();
      } else if (snapshot.state == TaskState.success) {
        uploadedPdfUrl = await snapshot.ref.getDownloadURL();
        notifyListeners();
      }
    });
  }

  Future<void> filePicker() async {
    archiveSelected = null;
    notifyListeners();
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      archiveSelected = result.files.single.name;
      if (file != result.files.single.bytes) total = 0;
      file = result.files.single.bytes;
      notifyListeners();
    }
  }

  Future save() async {
    final BuildContext context = scaffoldKey.currentContext!;
    if (formKey.currentState!.validate()) {
      try {
        if (FirebaseAuth.instance.currentUser == null) {
          _buildSnackBar(
            context: context,
            content: 'Faça login para salvar!',
            duration: 5,
            action: SnackBarAction(
              label: 'Fazer Login',
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  '/',
                );
              },
            ),
          );
        } else {
          await firestore.collection('articles').doc('$articleId').update({
            'author': authorController.text,
            'course': courseController.text,
            'title': titleController.text,
            'description': resumeController.text,
            'url': uploadedPdfUrl,
            'year': yearController.text,
            'advisor': advisorController.text,
            'wasSendedBy': FirebaseAuth.instance.currentUser!.email.toString(),
            'pdfName': archiveSelected,
            'imageUploaded': imageUploaded,
            'imageUploadedName': imageSelected,
          });

          pushToHomePage();

          clean();
          _buildSnackBar(
            context: context,
            content: 'Artigo editado com sucesso!',
            duration: 3,
          );
        }
      } catch (e) {
        _buildSnackBar(
          context: context,
          content: 'Erro ao editar o artigo: $e',
          duration: 2,
        );
      }
    }
  }

  void pushToHomePage() {
    Navigator.pushReplacementNamed(scaffoldKey.currentContext!, '/home');
  }

  void _buildSnackBar({
    required BuildContext context,
    required String content,
    required int duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          content,
        ),
        action: action,
        duration: Duration(seconds: duration),
      ),
    );
  }

  void clean() {
    titleController.clear();
    yearController.clear();
    resumeController.clear();
    courseController.clear();
    authorController.clear();
    advisorController.clear();
    uploadedPdfUrl = null;
    file = null;
    archiveSelected = null;
    total = 0;
    notifyListeners();
  }
}
