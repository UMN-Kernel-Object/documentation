===================
Building the kernel
===================

November 30, 2022
=================

Topics
------

* Built-in versus loadable kernel module
* Kernel configuration
* Kernel build

Future topics
-------------

* More about the kernel source tree organization
* Bootstrap process, including the initial ramdisk

----

Kernel modules
--------------

* The kernel is just a large program (much like user space)
* Normally, kernel code is "built in"

  * Pieces are compiled separately into object files
  * Object files are linked together to produce a (bootable) executable

* The kernel offers a way to load pieces of the kernel dynamically

  * Loadable kernel modules can be unloaded if not in use

* This allows optional features to be added to the kernel at runtime

  * Allows a minimal kernel to still provide full functionality

* Modules are located under /lib/modules/<kernel_version>

  * Where <kernel_version> is what's produced by ``uname -r``

      5.15.0-53-generic

+------------------------+----------------------------------------------+
| Command                | Explanation                                  |
+========================+==============================================+
| ``lsmod``              | List currently loaded modules                |
+------------------------+----------------------------------------------+
| ``insmod <path>``      | Insert a loadable module                     |
+------------------------+----------------------------------------------+
| ``rmmod <modname>``    | Remove a previously-loaded module            |
+------------------------+----------------------------------------------+
| ``depmod``             | Calculate module dependencies                |
+------------------------+----------------------------------------------+
| ``modprobe <modname>`` | Insert a module and everything it depends on |
+------------------------+----------------------------------------------+

----

Kernel build documentation

* Documentation found in kernel source tree:
    Documentation/kbuild/
* Already rendered on kernel.org:
    https://docs.kernel.org/kbuild/index.html

----

Kernel configuration input files

* To build a kernel, it must first be *configured*

  * Generally referred to as the "Kconfig" system
  * Kconfig is a language that seems clear
  * But in practice, some situations are tricky

* Kernel configuration defines what the built should "look like"

  * Fundamental things, like processor architecture, size of a long, size of a kernel pointer, page size.
  * Major subsystems are included (MMU, file systems, classes of supported hardware)
  * What optional features are present (debugging features, built-in compression libraries, kernel core dump)

* Default configuration files (defconfig) are specified for each architecture:

    | arch/<arch>/configs/\*
    | arch/<arch>/configs/\*_defconfig
    | arch/riscv/configs/defconfig
    | arch/arm64/configs/defconfig
    | arch/x86/configs/i386_defconfig
    | arch/x86/configs/tiny.config
    | arch/x86/configs/x86_64_defconfig
    | arch/x86/configs/ xen.config

----

How kernel configuration files are interpreted

* Specified by "Kconfig" files found throughout the source tree

  * Organized as a hierarchy; Kconfig files can include others
  * The complete set of files can be interpreted as a menu hierarchy for interactive configuration

      | make menuconfig

* Entries in "Kconfig" files define interdependencies

  * Configuring XFS depends on the BLOCK configuration option
  * Configuring XFS ACLs implies FS_POSIX_ACL gets enabled
  * Config options can often be "boolean" or "tristate"

    * Boolean means "built in to the kernel" (or not built)
    * tristate means "built in" or "modular" (or not built)

* Configuring the kernel parses a config file

  * Then it uses the collection of KConfig files to ensure that all dependencies are met, all implied configuration options are defined, and so on.
  * Output file name is ".config" in the build output directory

    * It is normally much bigger than the input config file

  * Also generates header files used during build, under: include/generated/*
  * Example:

      | ``make x86_64_defconfig``

  * Note, top-level Makefile also incorporates architecture-specific instructions.  So this:

      | ``make defconfig``

    becomes this on an x86_64 machine:

      | ``make x86_64_defconfig``

----

Kernel build
* GNU make is used, but it uses a set of conventions, which allow a great deal of automation
* Note that "-j $(nproc)" is an argument to GNU make (and is unrelated to the kernel build system)
* Collectively these conventions, etc. can be called "Kbuild"
* Subsystem Makefiles can be quite simple as a result

* Kernel command line options (using environment variables)

+----------------------------+-----------------------------------------------+
| Variable                   | Explanation                                   |
+============================+===============================================+
| ``O=<path>``               | Specify build output directory                |
+----------------------------+-----------------------------------------------+
| ``W=<n>``                  | Specify warning level (n = 1, 2, 3, e)        |
+----------------------------+-----------------------------------------------+
| ``C=<n>``                  | Call source code checker (n = 1 or 2)         |
+----------------------------+-----------------------------------------------+
| ``ARCH=<arch>``            | Specify target architecture (x86, arm64, ...) |
+----------------------------+-----------------------------------------------+
| ``CC=<compiler>``          | Specify C compiler command to use             |
+----------------------------+-----------------------------------------------+
| ``LLVM=1``                 | Use all LLVM tools (including clang)          |
+----------------------------+-----------------------------------------------+
| ``CROSS_COMPILE=<prefix>`` | Specify cross-compiler prefix                 |
+----------------------------+-----------------------------------------------+

* A big example:
    | ``make O=../output_dir W=1 C=1 ARCH=arm64 \``
    |        ``CROSS_COMPILE=aarch64-linux-gnu-``

* These could also be passed (exported) via the environment this way:

    | ``export O=../output_dir``
    | ``export W=1``
    | ``export C=1``
    | ``export ARCH=arm64``
    | ``export CROSS_COMPILE=aarch64-linux-gnu-``
    | ``make``

----

* ccache

  * Used to speed up builds
  * Saves a copy of object file output for a given source file
  * Computes a hash of a source file (plus some build metadata)

    * If hash matches one built before, just uses cached copy
    * Otherwise builds, and saves the result in the cache
  * Basic insight is that computing a hash is faster than compiling
  * Use it by setting:

      | ``CC="ccache gcc"``

    or maybe

      | ``CC="ccache clang"``

  So for example:

      | ``make -j 8 O=../output_dir CC="ccache clang"``
