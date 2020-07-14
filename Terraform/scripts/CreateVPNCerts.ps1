# Run this script before the terraform script
# It will generate a new cert suitable for a P2S VPN
# It also imports the cert to the current user store.

$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
-Subject "CN=P2SVPNRootCert" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

New-SelfSignedCertificate -Type Custom -DnsName P2SVPNClientCert -KeySpec Signature `
-Subject "CN=P2SVPNClientCert" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" `
-Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")

Export-Certificate -Cert $cert -FilePath "P2SVPNRootCert.cer" -Type CERT

$certFile = 'P2SVPNRootCert.cer'

$content = @(
    '-----BEGIN CERTIFICATE-----'
    [System.Convert]::ToBase64String($cert.RawData, 'InsertLineBreaks')
    '-----END CERTIFICATE-----'
)

$content | Out-File -FilePath $certFile -Encoding UTF8