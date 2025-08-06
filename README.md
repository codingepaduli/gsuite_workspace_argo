# gsuite_workspace_argo

A collection of script to help import, export and manage Argo and GSuite data.

See the [ARCHITECTURE.md](ARCHITECTURE.md) file for more information about how the repository folders are structured.

See the [UserGuide.md](UserGuide.md) file for more information about how to configure and run this app.

## Prerequisite

Install [sqlite3](https://www.sqlite.org/index.html), [sqlite-utils](https://pypi.org/project/sqlite-utils/) and [Google Admin Manager](https://github.com/GAM-team/GAM/wiki) on your system.

Note: GAM OAuth Token has validity of 6 months from the last access. After 6 months of inactivity, you will get the error "gam ERROR: ('invalid_grant: Bad Request')" or ``{"error": "invalid_grant", "error_description": "Bad Request"}``. In this case, you need to re-authorize the Admin Access, running another time the command:

Check you proper install the tools.

Customize the values of your environment variables in the file [_environment_working_tables.sh](_environment_working_tables.sh), it's not tracked by git, pay attention to NOT commit it with your secrets.

## User Guide

Once configured the tools, you can export data from Argo, import that in this tool and start using it.

The [user guide](UserGuide.md) will show you the steps to configure the tool and to perform operations.
