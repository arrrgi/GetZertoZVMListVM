# GetZertoZVMListVM

_**CAUTION: This tool is still in beta and has not been tested yet**_

## Description
Powershell utility to export CSV list of VM's managed by a Zerto ZVM with additional details.

Per VM output provides:

- VM Name
- VPG association
- Used Storage in Megabytes
- Source Site
- Destination Site
- VPG Priority numeric value

## Requirements

To execute this script, you will need to allow PowerShell to execute unsigned scripts and have network access to the target ZVM API port, typically **9669/tcp**. No Zerto CMDlets or additional utility libraries are required.

## Usage

Executing this script will prompt for:

1. The IP address of the ZVM to connect to for REST API - this will default to **localhost** if no address is entered, making this script suitable to run on the ZVM
2. The TCP port number to connect to on the ZVM 
3. Domain credentials for a valid account with permissions to the Zerto ZVM
4. A folder location to save the CSV file output

### TODO

- [ ] check TCP connection can be established and offer to try an alternate if the connection fails
- [ ] allow CSV output to be saved with alternate filename