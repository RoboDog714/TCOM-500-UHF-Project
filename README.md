# UHF SATCOM Streaming over Local Area Network

The goal of this project is to capture a RF TV broadcast signal via a software defined radio (SDR), demodulate those samples into an ATSC transport stream with SDR tools, configure TVHeadend on a RasPi to stream the decoded channels as a LAN service, then stream those channels via Wi-Fi using TVHeadend.  This is similar to how most LAN TV SATCOM streaming services are done today (such as Dish).

_End Goal_:
Watch a live UHF tv broadcast streamed from a software defined radio (SDR) receiver connected to a raspberry pi serving as a server.

_Key Milestones_:
1) Use a raspberry pi (in this case a Rasp Pi 5) to act as a local receiver server
2) Configure the software defined radio (in this case a RSPdx-R2) to receive and decode ATSC transport signals over UHF.
   - The goal is to do this in real time, however preliminary research shows that live decoding via GNU radio for extended periods is not feasible.
   - In the event live-streaming cannot be completed, recording of received signal and playback of recording via GNU radio will be attempted instead
3) Stream the received signal from another device on the LAN, such as a laptop or computer

_Additional tasks_:
1) Creation of block diagram to show connections and data flow
2) Analysis of work completed to ensure final end goal is achieved (verification and validation)
3) Docker container of code deployed to raspberry pi for SDR and ATSC processing
4) Completed ReadMe

_Hardware required_:
UHF antenna - SMA-W100RX2
SDR - RSPdx-R2
Rasperry Pi 5 (RP5)
MicroSD card

_Software required_:
- PiOS
- GNU Radio - can be installed with 'sudo apt-get install gnuradio'
- SDRPlay - Optional for testing only, not necessary for final run (and is excluded from the Docker container)
- TVHeadend - Package that can be installed with 'sudo apt-get tvheadend'.  This will prompt for a username and password on first installation
- SDRPlay API - Found here: https://www.sdrplay.com/api
- gr-sdrplay3 - GNU Radio module that enables compatibility between GNU Radio and RSPdx-R2 - Open Source found here: https://github.com/fventuri/gr-sdrplay3
- VLC Media player - pre-installed with PiOS

_Execution_:
The hardware used in this project was acquired from two primary locations:
- HAM Radio Outlet: For RSPdx-R2 and SMA-W100RX2
- Micro Center: RP5, cables, and SD card

After acquiring the hardware, the microSD card was flashed using the default raspberry pi launcher located here: https://www.raspberrypi.com/software/. Since a Raspberry Pi 5 was used, the base Raspberry Pi 5 OS was used and configured accordingly.  This should be done independently for any future users, including username, password, and network information.  SSH was not used for this project, however it could be used based off of individual preference.  If desired, ensure that setting is checked.

An optional step that was performed is the installation of the SDRPlay software on a computer, available for free here: https://www.sdrplay.com/softwarehome/. This software comes preconfigured, primarily to receive radio frequencies. This software was used to gain a base understanding of SDRs and how their settings interact.

Once the software installed, the microSD was inserted into the RP5, which was then connected to power with the recommended 27W power supply.  A keyboard and mouse were connected via usb cable, and a monitor was connected via micro HDMI.  DO NOT PLUG IN THE SOFTWARE DEFINED RADIO AT THIS POINT.

GNU Radio was then installed into the RP5 using 'sudo apt install gnuradio', which downloaded and installed the software.  In order to make GNU Radio compatible with the RSPdx-R2, the SDR API was necessary, and installed from the link above (https://www.sdrplay.com/api). With the API installed, 'gr-sdrplay3', an open source package from fventuri (https://github.com/fventuri/gr-sdrplay3) was installed following the commands included in the repository in order to have the flow block necessary for the SDR to talk to the GNU Radio software.  After navigating to the appropriate folder, they are as follows:
```cd gr-sdrplay3
mkdir build && cd build && cmake .. && make
sudo make install
sudo ldconfig
```

Additionally, TVHeadend was installed using 'sudo apt install tvheadend'.  This prompted the creation of a username and password, which were saved and set aside.  By default, this established tvheadend on port 9981 of the RP5.  On an external device (computer, laptop, etc.), going to <ip_address>:9981 enabled the resolution of the setup of tvheadend. Networks were then selected, including IPTV, which will allow GNU radio or VLC player to forward video to tvheadend.

With all of the software installed, the SDR could now be plugged in.

From this point, GNU Radio was opened, and three separate flow paths were created.  They can be found in the Documents folder.
- The first flow path, 'RSPdx-R2_ATSC', starts with the variable blocks, including a sample rate of 10.776MHz, Center Frequency of 527MHz (based off of highest strength signal in the area, can be adjusted), and RF Gain of 30 dB (recommended).  The flow starts with the SDRplay RSPdx-R2 block to talk to the SDR and includes the sample rate, center frequency, and a bandwidth of 8 MHz.  That then flowed to a GUI Frequency Sink (to view signal in progress) with similar center frequency and bandwidth, and an ATSC receive pipeline, whose input rate is equivalent to the sample rate and had an oversampling ratio of 1.1.
- - Unfortunately, for unknown reasons, I was never able to find out why this ATSC receive pipeline was not outputting any data despite capturing signals.  The only remaining potential possibilities would be either too weak of a signal in my area, requiring more powerful antennas, or some unknown software issue. Upon further testing using additional flow graphs, it is likely due to a software issue.  This block would then flow to a transport stream file sink, another frequency display, and a UDP sink, which was intended to push the data locally for playback.  A port of 7777 was used for this project, however any unused port could theoretically be used.  This flow graph was able to successfully capture ATSC signals over the air, however as mentioned, it could not push the transport stream due to the issue with the ATSC Receive Pipeline.
- The next two, fileStream_ATSC and cf32_Stream, were used for troubleshooting.  fileStream_ATSC would take in a sample transport stream (found here: https://samplelib.com/sample-mp4.html) and convert it into an ATSC modulation in the form of a cf32 file.  This cf32 file would then be passed to the cf32_Stream flow path.  The cf32_Stream flow path mimics the RSPdx-R2_ATSC path in every way except the receiver, instead taking in the cf32 file.  This test file encountered the same problem as the RSPdx-R2_ATSC flow path, leading to the conclusion that there is a software issue

In theory, in both cases, the stream could then be viewed via VLC Media player.  By navigating to 'Media -> Open Network Stream...', the appropriate port could then be set to receive the decoded video.  In this case, UDP://@:7777 was used, which corresponds to the port set asside in RSPdx-R2_ATSC.  If the playback wanted to be viewed locally, play could be hit.  Alternatively, VLC media player could forward the stream to another ip address port or server, including TVHeadend.

Once all of these connections were set up, going back into GNU Radio and the RSPdx-R2_ATSC flow graph allowed for running of the system.  To do this, the 'execute' button was hit, which brought up the two GUIs, where it was revealed that the SDR was able to receive a very weak ATSC signal, however that signal was getting dropped by the ATSC Receiver Pipeline.

To recreate this, the Docker container included in this repo can be cloned onto a RP5 and unpacked, which should install all necessary pieces of software and their dependencies.  IT IS IMPORTANT THAT WHILE THE DOCKER CONTAINER IS DEPLOYED THAT THE SDR IS NOT PLUGGED IN.  ONLY PLUG THE SDR INTO THE RP5 AFTER THE FULL DEPLOYMENT OF THE DOCKER CONTAINER.  The GRC files can be found within the docker container by navigating to ~/workspace/, where the GRC files can be loaded easily. If loading from the docker container, it will be important to ensure the hardware is connected correctly, as the success of this project is wholly reliant upon the connection of the hardware, which is often difficult to achieve with Docker.
- This container is maintained with Continuous Integration


_Within Docker folder_:
- The docker container to build the required software configuration for the Raspberry Pi
- NOTE:  CLAUDE AI WAS USED TO HELP WRITE THE DOCKER CONTAINER AS I AM UNFAMILIAR WITH DOCKER
- NOTE 2: MUST HAVE PiOS5 INSTALLED ALREADY ONTO RASPBERRY PI
- NOTE 3: DO NOT HAVE SDR PLUGGED IN FOR INITIAL BUILD, RADIO MUST BE PLUGGED IN AFTER FINAL BUILD
- NOTE 4: Jsmith212, AN ENGINEER FRIEND OF MINE, ALSO HELPED TEACH ME DOCKER FOR THIS PORTION

_Within Documents folder_:
- Wire diagram showing input stream flow starting from UHF stream
- CSV and Excel Spreadsheet of most recent requirements matrix
- Screenshots of the 3 GNU Radio flow diagrams

_Within GNU Radio GRC folder_:
- The RSPdx-R2.grc file, which contains the flow graph for the SDR to decode ATSC and stream to a local VLC player
- The fileStream_ATSC.grc file, the flow graph for converting the sample.ts transport stream into a cf32 file for testing
- The cf32_Stream.grc file, which contains the flow graph for converting the cf32 test file into a video stream that mimics the process of the SDR flow graph while using the sample transport stream

_References_:
The following sites, tools, and people were also used but not mentioned earlier:
- https://wiki.gnuradio.org/index.php/ATSC (GNU Radio)
- https://pimylifeup.com/raspberry-pi-tvheadend/ (TVHeadend)
- https://coolsdrstuff.blogspot.com/2015/09/watching-atsc-hdtv-on-sdrplay-rsp.html (Overall)
- https://www.site2241.net/may2025.htm (Overall)
- https://www.youtube.com/watch?v=UtLyX72-688 (Raspberry Pi 5 setup)
- https://www.youtube.com/watch?v=Twv4otLohCA (TVHeadend)
- https://www.youtube.com/watch?v=jQGk9dORKrc (GNU Radio)
