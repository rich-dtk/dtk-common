dtk-common
==========

DTK Common


GITOLITE
=========

Manager takes responsibility of handling all gitolite methods (or at least most of them). Reason is simple, gitolite commit / push are expensive operations and we want to mitigate that fact by using manager, and making sure that all our changes are under one commit / push.

