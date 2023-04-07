=====
Maize
=====

UKO has access to a desktop machine with constant uptime and modern
specifications named Maize.

It is highly recommended that all scheduler group members use Maize to avoid
nuances in different GNU/Linux environments. Maize also includes all of the
tools required to participate in scheduler development.

Request a Maize Account
-----------------------

You must have an existing user account to access Maize. Contact Alex Elder
`elder@umn.edu <elder@umn.edu>`_ or Jack Kolb
`jhkolb@umn.edu <jhkolb@umn.edu>`_ to create a Maize user with your student
x500.

Accessing Maize
---------------

Maize may be accessed using the Secure Shell Protocol, or SSH. You can connect
using::

   ssh [x500]@cs-u-maize.cs.umn.edu

You will be prompted to enter a password. Use the password that was given to
you during Maize account creation, not your regular UMN password.

| NOTE: You must be connected to the University's `eduroam` network to access
| Maize. This requirement may be circumvented using the
| `UMN VPN <https://it.umn.edu/services-technologies/virtual-private-network-vpn>`_

It is recommended that you change your Maize password upon successful login
using::

   passwd

All following Maize logins will expect this newly setup password following the
change.

Convenience Suggestions
-----------------------

You can simplify Maize login using this one-line command::

   X500=[x500] printf "Host maize\n\tUser\t\t${X500}\n\tHostname\tcs-u-maize.cs.umn.edu" >> ~/.ssh/config

This adds a new host entry into your SSH configuration so you can access Maize with::

   ssh maize

