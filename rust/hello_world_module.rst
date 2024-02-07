====================================
Creating a Hello World Kernel Module
====================================

Synopsis
--------

These steps outline how to modify the kernel source tree to include a new
"Hello, World!" kernel module. This module only performs the trivial task of
printing messages to the console  when it is loaded or removed. However, it
still serves as a useful illustration of how kernel modules are generally
structured and how to integrate a new module into the existing kernel codebase.

Preliminaries
-------------

This tutorial assumes you already have a working virtual machine set up on our
``maize`` server and that you are able to boot a kernel you have compiled
yourself on that VM. See our earlier tutorial on installing a custom kernel in a
VM if you have not already completed these tasks.

Obtaining the Source Code
-------------------------

First, you will need to obtain the source code for our simple kernel module.
You should already have cloned a copy of the Linux kernel source tree from a
previous tutorial, i.e., you should see something like the following:

.. code:: sh

    >> git remote -v
    origin  https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/ (fetch)
    origin  https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/ (push)

We have set up a local git repository on ``maize`` containing the source code
for this tutorial as a branch. We may choose to use this local git repository
for future activities, so it is worthwhile to add it to your own repository at
this time:

.. code:: sh

    >> git remote add maize /srv/git/linux
    >> git remote -v
	maize   /srv/git/linux (fetch)
	maize   /srv/git/linux (push)
	origin  https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/ (fetch)
	origin  https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/ (push)

Next, we'll update the new ``maize`` remote and switch to the new
``hello_module`` branch available from that remote.

.. code:: sh

	>> git remote update maize
	# Should see some ouptut about new information from this remote
	>> git branch hello_module maize/hello_module
	Branch 'hello_module' set up to track remote branch 'hello_module' from 'maize'.
	>> git switch hello_module
	>> git branch
	* hello_module
	master

Walking Through the Source Code
-------------------------------

This branch includes a few changes to the upstream Linux kernel source. In
short, it adds a new kernel module whose sole purpose is to print the string
``Hello, World!`` when the module is loaded and to print the string ``Goodbye,
World!`` when the module is removed.

A module is a unit of code that can be dynamically loaded or removed from the
kernel at runtime, rather than at compile time. This is often useful with device
drivers, as it allows the kernel to load only the drivers it needs for the
specific hardware configuration on which it is running, leaving out drivers for
irrelevant devices. The module in this tutorial can be viewed as a trivial
device driver.

Most of the relevant code for this tutorial is in the
``drivers/staging/hello_world`` subdirectory of the kernel tree. Feel free to go
to this directory and browse its files with the editor of your choice. A few
items of note are summarized below.

hello_world.c
~~~~~~~~~~~~~

- The functions ``hello_world_init`` and ``hello_world_exit`` will be called
  when this kernel module is loaded and removed, respectively.
- Kernel code doesn't use ``printf`` as you are likely accustomed to from
  userspace C programs. Instead, it uses the ``printk`` function, which has a
  generally similar usage.
- A few macros are used at the bottom of the C file to specify the description,
  author, and license for the module. These are required for any well-formed
  module in the kernel codebase.

Makefile
~~~~~~~~
- The ``SPDX-License-Identifier`` (also included in the C source) specifies the
  license for this code. It is a useful shorthand that is used in place of
  reproducing the full text of the license (here, GPL Version 2). Licensing is
  an important issue in open-source software development that is beyond the
  scope of this tutorial.
- The second line of this file integrates our module with the larger kernel
  configuration system (discussed below).

Kernel Configuration
--------------------

The remaining changes in the ``hello_world_module`` branch allow our new kernel
module to be integrated with the kernel configuration system. You may remember
that when you built your first kernel, you had to generate a configuration
before compilation, linking, etc. could take place. Among many other things,
this allows you to specify which modules are built into the kernel, which
modules are made available to load at runtime, and which modules are left out of
the built kernel.

We want to be able to apply this same configuration logic to our new, custom
module, so the following files are changed or modified:

- ``drivers/staging/hello_world/Kconfig``
- ``drivers/staging/Makefile``
- ``drivers/staging/Kconfig``

To begin, generate a default configuration file:

.. code:: sh

	>> make defconfig

Next, **you** will need to manually edit the just-generated ``.config`` file
to make the following changes:

1. Change the commented out text ``# CONFIG_STAGING is not set`` to instead read
   ``CONFIG_STAGING=y``.
2. Add a new line immediately below this that reads ``CONFIG_HELLO_WORLD=y``.

Save your work and then reconfigure your kernel based on these new changes:

.. code:: sh

	>> make oldconfig

At this point, go ahead and rebuild a new version of the Linux kernel, hopefully
including our new module, using some sensible value for the ``-j`` flag to
benefit from our server's multiple cores.

.. code:: sh

   >> make -j 20

You may get a few prompts about the inclusion of other device drivers in your
built kernel. Type in ``n`` for all of these prompts.

Kernel Installation
-------------------

You are now ready to install your new custom kernel on your virtual machine.
This was covered in detail in a previous tutorial, and you should follow the
instructions there.

It's recommended that you create a snapshot of your virtual machine in its
current, working state before installing a new kernel.

.. code:: sh

   >> virsh snapshot-create-as ubuntu22 before_hello

Here is a very brief recap of the steps to install and boot a custom kernel in
your VM:

1. Mount the VM's file system in the host using the ``guestmount`` command.
2. Use ``make`` to install the kernel and its modules in the mounted filesystem.
3. Unmount the VM guest's filesystem from the host.
4. Run the ``guestunmount`` command to unmount the VM's file system.
5. Boot into your VM with the ``virsh`` tool.
6. Run the ``initupdate-ramfs`` and ``update-grub`` commands in your VM.
7. Reboot the virtual machine.

Booting the New Kernel
----------------------

At this point, you likely have several kernel versions installed on your VM. You
will most likely see the following versions reflected in ``/boot`` and on the
GRUB menu when your VM starts up. They likely look something like the following:

1. ``5.15.0-52-generic``
2. ``5.15.0-92-generic``
3. ``6.8.0-rc3``
4. ``6.8.0-rc3-00001-gc4cbdfd00f16``

The first two versions came with the base Ubuntu 22.04 installation and the
third version was installed in our previous VM and kernel boot tutorial. You
should boot the `last`, most recent version as it will contain our new module.

The kernel module should have printed out a message to the console when your VM
booted up, but it probably went by too quickly for you to notice. We'll use the
``journalctl`` tool to review the logs from our most recent kernel boot.

.. code:: sh

	>> uname -a
	Linux kerneldev 6.8.0-rc3-00001-gc4cbdfd00f16
    >> journalctl -b
    # Boot Log Messages Appear on Screen

If you search this output, you should find the following line:

.. code:: sh

    Feb 04 22:23:38 kerneldev kernel: Hello, World!

Where the date at the left will likely be different for you. Congratulations,
you have now booted a kernel containing some of your own custom code!

One useful hint: The ``-b`` flag for ``journalctl`` indicates we want to read
logs from the system boot. We can also view logs from `previous` boots of our
virtual machine as follows:

.. code:: sh

   >> journalctl -b -1 # View logs from previous boot
   >> journalctl -b -2 # View logs from two boots ago
   >> journalctl -b -3 # View logs from three boots ago
   etc.

Recovering from a Broken Kernel
-------------------------------

One you actually start hacking on kernel code, you are likely to introduce bugs
that may cause a kernel panic, where your VM fails to boot at all. This is
precisely why we are working within virtual machines rather than directly on a
real system.

To address this, you should get into the habit of snapshotting your VM when it
is in a working state and before you try booting a new, unproven kernel.

Let's snapshot our VM now that our simple kernel module is working.

.. code:: sh

   >> virsh snapshot-create-as ubuntu_22 after_hello
   Domain snapshot after_hello created

Next, say we intentionally introduce an error in our kernel module:

.. code:: c

    static int __init hello_world_init(void)
    {
        char * c = NULL;
        printk("*c = %c\n", *c);
        return 0;
   }

If we follow the usual steps to build and install this kernerl in our VM, we
should expect to see some kind of failure because we're dereferencing a null
pointer.

`Note`: If you're following along and make this change, then compile and
install your kernel, you'll end up with a new set of files in ``/boot`` and a
new GRUB menu entry called something like ``6.8.0-rc3-0001-...-dirty``, since
you are creating a kernel based changes that are uncommitted to git.

Booting this kernel should produce a message indicating that a panic has
occurred and including a bunch of diagnostic information. At this point, you
should detach from your VM session with the key sequence ``<Ctrl>]``. You can
then shut down your VM with the ``virsh destroy`` command (don't worry, the
``destroy`` command sounds more serious than it is -- it shuts off your VM but
you won't lose anything as a result).

At this point, you have a couple of options with your VM. You can continue to
use it, being sure to select some working kernel version from the GRUB menu at
boot. Or, you can restore your VM from a snapshot to bring it back to a working
state.

The second option is recommended as it doesn't depend on the error-prone process
of reading GRUB menu output in the console and always choosing the correct menu
entry.

To restore our virtual machine back to its state before we installed the buggy
kernel, we can use the following command:

.. code:: sh

   >> virsh snapshot revert ubuntu22 after_hello
   >> virsh start ubuntu22 --console
   # Should now see a successful boot

Loading a Buggy Kernel Module
-----------------------------

Change the line for the hello world kernel module in your ``.config`` file from

.. code:: sh

	CONFIG_HELLO_WORLD=y

to the following:

.. code:: sh

	CONFIG_HELLO_WORLD=m

This will make our code available to the kernel as a module to load at runtime,
but it will not incorporate it directly into the kernel as it did before.

Now, we reconfigure our kernel with ``make oldconfig``, then recompile and
reinstall the new kernel into our virtual machine. Reboot your virtual machine,
making sure to select the ``6.8.0-rcc-00001-...-dirty`` kernel version.

You should now see your VM boot successfully. Since our module was not
automatically loaded, its bug has not (yet) affected our system. Let's now
instruct the kernel to load our module:

.. code:: sh

    >> sudo modprobe hello_world
    # Should see error messages reflecting kernel panic

Now, we can observe that, while loading the module failed due to the bug in its
initialization logic, the system itself stays up and running.

Future Goal: Kernel Build Script
--------------------------------

Eventually, we should aim to have a script that takes care of the tedium around
building and installing a new kernel (compiling, mounting the guest VM's file
system, etc.). One important part of this script will likely be generating a
snapshot of the VM, so that we always have a working configuration to fall back
to.

The current issue preventing our developing such a script is identifying a
method to run commands `in the VM` from a script executed on the host. This will
be necessary for the ``update-initramfs`` and ``update-grub`` commands.

If anyone would like to investigate this or knows of a solution, it would be a
valuable contribution to the group!
