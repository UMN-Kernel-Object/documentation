=====
Maize
=====

UKO has access to a desktop machine with constant uptime and modern specifications named Maize.

It is highly recommended that all group members use Maize for kernel development to avoid nuances in different GNU/Linux environments.
Shared use of Maize also lets us ensure that if something we're planning to do requires tools, we all have access to them.

Request a Maize Account
-----------------------

You must have an existing user account to access Maize.
Contact `kernel@umn.edu <kernel@umn.edu>`_ with your student x500 to get access to your own user account, or use the ``/maize-invite`` command in Discord.

Accessing Maize
---------------

Maize may be accessed using the Secure Shell Protocol, or SSH. You can connect using::

   ssh [x500]@cs-u-maize.cs.umn.edu

You will be prompted to enter a password.
This password is not synchronized with your regular UMN password.

If you haven't set a password yet, use the password that was given to you during Maize account creation.
You should be prompted to change your password on first login.
All following Maize logins will expect this newly setup password following the change.

   NOTE: You must be connected to the University's `eduroam` network to access
   Maize. This requirement may be circumvented using the
   `UMN VPN <https://it.umn.edu/services-technologies/virtual-private-network-vpn>`_

Convenience Suggestions
-----------------------

You can simplify Maize login using this one-line command::

   X500=[x500] printf "Host maize\n\tUser\t\t${X500}\n\tHostname\tcs-u-maize.cs.umn.edu" >> ~/.ssh/config

This adds a new host entry into your SSH configuration so you can access Maize with::

   ssh maize

