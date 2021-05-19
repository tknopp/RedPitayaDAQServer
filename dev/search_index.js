var documenterSearchIndex = {"docs":
[{"location":"connections.html#Connections","page":"Connections","title":"Connections","text":"","category":"section"},{"location":"connections.html","page":"Connections","title":"Connections","text":"An overview of the extension connectors (see also here) is given in the following image","category":"page"},{"location":"connections.html","page":"Connections","title":"Connections","text":"(Image: Connectors)","category":"page"},{"location":"connections.html","page":"Connections","title":"Connections","text":"The project uses most but not all connections that are used in the original RedPitaya image. From the connector E2 only the analog inputs and outputs are used. From the connector E1 several pins are reserved for the following purposes:","category":"page"},{"location":"connections.html","page":"Connections","title":"Connections","text":"DIO0_P for the ADC and DAC trigger. Connect it with the master's DIO5_P to distribute the trigger signal to all RPs including the master. As long as the input is high, the DACs and ADCs are running.\nDIO1_P is the input for the watchdog (see configuration register section for further details)\nDIO2_P is used to acknowledge a received watchdog signal.\nDIO3_P can be set to high, to stop all DACs instantly.\nDIO4_P outputs a high for 10 ms after a 100 ms pause on low to provide an alive signal.\nDIO5_P can be set to high via the configuration register to provide the mutual trigger signal.\nDIO7_P, DIO7_N, DIO6_P, DIO6_N, DIO5_N, DIO4_N, DIO3_N, DIO2_N can be used as arbitrary outputs set via the server.","category":"page"},{"location":"installation.html#Installation","page":"Installation","title":"Installation","text":"","category":"section"},{"location":"installation.html#Alpine-Linux-Image","page":"Installation","title":"Alpine Linux Image","text":"","category":"section"},{"location":"installation.html","page":"Installation","title":"Installation","text":"The RedPitayaDAQServer project uses a custom RedPitaya image that was derived from the red-pitaya-notes project. It consists of an Alpine Linux with some development tools installed. Additionally the image reserves the upper 128 MB of main memory for the FPGA, which is used as a buffer for recording the data from the fast ADCs. The linux image can be downloaded here. Just unzip the zip file and copy the content on an empty SD card that is formatted in FAT32. When you insert the SD card into the RedPitaya you should see a blinking LED.","category":"page"},{"location":"installation.html#Setting-Up-the-Server","page":"Installation","title":"Setting Up the Server","text":"","category":"section"},{"location":"installation.html","page":"Installation","title":"Installation","text":"Next you need to install the server application. To this end, connect the RedPitaya to you local network and access the device via ssh:","category":"page"},{"location":"installation.html","page":"Installation","title":"Installation","text":"ssh root@rp-f?????.local","category":"page"},{"location":"installation.html","page":"Installation","title":"Installation","text":"where ????? is the ID that is printed on the RedPitaya. The default password is root. After logging into the RedPitaya go to the folder","category":"page"},{"location":"installation.html","page":"Installation","title":"Installation","text":"/root/apps/","category":"page"},{"location":"installation.html","page":"Installation","title":"Installation","text":"and clone the RedPitayaDAQServer project:","category":"page"},{"location":"installation.html","page":"Installation","title":"Installation","text":"git clone https://github.com/tknopp/RedPitayaDAQServer","category":"page"},{"location":"installation.html","page":"Installation","title":"Installation","text":"Sometimes you might need to make the file system writable by entering","category":"page"},{"location":"installation.html","page":"Installation","title":"Installation","text":"mount -o remount,rw /dev/mmcblk0p1","category":"page"},{"location":"installation.html","page":"Installation","title":"Installation","text":"Then cd into RedPitayaDAQServer","category":"page"},{"location":"installation.html","page":"Installation","title":"Installation","text":"cd /root/apps/RedPitayaDAQServer","category":"page"},{"location":"installation.html","page":"Installation","title":"Installation","text":"and enter make. This will compile the library, the server, and some example applications. After you restart the RedPitaya the DAQ server will automatically run and you can access it via TCP.","category":"page"},{"location":"installation.html#Setting-Up-the-Client","page":"Installation","title":"Setting Up the Client","text":"","category":"section"},{"location":"installation.html","page":"Installation","title":"Installation","text":"Depending on the client library you are using you need to install them differently","category":"page"},{"location":"installation.html#Julia","page":"Installation","title":"Julia","text":"","category":"section"},{"location":"installation.html","page":"Installation","title":"Installation","text":"For the Julia client library you need to install RedPitayaDAQServer within Julia. To this end download Julia 1.5 or later and go into the package manager mode by intering ]. Then there are three options to install the client library.","category":"page"},{"location":"installation.html","page":"Installation","title":"Installation","text":"add RedPitayaDAQServer:src/client/julia\ndev RedPitayaDAQServer:src/client/julia","category":"page"},{"location":"installation.html","page":"Installation","title":"Installation","text":"The first is installing the currently published version. The second is installing in development mode and put the files to ~/dev/RedPitayaDAQServer/ where you can the also modify the files, which is handy when trying out the examples. Right now we recommend to dev the package. You need to git pull from ~/dev/RedPitayaDAQServer/ if you want to get updates, i.e. Julia will not update  developed packages automatically.","category":"page"},{"location":"installation.html#Matlab","page":"Installation","title":"Matlab","text":"","category":"section"},{"location":"installation.html","page":"Installation","title":"Installation","text":"TODO","category":"page"},{"location":"installation.html#Python","page":"Installation","title":"Python","text":"","category":"section"},{"location":"installation.html","page":"Installation","title":"Installation","text":"TODO","category":"page"},{"location":"examples/waveforms.html#Waveforms-Example","page":"Waveforms","title":"Waveforms Example","text":"","category":"section"},{"location":"examples/waveforms.html","page":"Waveforms","title":"Waveforms","text":"In this example we generate different signals with a base frequency of 10 kHz on fast DAC channel 1 and receive the same signals on the fast ADC. To run this example connect the RedPitaya in the following way.","category":"page"},{"location":"examples/waveforms.html","page":"Waveforms","title":"Waveforms","text":"(Image: Cluster)","category":"page"},{"location":"examples/waveforms.html#Julia-Client","page":"Waveforms","title":"Julia Client","text":"","category":"section"},{"location":"examples/waveforms.html","page":"Waveforms","title":"Waveforms","text":"This and all other examples are located in the examples directory","category":"page"},{"location":"examples/waveforms.html","page":"Waveforms","title":"Waveforms","text":"# Adapted from https://github.com/JuliaDocs/Documenter.jl/issues/499\nusing Markdown\nMarkdown.parse(\"\"\"\n```julia\n$(open(f->read(f, String), \"../../../src/examples/julia/waveforms.jl\"))\n```\n\"\"\")","category":"page"},{"location":"examples/waveforms.html","page":"Waveforms","title":"Waveforms","text":"(Image: Simple Example Results)","category":"page"},{"location":"examples/simple.html#Simple-Example","page":"Simple","title":"Simple Example","text":"","category":"section"},{"location":"examples/simple.html","page":"Simple","title":"Simple","text":"In the first example we generate a sinus signal of frequency 10 kHz on fast DAC channel 1 and receive the same signal on the fast ADC. To run this example connect the RedPitaya in the following way.","category":"page"},{"location":"examples/simple.html","page":"Simple","title":"Simple","text":"(Image: Cluster)","category":"page"},{"location":"examples/simple.html#Julia-Client","page":"Simple","title":"Julia Client","text":"","category":"section"},{"location":"examples/simple.html","page":"Simple","title":"Simple","text":"This and all other examples are located in the examples directory","category":"page"},{"location":"examples/simple.html","page":"Simple","title":"Simple","text":"# Adapted from https://github.com/JuliaDocs/Documenter.jl/issues/499\nusing Markdown\nMarkdown.parse(\"\"\"\n```julia\n$(open(f->read(f, String), \"../../../src/examples/julia/simple.jl\"))\n```\n\"\"\")","category":"page"},{"location":"examples/simple.html","page":"Simple","title":"Simple","text":"(Image: Simple Example Results)","category":"page"},{"location":"architecture.html#Architecture","page":"Architecture","title":"Architecture","text":"","category":"section"},{"location":"architecture.html","page":"Architecture","title":"Architecture","text":"The RedPitayaDAQServer project has an architecture where the following three parts are communicating through different interfaces:","category":"page"},{"location":"architecture.html","page":"Architecture","title":"Architecture","text":"FPGA on the RedPitaya\nServer running on the CPU of the RedPitaya\nClient on the host computer ","category":"page"},{"location":"architecture.html#FPGA/Server-Interface","page":"Architecture","title":"FPGA/Server Interface","text":"","category":"section"},{"location":"architecture.html","page":"Architecture","title":"Architecture","text":"The FPGA image is directly connected to certain memory regions that can be memory mapped on the CPU of the RedPitaya. The C library rp-daq-lib located in src/lib/ encapsulates these memory accessed into a convenient C library. It is possible to use this C library directly when no communication with the host system is required, i.e. if one wants to write the acquired data into a file. When making changes to the FPGA image one may need to adapt the rp-daq-lib C library.","category":"page"},{"location":"architecture.html#Client/Server-Interface","page":"Architecture","title":"Client/Server Interface","text":"","category":"section"},{"location":"architecture.html","page":"Architecture","title":"Architecture","text":"The DAQ server uses the rp-daq-lib C library and allows to access its functions via TCP/IP. The server has three main purposes:","category":"page"},{"location":"architecture.html","page":"Architecture","title":"Architecture","text":"It translates from TCP commands to C commands\nIt sends the data acquired with the fast ADCs to the client. Not all data is send but only the data requested by the client\nIt maintains a controller thread for feeding the slow DACs in a fully synchronized fashion.","category":"page"},{"location":"architecture.html#Application/Client-Interface","page":"Architecture","title":"Application/Client Interface","text":"","category":"section"},{"location":"architecture.html","page":"Architecture","title":"Architecture","text":"In principle it is possible to write the client in any programming language. The RedPitayaDAQServer offers a simple client implemented in Python and a more sophisticated client implemented in Julia.","category":"page"},{"location":"fpga.html#FPGA-Development","page":"FPGA Development","title":"FPGA Development","text":"","category":"section"},{"location":"fpga.html","page":"FPGA Development","title":"FPGA Development","text":"There may be needs to change the FPGA image. The following explains how this can be done.","category":"page"},{"location":"fpga.html#Preparation","page":"FPGA Development","title":"Preparation","text":"","category":"section"},{"location":"fpga.html","page":"FPGA Development","title":"FPGA Development","text":"If you want to make changes to the FPGA design, you need to install Vivado 2017.2. More infos for setting up a development machine we refer to the following recource.","category":"page"},{"location":"fpga.html","page":"FPGA Development","title":"FPGA Development","text":"After following the installation steps, you need to clone the repository into a directory of your choice and then regenerate the IP cores  and the project by running","category":"page"},{"location":"fpga.html","page":"FPGA Development","title":"FPGA Development","text":"./make_fpga_project.sh.","category":"page"},{"location":"fpga.html","page":"FPGA Development","title":"FPGA Development","text":"Afterwards you can start Vivado and open the recreated project in ./build/fpga/firmware/RedPitayaDAQServer.xpr. Apply the changes you need and then create the bitfile by using 'Flow -> Generate Bitstream'. This runs the synthesis and implementation steps and output the Bitfile to ./build/fpga/firmware/RedPitayaDAQServer.runs/impl_1/system_wrapper.bit. Please note, that you have to create both the master and the slave image. This can be done by simply changing the value of xlconstantmasterslave_. A '1' denotes the use of the internal ADC clock and is used for the master. A '0' selects the clock distributed via the daisy chain connectors and is therefore used for the slaves.","category":"page"},{"location":"fpga.html","page":"FPGA Development","title":"FPGA Development","text":"(Image: Clock selection in the blockdesign)","category":"page"},{"location":"fpga.html","page":"FPGA Development","title":"FPGA Development","text":"After creating the respective bitfile you need to copy it to your Red Pitayas. You can use","category":"page"},{"location":"fpga.html","page":"FPGA Development","title":"FPGA Development","text":"scp ./build/fpga/firmware/RedPitayaDAQServer.runs/impl_1/system_wrapper.bin root@<IP>:/root/RedPitayaDAQServer/bitfiles/<master,slave>.bin","category":"page"},{"location":"fpga.html","page":"FPGA Development","title":"FPGA Development","text":"for this. Set your IP and master/slave accordingly.","category":"page"},{"location":"fpga.html","page":"FPGA Development","title":"FPGA Development","text":"Since using git with Vivado can be annoying here are some hints how you can make your changes ready for git:","category":"page"},{"location":"fpga.html","page":"FPGA Development","title":"FPGA Development","text":"If you only changed some stuff in the blockdesign, you just have to export the blockdesign to ./src/fpga/bd by using 'File -> Export -> Export Block Design' in Vivado.\nChanges to the project settings have to be done in ./src/fpga/build.tcl in order to not lose the ability to recreate your changed project.\nFor your own IP cores, just create a new directory in ./src/fpga/cores and copy and adapt the core_config.tcl of another core. Afterwards re-run make_cores.tcl.","category":"page"},{"location":"cluster.html#Cluster","page":"Cluster","title":"Cluster","text":"","category":"section"},{"location":"cluster.html","page":"Cluster","title":"Cluster","text":"The RedPitayaDAQServer allows to use multiple RedPitayas in a fully synchronized fashion. One of the RedPitayas will act as the master and distribute its clock to all other RedPitayas acting as slaves.","category":"page"},{"location":"cluster.html#Prerequisites","page":"Cluster","title":"Prerequisites","text":"","category":"section"},{"location":"cluster.html","page":"Cluster","title":"Cluster","text":"Unfortunately, the STEMlab 125-4 does not allow cluster synchronization without hardware modifications.   It is therefore necessary to resolder all slaves according to this documentation. The required mode for this project is 'Directly from FPGA'. The heatsink has to be removed temporarily in order to unsolder the two resistor below it. In the following image you can see the new position of the 0 Ohm 0402 resistors. Since they get lost easily, make sure you have some in stock.","category":"page"},{"location":"cluster.html","page":"Cluster","title":"Cluster","text":"(Image: Cluster)","category":"page"},{"location":"cluster.html#Connections","page":"Cluster","title":"Connections","text":"","category":"section"},{"location":"cluster.html","page":"Cluster","title":"Cluster","text":"To run a cluster of RedPitayas one needs to connect the devices using different cables. An exemplary cluster with 3 devices is shown in the following image.","category":"page"},{"location":"cluster.html","page":"Cluster","title":"Cluster","text":"(Image: Cluster)","category":"page"},{"location":"cluster.html","page":"Cluster","title":"Cluster","text":"The clock is distributed from the master to the first slave via an SATA cable (green). Additional slaves can be used by connecting the next slave to the previous one. Additionally all slaves have connection from +3.3 Volt to DIO0_N.","category":"page"},{"location":"cluster.html","page":"Cluster","title":"Cluster","text":"In order to send a mutual trigger signal for starting the acquisition and the signal generation, you also have to connect the master's DIO5_P pin (see link) with the DIO0_P pin of all devices including the master.","category":"page"},{"location":"client.html#Client","page":"Client","title":"Client","text":"","category":"section"},{"location":"scpi.html#SCPI-Interface","page":"SCPI Interface","title":"SCPI Interface","text":"","category":"section"},{"location":"scpi.html","page":"SCPI Interface","title":"SCPI Interface","text":"For communication betten the server and the client an SCPI with custom commands is used. The following table gives an overview of all commands:","category":"page"},{"location":"scpi.html#DIO","page":"SCPI Interface","title":"DIO","text":"","category":"section"},{"location":"scpi.html","page":"SCPI Interface","title":"SCPI Interface","text":"Command Arguments Description Example\nRP:DIO:DIR identifier of pin, direction (IN/OUT) Set the direction of the DIO RP:DIO:DIR DIO7_P,IN\nRP:DIO identifier of pin, value (0/1) Set the output of the DIO RP:DIO DIO7_P,1\nRP:DIO? identifier of pin Get the input of the DIO RP:DIO? DIO7_P","category":"page"},{"location":"scpi.html#Fast-ADC","page":"SCPI Interface","title":"Fast ADC","text":"","category":"section"},{"location":"scpi.html","page":"SCPI Interface","title":"SCPI Interface","text":"Command Arguments Description Example\nRP:ADC:SlowADC   \nRP:ADC:SlowADC?   \nRP:ADC:DECimation   \nRP:ADC:DECimation?   \nRP:ADC:PERiod   \nRP:ADC:PERiod?   \nRP:ADC:PERiods:CURRent   \nRP:ADC:PERiods:DATa   \nRP:ADC:FRAme   \nRP:ADC:FRAme?   \nRP:ADC:FRAmes:CURRent?   \nRP:ADC:WP:CURRent?   \nRP:ADC:FRAmes:DATa   \nRP:ADC:BUFfer:Size?   \nRP:ADC:Slow:FRAmes:DATa   \nRP:ADC:ACQCONNect   \nRP:ADC:ACQSTATus   \nRP:ADC:ACQSTATus?   ","category":"page"},{"location":"scpi.html#DAC-and-Sequences","page":"SCPI Interface","title":"DAC and Sequences","text":"","category":"section"},{"location":"scpi.html","page":"SCPI Interface","title":"SCPI Interface","text":"Command Arguments Description Example\nRP:DAC:CHannel#:COMPonent#:AMPlitude?   \nRP:DAC:CHannel#:COMPonent#:AMPlitude   \nRP:DAC:CHannel#:COMPonent#:Next:AMPlitude?   \nRP:DAC:CHannel#:COMPonent#:Next:AMPlitude   \nRP:DAC:CHannel#:COMPonent#:FREQuency?   \nRP:DAC:CHannel#:COMPonent#:FREQuency   \nRP:DAC:CHannel#:COMPonent#:PHase?   \nRP:DAC:CHannel#:COMPonent#:PHase   \nRP:DAC:CHannel#:OFFset?   \nRP:DAC:CHannel#:OFFset   \nRP:DAC:MODe   \nRP:DAC:MODe?   \nRP:DAC:CHannel#:SIGnaltype signaltype (SINE / SQUARE / TRIANGLE / SAWTOOTH) set the signal type RP:DAC:CH0:SIG SINE\nRP:DAC:CHannel#:SIGnaltype?   \nRP:DAC:CHannel#:JumpSharpness   \nRP:DAC:CHannel#:JumpSharpness?   \nRP:ADC:SlowDAC   \nRP:ADC:SlowDAC?   \nRP:ADC:SlowDACLUT   \nRP:ADC:SlowDACEnable   \nRP:ADC:SlowDACLostSteps?   \nRP:ADC:SlowDACPeriodsPerFrame   \nRP:ADC:SlowDACPeriodsPerFrame?   \nRP:PDM:ClockDivider   \nRP:PDM:ClockDivider?   \nRP:PDM:CHannel#:NextValue   \nRP:PDM:CHannel#:NextValueVolt   \nRP:PDM:CHannel#:NextValue?   ","category":"page"},{"location":"scpi.html#Misc","page":"SCPI Interface","title":"Misc","text":"","category":"section"},{"location":"scpi.html","page":"SCPI Interface","title":"SCPI Interface","text":"Command Arguments Description Example\nRP:XADC:CHannel#?   \nRP:WatchDogMode   \nRP:WatchDogMode?   \nRP:RamWriterMode   \nRP:RamWriterMode?   \nRP:PassPDMToFastDAC   \nRP:PassPDMToFastDAC?   \nRP:KeepAliveReset   \nRP:KeepAliveReset?   \nRP:Trigger:MODe   \nRP:Trigger:MODe?   \nRP:MasterTrigger   \nRP:InstantResetMode   \nRP:InstantResetMode?   \nRP:PeripheralAResetN?   \nRP:FourierSynthAResetN?   \nRP:PDMAResetN?   \nRP:XADCAResetN?   \nRP:TriggerStatus?   \nRP:WatchdogStatus?   \nRP:InstantResetStatus?   ","category":"page"},{"location":"devtips.html#Development-Tips","page":"Development Tips","title":"Development Tips","text":"","category":"section"},{"location":"devtips.html","page":"Development Tips","title":"Development Tips","text":"On this slide some development hints are summarized. These might change regularely if things are properly integrated into the framework.","category":"page"},{"location":"devtips.html#Alpine-Linux","page":"Development Tips","title":"Alpine Linux","text":"","category":"section"},{"location":"devtips.html","page":"Development Tips","title":"Development Tips","text":"The Alpine linux as currently a root folder with only 185.8M free space, which disallows installing more","category":"page"},{"location":"devtips.html","page":"Development Tips","title":"Development Tips","text":"applications. To change this one can do","category":"page"},{"location":"devtips.html","page":"Development Tips","title":"Development Tips","text":"mount -o remount,size=1G /","category":"page"},{"location":"devtips.html","page":"Development Tips","title":"Development Tips","text":"Right now no debugger is installed. This can be change after increasing / using:","category":"page"},{"location":"devtips.html","page":"Development Tips","title":"Development Tips","text":"apk add gdb","category":"page"},{"location":"index.html#RedPitayaDAQServer","page":"Home","title":"RedPitayaDAQServer","text":"","category":"section"},{"location":"index.html","page":"Home","title":"Home","text":"Advanced DAQ Tools for the RedPitaya (STEMlab 125-14)","category":"page"},{"location":"index.html#Introduction","page":"Home","title":"Introduction","text":"","category":"section"},{"location":"index.html","page":"Home","title":"Home","text":"This project contains software to be used with the STEMlab 125-14 device from RedPitaya. It allows for continuous generation and measurement of signals with up to 15.625 MS/s, which is not possible with the standard image of the RedPitaya. In addition, the software allows to synchronize a cluster of multiple RedPitayas. This project contains the following parts:","category":"page"},{"location":"index.html","page":"Home","title":"Home","text":"Alpine Linux image for the RedPitaya\nFPGA image\nClient library (implemented in C) that can be used on the RedPitaya\nSCPI Server for accessing the functionality over TCP/IP\nSCPI Clients to access the server","category":"page"},{"location":"index.html","page":"Home","title":"Home","text":"The code repositories is contained in this repository.","category":"page"},{"location":"index.html#License-/-Terms-of-Usage","page":"Home","title":"License / Terms of Usage","text":"","category":"section"},{"location":"index.html","page":"Home","title":"Home","text":"The source code of this project is licensed under the MIT license. This implies that you are free to use, share, and adapt it. However, please give appropriate credit by citing the project.","category":"page"},{"location":"index.html#Contact","page":"Home","title":"Contact","text":"","category":"section"},{"location":"index.html","page":"Home","title":"Home","text":"If you have problems using the software, find mistakes, or have general questions please use the issue tracker to contact us.","category":"page"},{"location":"index.html#Contributors","page":"Home","title":"Contributors","text":"","category":"section"},{"location":"index.html","page":"Home","title":"Home","text":"Tobias Knopp\nJonas Schumacher\nMatthias Gräser","category":"page"},{"location":"index.html#Credit","page":"Home","title":"Credit","text":"","category":"section"},{"location":"index.html","page":"Home","title":"Home","text":"This package is partly based on work of Koheron [1] and Pavel Demin [2]","category":"page"},{"location":"index.html","page":"Home","title":"Home","text":"[1] https://www.koheron.com/blog/2016/11/29/red-pitaya-cluster [2] https://github.com/pavel-demin/red-pitaya-notes","category":"page"}]
}
