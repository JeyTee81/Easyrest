# EasyRest Tablette

Une application Flutter moderne pour la gestion de restaurant sur tablette, conçue pour offrir une expérience utilisateur intuitive et efficace.

## 🚀 Fonctionnalités

- **Interface tablette optimisée** - Conçue spécifiquement pour les écrans tactiles de tablette
- **Gestion des commandes** - Suivi en temps réel des commandes
- **Interface intuitive** - Navigation simple et ergonomique
- **Compatibilité Android** - Optimisée pour Android 14+ avec targetSdkVersion 34

## 🛠️ Technologies

- **Flutter** - Framework de développement cross-platform
- **Dart** - Langage de programmation
- **PostgreSQL** - Base de données locale
- **Android** - Plateforme cible principale
- **Google Play Services** - Intégration des services Google Play modernes

## 📱 Configuration requise

- **Android** : API 21+ (Android 5.0+)
- **Target SDK** : 34 (Android 14)
- **Compile SDK** : 34
- **Min SDK** : 21

## 🔧 Installation et configuration

### Prérequis

- Flutter SDK (dernière version stable)
- Android Studio
- JDK 17+
- Android SDK 34
- PostgreSQL 12+ (voir [POSTGRESQL_SETUP_GUIDE.md](POSTGRESQL_SETUP_GUIDE.md))

### Étapes d'installation

1. **Cloner le dépôt**
   ```bash
   git clone [URL_DU_REPO]
   cd easyrest_tablette
   ```

2. **Installer les dépendances**
   ```bash
   flutter pub get
   ```

3. **Configurer PostgreSQL**
   ```bash
   dart run scripts/setup_postgresql.dart
   ```
   Ou suivez le guide détaillé dans [POSTGRESQL_SETUP_GUIDE.md](POSTGRESQL_SETUP_GUIDE.md)

4. **Configurer la signature Android** (pour les builds de production)
   - Créer un fichier `key.properties` dans `android/`
   - Configurer les informations de keystore

5. **Lancer l'application**
   ```bash
   flutter run
   ```

## 🏗️ Build de production

### Build APK
```bash
flutter build apk --release
```

### Build App Bundle (recommandé pour Google Play)
```bash
flutter build appbundle --release
```

## 📁 Structure du projet

```
easyrest_tablette/
├── android/                 # Configuration Android
├── ios/                    # Configuration iOS (si applicable)
├── lib/                    # Code source Dart
├── assets/                 # Ressources (images, fonts, etc.)
├── test/                   # Tests unitaires et d'intégration
├── pubspec.yaml           # Dépendances et configuration Flutter
└── README.md              # Ce fichier
```

## 🔐 Configuration de sécurité

- **Keystore** : Configuration pour la signature des APKs
- **ProGuard** : Règles d'obfuscation et d'optimisation
- **Permissions** : Gestion des permissions Android

## 📊 Dépendances principales

- **Google Play Services** : Services Google Play modernes
- **Flutter plugins** : Plugins officiels et tiers
- **Dart packages** : Packages de la communauté Dart

## 🚨 Résolution des problèmes

### Erreurs de build courantes

1. **Conflits de classes Play Core**
   - Solution : Utilisation des bibliothèques Play Core modernes uniquement
   - Éviter les conflits avec les anciennes versions

2. **Problèmes de signature**
   - Vérifier la configuration du keystore
   - S'assurer que `key.properties` est correctement configuré

3. **Erreurs de dépendances**
   - Exécuter `flutter clean` puis `flutter pub get`
   - Vérifier la compatibilité des versions

## 🤝 Contribution

1. Fork le projet
2. Créer une branche pour votre fonctionnalité
3. Commiter vos changements
4. Pousser vers la branche
5. Ouvrir une Pull Request

## 📄 Licence

[Spécifier la licence du projet]

## 📞 Support

Pour toute question ou problème :
- Ouvrir une issue sur GitHub
- Contacter l'équipe de développement

---

**Développé avec ❤️ en Flutter**
