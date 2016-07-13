## Steps to Import Project in CloudConnect
- - - -
1.  Open CloudConnect application.
2.  In Menu Bar Select `File > Import`.
3.  Under Git choose Projects from Git. Click Next.
4.  Select Clone URI. Click Next.
5.  Use URI: `https://gitlab.com/just-capital/JCDP.git`.
6.  Provide Username and Password for authentication. Click Next.
7.  By default master branch should be selected. If not, select master branch. Click Next.
8.  Browse for Destination Directory:
    *   CloudConnect workspace folder is preferred.
    *   JCPD directory should be created inside the selected folder.
    *   Initial Branch should be set to master.
    *   Remote Name should be origin.
    *   Click Next.
9.  Select `Import existing projects`. Click Next.
10. By default **JCDP** folder should be selected. If not, then select **JCDP** folder.
11. Click Finish.


## Adding Commit Author Information in CloudConnect
- - - -
1.  In Menu Bar Select `CloudConnect > Preferences`.
2.  In Preferences Dialog Box Select `Team > Git > Configuration`.
3.  Choose `User Settings`.
4.  Click `Add Entry`.
    *   Enter Key: `user.name`.
    *   Enter Value: Enter Your Name.
    *   Click OK.
5.  Click `Add Entry`
    *   Enter Key: `user.email`.
    *   Enter Value: Enter Your Email Id.
    *   Click OK.
6.  Close Preferences Dialog Box.


## Accessing Git View in CloudConnect
- - - -
*   In Menu Bar Select `Window > Show View > Other`.
*   Choose Git Reflog, Git Repositories, and Git Staging.
*   In Git Staging View, author information should reflect the information provided previously.
    If not, then close the staging view and reopen it.
