# ZEN Reborn Prototype

Ce dépôt contient un prototype jouable pour Roblox Studio inspiré de l'arène minimaliste "ZEN". Il inclut :

- Une arène zen stylisée avec éclairage sobre et ambiance sonore.
- Un personnage joueur avec les contrôles : verrouillage (CTRL), course (SHIFT), attaque (LMB), bloc (RMB), choc (R), kick brise-bloc (F), provocation (T), emote (maintenir Q), boutique (B).
- Un système complet de combat (santé, dégâts, réduction pendant le blocage, choc de zone, kick anti-blocage).
- Une interface HUD affichant les contrôles, un message de bienvenue et une boutique de skins/armes/émotes.
- Un écran titre/lobby avec message de soutien et lien communautaire à personnaliser.

## Structure

```
ZENReborn.rbxlx        # Place Roblox (format texte) avec la scène, les scripts et l'UI
src/
  Client/              # Scripts locaux (inputs, boutique)
  Server/              # Scripts serveur (combat)
  Shared/              # Constantes et utilitaires partagés
assets/                # Emplacement pour vos futurs assets (sons, meshes, etc.)
docs/ADDING_CONTENT.md # Documentation pour étendre le contenu
```

Les scripts dans `src/` sont fournis pour l'édition versionnée. Ils sont intégrés dans `ZENReborn.rbxlx`. Utilisez [Rojo](https://rojo.space) pour synchroniser automatiquement si souhaité.

## Utilisation

1. Ouvrez `ZENReborn.rbxlx` dans Roblox Studio (`File → Open from File`).
2. Associez vos propres `AnimationId` dans `ReplicatedStorage/CombatShared.Animations`.
3. Lancez un test en Local Server (2 joueurs) pour valider le verrouillage et les interactions.
4. Personnalisez le message de lobby et le lien communautaire dans `StarterGui/ZenHUD/TitleFrame`.

## Contrôles

| Touche | Action |
| ------ | ------ |
| CTRL   | Verrouillage de cible |
| SHIFT  | Courir |
| Clic gauche | Attaque légère |
| Clic droit maintenu | Blocage (réduction de dégâts) |
| R | Choc de zone |
| F | Kick brise-bloc |
| T | Provocation |
| Maintenir Q | Emote circulaire |
| B | Ouvrir/fermer la boutique |

## Tests

- Local Solo (`F5`) pour vérifier les animations et l'UI.
- Test multi-joueurs (`Test → Local Server`) pour contrôler la synchronisation réseau.

## Étendre le projet

Consultez [`docs/ADDING_CONTENT.md`](docs/ADDING_CONTENT.md) pour ajouter des skins, armes et emotes.

## Support

Si vous appréciez le jeu, pensez à le soutenir en laissant un pouce levé et en rejoignant la communauté Discord (placeholder dans l'écran titre).
