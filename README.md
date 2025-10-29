# TCOM-500-UHF-Project

The goal of this project is to capture a RF TV broadcast signal via a software defined radio (SDR), demodulate those samples into an ATSC transport stream with SDR tools, configure TVHeadend on a RasPi to stream the decoded channels as a LAN service, then stream those channels via Wi-Fi using TVHeadend.  This is similar to how most LAN TV SATCOM streaming services are done today (such as Dish).

Major Milestones:

1) Connect SDR and ATSC-tuned antenna to RasPi 5
2) Capture Raw RF TV signal with SDR (~470-700 MHz)
3) Use a Linux SDR such as atsc-demod or GNU Radio to generate an MPEG transport stream
4) Install and configure TVHeadend on the RasPi to be able to accept the data stream
5) Expose the service on a local LAN and validate the playback on another device
6) Note: this must all be containerized and run via docker

Materials needed:
UHF antenna - SMA-W100RX2
SDR - RSPdx-R2
Rasperry Pi 5

