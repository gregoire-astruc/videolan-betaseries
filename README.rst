=============================
BetaSeries extension for VLC.
=============================

About.
======

BetaSeries_ enables TV series fans to keep track with their favorite
shows.
This extension for VLC allows the player to interact with BetaSeries.

Usage.
======
* Play a video in VLC. It must follow the serie naming *convention*
  such as ``Show Title S01E04 - title.avi`` or ``Show Title - 1x04 - title.avi``
* Click on ``View > Betaseries``.

  * If this is the first time, the extension will prompt for your betaseries username and password.
  * Otherwise your automatically logged in the api.

* Now the extension automagically adds a playlist item right after your video
  which will mark your episode as *watched* once your episode is done.

Installation.
=============

Follow the instruction below according to your operating system.

Then, run VLC. If the extension is installed properly, it should appear in the 'View' menu.

Linux
-----

Download and run the `Linux Install Script`_ available on the project main page.

Windows
-------

Download and run the `Windows Installer`_ available on the project main page.

Others
------

* Download the extension from the `Download link`_ on the project main page.
* Extract the archive directory content (the one from which you can see modules, meta and extensions
  directories) inside vlc lua directory. Depending on your configuration,
  it can be in any directory mentioned in the `VLC lua README`_ §2.
* **Warning**: If your *not* using the system-wide directory, you *must* do the following:

  * Create the folder ``lua/meta/modules``
  * Copy the file ``lua/modules/betaseries.lua`` in ``lua/meta/modules``
    (it has to exist in both places).
  * In ``lua/meta/fetcher/betaseries.lua``,
    replace the line ``require "modules.betaseries"`` by ``require "betaseries"``

.. _BetaSeries: http://www.betaseries.com/
.. _`Download link`: https://github.com/gregoire-astruc/videolan-betaseries/downloads
.. _`Linux Install Script`: https://github.com/downloads/gregoire-astruc/videolan-betaseries/install-videolan-betaseries.sh
.. _`Windows Installer`: https://github.com/downloads/gregoire-astruc/videolan-betaseries/videolan-betaseries-installer.exe
.. _`VLC lua README`: https://github.com/videolan/vlc/blob/master/share/lua/README.txt
