import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'pantalla_registro.dart';
import 'pantalla_docente.dart';
import '../main.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _cargando = false;
  bool _obscurePassword = true;

  // --- RECUPERAR CONTRASEÑA ---
  Future<void> _recuperarContrasena() async {
    final correo = _correoController.text.trim();

    if (correo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Por favor, escribe tu correo arriba para enviarte el enlace.'),
              backgroundColor: Colors.orange
          )
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: correo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('¡Enlace enviado! Revisa tu bandeja de entrada o Spam.'),
              backgroundColor: Colors.green
          )
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar el enlace: $e'), backgroundColor: Colors.red)
      );
    }
  }

  // --- LÓGICA DE INICIO DE SESIÓN ---
  Future<void> _iniciarSesion() async {
    // 1. Validar campos vacíos
    if (_correoController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor llena todos los campos')));
      return;
    }

    setState(() => _cargando = true);

    try {
      // iniciar sesión (CON EL ESCUDO DE 10 SEGUNDOS)
      UserCredential credencial = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _correoController.text.trim(),
        password: _passwordController.text.trim(),
      )
          .timeout(const Duration(seconds: 10));

      // buscar el Nombre y el Rol a la Base de Datos
      DocumentSnapshot docUsuario = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(credencial.user!.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (docUsuario.exists) {
        final datos = docUsuario.data() as Map<String, dynamic>;

        Map<String, dynamic> usuarioParaNavegacion = {
          'user': datos['correo'],
          'name': datos['nombre'],
          'rol': datos['rol'],
          'clase_id': datos['clase_id'] ?? '',
          'username': datos['username'] ?? datos['correo'].toString().split('@').first,
          'foto_base64': datos['foto_base64'] ?? '',
        };

        // 4. ROL DOCENTE
        if (datos['rol'] == 'docente') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PantallaDocente(usuarioLogueado: usuarioParaNavegacion),
            ),
          );
        } else {
          // Si es 'alumno'
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PantallaNavegacion(usuarioLogueado: usuarioParaNavegacion),
            ),
          );
        }

      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: No se encontraron los datos del perfil.'), backgroundColor: Colors.red));
      }

    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al iniciar sesión';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
        mensaje = 'Correo o contraseña incorrectos.';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El formato del correo no es válido.';
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión. Revisa tu internet e intenta de nuevo.'), backgroundColor: Colors.orange));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- CABECERA VISUAL ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.eco, size: 80, color: Colors.green.shade700),
                ),
                const SizedBox(height: 20),
                const Text('Bienvenido a', style: TextStyle(fontSize: 18, color: Colors.grey)),
                const Text(
                  'Reto Verde',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 40),

                // --- FORMULARIO LOGIN ---
                Card(
                  elevation: 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _correoController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                              labelText: 'Correo Electrónico',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              // Botón del ojito
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                          ),
                        ),

                        // --- BOTÓN DE RECUPERAR CONTRASEÑA ---
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _recuperarContrasena,
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // --- BOTÓN INICIAR SESIÓN ---
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _cargando ? null : _iniciarSesion,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                            child: _cargando
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Iniciar Sesión', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- BOTÓN REGISTRO ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿No tienes cuenta?', style: TextStyle(color: Colors.grey.shade700)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaRegistro()));
                      },
                      child: Text('Regístrate aquí', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}