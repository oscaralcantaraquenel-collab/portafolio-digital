import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'pantalla_login.dart';

class PantallaPerfil extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final Function(Map<String, dynamic>) onPerfilActualizado;

  const PantallaPerfil({super.key, required this.usuario, required this.onPerfilActualizado});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  late String _nombre;
  late String _correo;
  late String _username;
  late String _fotoBase64;

  @override
  void initState() {
    super.initState();
    _nombre = widget.usuario['name'] ?? '';
    _correo = widget.usuario['user'] ?? '';
    _username = widget.usuario['username'] ?? _correo.split('@').first;
    _fotoBase64 = widget.usuario['foto_base64'] ?? '';
  }

  // --- FUNCIÓN PARA SELECCIONAR Y CONVERTIR FOTO ---
  Future<void> _seleccionarFoto() async {
    final ImagePicker picker = ImagePicker();
    // Comprimimos la imagen para que la base de datos no se sature
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 25,
      maxWidth: 400,
      maxHeight: 400,
    );

    if (image != null) {
      // 1. Leemos el archivo y lo convertimos a texto (Base64)
      Uint8List bytes = await image.readAsBytes();
      String base64String = base64Encode(bytes);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 2. Guardamos la foto real como texto en Firestore
        await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
          'foto_base64': base64String,
        });

        // 3. Actualizamos la pantalla al instante
        setState(() {
          _fotoBase64 = base64String;
        });

        // 4. Le avisamos a main.dart
        Map<String, dynamic> usuarioActualizado = Map.from(widget.usuario);
        usuarioActualizado['name'] = _nombre;
        usuarioActualizado['username'] = _username;
        usuarioActualizado['foto_base64'] = base64String;

        widget.onPerfilActualizado(usuarioActualizado);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto de perfil actualizada y guardada en la nube'), backgroundColor: Colors.green)
        );
      }
    }
  }

  // --- FUNCIÓN PARA CAMBIAR CONTRASEÑA ---
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
          title: Row(
            children: [
              Icon(Icons.mark_email_read, color: Colors.green.shade700),
              const SizedBox(width: 10),
              const Text('Correo Enviado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text('Hemos enviado un enlace seguro a $_correo para restablecer tu contraseña.\n\nPor seguridad, cerraremos tu sesión actual para que puedas ingresar con tus nuevas credenciales una vez que las cambies.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                // Redirigimos al Login
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const PantallaLogin()),
                      (route) => false,
                );
              },
              child: const Text('Entendido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar la solicitud: $e'), backgroundColor: Colors.red)
      );
    }
  }

  // --- DIÁLOGO PARA EDITAR NOMBRE Y USERNAME ---
  void _mostrarDialogoEditar() {
    final nombreController = TextEditingController(text: _nombre);
    final usernameController = TextEditingController(text: _username);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Editar Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Nombre de Usuario',
                  prefixText: '@ ',
                  prefixIcon: const Icon(Icons.alternate_email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: TextEditingController(text: _correo),
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Correo (No editable)',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () async {
              if (nombreController.text.trim().isEmpty || usernameController.text.trim().isEmpty) return;

              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
                  'nombre': nombreController.text.trim(),
                  'username': usernameController.text.trim().replaceAll(' ', ''),
                });

                setState(() {
                  _nombre = nombreController.text.trim();
                  _username = usernameController.text.trim().replaceAll(' ', '');
                });

                Map<String, dynamic> usuarioActualizado = Map.from(widget.usuario);
                usuarioActualizado['name'] = _nombre;
                usuarioActualizado['username'] = _username;
                widget.onPerfilActualizado(usuarioActualizado);

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perfil actualizado con éxito'), backgroundColor: Colors.green)
                );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 40, top: 10),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 51,
                          backgroundColor: Colors.green.shade100,
                          // --- DECODIFICAR EL TEXTO A IMAGEN ---
                          backgroundImage: _fotoBase64.isNotEmpty
                              ? MemoryImage(base64Decode(_fotoBase64))
                              : null,
                          child: _fotoBase64.isEmpty
                              ? Icon(Icons.person, size: 55, color: Colors.green.shade700)
                              : null,
                        ),
                      ),
                      GestureDetector(
                        onTap: _seleccionarFoto,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.green.shade900, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _nombre,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '@$_username',
                    style: TextStyle(fontSize: 16, color: Colors.green.shade100, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.email_outlined, color: Colors.blue.shade700),
                        ),
                        title: const Text('Correo Electrónico', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        subtitle: Text(_correo, style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500)),
                      ),
                      const Divider(indent: 20, endIndent: 20),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.admin_panel_settings_outlined, color: Colors.orange.shade700),
                        ),
                        title: const Text('Rol de Cuenta', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        subtitle: Text(
                            (widget.usuario['rol'] ?? 'alumno').toString().toUpperCase(),
                            style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.bold)
                        ),
                      ),
                      const Divider(indent: 20, endIndent: 20),
                      // --- NUEVA OPCIÓN DE SEGURIDAD ---
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.lock_reset_outlined, color: Colors.red.shade700),
                        ),
                        title: const Text('Seguridad', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        subtitle: const Text('Cambiar Contraseña', style: TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: _enviarCambioContrasena,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text('Editar Perfil', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: _mostrarDialogoEditar,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}