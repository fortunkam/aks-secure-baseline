Set-ExecutionPolicy Bypass -Scope Process -Force

Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

$Packages = @( `
            [pscustomobject]@{ name='curl';version='latest' },`
            [pscustomobject]@{ name='azure-cli';version='latest' },`
            [pscustomobject]@{ name='terraform';version='0.12.24' },`
            [pscustomobject]@{ name='microsoft-edge';version='latest' },`
            [pscustomobject]@{ name='python';version='latest' },`
            [pscustomobject]@{ name='kubernetes-cli';version='latest' },`
            [pscustomobject]@{ name='kubernetes-helm';version='latest' },`
            [pscustomobject]@{ name='putty';version='latest' }`
            )

Foreach ($Package in $Packages)
{
    if($Package.version -ne 'latest')
    {
        choco install $Package.name --version $Package.version -y
    }
    else {
        choco install $Package.name -y
    }
}

#Install-Module -Name Az -AllowClobber -Scope AllUsers -Force

Write-Host "Script Complete"

exit 0
