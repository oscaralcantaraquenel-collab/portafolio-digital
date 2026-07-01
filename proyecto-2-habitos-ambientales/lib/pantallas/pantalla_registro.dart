import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'pantalla_login.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  // CONTROLAR ROLES
  String _rolSeleccionado = 'alumno';
  bool _cargando = false;

  Future<void> _registrarUsuario() async {
    // Validaciones básicas
    if (_nombreController.text.isEmpty || _correoController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor llena todos los campos')));
      return;
    }

    setState(() => _cargando = true);

    try {
      // 1. Crear el usuario en Firebase Authentication
      UserCredential credencial = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _correoController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Guardar los datos extras (Nombre, Rol, Clase) en Firestore Database
      await FirebaseFirestore.instance.collection('usuarios').doc(credencial.user!.uid).set({
        'nombre': _nombreController.text.trim(),
        'correo': _correoController.text.trim(),
        'rol': _rolSeleccionado,
        'clase_id': '',
        'fecha_creacion': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Cuenta creada con éxito!'), backgroundColor: Colors.green));

      // regresaR al login
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      // Manejo de errores
      String mensajeError = 'Ocurrió un error al registrarse.';
      if (e.code == 'weak-password') mensajeError = 'La contraseña es muy débil (mínimo 6 caracteres).';
      else if (e.code == 'email-already-in-use') mensajeError = 'Ese correo ya está registrado.';

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensajeError), backgroundColor: Colors.red));
    } catch (e) {
      // ---CAZADOR DE ERRORES GENERALES Y DE FIRESTORE ---
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error de conexión/base de datos: $e'),
                backgroundColor: Colors.orange.shade800,
                duration: const Duration(seconds: 6)
            )
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Crear Cuenta'), backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.eco, size: 80, color: Colors.green.shade700),
              const SizedBox(height: 20),
              const Text('Únete a Reto Verde', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              TextField(
                controller: _nombreController,
                decoration: InputDecoration(labelText: 'Nombre Completo', prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'Correo Electrónico', prefixIcon: const Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Contraseña (mín. 6 caracteres)', prefixIcon: const Icon(Icons.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 20),

              // Selector de Rol
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _rolSeleccionado,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.green),
                    items: const [
                      DropdownMenuItem(value: 'alumno', child: Text('Soy Alumno (Unirme a una clase)')),
                      DropdownMenuItem(value: 'docente', child: Text('Soy Docente (Crear clases)')),
                    ],
                    onChanged: (String? nuevoValor) {
                      setState(() {
                        _rolSeleccionado = nuevoValor!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _registrarUsuario,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Registrarme', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}