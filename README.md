# UHF SATCOM Streaming over Local Area Network

The goal of this project is to capture a RF TV broadcast signal via a software defined radio (SDR), demodulate those samples into an ATSC transport stream with SDR tools, configure TVHeadend on a RasPi to stream the decoded channels as a LAN service, then stream those channels via Wi-Fi using TVHeadend.  This is similar to how most LAN TV SATCOM streaming services are done today (such as Dish).

End Goal:
Watch a live UHF tv broadcast streamed from a software defined radio (SDR) receiver connected to a raspberry pi serving as a server.

Key Milestones:
1) Use a raspberry pi (in this case a Rasp Pi 5) to act as a local receiver server
2) Configure the software defined radio (in this case a RSPdx-R2) to receive and decode ATSC transport signals over UHF.
   - The goal is to do this in real time, however preliminary research shows that live decoding via GNU radio for extended periods is not feasible.
   - In the event live-streaming cannot be completed, recording of received signal and playback of recording via GNU radio will be attempted instead
3) Stream the received signal from another device on the LAN, such as a laptop or computer

Additional tasks:
1) Creation of block diagram to show connections and data flow - Complete
2) Analysis of work completed to ensure final end goal is achieved (verification and validation)
3) Docker container of code deployed to raspberry pi for SDR and ATSC processing
4) Completed ReadMe

Hardware required:
UHF antenna - SMA-W100RX2
SDR - RSPdx-R2
Rasperry Pi 5

Software required:
- PiOS
- GNU Radio - can be installed with 'sudo apt-get install gnuradio'
- SDRPlay - Optional for testing only, not necessary for final run (and is excluded from the Docker container)
- TVHeadend - Package that can be installed with 'sudo apt-get tvheadend'.  This will prompt for a username and password on first installation
- SDRPlay API - Found here: 
- gr-sdrplay3 - GNU Radio module that enables compatibility between GNU Radio and RSPdx-R2 - Open Source found here: 

Within Docker folder:
- The docker container to build the required software configuration for the Raspberry Pi
- NOTE:  CLAUDE AI WAS USED TO HELP WRITE THE DOCKER CONTAINER AS I AM UNFAMILIAR WITH DOCKER
- NOTE 2: MUST HAVE PiOS5 INSTALLED ALREADY ONTO RASPBERRY PI
- NOTE 3: DO NOT HAVE SDR PLUGGED IN FOR INITIAL BUILD, RADIO MUST BE PLUGGED IN AFTER FINAL BUILD

Within Documents folder:
- Wire diagram showing input stream flow starting from UHF stream
- CSV and Excel Spreadsheet of most recent requirements matrix

Within GNU Radio GRC folder:
- The RSPdx-R2.grc file, which contains the flow graph for the SDR to decode ATSC and stream to a local VLC player
- The fileStream_ATSC.grc file, the flow graph for converting the sample.ts transport stream into a cf32 file for testing
- The cf32_Stream.grc file, which contains the flow graph for converting the cf32 test file into a video stream that mimics the process of the SDR flow graph while using the sample transport stream
