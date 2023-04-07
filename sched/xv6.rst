====================
xv6 Operating System
====================

MITs xv6 is a re-implementation of Dennis Ritchie's and Ken Thompson's Unix
Version 6 (v6). xv6 loosely follows the structure and style of v6, but is
implemented for a modern x86-based multiprocessor using ANSI C.

The entire xv6 source code totals to around 100k lines of code, a relatively
small number compared to modern operating systems. The code is also simple
making it a great candidate to analyze and improve upon.

The scheduling subgroup has made plans to profile and improve the xv6
scheduler. See documentation on `xv6 scheduling <sched.rst>`_ for details.

Accessing xv6
-------------

| NOTE: It is recommended you follow these steps on
| `Maize </maize/setup.rst>`_. Development in other environments is not
| supported.

You will probably want to clone the xv6 repository so you can make your own
changes. MIT hosts the source code on their GitHub. Clone that repository
using::

   git clone https://github.com/mit-pdos/xv6-public.git

It is suggested that you add the UKO remote to your repository so you can keep
up with the group's changes::

    git remote add UKO https://github.com/UMN-Kernel-Object/xv6-public.git

Update the remote using::

   git remote update UKO

Then checkout the UKO `sched` development branch::

   git checkout sched

Any changes you make to this branch may be committed normally and pushed
using::

   git push UKO sched

Remember to adhere to standard `kernel coding practices <>`_ before sending
patches.
