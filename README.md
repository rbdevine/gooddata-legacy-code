## Downloading Java
- - - -
1.  Open browser. Go to `https://java.com/en/download/`.
2.  Click `Free Java Download`. 
3.  Chrome users may encounter an alert message. If so, click `Agree and Start Free Download`.
4.  Install Java.


## Downloading JCBC Driver
- - - -
1.  Go to `https://developer.gooddata.com/tools`.
2.  Scroll down to 'Agile Data Warehousing Service'. Click 'Download Now' next to 'Download JDBC Driver'.
3.  Open zip file to extract .jar file, if machine does not do so automatically.


## Downloading DbVisualizer
- - - -
1.  Go to `https://www.dbvis.com/download/`.
2.  Download 'Mac OS X (setup installer)', under 'Without Java VM'.
3.  Double click 'DbVisualizer Installer'. A pop up will appear. Click the Open button.
4.  In the installer, accept default fields by hitting Next in each window.
5.  Once done, **New Connection Wizard** pop up will appear. Click Cancel.
6.  Now in DbVisualizer application, go to `Tools > Driver Manager`.
7.  Click top left icon to create a new driver.
8.  Under 'Driver File Paths', click the Open File folder icon on the far right.
9.  In Downloads, select `dss-jdbc-driver-2.8.1.jar` file. Click Choose.
10. Under 'Driver Settings', name: `GoodData ADS`. Close window.
11. Click the 'green plus' icon (to the left of 'green plus, folder' icon). Click 'No Wizard'.
12. Name the connection: `GoodData Dev`.


## Downloading CloudConnect
- - - -
1.  
2.  
3.  
4.  



## For existing CloudConnect users
- - - -
1.  In Finder, open Home Directory. Create folder 'Code'.
2.  Open CloudConnect application. `File > Switch Workspace > Other`.
3.  Use Workspace: `/Users/[your OSX username]/Code/cloudconnect`. Click OK.

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
