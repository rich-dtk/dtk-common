dtk-common
==========

DTK Common


GITOLITE
=========

Manager takes responsibility of handling all gitolite methods (or at least most of them). Reason is simple, gitolite commit / push are expensive operations and we want to mitigate that fact by using manager, and making sure that all our changes are under one commit / push.


Example: Adding user/user group/all to repo configuration

    manager = Gitolite::Manager.new('/home/git/gitolite-admin')

    repo_conf = manager.open_repo('r8--cm--java')
    repo_conf.add_username_with_rights(
      'dtk-instance-dtk9', 
      'RW+'
    )

    repo_conf.add_user_group_with_rights(
      'tenants', 
      'R'
    )

    repo_conf.add_all_with_rights(
      gitolite_friendly('RW')
    )

    manager.push()


License
----------------------
DTK Common is released under the GPLv3 license. Please see LICENSE for more details.
