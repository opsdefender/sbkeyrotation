# Check if Az.ServiceBus module already exists and install if not exists
if (-not (Get-Module -Name Az.ServiceBus -ListAvailable)) {
    Install-Module -Name Az.ServiceBus -Scope CurrentUser
}

Import-Module -Name Az.ServiceBus

# Set the Azure AD Tenant ID where the service principal is registered
$tenantId = " "

# # Set the Application ID (Client ID) of the service principal
# $appId = ""

# # Set the Application Secret (Client Secret) of the service principal
# $appSecret = ""

# Set the Subscription ID where the resources are located
$subscriptionId = " "

# Set the name of the Azure Service Bus Namespace where the topics are located
$serviceBusNamespaceName = " "


# Set the name of the Azure Key vault
$keyVaultName = " "

# Authenticate with the service principal
# $SecurePassword = ConvertTo-SecureString $appSecret -AsPlainText -Force
# $psCred = New-Object System.Management.Automation.PSCredential($appId, $SecurePassword)
# Connect-AzAccount -ServicePrincipal -Credential $psCred -Tenant $tenantId -Subscription $subscriptionId

# Get the Azure Service Bus Namespace object
$serviceBusNamespace = Get-AzServiceBusNamespace -Name $serviceBusNamespaceName

# Get all the Azure Service Bus Topics in the Namespace
$topics = Get-AzServiceBusTopic -ResourceGroupName $serviceBusNamespace.ResourceGroupName -NamespaceName $serviceBusNamespace.Name

# Loop through each Topic and regenerate the primary key of each authorization rule
foreach ($topic in $topics) {
    # Get all the authorization rules for the Topic
    $authorizationRules = Get-AzServiceBusAuthorizationRule -ResourceGroupName $serviceBusNamespace.ResourceGroupName -NamespaceName $serviceBusNamespace.Name -TopicName $topic.Name

    # Loop through each authorization rule and regenerate its primary key
    foreach ($authorizationRule in $authorizationRules) {
    $CurrentKey = Get-AzServiceBusKey -ResourceGroup $serviceBusNamespace.ResourceGroupName -NamespaceName $serviceBusNamespaceName -Name $authorizationRule.Name -TopicName $topic.Name

          $Secret = ConvertTo-SecureString -String $CurrentKey.PrimaryKey -AsPlainText -Force
          $secretName='primary'+$authorizationRule.Name
          Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -SecretValue $Secret
          $Secret = ConvertTo-SecureString -String $CurrentKey.SecondaryKey -AsPlainText -Force
          $secretName='second'+$authorizationRule.Name
          Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -SecretValue $Secret


        $regeneratedPrimaryKey = New-AzServiceBusKey -ResourceGroupName $serviceBusNamespace.ResourceGroupName -NamespaceName $serviceBusNamespace.Name -TopicName $topic.Name -AuthorizationRuleName $authorizationRule.Name -KeyType PrimaryKey
        $regeneratedSecondaryKey = New-AzServiceBusKey -ResourceGroupName $serviceBusNamespace.ResourceGroupName -NamespaceName $serviceBusNamespace.Name -TopicName $topic.Name -AuthorizationRuleName $authorizationRule.Name -KeyType SecondaryKey
        Write-Host "Regenerated primary and secondary keys for authorization rule $($authorizationRule.Name) in Topic $($topic.Name): Primary: $($regeneratedPrimaryKey.PrimaryKey), Secondary: $($regeneratedSecondaryKey.SecondaryKey)"
     
    $CurrentKey = Get-AzServiceBusKey -ResourceGroup $serviceBusNamespace.ResourceGroupName -NamespaceName $serviceBusNamespaceName -Name $authorizationRule.Name -TopicName $topic.Name

          $Secret = ConvertTo-SecureString -String $CurrentKey.PrimaryKey -AsPlainText -Force
          $secretName='primary'+$authorizationRule.Name
          Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -SecretValue $Secret
          $Secret = ConvertTo-SecureString -String $CurrentKey.SecondaryKey -AsPlainText -Force
          $secretName='second'+$authorizationRule.Name
          Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -SecretValue $Secret

    
    }
}