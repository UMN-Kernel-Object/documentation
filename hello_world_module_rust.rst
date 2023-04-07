===========================================================
Creating a Hello World Kernel Module, but this time in Rust
===========================================================

   :Author: Shaun Loo


Synopsis
--------

These steps outline how to modify the kernel source tree to include a new
"Hello, World!" kernel module in Rust. This module only performs the task
of printing a message to the console, but demonstrates a good amount of the
Rust workflow in the kernel, as well as getting a deep insight into the
current infrastructure available in the kernel for Rust support

Preliminaries
-------------

This tutorial assumes you already have a working virtual machine set up on our
``maize`` server and that you are able to boot a kernel you have compiled
yourself on that VM. See our earlier tutorial on installing a custom kernel in a
VM if you have not already completed these tasks.

This tutorial also presumes that you have a working Rust toolchain on ``maize``
Currently, the prefered way of getting such a toolchain is to install rustup
in your own user account. Visit
`this page https://www.rust-lang.org/tools/install`_ to get set up with a
toolchain.

Obtaining the Source Code
-------------------------

You will need to clone the kernel source tree again. The last two versions of
the Linux kernel since the Fall tutorials have added heaps in terms of Rust
support. 

Remember, to make a shallow clone of the Linux kernel source:

..code-block:: sh

   git clone --depth=1 git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git

Setting up the Rust toolchain for kernel development
----------------------------------------------------

`Adapted from here <https://docs.kernel.org/rust/quick-start.html#configuration>`_

Firstly, we check if Rust is even available

..code-block:: sh

   make defconfig
   make LLVM=1 rustavailable

Invoking the build script with :code:`rustavailable` will test the current
configuration. It will report any incompatibilities with the current rustup
configuration. 

For example, if you just installed :code:`rustup`, you might see an error
message like this:

..code-block:: sh

   ***
   *** Rust compiler 'rustc' is too new. This may or may not work.
   ***   Your version:     1.68.2
   ***   Expected version: 1.62.0
   ***
   ***
   *** Source code for the 'core' standard library could not be found
   *** at '/home/loo00013/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/lib/rustlib/src/rust/library/core/src/lib.rs'.
   ***
   make: *** [Makefile:1825: rustavailable] Error 1

We can't go thru all the errors, so see the above link to find solutions
to each error. In this specific error, we see that the version of the
Rust compiler is too new. We fix this by telling rustup to override the
Rust compiler with the older version when you're in the Linux kernel
source folder. 

..code-block:: sh

   rustup override set $(scripts/min-tool-version.sh rustc)

Hopefully, at the end of this, you'll get this output:

..code-block:: sh

   Rust is available!

This means we can move to the next step

Writing the kernel module
--------------------------

We will edit these files. If you're not sure what
these files are, do review the earlier C hello world module tutorial.

:code:`sample/rust/Kconfig`

..code-block::
   
   ...

   config SAMPLE_RUST_HELLO
      tristate "Hello Module"
      help 
         This option builds a simple Hello World module.

         To compile this as a module, choose M here:
         the module wil be called rust_hello.

         If unsure, say N.

   ...

:code:`sample/rust/Makefile`

..code-block::

   ...
   obj-$(CONFIG_SAMPLE_RUST_VDEV) 			+= rust_hello.o
   ...

:code:`sample/rust/hello.rs` (create this!)

..code-block:: rust

   // SPDX-License-Identifier: GPL-2.0

   //! Rust printing macros sample.

   use kernel::prelude::*;

   module! {
      type: RustHello,
      name: "rust_hello",
      author: "Rust for Linux Contributors",
      description: "Rust hello world sample",
      license: "GPL",
   }

   struct RustHello;

   impl kernel::Module for RustHello {
      fn init(_module: &'static ThisModule) -> Result<Self> {
         pr_info!("-------------------------\n");
         pr_info!("Vote Shaun for Vice Prez!\n");
         pr_info!("-------------------------\n");
      }
   }

Building the kernel with the module!

In the kernel source folder, :code:`make menuconfig`

Enter General Setup, then navigate all the way to the bottom. You
should see :code:`[ ] Rust support`. Navigate to that item and hit
the spacebar. You should see a star next to it, indicating that Rust
support has been activated.

Hit Exit, then navigate to the Kernel Hacking section at the very bottom.
Find the entry :code:`[ ] Sample kernel code`. As with before, hit
the spacebar to activate the entry. Then, hit enter to enter the menu.

Scroll until you find :code:`[ ] Rust samples (NEW)`. Again, activate
the entry and enter it. You'll see `< > Hello Module (NEW)`. Hit the
spacebar until you see the * indicating that it is activated (I have
not tested M yet).

Hit Save, and save the config as :code:`.config`, then exit the makeconfig
menu. 

Now, invoke build with :code:`make LLVM=1 -j16`. We need the flag 
:code:`LLVM=1` because the Rust compiler uses the LLVM backend and
integrating Rust code with a :code:`clang`-built kernel (which uses
the LLVM backend) is easier. 

Hopefully, this compiles without issues. The final step is to install
the kernel in your VM. Refer to the previous tutorial for instructions
on that. 

When booting into the kernel, you should see a cute little message
fly by if you're quick enough. If you're not, however, type
:code:`sudo journalctl -b` and you should be able to scroll thru
it and find it!
