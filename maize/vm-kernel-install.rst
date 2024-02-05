====================
Kernel Install in VM
====================

    :Author: Christopher Kauffman

Synopsis
--------

These steps outline how to copy an existing VM image, "play" with it a
bit, then install a freshly compiled Linux Kernel into the VM and boot
into it.

Tutorial Steps
--------------

.. code:: sh

    # log into the maize server
    laptop>> ssh myx500@maize.cs.umn.edu
    ...

    # check that you are a member of the correct Linux groups to run VMs
    # with hardware acceleration
    >> groups
    ... kvm libvirt libvirt-qemu ...

    # If missing, ask an admin to run the command
    >> sudo usermod -a -G kvm,libvirt-qemu,libvirt myusername

    # Set environment variable, consider adding this line to ~/.profile so
    # it is set on each login
    >> export LIBVIRT_DEFAULT_URI=qemu:///session

    # Copy Virtual Machine Image via Kauffman's script; amounts to a
    # virt-clone with some files and options
    >> ~kauffman/vm-shares/clone-vm.sh

    # Log in to Guest VM and experiment
    #
    # NOTE: console can be flaky especially for Grub boot loader, Press
    # the Up / Down arows and some highlighted text should appear
    # indicating which kernel will boot
    >> virsh start ubuntu22 --console
    ...
    login: user
    password: linuxrocks
    ...
    user@kerneldev:~$ ls
    ...
    # Check Guest VM kernel version
    user@kerneldev:~$ uname -a
    Linux kerneldev 5.15.0-92-generic #102-Ubuntu SMP Wed Jan 10 09:33:48 UTC 2024 x86_64 x86_64 x86_64 GNU/Linux

    # Escape from VM via Ctrl-]
    >>
    # VM Continues to run in the background
    # Re-enter VM console
    >> virsh console ubuntu22

    # May need to press Enter to re-display prompt
    user@kerneldev:~$

    # Escape VM or run `sudo shutdown now`

    # Ensure VM is shut down before proceeding
    >> virsh shutdown ubuntu22

    # Mount VM image on host via guestmount
    >> mkdir $HOME/mnt
    >> guestmount -a $HOME/.local/share/libvirt/images/ubuntu22.qcow2 -i $HOME/mnt

    # Clone linux kernel source from local copy on `maize`
    >> git clone /srv/git/linux

    # Change to linux source tree and build it
    >> cd $HOME/linux
    >> make defconfig
    >> make -j 20

    # Install kernel with adjusted root directory
    >> make install INSTALL_PATH=$HOME/mnt/boot

    # Install kernel modules with adjusted root
    >> make modules_install INSTALL_MOD_PATH=$HOME/mnt

    # Unmount guest disk
    >> guestunmount $HOME/mnt

    # Start virtual machine
    >> virsh start ubuntu22 --console
    ...
    login: user
    password: linuxrocks
    ..
    user@kerneldev:~$

    # Check that files are listed properly in the /boot directory
    user@kerneldev:~$ ls /boot
    ...
    vmlinuz-5.15.0-92-generic                  # old kernel
    vmlinuz-6.8.0-rc3                          # fresh kernel
    ...
    System.map-5.15.0-59-generic               # old kernel symbols
    System.map-6.8.0-rc3                       # fresh symbols
    ...
    config-5.15.0-92-generic                   # old config
    config-6.8.0-rc3                           # fresh config
    ...
    initrd.img-5.15.0-92-generic               # old initial ram disk
    # need a fresh initial ramdisk

    user@kerneldev:~$
    # Press Ctrl-] to escape the Guest VM and return to the terminal
    >>

    # Create a snapshot just in case...
    >> virsh snapshot-create-as ubuntu22 before-rdupdate
    Domain snapshot before-rdupdate created

    # Show the snapshot
    >> virsh snapshot-list ubuntu22
     Name              Creation Time               State
    --------------------------------------------------------
     before-rdupdate   2022-11-09 05:54:57 +0000   running

    # Return to the guest VM
    >> virsh console ubuntu22

    user@kerneldev:~$

    # Re-generate ramdisks for all kernel
    user@kerneldev:~$ sudo update-initramfs -c -k all
    update-initramfs: Generating /boot/initrd.img-5.15.0-52-generic
    update-initramfs: Generating /boot/initrd.img-6.1.0-rc2-00189-g23758867219c
    W: Possible missing firmware /lib/firmware/i915/dg1_huc.bin for built-in driver i915
    ... # various other warnings

    # Update the boot loader (lets us select kernel at boot)
    user@kerneldev:~$ sudo update-grub

    # Reboot the guest vm
    user@kerneldev:~$ sudo reboot
    ....

    # Grub menu should appear, select new kernel 6.8
                                 GNU GRUB  version 2.06

     +----------------------------------------------------------------------------+
     |*Ubuntu, with Linux 6.8.0-rc3                                               |
     | Ubuntu, with Linux 6.8.0-rc3 (recovery mode)                               |
     | Ubuntu, with Linux 5.15.0-92-generic                                       |
     | Ubuntu, with Linux 5.15.0-92-generic (recovery mode)                       |
     | Ubuntu, with Linux 5.15.0-52-generic                                       |
     | Ubuntu, with Linux 5.15.0-52-generic (recovery mode)                       |
     |                                                                            |
     |                                                                            |
     |                                                                            |
     |                                                                            |
     |                                                                            |
     |                                                                            |
     |                                                                            |
     |                                                                            |
     +----------------------------------------------------------------------------+
    ....
    # Expect some minor failures in the boot messages as the new kernel
    # doesn't have all modules build properly
    ...
    # Log in to Guest VM
    login: user
    password: linuxrocks

    # Check that the new kernel is running
    user@kerneldev:~$ uname -a
    Linux kerneldev 6.8.0-rc3 #1 SMP PREEMPT_DYNAMIC Sun Feb  4 20:59:48 CST 2024 x86_64 x86_64 x86_64 GNU/Linux

    # Press Ctrl-] to escape to host shell
    >>

    # Take a snapshot of the install
    >> virsh snapshot-create-as ubuntu22 kernel-68-installed
    Domain snapshot kernel-68-installed created

    # Congratulations!

Advantages
----------

- This process works, despite being a little clunky, is not
  tremendously long for a kernel build / install / test cycle

- Requires no graphical access: libvirt and QEMU allow for working on
  VMs in their own graphical window by default but also allow console
  / headless work; this allows workflow when only SSH access is
  available, appropriate for school settings / remote servers;
  however

Caveats
-------

- Relies on Host machine having the same kernel build style as the
  guest vm so that ``make install`` and ``make modules_install`` work
  correctly

- Requires logging into the VM to update initrd and boot loader for
  the first time, possibly on subsequent builds

- The VM image provided has already been configured with these
  features

  - Ubuntu22 Server set up with default options, initial user set

Alternatives
------------

- Build kernel entirely within the Guest VM; small performance hits
  and if things go sideways, hard to recover

- Mount a host machine directory from the guest to gain access to the
  kernel; unfortunately not currently supported in libvirt "session"
  mode, only in "system" mode which requires root permission when
  running VMs

- Ditch libvirt in favor of plain qemu usage; likely the most
  efficient way to do this as can specify alternate kernels to use at
  boot time; lose the nice management features of libvirt, easy
  console escape / restoration, initial forays did resulted in errors
  and kernel panics; ideally something like

  .. code:: sh

      qemu-system-x86_64 \
          -nographic \
          -m 4096 \
          -cpu host \
          --enable-kvm \
          -kernel /home/kauffman/linux/arch/x86_64/boot/bzImage \
          -append "console=ttyS0 root=/dev/sda" \
          -hda /home/kauffman/.local/share/libvirt/images/ubuntu22_work.qcow2

  but since modules and initial ram disk are needed, likely the setup
  is trickier than this

QEMU Resources
--------------

Some of these resources may be useful for deriving a direct method to
launch a kernel via QEMU and an existing disk image

- `https://nickdesaulniers.github.io/blog/2018/10/24/booting-a-custom-linux-kernel-in-qemu-and-debugging-it-with-gdb/ <https://nickdesaulniers.github.io/blog/2018/10/24/booting-a-custom-linux-kernel-in-qemu-and-debugging-it-with-gdb/>`_
  Describes how to launch basic kernel in a VM with qemu, attach a debugger to
  debug the kernel. Missing how to use an existing disk

- `https://www.youtube.com/watch?v=x_5MNWByT8I <https://www.youtube.com/watch?v=x_5MNWByT8I>`_
  Demos QEMU to set up disk image for an initial install mirroring
  existing OS, mirrors in environment, uses files and initial ram disk
  from host, Arch specific

Ideas for Future Discussion
---------------------------

- Discussion of where the Initial RAM Disk fits into the boot process;
  several resources available `from Linux Kernel docs <https://docs.kernel.org/admin-guide/initrd.html>`_, `from IBM <https://developer.ibm.com/articles/l-initrd/>`_, and `in
  Ubuntu's manual pages <https://manpages.ubuntu.com/manpages/xenial/man4/initrd.4.html>`_; would be good to know more about this

- Further exploration of how host and guest can interact in libvirt
  VMs; several items that make it less than ideal

  - Run libvirt and ``virsh`` via qemu:///session hypervisor so students
    do not need root access to run VMs and get their own collection of
    VMs. In contrast qemu:///system hypervisor requires root
    privileges and has a single set of VMs for whole system, allows
    guest VMs to do more; `good overview of "session" vs "system"
    hypervisor <https://blog.wikichoon.com/2016/01/qemusystem-vs-qemusession.html>`_

  - Networking in qemu:///session is limited: can network OUT of the
    Guest to Host and wider internet BUT cannot network INTO the Guest
    from Host; several sources indicate one can set up better
    networking using `qemu-bridge-helper <https://mike42.me/blog/2019-08-how-to-use-the-qemu-bridge-helper-on-debian-10>`_

  - Should be able to share directories between host/guest according
    to `libvirt docs on host/guest directory sharing <https://libvirt.org/kbase/virtiofs.html>`_ BUT current
    `limitations of virtiofs prevent qemu:///session from sharing <https://www.mail-archive.com/libvir-list@redhat.com/msg215780.html>`_,

- VM image chosen is large (Ubuntu 22 server); QEMU apparently smaller
  minimalist images exist which will occupy less disk space

- libvirt allows for graphical launching of remote VMs, may provide
  some conveniences (e.g. can run a desktop environment like Gnome in
  a VM on maize but see the graphics output on your laptop in a VM
  window, may require running Linux on laptop natively or in its own
  VM)
