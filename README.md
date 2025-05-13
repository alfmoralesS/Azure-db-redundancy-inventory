# 🔍 Azure-db-redundancy-inventory
This powershell script leverages the Azure CLI to inventory all Azure SQL Databases and Azure Managed Instances in your subscription. It organizes the databases by SQL server and resource group, and displays useful details such as service tier, current status, and redundancy type.

Ideal for Database Administrators, cloud administrators, DevOps engineers, or developers managing large-scale Azure environments.

----------------------------------------------------------------------------------------------------------------------------------------------------------------------

📋 Features
✅ Lists all Azure SQL Databases across your subscription
🗂️ Groups databases by their parent SQL server and resource group
📊 Displays database service tier, status, and zone redundancy in a clean table format
🔁 Uses standard CLI tools
🧩 Easily customizable for filtering, CSV export


----------------------------------------------------------------------------------------------------------------------------------------------------------------------


📦 Pre-requisites
To use this script, you'll need the following installed:

* Git
[Install Instructions](https://git-scm.com/downloads)

* Azure CLI
[Install Instructions](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)

* Login to your Azure account before running the script:

```bash
az login
```

* ✅ Minimum Role Required To run your script successfully, a user needs at least the Reader role at the subscription level plus visibility into the SQL resources.

Specifically, they need permission to:

- List Azure resources (for az resource list)
- List SQL servers and databases and Managed Instances

----------------------------------------------------------------------------------------------------------------------------------------------------------------------

🚀 Getting Started

🔧 1. Clone the repository

```bash
git clone https://github.com/alfmoralesS/Azure-db-redundancy-inventory.git
```


▶️ 2. Run the script

```bash
cd Azure-db-redundancy-inventory
```
```bash
cd scripts
```
```bash
az login
```
```bash
.\list-azure-sql-databases.ps1
```

Output result

![image](https://github.com/user-attachments/assets/c7bae131-36b6-4d24-aa02-f5f9ccd2ff9d)



----------------------------------------------------------------------------------------------------------------------------------------------------------------------

🖥️ Example Output

![image](https://github.com/user-attachments/assets/56fb3d27-54cb-428f-a68d-9892e0d1e89e)

