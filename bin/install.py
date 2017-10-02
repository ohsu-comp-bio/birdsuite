import sys
import os
import optparse
import re
import subprocess
from StringIO import StringIO

#LOOK IN BASE DIR, LOOK IN DATA
def main(argv = None):  
    if not argv:
        argv = sys.argv
    
    #ARG PARSING    
    parser = optparse.OptionParser(usage=__doc__)
    parser.add_option("-l", "--install-dir", dest="libdir",
                      help="""Directory that libraries will be installed, use if you do not have root access
                            You will need to set your PYTHONPATH environment variable for this procedure""")
    parser.add_option("-g", "--egg-dir",dest="eggdir", default=sys.path[0],
                      help="""Egg directory for scanning.""")
    parser.add_option("-e", "--easy-install", dest="easyinstalldir", 
                      help="""The path to easy_install, if it does not exist on the default path.""")
    parser.add_option("-s", "--script-dir", dest="scriptdir",
                      help="""Directory you would like to executeables to. Defaults to working directory when run""")
    
    dctOptions, lstArgs = parser.parse_args(argv)
    
    #BASE DIRECTORIES
    if dctOptions.scriptdir:
        script_dir = dctOptions.scriptdir
    else:
        script_dir = sys.path[0]
        
    #LOOK FOR CONFIG FILE
    dependencies = []
    config_file = findFiles(sys.path[0], re.compile("Install.cfg", re.IGNORECASE))
    if config_file:
        fConfig = open(config_file[0])
        print "Found Config File: " + config_file[0]
        for line in fConfig:
            dependencies.append(line)
            print "Found Dependency: " + line
        
    #EASYINSTALL
    if not dctOptions.easyinstalldir:
        
        print "INSTALLING SETUPTOOLS"
        print "\n------------------------------------------------\n"
        
        try:
            import ez_setup
        except:
            try:
                from data import ez_setup
            except:
                print "\nUnable to load SetupTools, please either install easy_install or have ez_setup.py in the same directory as this program\n"
                print "If you have easy_install already on your system, use --easy-install to define it's location"
                sys.exit(1)
                
        
        if not dctOptions.libdir:
            items = ["--script-dir=" + script_dir, "-U", "setuptools"]
        else:
            items = ["--script-dir=" + script_dir, "--install-dir=" + os.path.expanduser(dctOptions.libdir), "-U", "setuptools"]
        
        #CAPTURE OUTPUT FROM EZSETUP
        saved = sys.stdout
        net = StringIO()
        sys.stdout = net
        ez_setup.main(items)
        sys.stdout = saved
        net.seek(0)
        
        #SEARCH FOR INSTALLATION DIRECTORY OF EASY INSTALL
        p1 = re.compile('Installing easy_install script to', re.IGNORECASE)
        for line in net.readlines():
            print line
            m1 = p1.match(line)
            if m1:
                install_items = line.split()
                setattr(dctOptions, 'easyinstalldir', install_items[len(install_items)-1])
                break
    
    #FIND EGGS
    Eggs = findFiles(dctOptions.eggdir, re.compile("[.]egg", re.IGNORECASE))
    easyinstall = os.path.join(dctOptions.easyinstalldir, "easy_install")
    Eggs += dependencies
    
    #INSTALL EGGS
    for Egg in Eggs:
        print "\n------------------------------------------------\n"
        print "SETTING UP " + Egg + ":"
        try:
            if dctOptions.libdir:
                lstArgs = [easyinstall, "--script-dir=" + script_dir, "--install-dir=" + os.path.expanduser(dctOptions.libdir), "-U", Egg]
            else:
                lstArgs = [easyinstall, "--script-dir=" + script_dir, "-U", Egg]
            check_call(lstArgs)
            print "\n------------------------------------------------\n"
        except:
            print "\n------------------------------------------------\n"
            continue
        
def findFiles(folder_root, pattern):
    Files = []
    for root, dirs, files in os.walk(folder_root, False):
        for name in files:
            match = pattern.search(name)
            if match:
                Files.append(os.path.join(root, name))
    return Files

def check_call(lstArgs):
    retcode = subprocess.call(lstArgs)
    if retcode != 0:
        raise Exception("ERROR: exit status %d from command %s" % (retcode, " ".join(lstArgs)))

if __name__ == "__main__":
    main()