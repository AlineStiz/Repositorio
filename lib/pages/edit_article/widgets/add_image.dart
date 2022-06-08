import 'package:flutter/material.dart';
import 'package:projeto_tcc/controller/edit_article_controller.dart';
import 'package:provider/provider.dart';

class AddImage extends StatelessWidget {
  const AddImage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final EditController addController = Provider.of<EditController>(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (addController.imageFile == null)
          TextButton(
            onPressed: () {
              addController.pickImageFromGallery();
            },
            child: const Text('Editar imagem'),
          ),
        if (addController.imageUploaded != null) const Text('Imagem Enviada!')
      ],
    );
  }
}
