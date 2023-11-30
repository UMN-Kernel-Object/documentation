============
Code Patches
============

All code patches may be submitted to the
`UKO-PATCHES@lists.umn.edu <UKO-PATCHES@lists.umn.edu>`_ mailing list for review.
Before sending a patch, your UMN email must be subscribed to the list.
You can do that `here <https://lists.umn.edu/cgi-bin/wa?A0=UKO-PATCHES&X=O363B529658766E8A03&Y>`_.

.. image:: patches_sub.avif

Once subscribed, you may send emails and respond to other patch submissions
with feedback.

Creating a Patch
----------------

It is assumed that you have cloned some UKO repository, made a valuable change,
and committed it locally. In order to submit that change for review, a patch
must be created using `git-format-patch(1) <https://git-scm.com/docs/git-format-patch>`_::

   git format-patch --signoff <commit range>

For example, to create a patch for the latest commit::

   git format-patch --signoff HEAD~1

Sending a Patch
---------------

Patches may be sent to the mailing list using
`git-send-email(1) <https://git-scm.com/docs/git-send-email>`_,
but some configuration must be done beforehand. Add the following to your Git
configuration file::

.. code-block::
   :caption: .config/git/config

   [user]
     name = First Last
     email = x500@umn.edu
   [sendemail]
     smtpServer = smtp.gmail.com
     smtpServerPort = 587
     smtpEncryption = tls
     smtpUser = x500@umn.edu

Patches can then be sent to a mailing list using::

   git send-email <patch file(s)>

Before the email is sent out, you will be prompted to enter a mail
password. Your standard UMN password will not work here. Instead, you must
create a one-time-password (OTP) to send mail using
`git-send-email(1) <https://git-scm.com/docs/git-send-email>`_.
Instructions on creating an OTP for your UMN account can be found
`here <https://docs.google.com/presentation/d/1IjUKb9kCIbKOGVrz4T-zBAUCBCYsclrqXDjEc0wRzwI/edit?usp=sharing>`_.
Be sure to save this password for use during future patch submissions.

If no errors arise, then the patch was sent successfully. You can verify this
by looking for the email in your UMN Gmail `Sent` mailbox.
