# 🏗️ Forma3D - Arquitectura Técnica

## 📱 Descripción

**Forma3D** es una aplicación de escaneo y reconocimiento 3D construida con las últimas tecnologías de Apple para iOS 18+.

### Características Principales:
- 📸 **Escaneo 3D**: Fotogrametría con Object Capture API y LiDAR
- 📚 **Biblioteca**: Gestión de modelos 3D con persistencia local
- 🎯 **Identificación AR**: Reconocimiento de objetos en tiempo real con Vision Framework
- 🗺️ **Guías Interactivas**: Sistema de anotaciones AR con hotspots y flechas direccionales

---

## 🏛️ Arquitectura

### Patrón: **MVVM Pragmático + SwiftUI**

Implementamos una variante pragmática del patrón MVVM optimizada para desarrollo rápido sin sacrificar mantenibilidad:

```
┌─────────────────────────────────────────────────┐
│                    VIEW                         │
│  (SwiftUI - UI Declarativa)                     │
│  - MainMenuView, ScanView, LibraryView...       │
└────────────────┬────────────────────────────────┘
                 │ Binding / Observable
                 ▼
┌─────────────────────────────────────────────────┐
│                 VIEW MODEL                      │
│  (@Observable - Lógica de Presentación)         │
│  - ScanViewModel, IdentifyViewModel...          │
└────────────────┬────────────────────────────────┘
                 │ Coordina
                 ▼
┌─────────────────────────────────────────────────┐
│           MODEL + SERVICES                      │
│  - ScannedObject, Annotation (SwiftData)        │
│  - ObjectRecognitionService (Vision)            │
│  - StorageService (FileManager)                 │
└─────────────────────────────────────────────────┘
```

---

## 📁 Estructura del Proyecto

```
Forma3D/
│
├── 📱 App/
│   └── ScannerApp.swift              # Entry point con ModelContainer
│
├── 🎨 Views/                         # Capa de presentación (UI pura)
│   ├── Main/
│   │   └── MainMenuView.swift        # Menú principal
│   ├── Scan/
│   │   └── ScanView.swift            # Interfaz de escaneo 3D
│   ├── Library/
│   │   ├── LibraryView.swift         # Lista de objetos escaneados
│   │   └── ObjectDetailView.swift    # Visor 3D interactivo
│   ├── Identify/
│   │   └── IdentifyView.swift        # AR de reconocimiento
│   └── Guides/
│       ├── GuideEditorView.swift     # Editor de anotaciones AR
│       ├── GuideViewerView.swift     # Visor de guías
│       └── GuideLibraryView.swift    # Biblioteca de guías
│
├── 🧠 ViewModels/                    # Lógica de presentación
│   ├── ScanViewModel.swift           # Estado y lógica del escaneo
│   ├── IdentifyViewModel.swift       # (Futuro) Estado de identificación
│   └── GuideEditorViewModel.swift    # (Futuro) Estado del editor
│
├── 📦 Models/                        # Modelos de datos
│   ├── ScannedObject.swift           # Modelo SwiftData principal
│   └── Annotation.swift              # Modelo de anotaciones AR
│
├── 🔧 Services/                      # Lógica de negocio
│   └── ObjectRecognitionService.swift # Servicio de Vision Framework
│
├── 🧩 Components/                    # Componentes reutilizables
│   └── CustomButton.swift            # Botón con gradientes animados
│
└── 📄 Documentation/
    ├── ESTRUCTURA_MVVM_ANALISIS.md   # Análisis técnico completo
    └── ARQUITECTURA_README.md        # Este archivo
```

---

## 🛠️ Stack Tecnológico

### Frameworks de Apple:
- **SwiftUI**: UI declarativa con Swift 6
- **RealityKit**: Renderizado 3D y AR
- **ARKit**: Detección de objetos y tracking
- **SwiftData**: Persistencia moderna con macros
- **Vision**: Feature extraction y reconocimiento de imágenes
- **QuickLook**: Generación de thumbnails de modelos USDZ

### Arquitectura de Concurrencia:
- **Swift Concurrency** (async/await, actors)
- **@Observable Macro** para reactividad
- **@MainActor** para operaciones de UI

### Requisitos:
- iOS 18.0+
- iPhone/iPad con chip A12 Bionic o superior
- Sensor LiDAR (para escaneo, opcional para identificación)
- Swift 6.0+
- Xcode 16.0+

---

## 🔄 Flujo de Datos

### 1️⃣ Escaneo 3D (SCAN):
```
Usuario → ScanView → ScanViewModel → ObjectCaptureSession (RealityKit)
                          ↓
                  PhotogrammetrySession
                          ↓
                   Genera USDZ + ARObject
                          ↓
                  Guarda en SwiftData (ScannedObject)
```

### 2️⃣ Identificación AR (IDENTIFY):
```
Cámara AR → PixelBuffer → ObjectRecognitionService
                              ↓
                      Vision FeaturePrint
                              ↓
                  Comparación con biblioteca (SwiftData)
                              ↓
                    Retorna mejor match → Vista AR
```

### 3️⃣ Anotaciones (GUIDES):
```
ObjectDetailView → GuideEditorView → Crear Annotation
                                          ↓
                              SwiftData (Relationship)
                                          ↓
                          Visualizar en GuideViewerView
```

---

## 🎯 Decisiones de Arquitectura

### ¿Por qué MVVM Pragmático?

**Ventajas en este proyecto:**
- ✅ **Separación clara** entre UI (Views) y lógica (ViewModels)
- ✅ **Testeable**: ViewModels sin dependencias de UIKit/SwiftUI
- ✅ **Reactividad nativa** con `@Observable` (sin Combine)
- ✅ **Compatible con SwiftData** y `@Environment`

**Adaptaciones pragmáticas:**
- ⚡ Algunos estados simples (`@State`) directamente en vistas para rapidez
- ⚡ SwiftData accedido directamente con `@Query` en vistas de lectura
- ⚡ Servicios como singletons (`shared`) para simplificar inyección

### ¿Por qué SwiftData en lugar de Core Data?

- ✅ API declarativa con macros Swift
- ✅ Sin necesidad de .xcdatamodeld
- ✅ Type-safe por diseño
- ✅ Relaciones automáticas con `@Relationship`
- ✅ Menor boilerplate

### ¿Por qué Vision en lugar de ARReferenceObject?

- ✅ Funciona sin LiDAR (más dispositivos compatibles)
- ✅ Reconocimiento más flexible (diferentes ángulos/iluminación)
- ✅ Feature prints más robustos que anchors geométricos
- ⚠️ Menor precisión que ARReferenceObject nativo

---

## 🧪 Testing (Futuro)

### Estrategia de Pruebas:

```swift
// ViewModels Tests (Lógica pura)
@Test("ScanViewModel - Finalizar escaneo guarda objeto")
func scanCompletionSavesObject() async {
    let vm = ScanViewModel()
    let context = ModelContext(...)
    
    await vm.finishScanAndProcess(name: "Test", modelContext: context)
    
    #expect(vm.scanCompleted == true)
}

// Services Tests
@Test("ObjectRecognitionService - Identifica objeto conocido")
func recognizesKnownObject() async {
    let service = ObjectRecognitionService.shared
    let object = ScannedObject(...)
    
    let result = await service.identifyObject(from: pixelBuffer, candidates: [object])
    
    #expect(result != nil)
}

// Models Tests
@Test("Annotation - Relación bidireccional con ScannedObject")
func annotationRelationship() {
    let object = ScannedObject(...)
    let annotation = Annotation(scannedObject: object, ...)
    
    #expect(object.annotations.contains(annotation))
}
```

---

## 🚀 Mejoras Futuras

### Corto Plazo:
- [ ] Crear `IdentifyViewModel` para encapsular lógica AR
- [ ] Implementar caché de thumbnails con `NSCache`
- [ ] Añadir feedback háptico en acciones críticas
- [ ] Soporte de modo oscuro/claro dinámico

### Medio Plazo:
- [ ] Sincronización iCloud con CloudKit
- [ ] Exportar/importar biblioteca completa
- [ ] Compartir objetos con AirDrop
- [ ] Widget de Quick Look en pantalla de inicio

### Largo Plazo:
- [ ] App companion para macOS con editor avanzado
- [ ] Generación automática de guías con Vision + LLM
- [ ] Multiplayer colaborativo (edición simultánea)
- [ ] Soporte para visionOS con volumenes espaciales

---

## 📊 Métricas de Rendimiento

### Objetivos:
- ⚡ Escaneo completo: < 3 minutos
- ⚡ Reconstrucción fotogramétrica: < 2 minutos
- ⚡ Identificación AR: < 500ms por frame
- ⚡ Carga de modelo 3D: < 1 segundo

### Optimizaciones Implementadas:
- ✅ Generación asíncrona de thumbnails
- ✅ Lazy loading de modelos en lista
- ✅ Downsampling automático de photogrammetry
- ✅ Actor isolation para operaciones pesadas

---

## 👥 Contribuciones

### Convenciones de Código:

```swift
// MARK: - Properties
var publicProperty: Type

private var _privateProperty: Type

// MARK: - Initialization
init(dependency: Dependency) {
    self.dependency = dependency
}

// MARK: - Public Methods
func publicMethod() { }

// MARK: - Private Methods
private func privateMethod() { }
```

### Git Workflow:
```bash
main           # Producción (releases)
  ├── develop  # Desarrollo activo
      ├── feature/scan-improvements
      ├── feature/guide-animations
      └── bugfix/memory-leak-fix
```

---

## 🐛 Troubleshooting

### Error: "Object Capture no está soportado"
**Causa**: Dispositivo sin LiDAR  
**Solución**: Verificar `ObjectCaptureSession.isSupported` antes de iniciar

### Error: "No se pudo cargar el modelo USDZ"
**Causa**: Archivo corrupto o no existe  
**Solución**: Validar `FileManager.fileExists(atPath:)` antes de cargar

### Warning: "Llamada a @MainActor desde contexto no-main"
**Causa**: Operación de UI en background thread  
**Solución**: Envolver con `await MainActor.run { }`

---

## 📞 Contacto

**Desarrollador**: Victor Munera  
**Fecha**: Septiembre 2026  
**Evento**: Hackathon Sprint - App 3D Scanner

---

## 📄 Licencia

Este proyecto es parte de un hackathon educativo.  
Código disponible bajo licencia MIT.

---

**Última actualización**: Septiembre 27, 2026

