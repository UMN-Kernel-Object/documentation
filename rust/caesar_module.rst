===================================
Creating a Simple Encryption Module
===================================

Synopsis
--------

This tutorial discusses the implementation of a kernel module that performs
encryption of text using a very simple Caesar cipher. Be aware that referring to
a Caesar cipher as an encryption mechanism is a charitable characterization, as
it is trivial to break. Expect no real security benefits from this encryption.
Instead, we have chosen this task because it motivates a number of challenges
that you will encounter repeatedly in kernel development: dynamically allocating
memory, using pre-defined kernel structures, and basic input/output.

Preliminaries
-------------

This tutorial assumes you already have a working virtual machine set up on our
``maize`` server, that you are able to compile, install, and boot your own
kernel on this virtual machine, and that you have worked through the "Hello,
World!" module tutorial. Refer back to those tutorials if you need a refresher
on those topics.

Obtaining the Source Code
-------------------------

First, you will need to obtain the source code for our Caesar cipher kernel
module. You should already have a remote set up to access our git repository
hosted locally on maize. That is, you should see something like the following in
your Linux source tree:

.. code:: sh

    >> git remote -v
	maize   /srv/git/linux (fetch)
	maize   /srv/git/linux (push)
	origin  https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/ (fetch)
	origin  https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/ (push)

Next, we'll update the ``maize`` remote and switch to the new ``caesar`` branch
available from that remote.

.. code:: sh

	>> git remote update maize
	# Should see some ouptut about new information from this remote
	>> git branch caesar maize/caesar
	Branch 'caesar' set up to track remote branch 'caesar' from 'maize'.
	>> git switch caesar
	>> git branch
	* caesar
	master

Walking Through the Source Code
-------------------------------

Like the previous "Hello, World!" module, this branch includes a few changes to
the upstream Linux kernel source. It adds a new directory,
``drivers/staging/caesar`` and adds the necessary Makefiles and Kconfig files to
integrate this new directory into the larger kernel configuration system. Most
of these changes are identical in nature to the "Hello, World!" module and will
not be discussed in detail here.

The ``caesar.c`` file is the main point of interest. It has quite a bit more
code than we saw for the "Hello, World!" module, although the general structure
remains the same.

debugfs and the File Interface
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``caesar`` module uses a feature of the Linux kernel known as debugfs.
Briefly, debugfs allows kernel developers to provide information and
functionality accessible as "files" under ``/sys/kernel/debug``. One can
interact with these files by opening, reading, and writing as one would do with
any normal file. However, unlike traditional files, which represent a sequence
of bytes stored persistently on disk, debugfs files are much more flexible.
Reading a debugfs file might return the contents of a specific location in
memory, for example.  You should therefore think of reads and writes against
debugfs files more as invocations against an API rather than direct reads and
writes to the contents of a disk.

In our particular module, writing a chunk of text to the associated debugfs file
will encrypt that text using a Caesar cipher. Reading from the file will return
ciphertext (encrypted text) back to the reader. Note that our module will have
no memory, i.e., it will only retain encrypted text for the most recently
written plaintext.

Module Init and Exit
~~~~~~~~~~~~~~~~~~~~

Just like in our simple "Hello, World!" module, the ``module_init`` and
``module_exit`` macros at the end of ``caesar.c`` specify which functions are
invoked when the module is initialized and when it exits.

When our module is initialized, we need to create a new debugfs file to be made
available to the user. First, we create a ``caesar`` directory, then we create a
file named ``encrypt`` within that directory. This means our encryption
system will be accessible to the user through reads and writes to the file
``/sys/kernel/debug/caesar/encrypt``.

If you've taken an operating systems class, you may remember that nodes in the
file system's tree correspond to entries in a hierarchical system of
directories. The module initialization code creates a directory entry for the
``caesar`` directory and for the ``encrypt`` file, both represented as instances
of ``struct dirent``. Note that the directory entry for the ``caesar`` file is
saved as a global variable. This allows us to save it for later use in the
module exit, where we remove this directory and all of its contents to clean up
after ourselves.

The ``debugfs_create_file`` function specifies the name and permissions for the
new file. ``S_IRUSR | S_IWUSR`` makes the file readable and writable for its
owner. The last argument is especially important: it specifies which functions
are invoked when the file is read or written. This is represented by an instance
of the ``struct file_operations`` type. Such an instance is declared immediately
above the ``caesar_init`` function.

The ``file_operations_caesar_struct`` has two of its fields initialized.
``read`` identifies which function is called when the file is read (here,
``read_caesar``) and which function is called when the file is written (here,
``write_caesar``). A ``struct file_operations`` is used often in the Linux
kernel codebase and has several other fields to specify logic for other file
operations. Here, we have a minimal file definition that only supports basic
reading and writing.

Writing Plaintext
~~~~~~~~~~~~~~~~~

The ``write_caesar`` function is invoked whenever the ``encrypt`` debugfs file
is written to, thanks to our setup during module initialization. Our goal is to
take a body of text provided by the user, encrypt it using a Caesar cipher, and
then preserve this encrypted text for future reads against the file.

A few variable declarations occur at the beginning of the function. This is in
accordance with the expected style for Linux kernel code.

The ``ppos`` argument can be used to specify an offset for a file read or file
write. In our case, that doesn't apply as our file holds just one item of
information and is not seekable in the usual sense. Therefore, we first verify
that ``ppos`` is ``0`` and return an error if it is not. In a more traditional
file, one would need to account for the offset in determining where to read or
write bytes within the file's overall contents.

Our module can't operate directly on user memory. We immediately know that the
``buf`` parameter points to such memory because it has a ``__user`` tag attached
to it. Therefore, we need to allocate memory within the kernel to hold a copy of
the user's original data. This will also be convenient for our use case because
we can then iterate through this in-kernel buffer to perform our encryption and
we can save a pointer to this buffer to access for any later read operations.

We use the ``kzalloc`` function to allocate kernel memory. It is similar to the
``malloc`` function you may be used to from userspace C programming. The ``z``
in the function's name indicates that the allocated chunk of memory will be
zeroed out for us. This is a common practice in kernel coding as it addresses
some security concerns. There are several different flags one can specify as the
second argument to ``kzalloc`` that are well documented. ``GFP_KERNEL`` just
says that we need some general-purpose memory without any special
considerations.

Error handling is important in kernel code. The ``caesar`` module uses the
``IS_ERR`` macro on the pointer returned from ``kzalloc`` to check for an error.
Linux kernel functions traditionally return negative integer values to indicate
errors. The ``PTR_ERR`` macro converts our pointer to such a negative integer to
indicate what went wrong.

``copy_from_user``, as expected, copies bytes from a userspace buffer into our
allocated kernel buffer. The return value may seem slightly strange to you -- it
is the number of `uncopied` bytes. If an error occurs, then the return value
will be nonzero, otherwise it is ``0``.

Our implementation assumes the text to be encrypted is a properly
null-terminated string, and this is verified before we proceed. Kernel code
generally needs to be very careful with anything passed in from the user to
ensure it meets the expected assumptions.

The Caesar encryption comes next. It is a bit tedious and isn't any different in
a kernel setting from it would be in userspace. It iterates through each
character in the user's original input and does roughly the following:

1. Check if the current character is an uppercase or lowercase letter.
2. If so, shift it forwards three positions in the alphabet. ``A`` becomes
   ``D``, ``B`` becomes ``E``, and so on.
3. If the shift goes "past the end" of the alphabet, we wrap around again to the
   beginning. For example, the letter ``Z`` becomes ``C``.

Finally, we need a place to hold a pointer to the modified buffer that will
persist between file reads and writes. You might also remember from an OS class
that directory entries typically correspond to an `inode` in the underlying file
system. In Linux, the ``inode`` struct conveniently has a ``void *`` field
named ``i_private`` that we can use as we see fit. Therefore, we'll just modify
this field to point to the buffer holding the ciphertext. Note that this uses
the global variable ``stash_ptr`` that was first set up during module
initialization. If this pointer is not ``NULL``, it refers to a previously
constructed batch of ciphertext from a previous write, and we use ``kfree`` to
deallocate this (now unnecessary) buffer.

Note that this function returns the number of bytes "written" to the file, i.e.,
the length of the ciphertext. This corresponds to the expected return value of a
``write`` system call in Unix.

Reading Ciphertext
~~~~~~~~~~~~~~~~~~

Most of the heavy lifting happens with a write. Reading from the
``caesar/encrypt`` debugfs file is relatively simple.

We first verify that ``ppos`` is ``0`` as we did for a write. Then, we use the
``strnlen`` function to compute the length of the stored ciphertext. Note that
this is written to ensure that at most ``count`` bytes are used. The end of the
ciphertext is cut off if the user does not ask to read enough total bytes
(although, in this case, the result of a read will no longer be a properly
null-terminated string).

``copy_to_user`` copies bytes from our kernel buffer, accessed via the same
inode field as before, to user memory. The meaning of its return value are the
same as ``copy_from_user`` -- the number of uncopied bytes. We check for a
copying error and otherwise return the number of bytes copied. This corresponds
to the expected return value of a ``read`` system call in Unix.

Testing the Module
------------------

Note that you will need to make the following changes to the ``.config`` file in
your Linux repository:

.. code:: sh

 CONFIG_STAGING=y
 CONFIG_CAESAR=y

Compile a new kernel with this code in place, configured as needed, and install
it on your virtual machine. We're now ready to test out the code!

All we really need to do is issue system calls to write and then read from the
appropriate file. We should be able to read back the encrypted form of what was
written immediately before.

Here's a rudimentary C program to "encrypt" the text ``Hello, World!``. You may
want to add some error checking for easier debugging.

.. code:: c

    int main() {
        char *message = "Hello, World!\n";
        int fd = open("/sys/kernel/debug/caesar/encrypt", O_WRONLY);
        write(fd, message, strlen(message) + 1);
        close(fd);

        char buf[512];
        fd = open("/sys/kernel/debug/caesar/encrypt", O_RDONLY);
        read(fd, buf, 512);
        printf("Ciphertext: %s\n", buf);

        return 0;
    }

What's Next?
------------

There are lots of things you might try to do from here. Here are a couple of
ideas:

* Write a kernel module to carry out a more sophisticated encryption scheme. A
  Caesar cipher is about as simple (and unsecure) as you can get.
* Extend this module to perform decryption as well as encryption. You could
  create a second debugfs file at ``caesar/decrypt`` that performs the inverse
  of what we've seen here for reading and writing.
