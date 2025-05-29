# SRA Mysql Replication Plugin

```
This is a plugin for the SRA (Server Resource Analysis) system that monitors MySQL replication status. This plugin 
**could** work as standalone, but it's better to be used with SRA. Get the SRA from [GitHub](nchankov/sra).
```

The plugin monitors the MySQL replication status and reports if there is a problem with the replication. 
The script checks the following parameters:

1. **Slave_IO_Running** - if the slave IO thread is running
2. **Slave_SQL_Running** - if the slave SQL thread is running
3. **Seconds_Behind_Master** - how many seconds the slave is behind the master

If any of the parameters is not as expected, the plugin will report it using the configured channels.

## Configuration

Create a `.env` file in the plugin directory (copy `.env.sample` as a template)

## Activation

run the `activate.sh` script from the root SRA directory to activate the plugin:

```bash
./activate.sh mysql_replication
```
## Deactivation
To deactivate the plugin, run the `deactivate.sh` script from the root SRA directory:

```bash
./deactivate.sh mysql_replication
```
## Requirements
The plugin should be activated on a server with mysql client with passwordless access to localhost. The current version 
of the script works with MySQL 8. As "SHOW REPLICA STATUS" is not the same as the "SHOW SLAVE STATUS" command in other 
versions of the MySQL Server