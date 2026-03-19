# Guía de Firma de Aplicación para Play Store

Para publicar **SoundUpar** en la Google Play Store, debes firmar digitalmente la aplicación con una clave privada. Sigue estos pasos:

## 1. Generar la Clave de Firma (Keystore)

Ejecuta el siguiente comando en tu terminal (asegúrate de tener `keytool` instalado, que viene con el JDK):

```bash
keytool -genkey -v -keystore soundupar-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias soundupar
```

> [!IMPORTANT]
> Guarda este archivo (.jks) y las contraseñas en un lugar seguro. Si pierdes la clave, no podrás actualizar tu aplicación en la Play Store.

## 2. Crear el archivo `key.properties`

Crea un archivo llamado `key.properties` dentro de la carpeta `android/` con el siguiente contenido:

```properties
storePassword=<tu-password-de-almacen>
keyPassword=<tu-password-de-llave>
keyAlias=soundupar
storeFile=<ruta-hacia-el-archivo>/soundupar-keystore.jks
```

## 3. Configurar Gradle

Modifica el archivo `android/app/build.gradle.kts` para cargar estas propiedades y usarlas en la compilación de lanzamiento.

### Ejemplo de configuración en `build.gradle.kts`:

```kotlin
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

## 4. Compilar

Una vez configurado, usa el script `build_apk.bat` para generar el APK y el AAB firmados oficialmente.
