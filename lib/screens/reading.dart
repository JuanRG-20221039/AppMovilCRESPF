import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:device_info_plus/device_info_plus.dart';

class ReadingScreen extends StatefulWidget {
  final String pdfUrl;
  final String? title;

  const ReadingScreen({
    super.key,
    required this.pdfUrl,
    this.title,
  });

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  File? localFile;
  bool isDownloading = false;
  String? errorMessage;
  double downloadProgress = 0.0;
  bool isLoadingPdf = true;
  PdfViewerController pdfViewerController = PdfViewerController();

  @override
  void initState() {
    super.initState();
    _checkIfDownloaded();
  }

  Future<void> _checkIfDownloaded() async {
    setState(() {
      isLoadingPdf = true;
      errorMessage = null;
    });
    
    try {
      final fileName = _getFileName();
      
      // Verificar en almacenamiento interno
      final internalDir = await getApplicationDocumentsDirectory();
      final filePath = '${internalDir.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        if (mounted) {
          setState(() {
            localFile = file;
            isLoadingPdf = false;
          });
          debugPrint('Archivo encontrado en almacenamiento interno: $filePath');
          return;
        }
      }
      
      // También verificar en directorio de descargas (para Android)
      if (Platform.isAndroid) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final externalFilePath = '${externalDir.path}/$fileName';
          final externalFile = File(externalFilePath);
          
          if (await externalFile.exists()) {
            if (mounted) {
              setState(() {
                localFile = externalFile;
                isLoadingPdf = false;
              });
              debugPrint('Archivo encontrado en almacenamiento externo: $externalFilePath');
              return;
            }
          }
        }
      }
      
      setState(() {
        isLoadingPdf = false;
      });
    } catch (e) {
      debugPrint('Error al verificar archivo descargado: $e');
      setState(() {
        errorMessage = 'Error al verificar archivo: $e';
        isLoadingPdf = false;
      });
    }
  }
  
  String _getFileName() {
    // Extraer nombre de archivo de la URL
    final uri = Uri.parse(widget.pdfUrl);
    String fileName = path.basename(uri.path);
    
    // Si no tiene extensión .pdf, agregarla
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      fileName = '$fileName.pdf';
    }
    
    // Asegurar que el nombre sea válido para el sistema de archivos
    fileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    
    return fileName;
  }

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses;
    
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        // Android 13+ (API 33+) usa permisos granulares
        statuses = await [
          Permission.photos,
          Permission.notification,
        ].request();
        
        return statuses[Permission.photos]?.isGranted == true;
      } else {
        // Android 12 o inferior
        statuses = await [
          Permission.storage,
        ].request();
        
        return statuses[Permission.storage]?.isGranted == true;
      }
    }
    
    // Para iOS y otros, siempre retornar true ya que no necesitan estos permisos específicos
    return true;
  }
  
  Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 33; // Android 13 es API 33
    }
    return false;
  }

  Future<void> _downloadPdf() async {
    setState(() {
      isDownloading = true;
      downloadProgress = 0;
      errorMessage = null;
    });

    try {
      // Solicitar permisos según la versión de Android
      bool permissionGranted = await _requestPermissions();
      
      if (!permissionGranted) {
        setState(() {
          errorMessage = 'Permisos denegados. No se puede descargar el PDF.';
          isDownloading = false;
        });
        
        _showPermissionDeniedDialog();
        return;
      }

      // Obtener directorio para guardar
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _getFileName();
      final filePath = '${directory.path}/$fileName';
      
      // Crear directorio si no existe
      final fileDir = Directory(path.dirname(filePath));
      if (!await fileDir.exists()) {
        await fileDir.create(recursive: true);
      }
      
      // Descargar archivo
      final dio = Dio();
      await dio.download(
        widget.pdfUrl, 
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              downloadProgress = received / total;
            });
          }
        }
      );

      final file = File(filePath);
      if (await file.exists()) {
        if (mounted) {
          setState(() {
            localFile = file;
            isDownloading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF "$fileName" guardado en:\n${file.path}'),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error: $e';
          isDownloading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar: $e')),
        );
      }
    }
  }
  
  void _showPermissionDeniedDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos requeridos'),
        content: const Text(
          'Esta aplicación necesita permisos de almacenamiento para guardar PDFs. '
          'Por favor, ve a la configuración de la aplicación y habilita los permisos de almacenamiento.'
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Abrir Configuración'),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    if (isLoadingPdf) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error al cargar el PDF',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }
    
    try {
      // Si tenemos archivo local, usarlo
      if (localFile != null && localFile!.existsSync()) {
        debugPrint('Cargando PDF desde archivo local: ${localFile!.path}');
        return SfPdfViewer.file(
          localFile!,
          controller: pdfViewerController,
          canShowScrollHead: false,
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            debugPrint('Error al cargar PDF local: ${details.error}');
            setState(() {
              errorMessage = 'Error al cargar PDF local: ${details.description}';
            });
          },
        );
      } else {
        // Si no hay archivo local, cargar desde la red
        debugPrint('Cargando PDF desde URL: ${widget.pdfUrl}');
        return SfPdfViewer.network(
          widget.pdfUrl,
          controller: pdfViewerController,
          canShowScrollHead: false,
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            debugPrint('Error al cargar PDF de red: ${details.error}');
            setState(() {
              errorMessage = 'Error al cargar PDF de red: ${details.description}';
            });
          },
        );
      }
    } catch (e) {
      debugPrint('Excepción al cargar PDF: $e');
      return Center(
        child: Text('Error al cargar el PDF: $e'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // AppBar personalizado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
              color: Colors.green,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.green),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      iconSize: 24,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Text(
                      widget.title ?? 'Lectura',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Botón de descarga
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: isDownloading
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: downloadProgress > 0 ? downloadProgress : null,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                                strokeWidth: 2.0,
                              ),
                              if (downloadProgress > 0)
                                Text(
                                  '${(downloadProgress * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          )
                        : IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 24,
                            icon: Icon(
                              localFile != null ? Icons.check_circle : Icons.download,
                              color: localFile != null ? Colors.green : Colors.orange,
                            ),
                            onPressed: localFile != null ? null : _downloadPdf,
                          ),
                  ),
                ],
              ),
            ),
            
            // Mensaje de error si existe
            if (errorMessage != null && !isLoadingPdf)
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.red.shade100,
                width: double.infinity,
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            
            // PDF Viewer
            Expanded(
              child: _buildPdfViewer(),
            ),
          ],
        ),
      ),
    );
  }
}
