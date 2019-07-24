# FastlyCTL [![Gem Version](https://img.shields.io/gem/v/fastlyctl.svg)](https://rubygems.org/gems/fastlyctl)

CLI for manipulating objects with [Fastly's API](https://docs.fastly.com/api/config).

## Dependencies

 * Ruby 2.2+
 * diff
 * Bundler 

## Installation

```
gem install fastlyctl
```

## Workflow

Basic setup for a service:

```
$ fastlyctl download --service 72rdJo8ipqaHRFYnn12G2q
No VCLs on this service, however a folder has been created. Create VCLs in this folder and upload.
$ cd Sandbox\ -\ 72rdJo8ipqaHRFYnn12G2q/
$ fastlyctl skeleton
Boilerplate written to main.vcl.
$ fastlyctl upload
VCL main does not currently exist on the service, would you like to create it? y
[You will see a diff here for the new VCL]
Given the above diff, are you sure you want to upload your changes? y
main uploaded to 72rdJo8ipqaHRFYnn12G2q
VCL(s) have been uploaded to version 286 and validated.
$ fastlyctl activate
Version 286 on 72rdJo8ipqaHRFYnn12G2q activated.
```

Once you are past this point you can edit your VCLs and use the commmand `fastlyctl upload && fastlyctl activate`. The service ID will be automatically inferred from the folder you are currently in. In fact, all commands will attempt to assume the service ID of the current directory if it is relevant.

You may find it useful to keep a Github repo with one folder created by this command for each service. This way you can version your VCL files.

## Command Reference

### acl

Manipulate ACLs on a service.

Usage:

```
fastlyctl acl [action] [acl_name] [ip]
```

Available Actions:
  * create: Creates a new ACL. `ip` parameter is omitted.
  * delete: Deletes an ACL. `ip` parameter is omitted.
  * list: Lists all ACLs. `ip` parameter is omitted.
  * add: Adds a new IP or Subnet to an ACL.
  * remove: Removes an IP or Subnet from an ACL.
  * list_ips: Lists all IPs/Subnets in an ACL.
  * sync: Synchronizes an ACL with a comma separated list of IPs. Will create or delete ACL entries as needed.
  * bulk_add: Adds multiple items to an ACL. See [this documentation](https://docs.fastly.com/api/config#acl_entry_c352ca5aee49b7898535cce488e3ba82) for information on the format.

Flags:
  * --s: The service ID to use. Current working directory is assumed.
  * --v: The version to use. Latest writable version is assumed.

### activate

Activates a service version. 

Usage:

```
fastlyctl activate
```

Flags: 
  * --s: The service ID to activate. Current working directory is assumed.
  * --v: The version to activate. Latest writable version is assumed.
  * --c: Adds a comment to the version.
 
### clone

Clones a service version to a new version on another service. 

Usage: 

```
fastlyctl clone [sid_1] [sid_2]
```

Flags
  * --v: The version to clone. The currently active version is assumed.
  * --sl: Skip logging objects during the clone.

### copy

Copies an object from one service to another

Usage: 

```
fastlyctl copy [sid_1] [sid_2] [obj_type] [obj_name]
```

Flags
  * --v1: The version to clone from on the source service. The currently active version is assumed.
  * --v2: The version to clone to on the target service. Latest writable version is assumed.

### create_service

Creates a new service.

Usage:

```
fastlyctl create_service [name]
```

### dictionary

Manipulate edge dictionaries on a service.

Usage:

```
fastlyctl dictionary [action] [dictionary_name] [key] [value]
```

Available Actions:
  * create: Creates a new dictionary. Key and value parameters are omitted.
  * delete: Deletes a dictionary. Key and value parameters are omitted.
  * list: Lists all dictionaries. Key and value parameters are omitted.
  * upsert: Inserts a new item into a dictionary. If the item exists, its value will be updated.
  * remove: Removes an item from a dictionary.
  * list_items: Lists all items in a dictionary.
  * sync: Synchronizes a dictionary with a comma separated list of key/value pairs. Will create, delete, or update keys as needed. Separate keys and values with `=` or `:`.
  * bulk_add: Adds multiple items to a dictionary. See [this documentation](https://docs.fastly.com/api/config#dictionary_item_dc826ce1255a7c42bc48eb204eed8f7f) for information on the format.

Flags:
  * --s: The service ID to use. Current working directory is assumed.
  * --v: The version to use. Latest writable version is assumed.
  * --wo: When used with `create`, flags the dictionary as write-only.

### diff

Provides a diff of two service versions. You may optionally specify which two service IDs and which two versions to diff. If you do not provide service IDs, the context of the current working directory is assumed. 

 * If you provide no service IDs, the service ID of the working directory is assumed.
  * If you do not specify versions, active VCL will be diffed with local VCL in the current directory.
  * If you specify version 1 but not version 2, version 1 will be diffed with local VCL
  * If you specify both versions, they will be diffed with each other.
 * If you provide service 1 but not service 2, service 2 will be assumed from the current working directory.
 * Regardless of how you specify services, if service 1 and service 2 are _different_, the versions will default to the active versions instead of local VCL.

Usage:

```
fastlyctl diff
```

  * --s1: The first service to diff against.
  * --v1: The version to diff.
  * --s2: The second service to diff against.
  * --v2: The second service's version to diff.
  * --g: Diffs the generated VCL instead of the custom VCL.

### domain

Manipulate domains on a service.

Usage:

```
fastlyctl domain [action] [hostname]
```

Available Actions:
  * create: Create a new domain.
  * delete: Delete a domain.
  * list: List all domains.
  * check: Check the DNS of all domains on a service and print the status.

Flags:
  * --s: The service ID to use. Current working directory is assumed.
  * --v: The version to use. Latest writable version is assumed.

### download

Download the VCLs and snippets on a service. If you are not in a service directory already, a new directory will be created.

Usage:

```
fastlyctl download
```

Flags:
  * --s: The service ID to download. Current working directory is assumed.
  * --v: The version to download. The currently active version is assumed.

### logging 

Manage the realtime logging configuration for a service, as well as checking on the status of the logging endpoints.  Logging requires a subcommand of either `status` or the name of a logging provider listed below.

##### status
Usage:

```
fastlyctl logging status
```

Flags:

  * `--s / --service`  Service ID to use

##### BigQuery

Usage: 
```
fastlyctl logging bigquery ACTION [FLAGS]
```

Supported ACTIONs are `create`, `update`, `show`, `delete`, `list` 

Flags:

  * `--s / --service`  Service ID to use  (required) 
  * `--v / --version`  Version of the service to use 
  * `--n / --name`     Current name of the logging configuration
  * `--nn / --new-name`  Used for the update method to rename a configuration
  * `--ff / --format-file`  Path to the file containing the JSON Representation of the logline, must match BigQuery schema
  * `--u / --user`     Google Cloud Service Account Email
  * `--scf / --secret-key-file` Path to the file that contains the Google Cloud Account secret key
  * `--p / --project-id` Google Cloud Project ID
  * `--d / --dataset` Google BigQuery dataset 
  * `--t / --table` Google BigQuery table
  * `--ts / --template-suffix` Google table name suffix 
  * `--pl / --placement` Placement of the logging  call, can be none or waf_debug.  Not required and no default
  * `--r / --response-condition` When to execute, if empty it is always


To print the full list of the options required type the command:

```
fastlyctl logging bigquery --help
```


### login

Login to the Fastly app and create an API token. This token will be stored in your home directory for the CLI to use for all requests.

If your origanization uses SSO to login to Fastly, this command will prompt you to create a token and save it to `~/.fastlyctl_token` on your computer. You may also create the token and save it to the fastlyctl_token file without using the `fastlyctl login` command at all.

Usage:

```
fastlyctl login
```

### open

Opens the Fastly app for a service for a hostname of a service ID.

Usage:

```
fastlyctl open [hostname]
```

Flags:
  * --s: The service ID to open. Current working directory is assumed.

### purge_all

Perform a purge all on a service.

Usage:

```
fastlyctl purge_all
```
Flags:
  * --s: The service ID to purge. Current working directory is assumed.

### skeleton

Download the VCL boilerplate into the current directory.

Usage

```
fastlyctl skeleton [local_filename]
```

### snippet

Manipulate snippets on a service.

Usage:

```
fastlyctl snippet [action] [snippet_name]
```

Available Actions:
  * create: Create a new snippet
  * upload: Upload a specific dynamic snippet
  * delete: Delete a snippet
  * list: List all snippets

Flags:
  * --s: The service ID to use. Current working directory is assumed.
  * --v: The version to use. Latest writable version is assumed.
  * --t: The type of snippet to create. Types are named after subroutines--for instance a snippet for `vcl_recv` would be of type `recv`. Use `init` for snippets outside of a subroutine.
  * --d: When used with the create command, specifies that the snippet should be dynamic.

### token

Manipulate tokens for an account.

Usage:

```
fastlyctl token [action]
```

Available Actions:
  * create: Create a token
  * delete: Delete a token
  * list: List all tokens on the account

Flags:
  * --scope: Scope of the token. See Fastly's public API documentation for a [list of scopes](https://docs.fastly.com/api/auth#scopes).
  * --s: The services to restrict this token to. The token cannot be used to modify any services not on this list if this option is specified.

### upload

Upload VCLs and snippets to a service.

Usage:

```
fastlyctl upload
```

Flags:
  * --v: The version to upload the VCL to. The latest writable version is assumed.
  * --c: Adds a comment to the version.

### watch

Watch live stats on a service.

Usage:

```
fastlyctl watch [pop]
```

Flags:
  * --s: The service ID to watch. Current working directory is assumed.

## Contributing

Submit a pull request. Don't break anything.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

