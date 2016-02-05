dtk-common
==========

What it is?
----------------------
This is helper library used across DTK components (dtk-server, dtk-repo-manager). Since it is included as dependency on DTK components, there is no need for installing/configuring it separately. We use [Gitolite](https://github.com/sitaramc/gitolite) for fine-grained access control to our component and service modules. One of the functionalities that dtk-common exposes is interaction with Gitolite via Gitolite Manager. Below is an example why and how Gitolite manager is used.

Gitolite manager usage
----------------------
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
