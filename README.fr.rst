=============================
Extension BetaSeries pour VLC
=============================

About.
======

BetaSeries_ permet aux fans de séries TV de suivre leurs émissions favorites.
Cette extension pour VLC permet au lecteur d'interagir avec le site.

Utilisation.
======
* Lancez un épisode dans VLC. Le nom du fichier doit suivre une certaine *convention* comme
  ``Show Title S01E04 - title.avi`` ou ``Show Title - 1x04 - title.avi``.
* Cliquez sur ``Vue > Betaseries``.

  * La première fois, l'extension va vous demander votre login et votre mot de passe betaseries.
  * Autrement vous êtes automatiquement loggé grâce à l'API.

* L'extension ajoute alors automagiquement un item juste après votre épisode qui le marquera comme
  *vu* sur BetaSeries_ une fois terminé.

Installation.
=============

Suivez les instructions ci-dessous en fonction de votre système d'exploitation.

Ensuite, lancez VLC. Si l'extension s'est installée correctement, elle devrait apparaître dans le
menu 'Vue' du lecteur.

Linux
-----

Téléchargez et lancez le `Linux Install Script`_ disponible sur la page d'accueil du projet.

Windows
-------

Téléchargez et exécutez le `Windows Installer`_ disponible sur la page d'accueil du projet.

Autres
------

* Télécharger l'extension depuis le `Download link`_ sur la page d'accueil du projet.
* Désarchivez le répertoire de l'archive (celui dans lequel vous voyez modules, meta et extensions)
  dans le répertoire lua de VLC. Selon votre configuration, cela peut être n'importe quel répertoire
  mentionné dans le `VLC lua README`_ §2.
* **Attention** : Si vous utilisez le répertoire utilisateur, vous *devez*
  effectuer les actions suivantes :

  * Créez le dossier``lua/meta/modules``
  * Copiez le fichier ``lua/modules/betaseries.lua`` dans ``lua/meta/modules``
    (il doit être présent aux deux endroits)
  * Dans ``lua/meta/fetcher/betaseries.lua``,
    remplacez la ligne ``require "modules.betaseries"`` par ``require "betaseries"``

.. _BetaSeries: http://www.betaseries.com/
.. _`Download link`: https://github.com/gregoire-astruc/videolan-betaseries/downloads
.. _`Linux Install Script`: https://github.com/downloads/gregoire-astruc/videolan-betaseries/install-videolan-betaseries.sh
.. _`Windows Installer`: https://github.com/downloads/gregoire-astruc/videolan-betaseries/videolan-betaseries-installer.exe
.. _`VLC lua README`: http://git.videolan.org/?p=vlc.git;a=blob_plain;f=share/lua/README.txt