# Ajouter du contenu dans ZEN Reborn

Ce guide explique comment compléter le prototype fourni (shop, armes, emotes, skins) directement dans Roblox Studio.

## Prérequis

- Roblox Studio installé
- [Rojo](https://github.com/rojo-rbx/rojo) (optionnel mais recommandé) si vous souhaitez synchroniser les scripts depuis ce dépôt
- Animations exportées (format `.rbxm` ou `.fbx`) afin de publier vos propres `AnimationId`

## Importer le lieu

1. Ouvrez Roblox Studio et choisissez **Open From File**.
2. Sélectionnez `ZENReborn.rbxlx` (ou `ZENReborn.rbxl` si vous l'avez reconstruit via Rojo).
3. Publiez le jeu pour créer un emplacement si nécessaire.

## Structure des dossiers

- `ReplicatedStorage/CombatShared` : contient la configuration des dégâts, distances et IDs d'animations.
- `ReplicatedStorage/Remotes` : ensemble des événements `RemoteEvent` et `RemoteFunction` utilisés par le système de combat.
- `StarterPlayer/StarterPlayerScripts` : scripts locaux `ZenController` et `ShopController`.
- `ServerScriptService/CombatService` : script serveur autoritaire.
- `StarterGui/ZenHUD` : HUD avec commandes et boutique.
- `Workspace/Environment` : pièces de décor, dojo, éclairage.

## Ajouter un skin ou une arme

1. Créez un `Tool` dans `ReplicatedStorage/Assets/Weapons`.
2. Ajoutez un modèle 3D (mesh, handle, etc.). Assurez-vous qu'il possède un `Handle`.
3. Ajoutez un `StringValue` nommé `ItemId` pour correspondre au bouton de boutique.
4. Ajoutez votre logique spécifique (par exemple un script de particules) dans le `Tool`.
5. Dupliquez le bouton correspondant dans `StarterGui/ZenHUD/ShopFrame` ou créez-en un nouveau en indiquant le même `Name` que `ItemId`.
6. Dans `CombatService.server.lua`, complétez la fonction `onPurchaseRequest` afin de donner l'outil :

   ```lua
   local assets = ReplicatedStorage.Assets
   local weapons = assets:WaitForChild("Weapons")
   local template = weapons:FindFirstChild(itemId)
   if template then
       local clone = template:Clone()
       clone.Parent = player.Backpack
   end
   ```

## Ajouter une emote

1. Publiez votre animation personnalisée pour obtenir un `AnimationId`.
2. Dans `CombatShared.Animations`, remplacez l'ID de `Taunt` ou ajoutez un nouvel identifiant (`Emote2`, etc.).
3. Dans `ZenController.client.lua`, ajoutez un nouveau binding de touche qui :
   - Joue l'animation via `playAnimation("Emote2")`
   - Envoie un remote (si besoin) pour déclencher des effets serveur.
4. Ajoutez une entrée dans la boutique pour que les joueurs puissent l'acheter.

## Ajouter une nouvelle attaque spéciale

1. Définissez ses constantes dans `CombatShared.Config` (dégâts, portée, temps de recharge).
2. Créez un `RemoteEvent` dans `ReplicatedStorage/Remotes` (ex: `Lunge`).
3. **Client** : dans `ZenController.client.lua`, mappez une touche et appelez le remote.
4. **Serveur** : dans `CombatService.server.lua`, connectez le remote à une nouvelle fonction qui vérifie les prérequis et applique l'effet.
5. Ajoutez des effets visuels (`ParticleEmitter`, `Sound`) sur le personnage du joueur ou dans l'environnement.

## Mise à jour de l'UI de boutique

- Le script `ShopController.client.lua` associe automatiquement chaque `TextButton` enfant de `ShopFrame` à l'événement d'achat.
- Pour afficher le prix, modifiez la propriété `Text` du bouton.
- Utilisez un `UIListLayout` dans `ShopFrame` pour aligner automatiquement les nouveaux boutons.

## Astuces

- Personnalisez l'ambiance sonore en remplaçant les sons dans `SoundService/Zenscape` et `SoundService/ArenaLoop`.
- Ajustez les couleurs du dojo via les propriétés `Color` des `Part` (palette gris/blanc/rouge suggérée).
- Les effets de choc utilisent un `BodyVelocity`. Vous pouvez basculer vers `VectorForce` pour un contrôle plus précis.

## Tests

1. Lancer une session Play Solo (F5).
2. Ouvrir un serveur local avec au moins deux joueurs (Test → Local Server).
3. Vérifiez :
   - Attaques, blocage, choc et kick fonctionnent.
   - La provocation envoie un message.
   - La boutique s'affiche (touche `B`).
   - Le verrouillage cible bien l'adversaire le plus proche.

Bon développement !
