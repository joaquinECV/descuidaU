import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/fs_service.dart';
import '../theme/app_theme.dart';

class PublicarPage extends StatefulWidget {
  const PublicarPage({super.key});

  @override
  State<PublicarPage> createState() => _PublicarPageState();
}

class _PublicarPageState extends State<PublicarPage> {
  final _formKey = GlobalKey<FormState>();

  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _lugarCtrl = TextEditingController();
  final _fechaHoraCtrl = TextEditingController();
  String? _tipoSeleccionado;
  String? _categoriaSeleccionada;
  DateTime _fechaSeleccionada = DateTime.now();
  Uint8List? _fotoBytes;
  String? _errorFoto;
  bool _guardando = false;

  static const int _maxBytesPermitidos = 950 * 1024;

  final ImagePicker _picker = ImagePicker();
  late final Future<QuerySnapshot> _categoriasFuture;

  @override
  void initState() {
    super.initState();
    _categoriasFuture = FsService().getCategorias();
    _fechaHoraCtrl.text =
        DateFormat('dd/MM/yyyy HH:mm').format(_fechaSeleccionada);
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _lugarCtrl.dispose();
    _fechaHoraCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFechaYHora() async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2026),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (fecha == null || !mounted) return;

    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fechaSeleccionada),
    );
    if (hora == null || !mounted) return;

    final combinada = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );

    setState(() {
      _fechaSeleccionada = combinada;
      _fechaHoraCtrl.text = DateFormat('dd/MM/yyyy HH:mm').format(combinada);
    });
  }

  Future<void> _obtenerImagen(ImageSource origen) async {
    try {
      final XFile? archivo = await _picker.pickImage(
        source: origen,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );

      if (archivo == null) return;

      Uint8List bytes = await archivo.readAsBytes();

      if (bytes.lengthInBytes > _maxBytesPermitidos) {
        final XFile? recomprimida = await _picker.pickImage(
          source: origen,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 55,
        );
        if (recomprimida != null) {
          bytes = await recomprimida.readAsBytes();
        }
      }

      if (!mounted) return;

      if (bytes.lengthInBytes > _maxBytesPermitidos) {
        setState(() {
          _fotoBytes = null;
          _errorFoto =
              'La imagen sigue pesando más de 1 MB (${(bytes.lengthInBytes / 1024).toStringAsFixed(0)} KB). Elige otra foto más liviana.';
        });
        return;
      }

      setState(() {
        _fotoBytes = bytes;
        _errorFoto = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorFoto = 'No se pudo cargar la imagen. Intenta nuevamente.';
      });
    }
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppTheme.primaryGreen,
                ),
                title: const Text('Tomar foto con la cámara'),
                onTap: () {
                  Navigator.pop(context);
                  _obtenerImagen(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppTheme.primaryGreen,
                ),
                title: const Text('Seleccionar desde la galería'),
                onTap: () {
                  Navigator.pop(context);
                  _obtenerImagen(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardarPublicacion() async {
    final bool formularioValido = _formKey.currentState!.validate();

    if (_fotoBytes == null) {
      setState(() {
        _errorFoto = 'La foto del objeto es obligatoria.';
      });
    }

    if (!formularioValido || _fotoBytes == null) {
      return;
    }

    if (_fotoBytes!.lengthInBytes > _maxBytesPermitidos) {
      setState(() {
        _errorFoto =
            'El tamaño de la foto excede el límite permitido de 1 MB.';
      });
      return;
    }

    final usuario = AuthService().currentUser;
    if (usuario == null) return;

    setState(() {
      _guardando = true;
    });

    try {
      await FsService().crearPublicacion(
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        tipo: _tipoSeleccionado!,
        categoria: _categoriaSeleccionada!,
        lugar: _lugarCtrl.text.trim(),
        fechaHora: _fechaHoraCtrl.text.trim(),
        fotoBytes: _fotoBytes!,
        autorNombre: usuario.displayName ?? usuario.email ?? 'Usuario Campus',
        autorUid: usuario.uid,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la publicación. Intenta nuevamente.'),
          backgroundColor: AppTheme.perdidoColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nueva Publicación'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _guardando ? null : _mostrarOpcionesFoto,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _errorFoto != null
                        ? Colors.redAccent
                        : AppTheme.mediumGreen.withValues(alpha: 0.4),
                    width: _errorFoto != null ? 1.8 : 1.2,
                  ),
                ),
                child: _fotoBytes != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.memory(
                              _fotoBytes!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Cambiar foto (${(_fotoBytes!.lengthInBytes / 1024).toStringAsFixed(0)} KB)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_rounded,
                            size: 44,
                            color: AppTheme.mediumGreen,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Agregar foto del objeto *',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Toca para usar cámara o galería (máx. 1 MB)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (_errorFoto != null) ...[
              SizedBox(height: 6),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _errorFoto!,
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _tipoSeleccionado,
              decoration: InputDecoration(
                labelText: 'Tipo de publicación *',
              ),
              items: [
                DropdownMenuItem(
                  value: 'Perdido',
                  child: Text('Perdido (lo estoy buscando)'),
                ),
                DropdownMenuItem(
                  value: 'Encontrado',
                  child: Text('Encontrado (busco a su dueño)'),
                ),
              ],
              validator: (valor) {
                if (valor == null || valor.isEmpty) {
                  return 'Seleccione si el objeto fue perdido o encontrado';
                }
                return null;
              },
              onChanged: (valor) {
                setState(() {
                  _tipoSeleccionado = valor;
                });
              },
            ),
            SizedBox(height: 14),
            TextFormField(
              controller: _tituloCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Título del objeto *',
                hintText: 'Ej: Audífonos negros',
              ),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'El título es requerido';
                }
                if (valor.trim().length < 3) {
                  return 'Ingresa al menos 3 caracteres';
                }
                return null;
              },
            ),
            SizedBox(height: 14),
            FutureBuilder<QuerySnapshot>(
              future: _categoriasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Categoría *',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    child: Text('Cargando categorías...'),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return Text(
                    'Error al cargar las categorías.',
                    style: TextStyle(color: Colors.redAccent),
                  );
                }

                final docs = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  initialValue: _categoriaSeleccionada,
                  decoration: InputDecoration(
                    labelText: 'Categoría *',
                  ),
                  items: docs.map((doc) {
                    final nombreCat = doc['nombre'].toString();
                    return DropdownMenuItem<String>(
                      value: nombreCat,
                      child: Text(nombreCat),
                    );
                  }).toList(),
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'Seleccione una categoría';
                    }
                    return null;
                  },
                  onChanged: (valor) {
                    setState(() {
                      _categoriaSeleccionada = valor;
                    });
                  },
                );
              },
            ),
            SizedBox(height: 14),
            TextFormField(
              controller: _lugarCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Lugar del campus *',
                hintText: 'Ej: Laboratorio U100, Biblioteca, Casino',
              ),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'El lugar del campus es requerido';
                }
                return null;
              },
            ),
            SizedBox(height: 14),
            TextFormField(
              controller: _fechaHoraCtrl,
              readOnly: true,
              onTap: _seleccionarFechaYHora,
              decoration: InputDecoration(
                labelText: 'Fecha y hora (DD/MM/AAAA hh:mm) *',
                suffixIcon: Icon(Icons.edit_calendar_outlined),
              ),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'La fecha y hora son requeridas';
                }
                return null;
              },
            ),
            SizedBox(height: 14),
            TextFormField(
              controller: _descripcionCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Descripción detallada *',
                hintText: 'Color, marca, señas particulares o cómo contactarte',
                alignLabelWithHint: true,
                
              ),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'La descripción es requerida';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _guardando ? null : _guardarPublicacion,
                icon: _guardando
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.publish_rounded),
                label: Text(
                  _guardando ? 'Publicando...' : 'Publicar Objeto',
                ),
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}