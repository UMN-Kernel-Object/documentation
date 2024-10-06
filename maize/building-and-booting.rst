============================================
Building and Booting a Linux kernel on Maize
============================================

    :Author: Nathan Ringo

Synopsis
========

This document is a tutorial about how to get the Linux kernel sources on Maize, how to build them, and how to access a VM using the just-built kernel.
It then proceeds to cover how to configure the kernel, and use this to build a kernel with a "Hello, World!" kernel module.

Tutorial
========

First, check that you can log into Maize and that your user has the right permissions on it.

.. code:: sh

    # Log in to Maize. Your command might be different if you created an alias
    # for it in ~/.ssh/config
    user@laptop:~$ ssh myx500@cs-u-maize.cs.umn.edu

    # Check what groups your user is in. You need to be in the kvm group to run
    # hardware-accelerated VMs. Without this, your VM will run _really_ slowly.
    myx500@cs-u-maize.cs.umn.edu:~$ groups
    ... kvm ...

If your user does not have the ``kvm`` group, please contact an officer.

Next, make a clone of the kernel Git repo.
To save network bandwidth, we have a copy of the kernel's Git repo on Maize already, which you should clone.

.. code:: sh

    # Clone the repo. This will clone it to the current working directory, as a
    # directory named linux. You can clone it to a different directory or move
    # it after cloning it if you would prefer it to be elsewhere.
    myx500@cs-u-maize.cs.umn.edu:~$ git clone /srv/git/linux

    # Once the kernel is cloned, cd into it before proceeding to the following
    # steps.
    myx500@cs-u-maize.cs.umn.edu:~$ cd linux

If, when cloning the repo, you get an error like the following, run the command from the error:

.. code:: sh

    myx500@cs-u-maize.cs.umn.edu:~$ git clone /srv/git/linux
    Cloning into 'linux'...
    fatal: detected dubious ownership in repository at '/srv/git/linux/.git'
    To add an exception for this directory, call:

            git config --global --add safe.directory /srv/git/linux/.git
    fatal: Could not read from remote repository.

    Please make sure you have the correct access rights
    and the repository exists.

    myx500@cs-u-maize.cs.umn.edu:~$ git config --global --add safe.directory /srv/git/linux/.git

    # After running the command, re-run git clone.
    myx500@cs-u-maize.cs.umn.edu:~$ git clone /srv/git/linux

We're using a tool called `virtme-ng <https://github.com/arighi/virtme-ng>`_ to automate the process of building the kernel and starting a VM containing it.
Each of these two steps is a single command.

.. code:: sh

    # Make sure that you've cd'd into the kernel repo. This command builds the
    # kernel, using a minimal default configuration that will build quickly and
    # work for these steps. Later, we'll see how you can adjust the
    # configuration.
    myx500@cs-u-maize.cs.umn.edu:~/linux$ vng --verbose --build

    # This command boots a virtual machine that has access to your home
    # directory.
    myx500@cs-u-maize.cs.umn.edu:~/linux$ vng --verbose

After launching the virtual machine, you should be in the same directory, but the hostname should display as ``virtme-ng``.

.. code:: sh

    # This command is now running in the virtual machine.
    myx500@virtme-ng:~/linux$ uname -a
    Linux virtme-ng 6.12.0-rc1-virtme #1 SMP PREEMPT_DYNAMIC Sat Oct  5 19:44:31 CDT 2024 x86_64 x86_64 x86_64 GNU/Linux

You can exit out of the virtual machine by exiting the shell, either with the ``exit`` shell built-in or with the :kbd:`Ctrl+D` keypress [#ctrld]_.

Now that we have the kernel working, we can see how to modify and configure it.
In this tutorial, we won't cover the process of authoring a new kernel module.
Instead, we'll use a "Hello, World!" module that's already been written.
This module is present on a branch in the kernel repo on Maize.

Check out the branch with the module on it.

.. code:: sh

    myx500@cs-u-maize.cs.umn.edu:~/linux$ git checkout hello_module
    branch 'hello_module' set up to track 'origin/hello_module'.
    Switched to a new branch 'hello_module'

This branch adds a new module named ``hello_world``.
Like many kernel modules, this module will only get built if the appropriate option is set in the kernel's build-time configuration.
The kernel's build-time configuration is stored in a file named ``.config`` [#dotfile]_.

You can run ``less`` to view the file's contents, which should be a minimal configuration that virtme-ng came up with when you first built the kernel.

.. code:: sh

    # You can scroll in less with the arrow keys, or the j and k keys. You can
    # exit less with the q key.
    myx500@cs-u-maize.cs.umn.edu:~/linux$ less .config

While it is possible to edit the ``.config`` file by hand, the Linux kernel comes with several tools to make it more convenient to edit the configuration.
The one we'll be using is ``menuconfig``, which has a menu-driven interface for configuring the kernel.

.. code:: sh

    # This will compile menuconfig if necessary, then run it.
    myx500@cs-u-maize.cs.umn.edu:~/linux$ make menuconfig

After running the above command, your terminal should be displaying a menu with a blue background.
There are two configuration options we want to enable.

The first configuration option to enable is ``CONFIG_STAGING``.
This enables building drivers that are marked as not yet being ready for release in the main Linux kernel, but are still in the repo for users willing to try them out.
Most new drivers enter the kernel as staging drivers, so we've marked our ``hello_world`` module as one.

Use the arrow keys to navigate to the ``Device Drivers`` option, then hit :kbd:`Enter` to enter that submenu.
Then, scroll until you find the ``Staging drivers`` option, then hit :kbd:`Space` to enable it.

The second option we want to enable is ``CONFIG_HELLO_WORLD``, which enables our driver.

With the cursor still on ``Staging drivers``, hit :kbd:`Enter` to enter the submenu for staging drivers.
Then, scroll to the ``'Hello, World!' Driver`` option and hit :kbd:`Space`.
This should make the field next to it go from ``< >`` (indicating that the module will not be built) to ``<M>`` (indicating that the module will be built, but kept as a ``.ko`` file separately from the rest of the kernel).
Hit :kbd:`Space` again to make it go from ``<M>`` to ``<*>``, which indicates that the module will be built and linked into the rest of the kernel.

.. code::

    Device Drivers --->
      [*] Staging drivers --->
        <*> 'Hello, World!' Driver

Hit :kbd:`Esc` twice to go up a menu level to the ``Staging drivers`` menu, then four more times to get to the main menu.

Hit :kbd:`Esc` twice more to exit.
``menuconfig`` will prompt you, asking if you want to save your changes.
Press :kbd:`Enter` to save them.

We've now configured our kernel.
We can use virtme-ng again to build it.
Notice how this time, the build is much faster, since we can re-use almost all of the output files from the previous build.
You should also be able to see a line from compiling the ``hello_world`` driver.

.. code:: sh

    myx500@cs-u-maize.cs.umn.edu:~/linux$ vng --verbose --build
    [...]
      CC      drivers/staging/hello_world/hello_world.o
    [...]

You can use virtme-ng again to boot the kernel, too.

.. code:: sh

    myx500@cs-u-maize.cs.umn.edu:~/linux$ vng --verbose

Our driver just prints ``Hello, World!`` as the kernel boots.
We can see the kernel logs with the ``dmesg`` command, and pipe them through the ``grep`` command to search for ones that include "Hello".

.. code:: sh

    myx500@virtme-ng:~/linux$ dmesg | grep Hello
    [    0.257566] Hello, World!

Next steps
==========

Now that you've seen how to configure, build, and boot a Linux kernel, you're prepared to actually modify the code of the kernel, for example by adding a new kernel module.

The next group meeting that includes a tutorial should teach you about the basics of kernel programming, so you can start to make your own changes to the kernel's code.

.. [#ctrld] If there's extra time, discussing why :kbd:`Ctrl+D` causes the shell (and many other programs) to exit is worthwhile, and cuts a neat slice through some parts of Unix and Linux that aren't always well-covered by our operating systems courses.
.. [#dotfile] This file won't show up if you just run ``ls``, because its name starts with a ``.``. By convention, most Unix programs treat files whose names start with ``.`` as hidden files. The ``ls -a`` command will show hidden files as well.
