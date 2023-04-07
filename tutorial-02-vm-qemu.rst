====================
Running bare QEMU kernel
====================

    :Author: Shaun Loo

Synopsis
--------

These steps outline how to create a virtual machine and boot a
virtual machine with any arbitrary kernel image. This presents
a more flexible virtual machine workflow for kernel development.

Rationale
---------

The :code:`virsh` based workflow outlined in Professor Kauffman's
previous tutorial works pretty well, so why create an alternative
workflow?

The underlying hypervisor behind :code:`virsh` is :code:`qemu`.
:code:`qemu` was created with Linux virtual machines in mind, and
is able to load any Linux kernel image. Using bare :code:`qemu`
allows us to explit this feature to compile on bare metal and
boot into a virtual machine to test our changes.

Setting up
----------

Firstly, copy this block of code into a new folder:

:code:`boot.sh`:
.. code:: sh
  #!/bin/bash

  declare -i cpu=2
  declare -i threads=cpu * 2
  declare -i ram=2560 #RAM count
  img_hdd0="hdd.img"
  img_hdd1="seed.img"

  qemu-system-x86_64 -machine q35,accel=kvm \
  -smp $threads,cores=$cpu -m $ram \
  -drive file=$img_hdd0,format=qcow2,if=virtio \
  -drive file=$img_hdd1,format=raw,if=virtio \
  -nographic

:code:`boot-kernel.sh`:
.. code:: sh
  #!/bin/bash

  declare -i cpu=2
  declare -i threads=cpu * 2
  declare -i ram=2560 #RAM count
  img_hdd0="hdd.img"
  img_hdd1="seed.img"

  qemu-system-x86_64 -machine q35,accel=kvm \
  -smp $threads,cores=$cpu -m $ram \
  -drive file=$img_hdd0,format=qcow2,if=virtio \
  -drive file=$img_hdd1,format=raw,if=virtio \
  -kernel $1 -append "root=/dev/vda1 console=ttyS0" \
  -nographic

The first 5 lines declare a few variables relating to VM configuration.
Right now, this creates a VM with 2 cores and 4 threads, 2.5GB of RAM,
and two HDD images - :code:`hdd0` and :code:`hdd1`

The rest of the shell script just tells :code:`qemu` to start a VM based
on the specifications we've stated above. The :code:`boot-kernel.sh`
version takes 1 argument: a kernel image, and tells QEMU to boot the virtual
machine using that kernel image.

Then, we find a suitable virtual machine image to work with. We utilize
cloud images provided by Ubuntu for convenience. Download the Ubuntu
22.04 LTS cloud image using the command

In the folder where you copied the shell scripts to:

.. code:: sh
  wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
  cp jammy-server-cloudimg-amd64.img hdd.img
  qemu-img resize hdd.img +50G

The last two commands there basically copy the image to :code:`hdd.img`
(leaving the original for when things get messed up), and gives this 
image 50 gigabytes of virtual storage. This does not increase the size
of the image itself - only the virtual machine will see this increase!

Now, we have to configure the cloud image. We do so with two files
that define our VM initialization parameters.

:code:`metadata.yml`: 
.. code:: yaml
  instance-id: iid-local01
  local-hostname: cloudimg

:code:`user-data.yml`:
.. code:: yaml
  #cloud-config

  users:
    - name: your-username
      ssh-authorized-keys:
        - ssh-ed25519 your-ssh-public-key
      sudo: ['ALL=(ALL) NOPASSWD:ALL']
      groups: sudo
      shell: /bin/bash
      lock_passwd: false
      passwd: generate a password hash with mkpasswd --method=SHA-512 --rounds=4096

Now, we generate the :code:`seed.img` file that contains our parameters. In
the same working folder:

.. code:: sh
  cloud-localds seed.img user-data.yaml metadata.yaml

Now, try booting by invoking :code:`./boot.sh`! You'll see a flurry of
text go by, and you'll find a login prompt! You're in the VM! 

To exit the VM, :code:`Ctrl+A` then :code:`X` and you will see

.. code::
  QEMU: Terminated

This ends the virtual machine

Booting a kernel image
----------------------

In the Linux kernel repository where you built the kernel,

.. code:: sh
  INSTALL_PATH=/some/location/ make install

This will save the kernel in the speficied location. :code:`WORKDIR/kernels`,
where :code:`WORKDIR` is where the boot scripts are, is one good place to
install the kernels to, but it can be anywhere.

Now, boot with :code:`./boot-kernel.sh /some/location/vmlinuz-6...`, and
you'll see the same flurry of text, which hopefully includes some of the 
changes you might see!

