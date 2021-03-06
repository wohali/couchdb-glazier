# Glazier

Glazier is a set of batch files, scripts and toolchains designed to
ease building CouchDB on Windows. It's as fully automated as
possible, with most of the effort required only once.

Glazier uses the MS Visual Studio 2013 toolchain as much as possible,
to ensure a quality Windows experience and to execute all binary
dependencies within the same runtime.

We hope Glazier simplifies using Erlang and CouchDB for you, giving
a consistent, repeatable build environment.


# Base Requirements

- 64-bit Windows 7 or 8.1. *As of CouchDB 2.0 we only support a 64-bit build of CouchDB*.
  - We like 64-bit Windows 7, 8.1 or 10 Enterprise N (missing Media Player, etc.) from MSDN.
- If prompted, reboot after installing the .NET framework.
- [Visual Studio 2013 x64 Community Edition](https://www.visualstudio.com/en-us/news/vs2013-community-vs.aspx) installed on the *C: drive*
- [Chocolatey](https://chocolatey.org). From an *administrative* __cmd.exe__ command prompt:

```
@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin
```

- Apply Windows Updates and reboot until no more updates appear.
- If using a VM, shutdown and snapshot your VM at this point.

# Install Pre-requisites

## Clean Package Installs with Chocolatey, cyg-get and pip

These packages install silently, without intervention. Cut and paste them
into a command prompt, leave it running, and open another one for the next
section.

    cinst -y git 7zip.commandline StrawberryPerl nasm cyg-get wixtoolset python aria2 nodejs.install nssm
 
*NOTE*: There is a bug presently in the Chocolatey cygwin package. After the `cinst` above, download the cygwin installer from https://cygwin.com/, rename the installer to cygwinsetup.exe, and move the installer to `C:\tools\cygwin`. This will enable the cyg-get line below.

    cyg-get p7zip autoconf binutils bison gcc-code gcc-g++ gdb git libtool make patchutils pkg-config readline file renameutils socat time tree util-linux wget
    C:\ProgramData\chocolatey\lib\python3\tools\Scripts\pip install sphinx docutils pygments

*Note: Do NOT install curl or help2man inside CygWin!*

## Mozilla build
Fetch the latest Mozilla Build version from
https://wiki.mozilla.org/MozillaBuild and install to c:\mozilla-build.

## Make a new prompt shortcut

Make a new shortcut on the desktop. The location should be:

    cmd.exe /E:ON /V:ON /T:1F /K ""C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat"" amd64 && color 1f

Name it something like "Couch SDK Prompt." 
Right-click on the icon, click the `advanced`
button, and tick the `Run as Administrator` button.

I suggest you pin it to the Start menu. We'll use this all the time.

Let's confirm we have the right bits with
`where cl mc mt link lc rc nmake`:

    C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\bin\amd64\cl.exe
    C:\Program Files (x86)\Windows Kits\8.1\bin\x64\mc.exe
    C:\Program Files (x86)\Windows Kits\8.1\bin\x86\mc.exe
    C:\Program Files (x86)\Windows Kits\8.1\bin\x64\mt.exe
    C:\Program Files (x86)\Windows Kits\8.1\bin\x86\mt.exe
    C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\bin\amd64\link.exe
    C:\Program Files (x86)\Microsoft SDKs\Windows\v8.1A\bin\NETFX 4.5.1 Tools\x64\lc.exe
    C:\Program Files (x86)\Windows Kits\8.1\bin\x64\rc.exe
    C:\Program Files (x86)\Windows Kits\8.1\bin\x86\rc.exe
    C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\bin\amd64\nmake.exe

Stop here if your results are not *identical*. If you are unable to
reproduce these results, please open an issue on this repository for
assistance.

## Set up required convenience links & environment variable

    pushd c:\relax
    rd /s/q SDK VC nasm inno5 nsis strawberry
	mklink /j c:\relax\SDK "c:\Program Files (x86)\Windows Kits\8.1"
	mklink /j c:\relax\VC "C:\Program Files (x86)\Microsoft Visual Studio 12.0"
	mklink /j nasm "c:\Program Files\NASM"
	:: this one is for the picky software packagers
	mklink /j c:\openssl c:\relax\openssl
    :: environment variable for future scripts
	setx RELAX c:\relax

Close all open command prompts. Now we're ready to go!

# Building CouchDB Pre-requisites

## Downloading glazier and dependency sources

Open a `Couch SDK Prompt`:

	cd c:\relax
    git config --global core.autocrlf input
	git clone https://github.com/dch/glazier.git
    :: or git clone git://github.com/dch/glazier.git if you are a developer
	mklink /j c:\relax\bin c:\relax\glazier\bin
	path=c:\relax\bin;%PATH%;
	aria2c --force-sequential=false --max-connection-per-server=5 --check-certificate=false --auto-file-renaming=false --allow-overwrite=true --input-file=glazier/downloads.md --max-concurrent-downloads=5 --dir=bits --save-session=bits/a2session.txt
    color 1f

## Build & Test 64-bit OpenSSL

	cd %RELAX%\bin && build_openssl.cmd

## Build 64-bit libcurl

    cd %RELAX%\bin && build_curl.cmd

## Build 64-bit ICU

	cd %RELAX%\bin && build_icu.cmd

## Start a UNIX-friendly shell with MS compilers

1. Start your `SDK prompt` as above
2. Launch a cygwin erl-ified shell via `c:\relax\bin\shell.cmd`
3. Select 17.5 unless you know what you are doing!
4. Select `b for bash prompt`.

For more detail on why this is necessary, see
[UNIX-friendly shell details](#unix-friendly-shell-details) below.

## Unpack, configure and build Erlang/OTP 17.5

    ln -s /cygdrive/c/relax /relax
	cd .. && tar xzf /relax/bits/otp_src_17.5.tar.gz
	cd $ERL_TOP
	echo "skipping gs" > lib/gs/SKIP
    echo "skipping wx" > lib/wx/SKIP
	echo "skipping ic" > lib/ic/SKIP
	echo "skipping jinterface" > lib/jinterface/SKIP
	erl_config.sh
    :: Ensure OpenSSL is found by the configure script.
    erl_build.sh
    exit
    exit

## Build Spidermonkey JavaScript 1.8.5

Spidermonkey needs to be compiled with the Mozilla Build chain.
To build it with VS2013 requires a few patches.

Start by launching a fresh `SDK prompt`.

    call c:\mozilla-build\start-shell-msvc2013-x64.bat
    which cl lc link mt rc make
    # /c/Program Files (x86)/Microsoft Visual Studio 12.0/VC/BIN/amd64/cl.exe
    # /c/Program Files (x86)/Microsoft SDKs/Windows/v8.1A/bin/NETFX 4.5.1 Tools/x64/lc.exe
    # /c/Program Files (x86)/Microsoft Visual Studio 12.0/VC/BIN/amd64/link.exe
    # /c/Program Files (x86)/Windows Kits/8.1/bin/x64/mt.exe
    # /c/Program Files (x86)/Windows Kits/8.1/bin/x64/rc.exe
    # /local/bin/make.exe
    cd /c/relax
    tar xzf bits/js185-1.0.0.tar.gz
    patch -p0 </c/relax/glazier/bits/js185-msvc2013.patch
    cd js-1.8.5/js/src
    autoconf-2.13
    ./configure --enable-static --enable-shared-js --disable-debug-symbols --disable-debug --disable-debugger-info-modules --target=x86_64-pc-mingw32 --host=x86_64-pc-mingw32
    make
    ## optional, takes a while, math-jit-tests will fail
    ## for more detail see https://bugzilla.mozilla.org/show_bug.cgi?id=1076670
    ## TODO: apply fix as part of patch
    ## also one jsapi test has been disabled that crashes, call we don't use
    make check
    exit
    exit

## Building CouchDB itself

Start a new `SDK prompt`, then run `c:\relax\bin\shell.cmd`.
Select `Erlang 17.5` and `w for a Windows prompt`.

    cd \relax && git clone http://git-wip-us.apache.org/repos/asf/couchdb.git
    cd couchdb
    # optional, use suitable tag here
    # git checkout --track origin/2.0.x
    git clean -fdx && git reset --hard
    powershell -ExecutionPolicy Bypass .\configure.ps1 -WithCurl
    make -f Makefile.win check

This will build a development version of CouchDB runnable via

    python dev\run <-n1> <--with-admin-party-please>

To build a self-contained CouchDB installation (also known as an Erlang
_release_), after running the above use:

    make -f Makefile.win release

To build an installer using WiX to creates a full Windows .msi:

    cd \relax\glazier
    bin\build_installer.cmd

# Appendix

## Why Glazier?

@dch first got involved with CouchDB around 0.7. Only having a low-spec Windows
PC to develop on, and no CouchDB Cloud provider being available, he tried
to build CouchDB himself. It was hard going, and most of the frustration was
trying to get the core Erlang environment set up and compiling without needing
to buy Microsoft's expensive but excellent Visual Studio tools. Once
Erlang was working he found many of the pre-requisite modules such as cURL,
Zlib, OpenSSL, Mozilla's SpiderMonkey JavaScript engine, and IBM's ICU were
not available at a consistent compiler and VC runtime release.

There is a branch of glazier that has been used to build each CouchDB release.

## UNIX-friendly shell details

Our goal is to get the path set up in this order:

1. erlang and couchdb build helper scripts
2. Microsoft VC compiler, linker, etc from Windows SDK
3. cygwin path for other build tools like make, autoconf, libtool
4. the remaining windows system path

It seems this is a challenge for most environments, so `glazier` just
assumes you're using [chocolatey] and takes care of the rest.

Alternatively, you can launch your own cmd prompt, and ensure that your system
path is correct first in the win32 side before starting cygwin. Once in cygwin
go to the root of where you installed erlang, and run the Erlang/OTP script:

        eval `./otp_build env_win32 x64`
        echo $PATH | /bin/sed 's/:/\n/g'
        which cl link mc lc mt nmake rc

Confirm that output of `which` returns only MS versions from VC++ or the SDK.
This is critical and if not correct will cause confusing errors much later on.
Overall, the desired order for your $PATH is:

- Erlang build helper scripts
- Visual C++ / .NET framework / SDK
- Ancillary Erlang and CouchDB packaging tools
- Usual cygwin unix tools such as make, gcc
- Ancillary glazier/relax tools for building dependent libraries
- Usual Windows folders `%windir%;%windir%\system32` etc
- Various settings form the `otp_build` script

More details are at [erlang INSTALL-Win32.md on github](https://github.com/erlang/otp/blob/master/HOWTO/INSTALL-WIN32.md)
