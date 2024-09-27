============================================
Building and Booting a Linux kernel on Maize
============================================

    :Author: Nathan Ringo

Synopsis
========

This document is a tutorial about how to get the Linux kernel sources on Maize, how to build them, and how to access a VM using the just-built kernel.

Tutorial Steps
==============

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
    Linux virtme-ng 6.8.0-rc3-virtme #45 SMP PREEMPT_DYNAMIC Tue Sep 24 20:34:53 CDT 2024 x86_64 x86_64 x86_64 GNU/Linux
