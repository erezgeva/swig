

# <a name="Windows"></a> 3 Getting started on Windows 

<!-- INDEX -->

<!-- INDEX -->

This chapter describes SWIG usage on Microsoft Windows. 
Installing SWIG and running the examples is covered as well as building the SWIG executable.
Usage within the Unix like environments MinGW and Cygwin is also detailed.

## <a name="Windows_installation"></a> 3.1 Installation on Windows

SWIG does not come with the usual Windows type installation program, however it is quite easy to get started. The main steps are:

- Download the swigwin zip package from the [SWIG website](https://www.swig.org) and unzip into a directory. This is all that needs downloading for the Windows platform.
- Set environment variables as described in the [SWIG Windows Examples](#Windows_examples) section in order to run examples using Visual C++.

### <a name="Windows_executable"></a> 3.1.1 Windows Executable

The swigwin distribution contains the SWIG Windows 64-bit executable, swig.exe, which will only run on 64-bit versions of Windows.
If you want to build your own swig.exe have a look at [Building swig.exe on Windows](#Windows_swig_exe).

## <a name="Windows_examples"></a> 3.2 SWIG Windows Examples

Microsoft Visual C++ is used for compiling and linking SWIG's output on Windows for some languages.
However, MinGW and gcc is often the only supported toolchain for a number of target languages.
The Examples directory has a few Visual C++ project files (.vcxproj files) where the target languages are known to work with Visual C++.
These were produced by Visual Studio 2019.
Newer versions of Visual Studio, such as Visual Studio 2022, are able to open and convert these project files if necessary.
Each C# example comes with a Visual Studio 2019 solution in addition to the .vcxproj file the C# (.csproj) project file.
The project files have been set up to execute SWIG in a custom build rule for the SWIG interface (.i) file. 
Alternatively run the [examples using Cygwin](#Windows_examples_cygwin).

More information on each of the examples is available with the examples distributed with SWIG (Examples/index.html).

### <a name="Windows_visual_studio"></a> 3.2.1 Instructions for using the Examples with Visual Studio

Ensure the SWIG executable is as supplied in the SWIG root directory in order for the examples to work. 
Most languages require some environment variables to be set **before** running Visual C++. 
Note that Visual Studio must be re-started to pick up any changes in environment variables. 
Open up an example .vcxproj file or .sln file, Visual Studio will prompt you to upgrade the project if necessary.
Ensure the Release build is selected then do a Rebuild Solution from the Build menu.
The required environment variables are displayed with their current values during the build.

The list of required environment variables for each module language is also listed below.
They are usually set from the Control Panel and System properties, but this depends on which flavour of Windows you are running.
If you don't want to use environment variables then change all occurrences of the environment variables in the .dsp files with hard coded values.
If you are interested in how the project files are set up there is explanatory information in some of the language module's documentation.

#### <a name="Windows_csharp"></a> 3.2.1.1 C#

The C# examples do not require any environment variables to be set as a C# project file is included.
Just open up the .sln solution file in Visual Studio 2019 or later, select Release Build, and do a Rebuild Solution from the Build menu.
The accompanying C# and C++ project files are automatically used by the solution file.

#### <a name="Windows_java"></a> 3.2.1.2 Java

**`JAVA_INCLUDE`** : Set this to the directory containing jni.h

**`JAVA_BIN`** : Set this to the bin directory containing javac.exe

Example using the openjdk package installed in a Conda environment:

```
JAVA_INCLUDE: C:\miniconda3\envs\java\Library\lib\jvm\include

JAVA_BIN: C:\miniconda3\envs\java\Library\lib\jvm\bin
```

#### <a name="Windows_python"></a> 3.2.1.3 Python

**`PYTHON_INCLUDE`** : Set this to the directory that contains Python.h

**`PYTHON_LIB`** : Set this to the Python library including path for linking

Example using Python 3.13 installed in a Conda environment:

```
PYTHON_INCLUDE: C:\miniconda3\envs\python\include

PYTHON_LIB: C:\miniconda3\envs\python\libs\python313.lib
```

#### <a name="Windows_tcl"></a> 3.2.1.4 TCL

**`TCL_INCLUDE`** : Set this to the directory containing tcl.h

**`TCL_LIB`** : Set this to the TCL library including path for linking

Example using ActiveTcl 8.6

```
TCL_INCLUDE: C:\ActiveTcl\include

TCL_LIB: C:\ActiveTcl\lib\tcl86t.lib
```

### <a name="Windows_other_compilers"></a> 3.2.2 Instructions for using the Examples with other compilers

If you do not have access to Visual C++ you will have to set up project files / Makefiles for your chosen compiler. There is a section in each of the language modules detailing what needs setting up using Visual C++ which may be of some guidance. Alternatively you may want to use Cygwin as described in the following section.

## <a name="Windows_swig_exe"></a> 3.3 Building swig.exe on Windows

The SWIG distribution provides a pre-built swig.exe and so it is not necessary for users to build the SWIG executable.
However, this section is provided for those that want to modify the SWIG source code in a Windows environment. 
Normally this is not needed, so most people will want to ignore this section.

There are various ways to build the SWIG executable including [CMake](https://cmake.org/) which is able to generate project files for building with [Visual Studio](https://visualstudio.microsoft.com/) [MSVC](https://docs.microsoft.com/cpp/).

SWIG can also be compiled and run using [MSYS2](https://www.msys2.org/) with [MinGW-w64](https://www.mingw-w64.org/), [Cygwin](https://www.cygwin.com) or [MinGW](https://osdn.net/projects/mingw/), all of which provide a Unix like front end to Windows and comes free with the [GCC](https://gcc.gnu.org/) C/C++ compiler.

SWIG can also be compiled with MSYS2 using MSVC and SWIG [MSVC wrapper](https://github.com/swig/cccl).

### <a name="Windows_cmake"></a> 3.3.1 Building swig.exe using CMake

SWIG can be built using [CMake](https://cmake.org/) and Visual Studio rather than autotools. As with the other approaches to 
building SWIG the dependencies need to be installed. The steps below are one of a number of ways of installing the dependencies without requiring Cygwin or MinGW.
For fully working build steps always check the Continuous Integration (CI) setups currently detailed in the [GitHub Actions YAML file](https://github.com/swig/swig/tree/master/.github/workflows/cmake.yml).

1. Install Nuget from [https://www.nuget.org/downloads](https://www.nuget.org/downloads) (v6.0.0 is used in this example, and installed to `C:\Tools`). Nuget is the package manager
        for .NET, but allows us to easily install [CMake](https://cmake.org/) and other dependencies required by SWIG.
1. Install [CMake-win64 Nuget package](https://www.nuget.org/packages/CMake-win64/) using the following command: `C:\Tools\nuget install CMake-win64 -Version 3.15.5 -OutputDirectory C:\Tools\CMake`
        Using PowerShell the equivalent syntax is: `& "C:\Tools\nuget" install CMake-win64 -Version 3.15.5 -OutputDirectory C:\Tools\CMake`
        Alternatively you can download CMake from [https://cmake.org/download/](https://cmake.org/download/) or install a copy through your Visual Studio installer.
1. Install the [Bison Nuget package](https://www.nuget.org/packages/bison/) using the following command: `C:\Tools\nuget install Bison -Version 3.7.4 -OutputDirectory C:\Tools\bison`
        Alternatively download Bison from
        [SourceForge](https://sourceforge.net/projects/winflexbison/files/)
        or [GitHub](https://github.com/lexxmark/winflexbison/releases)
        (Bison 3.7.4 is used in this example) and unpack the ZIP to a folder,
        e.g. `C:\Tools\Bison`
1. Install the [PCRE2 Nuget package](https://www.nuget.org/packages/pcre2/) using the following command: `C:\Tools\nuget install PCRE2 -Version 10.39 -OutputDirectory C:\Tools\pcre2`
        Note this is a x64 static library build; if this is not suitable PCRE2 can be built from source using [https://github.com/PCRE2Project/pcre2](https://github.com/PCRE2Project/pcre2).
        Alternatively, set `WITH_PCRE=OFF` to disable PCRE2 support if you are sure you do not require it.
1. We will also need the SWIG source code. Either download a zipped archive from GitHub, or if git is installed clone the latest codebase
        using: `git clone https://github.com/swig/swig.git`
        In this example we are assuming the source code is available at `C:\swig`
1. Now we have all the required dependencies we can build SWIG using PowerShell and the commands below. We are assuming Visual Studio 2019 or higher is installed and we will be building a 64-bit version of SWIG.
For documentation on specific Visual Studio generators see the associated
[Visual Studio Generators](https://cmake.org/cmake/help/latest/manual/cmake-generators.7.html#visual-studio-generators) documentation.
We add the required build tools to the system `PATH` and then
build a Release version of SWIG. If all runs successfully a new
`swig.exe` should be generated in `C:/swig/install2/bin`.

```powershell

cd C:\swig

$env:PATH="C:\Tools\CMake\CMake-win64.3.15.5\bin;C:\Tools\bison\Bison.3.7.4\bin;" + $env:PATH
$PCRE_ROOT="C:\Tools\pcre2\PCRE2.10.39.0"

# CMAKE_INSTALL_PREFIX: where cmake --install will install SWIG
# PCRE2_ROOT: where PCRE2 is installed
# PCRE2_USE_STATIC_LIBS: ON to search for static PCRE2 libraries
cmake -S . -B build -A x64 `
  -DCMAKE_INSTALL_PREFIX="C:/swig/install2" `
  -DPCRE2_ROOT="$PCRE_ROOT" `
  -DPCRE2_USE_STATIC_LIBS=ON

cmake --build build --config Release
cmake --install build --config Release

# to test that the exe built correctly
cd install2/bin
./swig.exe -version
./swig.exe -help

```

In addition to Release builds you can create a Debug build using:

```powershell
cmake --build build --config Debug
```

A Visual Studio solution file should be generated in `build` named
`swig.sln`. This can be opened and debugged by running the swig
project and setting `Properties> Debugging > Command Arguments`.

For example, to debug one of the test-suite `.i` files included with
the SWIG source use the following:

```powershell
-python -c++ -o C:\Temp\doxygen_parsing.cpp C:\swig\Examples\test-suite\doxygen_parsing.i
```

### <a name="Windows_msys2"></a> 3.3.2 Building swig.exe using MSYS2 and MinGW-w64

Download and install MSYS2 from [www.msys2.org](https://www.msys2.org/) (tested with version msys2-x86_64-20201109).
Launch the MSYS2 shell.

Install the packages needed to build swig:

```powershell

pacman -S git autoconf automake bison gcc make pcre2-devel

```

Clone the repository to /usr/src/:

```powershell

mkdir /usr/src/
cd /usr/src/
git clone https://github.com/swig/swig.git

```

Configure and build:

```powershell

cd /usr/src/swig
./autogen.sh
./configure
make

```

Finally you may also want to install SWIG:

```powershell

make install

```

### <a name="Windows_mingw_msys"></a> 3.3.3 Building swig.exe using MinGW and MSYS

Warning: These instructions were added in 2006 and have barely changed since
so are unlikely to work exactly as written.

The short abbreviated instructions follow...

- Install MinGW and MSYS from the [MinGW](https://osdn.net/projects/mingw/) site. This provides a Unix environment on Windows.
- Follow the usual Unix instructions in the README file in the SWIG root directory to build swig.exe from the MinGW command prompt.

The step by step instructions to download and install MinGW and MSYS, then download and build the latest version of SWIG from Github follow...
Note that the instructions for obtaining SWIG from Github are also online at [SWIG Bleeding Edge](https://www.swig.org/svn.html).

**Pitfall note:**
Execute the steps in the order shown and don't use spaces in path names. In fact it is best to use the default installation directories.

1. Download the following packages from the [MinGW download page](https://osdn.net/projects/mingw/releases/).
  Note that at the time of writing, the majority of these are in the Current
  release list and some are in the Snapshot or Previous release list.
  

- MinGW-3.1.0-1.exe
- MSYS-1.0.11-2004.04.30-1.exe
- msysDTK-1.0.1.exe
- bison-2.0-MSYS.tar.gz
- msys-autoconf-2.59.tar.bz2
- msys-automake-1.8.2.tar.bz2
1. Install MinGW-3.1.0-1.exe (C:\MinGW is default location.)
1. Install MSYS-1.0.11-2004.04.30-1.exe. Make sure you install it on the same
  windows drive letter as MinGW (C:\msys\1.0 is default).
  In the post install script,
  

- Answer y to the "do you wish to continue with the post install?"
- Answer y to the "do you have MinGW installed?"
- Type in the folder in which you installed MinGW (C:/MinGW is default)
1. Install msysDTK-1.0.1.exe to the same folder that you installed MSYS (C:\msys\1.0 is default).
1. Copy the following to the MSYS install folder (C:\msys\1.0 is default):
  

- msys-automake-1.8.2.tar.bz2
- msys-autoconf-2.59.tar.bz2
- bison-2.0-MSYS.tar.gz
1. Start the MSYS command prompt and execute:

```powershell

cd /
tar -jxf msys-automake-1.8.2.tar.bz2
tar -jxf msys-autoconf-2.59.tar.bz2
tar -zxf bison-2.0-MSYS.tar.gz

```
1. The very latest development version of SWIG is available from [SWIG on Github](https://github.com/swig/swig)
  and can be downloaded as a zip file or if you have Git installed, via Git.
  Either download the latest [Zip file](https://github.com/swig/swig/archive/master.zip) snapshot and unzip and rename the top level folder to /usr/src/swig.

  Otherwise if using Git, type in the following:

```powershell

mkdir /usr/src
cd /usr/src
git clone https://github.com/swig/swig.git

```
**Pitfall note:**
If you want to place SWIG in a different folder to the proposed
/usr/src/swig, do not use MSYS emulated windows drive letters, because
the autotools will fail miserably on those.
1. The PCRE2 third party library needs to be built next.
Download the latest PCRE2 source tarball, such as `pcre2-10.39.tar.bz2`, from
[www.pcre.org](https://www.pcre.org) and place in the `/usr/src/swig` directory.
Build PCRE2 as a static library using the Tools/pcre-build.sh script as follows:

```powershell

cd /usr/src/swig
Tools/pcre-build.sh

```
1. You are now ready to build SWIG. Execute the following commands to build swig.exe:

```powershell

cd /usr/src/swig
./autogen.sh
./configure
make

```

### <a name="Windows_cygwin"></a> 3.3.4 Building swig.exe using Cygwin

Note that SWIG can also be built using Cygwin.
However, SWIG will then require the Cygwin DLL when executing. 
Follow the Unix instructions in the README file in the SWIG root directory.
Note that the Cygwin environment will also allow one to regenerate the autotool generated files which are supplied with the release distribution. 
These files are generated using the `autogen.sh` script and will only need regenerating in circumstances such as changing the build system.

#### <a name="Windows_examples_cygwin"></a> 3.3.4.1 Running the examples on Windows using Cygwin

The examples and test-suite work as successfully on Cygwin as on any other Unix operating system. 
The modules which are known to work are Python, Tcl, Perl, Ruby, Java and C#.
Follow the Unix instructions in the README file in the SWIG root directory to build the examples.

## <a name="Windows_interface_file"></a> 3.4 Microsoft extensions and other Windows quirks

### <a name="Windows_msvc_cpp_standards"></a> 3.4.1 Visual C++ standards compliance

The Visual C++ compiler (MSVC) has a long history of not being standards compliant, but this has been getting better
over the years.

SWIG's [approach for C++](SWIGPlus/#SWIGPlus_nn3) is to generate standards compliant C++98 code along with
enhancements for later standards if the C++ compiler supports a later standard.
Unfortunately by default, in 2024, Visual C++ still does not set the `__cplusplus` macro correctly to pick up these later C++ standard features.
MSVC users are urged to ensure this macro is defined correctly by consulting the latest Microsoft Visual C++ documentation, in particular,
[/std](https://learn.microsoft.com/en-us/cpp/build/reference/std-specify-language-standard-version) and 
[/Zc:__cplusplus](https://learn.microsoft.com/en-us/cpp/build/reference/zc-cplusplus).

### <a name="Windows_calling_conventions"></a> 3.4.2 Calling conventions

A common problem when using SWIG on Windows are the Microsoft function calling conventions which are not in the C++ standard.
SWIG parses ISO C/C++ so cannot deal with proprietary conventions such as `__declspec(dllimport)`, `__stdcall` etc.
There is a Windows interface file, `windows.i`, to deal with these calling conventions though.
The file also contains typemaps for handling commonly used Windows specific types such as `__int64`, `BOOL`, `DWORD` etc.
Include it like you would any other interface file, for example:

```swig

%include <windows.i>

__declspec(dllexport) ULONG __stdcall foo(DWORD, __int32);

```

Note that if you follow Microsoft's recommendation of wrapping the
`__declspec` calls in a preprocessor definition, you will need to
make sure that the definition is included by SWIG as well, by either defining it
manually or via a header. For example, if you have specified the
preprocessor definition in a header named `export_lib.h` and include
other headers which depend on it, you should use the `%include` directive
to include the definition explicitly. For example, if you had a header file,
`bar.h`, which depended on `export_lib.h`, your SWIG definition
file might look like:

```swig

// bar.i
%module bar
%include <windows.i>
%include "export_lib.h"
%include "bar.h"

```

where export_lib.h may contain:

```swig

// export_lib.h
#define BAR_API __declspec(dllexport)

```

and bar.h may look like:

```swig

// bar.h
#include "export_lib.h"
BAR_API void bar_function(int, double);

```

Using the preprocessor to remove BAR_API is a popular simpler solution:

```swig

// bar.i
%module bar
#define BAR_API
%include "bar.h"

```
