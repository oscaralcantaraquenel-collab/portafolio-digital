import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'pantalla_login.dart';

class PantallaPerfilDocente extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final Function(Map<String, dynamic>) onPerfilActualizado;

  const PantallaPerfilDocente({super.key, required this.usuario, required this.onPerfilActualizado});

  @override
  State<PantallaPerfilDocente> createState() => _PantallaPerfilDocenteState();
}

class _PantallaPerfilDocenteState extends State<PantallaPerfilDocente> {
  late String _nombre;
  late String _correo;
  late String _fotoBase64;

  @override
  void initState() {
    super.initState();
    _nombre = widget.usuario['name'] ?? '';
    _correo = widget.usuario['user'] ?? '';
    _fotoBase64 = widget.usuario['foto_base64'] ?? '';
  }

  Future<void> _seleccionarFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 25, maxWidth: 400, maxHeight: 400);

    if (image != null) {
      Uint8List bytes = await image.readAsBytes();
      String base64String = base64Encode(bytes);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({'foto_base64': base64String});
        setState(() => _fotoBase64 = base64String);
        Map<String, dynamic> usuarioActualizado = Map.from(widget.usuario);
        usuarioActualizado['name'] = _nombre;
        usuarioActualizado['foto_base64'] = base64String;
        widget.onPerfilActualizado(usuarioActualizado);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto de perfil actualizada'), backgroundColor: Colors.green));
      }
    }
  }

  Future<void> _enviarCambioContrasena() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _correo);
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: [Icon(Icons.mark_email_read, color: Colors.green.shade700), const SizedBox(width: 10), const Text('Correo Enviado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
            content: Text('Hemos enviado un enlace seguro a $_correo para restablecer tu contraseña.\n\nCerraremos tu sesión por seguridad.'),
            actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () async { await FirebaseAuth.instance.signOut(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const PantallaLogin()), (route) => false); }, child: const Text('Entendido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))]
        ),
      );
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)); }
  }

  void _mostrarDialogoEditar() {
    final nombreController = TextEditingController(text: _nombre);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Editar Perfil Docente', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(controller: nombreController, decoration: InputDecoration(labelText: 'Nombre Completo', prefixIcon: const Icon(Icons.badge_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              if (nombreController.text.trim().isEmpty) return;
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({'nombre': nombreController.text.trim()});
                setState(() => _nombre = nombreController.text.trim());
                Map<String, dynamic> usuarioActualizado = Map.from(widget.usuario);
                usuarioActualizado['name'] = _nombre;
                widget.onPerfilActualizado(usuarioActualizado);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado'), backgroundColor: Colors.green));
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color colorPrimario = Colors.green.shade800;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(title: const Text('Perfil del Docente', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: colorPrimario, foregroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: colorPrimario, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40))),
              padding: const EdgeInsets.only(bottom: 40, top: 10),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(radius: 55, backgroundColor: Colors.white, child: CircleAvatar(radius: 51, backgroundColor: Colors.green.shade100, backgroundImage: _fotoBase64.isNotEmpty ? MemoryImage(base64Decode(_fotoBase64)) : null, child: _fotoBase64.isEmpty ? Icon(Icons.person, size: 55, color: colorPrimario) : null)),
                      GestureDetector(onTap: _seleccionarFoto, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.shade900, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.camera_alt, color: Colors.white, size: 20))),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(_nombre, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 5),
                  Text('Profesor Administrador', style: TextStyle(fontSize: 14, color: Colors.green.shade100, fontWeight: FontWeight.w500, letterSpacing: 1)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                color: Colors.white, elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      ListTile(leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.email_outlined, color: Colors.blue.shade700)), title: const Text('Correo Institucional', style: TextStyle(fontSize: 13, color: Colors.grey)), subtitle: Text(_correo, style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500))),
                      const Divider(indent: 20, endIndent: 20),
                      ListTile(leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.verified_user_outlined, color: Colors.orange.shade700)), title: const Text('Tipo de Cuenta', style: TextStyle(fontSize: 13, color: Colors.grey)), subtitle: const Text('DOCENTE VERIFICADO', style: TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.bold))),
                      const Divider(indent: 20, endIndent: 20),
                      ListTile(leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.lock_reset_outlined, color: Colors.red.shade700)), title: const Text('Seguridad', style: TextStyle(fontSize: 13, color: Colors.grey)), subtitle: const Text('Actualizar Contraseña', style: TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500)), trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey), onTap: _enviarCambioContrasena),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(width: double.infinity, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), icon: const Icon(Icons.edit, color: Colors.white), label: const Text('Editar Datos de Perfil', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)), onPressed: _mostrarDialogoEditar)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}