

#include "RssiDemoMessages.h"
#include "message.h"

configuration RssiBaseAppC {
} implementation {
  components BaseStationC;
  components RssiBaseC as App;

#ifdef __CC2420_H__
  components CC2420ActiveMessageC;
  App -> CC2420ActiveMessageC.CC2420Packet;
#elif  defined(PLATFORM_IRIS)
  components  RF230ActiveMessageC;
  App -> RF230ActiveMessageC.PacketRSSI;
#elif defined(PLATFORM_UCMINI)
  components  RFA1ActiveMessageC;
  App -> RFA1ActiveMessageC.PacketRSSI;
#elif defined(TDA5250_MESSAGE_H)
  components Tda5250ActiveMessageC;
  App -> Tda5250ActiveMessageC.Tda5250Packet;
#endif
  
  App-> BaseStationC.RadioIntercept[AM_RSSIMSG];
}
