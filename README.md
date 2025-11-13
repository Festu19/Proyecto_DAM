# CasaZenn - App de Gestión de Tareas del Hogar

A new Flutter project.

## Getting Started

 
Este es el repositorio del proyecto "CasaZenn", una aplicación móvil multiplataforma desarrollada con Flutter para la gestión colaborativa de tareas en el hogar.
Guía de Configuración del Entorno de Desarrollo
Sigue estos pasos para configurar el proyecto en un nuevo entorno de desarrollo desde cero.

1. Requisitos Previos


    Flutter SDK: Sigue la guía de instalación oficial de Flutter. https://docs.flutter.dev/get-started/quick
    Importante: Asegúrate de añadir la carpeta flutter\bin a la variable de entorno PATH de tu sistema.
    Node.js: Necesario para instalar las herramientas de Firebase. Descarga la versión LTS desde la página oficial de Node.js. https://nodejs.org/en/download
    Visual Studio Code: El editor de código recomendado, con la extensión oficial de Flutter instalada.
    Git: Para clonar el repositorio.


2. Configuración de Firebase
    Este proyecto utiliza Firebase como backend. Necesitarás crear tu propio proyecto de Firebase para poder ejecutar la aplicación.
    Paso 3.1: Crear el Proyecto en Firebase
    Ve a la consola de Firebase.
    Inicia sesión con tu cuenta de Google y haz clic en "Crear un proyecto".
    Dale un nombre al proyecto (ej. "CasaZenn-dev") y sigue los pasos del asistente.
    Paso 3.2: Instalar Herramientas CLI
    Necesitamos dos herramientas de línea de comandos para conectar la app con Firebase. Abre una terminal en la raíz del proyecto y ejecuta los siguientes comandos:
    Instalar Firebase Tools (vía npm):

    ## npm install -g firebase-tools

    Instalar FlutterFire CLI (vía pub):

    ## dart pub global activate flutterfire_cli

     Si la terminal no reconoce los comandos, asegúrate de que las rutas a las carpetas bin de npm y pub cache están en tu variable de entorno PATH y reinicia la terminal.
   

    Inicia sesión en Firebase:

     # firebase login


    Configura el proyecto Flutter:

    # flutterfire configure
  
3. Instalar Dependencias del Proyecto
    Una vez configurado Firebase, instala todos los paquetes de Dart/Flutter necesarios para el proyecto:

   # flutter pub get
4. Ejecutar la Aplicación

    flutter run
    También puedes usar la opción Run and Debug (F5) de Visual Studio Code.



## Para un rendimiento óptimo en Windows, se recomienda activar el "Modo de programador".