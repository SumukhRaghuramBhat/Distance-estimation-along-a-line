
#include "ApplicationDefinitions.h"
#include "RssiDemoMessages.h"  


module RssiBaseC {
  uses interface Intercept as RssiMsgIntercept;

#ifdef __CC2420_H__
  uses interface CC2420Packet;
#elif defined(TDA5250_MESSAGE_H)
  uses interface Tda5250Packet;    
#else
  uses interface PacketField<uint8_t> as PacketRSSI;
#endif 
} 

implementation {

  /*//queue buffer to cache serial messages
  message_t serialQueueBuf[SERAIL_QUEUE_LEN];
  message_t* serialQueue[SERAIL_QUEUE_LEN];
  uint8_t queueIn, queueOut;
  bool queueBusy, queueFull;

  */
  uint16_t getRssi(message_t *msg);
  
  event bool RssiMsgIntercept.forward(message_t *msg,
				      void *payload,
				      uint8_t len) {
    RssiMsg *rssiMsg = (RssiMsg*) payload;
    rssiMsg->rssi = getRssi(msg);
    
    return TRUE;
  }

#ifdef __CC2420_H__  
  uint16_t getRssi(message_t *msg){
    return (uint16_t) call CC2420Packet.getRssi(msg);
  }
#elif defined(CC1K_RADIO_MSG_H)
    uint16_t getRssi(message_t *msg){
    cc1000_metadata_t *md =(cc1000_metadata_t*) msg->metadata;
    return md->strength_or_preamble;
  }
#elif defined(PLATFORM_IRIS) || defined(PLATFORM_UCMINI)
  uint16_t getRssi(message_t *msg){
    if(call PacketRSSI.isSet(msg))
      return (uint16_t) call PacketRSSI.get(msg);
    else
      return 0xFFFF;
  }
#elif defined(TDA5250_MESSAGE_H)
   uint16_t getRssi(message_t *msg){
       return call Tda5250Packet.getSnr(msg);
   }
#else
  #error Radio chip not supported! This demo currently works only \
         for motes with CC1000, CC2420, RF230, RFA1 or TDA5250 radios.  
#endif
}
