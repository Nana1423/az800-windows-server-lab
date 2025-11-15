# Lab 03 — Managing Windows Server with Windows Admin Center

## Introduction

This lab focuses on managing Windows Server in a hybrid environment by leveraging **Windows Admin Center (WAC)** as the primary administrative tool. Through hands-on tasks, I learned how to install WAC, connect servers for remote administration, configure extensions, and validate remote management capabilities all essential skills for modern Windows Server hybrid administration.

## Objetives

In this lab, I worked with several key AZ-800 skills:

- Installing and configuring Windows Admin Center.
- Adding on-premises servers for remote administration.
- Configuring and using WAC extensions such as DNS.
- Managing servers using Remote PowerShell and Remote Desktop via WAC.
- Validating and troubleshooting hybrid management connectivity.

## Steps Performed

To make this lab more interesting, I decided to expose my Windows Admin Center (WAC) endpoint using my custom domain **engineerleite.com**.  
This required generating a valid SSL certificate, so I used **win-acme** to issue a free 60-day TLS certificate.

1. **Identified my public IP address**  
   This was required so I could configure DNS and ensure external access to the WAC endpoint.

2. **Created an A record on my DNS provider**  
   I mapped **sea-svr1.engineerleite.com** to my public IP, since WAC would run on SEA-SVR1.

3. **Configured internal name resolution**  
   SEA-DC1 also needed to resolve *sea-svr1.engineerleite.com*.  
   I added a corresponding entry pointing to the public IP, ensuring consistent resolution from inside the lab network.

4. **Issued an SSL certificate using win-acme**  
   I selected this tool because it is free and supports automated Let’s Encrypt certificate creation.

5. **Installed Windows Admin Center using the certificate’s thumbprint**  
   During installation, I specified the generated certificate so WAC could serve HTTPS correctly.

6. **Verified WAC was accessible**  
   WAC opened successfully.  
   I still received a minor security warning—some internal WAC calls use HTTP, which makes the browser treat the connection as partially non-secure, even though the certificate itself was valid.

7. **Added additional servers to WAC**  
   Once WAC was running, I onboarded the remaining servers in my environment.

8. **Configured proper authentication for extension management**  
   While attempting to install extensions, I learned WAC requires a **domain admin**-level account.  
   I created a dedicated user **WACUser**, assigned the correct administrative roles, and used it for management operations.

9. **Installed the DNS extension**  
   Using WACUser, I accessed the Extensions Marketplace and successfully installed the DNS extension to manage SEA-DC1 remotely.

10. **Tested PowerShell remoting through WAC**  
   With WACUser, I used WAC’s PowerShell module to inspect services on SEA-SVR1, confirming successful remote administration.

## Troubleshooting / Errors Encountered

### WAC Installation Issues  
**Error:**  
`Register-WACLocalCredSSP: Failed to register CredSSP session configuration`  

**Cause:**  
This occurred when trying to install WAC on a server that was also running ADDS. CredSSP registration failed due to local security policy restrictions in domain controllers.

**Solution:**  
I installed WAC on a non-ADDS server.  
This completely resolved the issue.

---

### Certificate Common Name (CN) Mismatch  
**Symptom:**  
When accessing `https://sea-svr1.engineerleite.com/`, the browser displayed:  
`ERR_CERT_COMMON_NAME_INVALID`.

**Cause:**  
The certificate was originally generated for **wac.engineerleite.com**, but WAC automatically binds itself to the server’s hostname (**sea-svr1**).  
Because the hostname didn’t match the certificate CN, the browser flagged the connection as invalid.

**Solution:**  
Generate a new certificate specifically for:  
`sea-svr1.engineerleite.com`.

---

### PowerShell Remote Session Connection Issues  
**Error:**  
`WinRM cannot process the request. ErrorCode 0x8009030e`  

**Cause:**  
Trying to perform remote PowerShell operations using a **local account**.  
CredSSP/Kerberos does not support multi-hop authentication with non-domain accounts.

**Solution:**  
Create a **domain user** with adequate administrative permissions.  
Only domain accounts can authenticate and perform successful remote connections across multiple servers.