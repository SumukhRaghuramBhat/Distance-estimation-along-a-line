
#include "AM.h"
#include "Serial.h"
#include "math.h"
#include "printf.h"
#include "float.h"

module BaseStationP @safe() {
  uses {
    interface Boot;
    interface SplitControl as SerialControl;
    interface SplitControl as RadioControl;

    interface AMSend as UartSend[am_id_t id];
    interface Receive as UartReceive[am_id_t id];
    interface Packet as UartPacket;
    interface AMPacket as UartAMPacket;
    
    interface AMSend as RadioSend[am_id_t id];
    interface Receive as RadioReceive[am_id_t id];
    interface Receive as RadioSnoop[am_id_t id];
    interface Packet as RadioPacket;
    interface AMPacket as RadioAMPacket;

    interface Leds;
  }
  
  provides interface Intercept as RadioIntercept[am_id_t amid];
  provides interface Intercept as SerialIntercept[am_id_t amid];
}

implementation
{
  enum {
    UART_QUEUE_LEN = 12,
    RADIO_QUEUE_LEN = 12,
  };

  message_t  uartQueueBufs[UART_QUEUE_LEN];
  message_t  *uartQueue[UART_QUEUE_LEN];
  uint8_t    uartIn, uartOut;
  bool       uartBusy, uartFull;

  message_t  radioQueueBufs[RADIO_QUEUE_LEN];
  message_t  *radioQueue[RADIO_QUEUE_LEN];
  uint8_t    radioIn, radioOut;
  bool       radioBusy, radioFull;

  task void uartSendTask();
  task void radioSendTask();
  double distFromRSSI(int16_t RSSI);

  void dropBlink() {
    call Leds.led2Toggle();
  }

  void failBlink() {
    call Leds.led2Toggle();
  }

  event void Boot.booted() {
    uint8_t i;

    for (i = 0; i < UART_QUEUE_LEN; i++)
      uartQueue[i] = &uartQueueBufs[i];
    uartIn = uartOut = 0;
    uartBusy = FALSE;
    uartFull = TRUE;

    for (i = 0; i < RADIO_QUEUE_LEN; i++)
      radioQueue[i] = &radioQueueBufs[i];
    radioIn = radioOut = 0;
    radioBusy = FALSE;
    radioFull = TRUE;

    call RadioControl.start();
    call SerialControl.start();
  }

  event void RadioControl.startDone(error_t error) {
    if (error == SUCCESS) {
      radioFull = FALSE;
    }
  }

  event void SerialControl.startDone(error_t error) {
    if (error == SUCCESS) {
      uartFull = FALSE;
    }
  }

  event void SerialControl.stopDone(error_t error) {}
  event void RadioControl.stopDone(error_t error) {}

  //globally declared 
  uint8_t count = 0;
  float d1;   //distance1
  float d2;   //distance2
  float errs;  //error
  float mserr;  //mean square erro
  double res;   //rssi to distance converted.

  message_t* receive(message_t* msg, void* payload,
		     uint8_t len, am_id_t id);
  
  event message_t *RadioSnoop.receive[am_id_t id](message_t *msg,
						    void *payload,
						    uint8_t len) {
    return receive(msg, payload, len, id);
  }
  
  event message_t *RadioReceive.receive[am_id_t id](message_t *msg,
						    void *payload,
						    uint8_t len) {
    return receive(msg, payload, len, id);
  }

  message_t* receive(message_t *msg, void *payload, uint8_t len, am_id_t id) {
    

    message_t *ret = msg;

    RssiMsg* pkt;
    if (!signal RadioIntercept.forward[id](msg,payload,len))
      return ret;
    pkt = (RssiMsg*) payload;

    //Distance value sent to dist
    pkt->dist = distFromRSSI(pkt->rssi);
    //printf("Testing dist.. %f %d \n",pkt->dist,pkt->rssi);
    //printfflush();

    //to calculate mse based on the beacon node id
    if(pkt->beacon_id == 1)
    {
        d1=res;
    }
    if(pkt->beacon_id == 2)
    {
        d2=res;
    }


    errs = sqrt(pow((d1),2) + pow((d2),2));
      
    //mean square error
    mserr=(errs/2);

    pkt->mse = mserr;

    //printf("Testing mse  ..%d %d %d\n",(int)pkt->mse,pkt->rssi, (int)res);
    //printfflush();

    atomic {
      if (!uartFull)
	{
	  ret = uartQueue[uartIn];
	  uartQueue[uartIn] = msg;

	  uartIn = (uartIn + 1) % UART_QUEUE_LEN;
	
	  if (uartIn == uartOut)
	    uartFull = TRUE;

	  if (!uartBusy)
	    {
	      post uartSendTask();
	      uartBusy = TRUE;
	    }
	}
      else
	dropBlink();
    }
    
    return ret;
  }

  uint8_t tmpLen;

  //funtion to convert rssi to dist
  double distFromRSSI(int16_t rssi) {

        double p;
        double alpha = 3.52;   //indoor value
        //Formula
        p = (-23-rssi)/(10*alpha);   //-23 for 1m rssi
        res = pow(10, p);

        //printf("dist %f\n",res);
        //printfflush();
        return res;
    }


  task void uartSendTask() {
    uint8_t len;
    am_id_t id;
    am_addr_t addr, src;
    message_t* msg;
    atomic
      if (uartIn == uartOut && !uartFull)
	{
	  uartBusy = FALSE;
	  return;
	}

    msg = uartQueue[uartOut];
    tmpLen = len = call RadioPacket.payloadLength(msg);
    id = call RadioAMPacket.type(msg);
    addr = call RadioAMPacket.destination(msg);
    src = call RadioAMPacket.source(msg);
    call UartAMPacket.setSource(msg, src);

    if (call UartSend.send[id](addr, uartQueue[uartOut], len) == SUCCESS)
      call Leds.led1Toggle();
    else
      {
	failBlink();
	post uartSendTask();
      }
  }

  event void UartSend.sendDone[am_id_t id](message_t* msg, error_t error) {
    if (error != SUCCESS)
      failBlink();
    else
      atomic
	if (msg == uartQueue[uartOut])
	  {
	    if (++uartOut >= UART_QUEUE_LEN)
	      uartOut = 0;
	    if (uartFull)
	      uartFull = FALSE;
	  }
    post uartSendTask();
  }

  event message_t *UartReceive.receive[am_id_t id](message_t *msg,
						   void *payload,
						   uint8_t len) {       
    message_t *ret = msg;
    bool reflectToken = FALSE;

    if (!signal SerialIntercept.forward[id](msg,payload,len))
      return ret;

    atomic
      if (!radioFull)
	{
	  reflectToken = TRUE;
	  ret = radioQueue[radioIn];
	  radioQueue[radioIn] = msg;
	  if (++radioIn >= RADIO_QUEUE_LEN)
	    radioIn = 0;
	  if (radioIn == radioOut)
	    radioFull = TRUE;

	  if (!radioBusy)
	    {
	      post radioSendTask();
	      radioBusy = TRUE;
	    }
	}
      else
	dropBlink();

    if (reflectToken) {
      //call UartTokenReceive.ReflectToken(Token);
    }
    
    return ret;
    
  }

  task void radioSendTask() {
    uint8_t len;
    am_id_t id;
    am_addr_t addr;
    message_t* msg;
    
    atomic
      if (radioIn == radioOut && !radioFull)
	{
	  radioBusy = FALSE;
	  return;
	}

    msg = radioQueue[radioOut];
    len = call UartPacket.payloadLength(msg);
    addr = call UartAMPacket.destination(msg);
    id = call UartAMPacket.type(msg);
    if (call RadioSend.send[id](addr, msg, len) == SUCCESS)
      call Leds.led0Toggle();
    else
      {
	failBlink();
	post radioSendTask();
      }
  }

  event void RadioSend.sendDone[am_id_t id](message_t* msg, error_t error) {
    if (error != SUCCESS)
      failBlink();
    else
      atomic
	if (msg == radioQueue[radioOut])
	  {
	    if (++radioOut >= RADIO_QUEUE_LEN)
	      radioOut = 0;
	    if (radioFull)
	      radioFull = FALSE;
	  }
    
    post radioSendTask();
  }

  default event bool
  RadioIntercept.forward[am_id_t amid](message_t* msg,
				       void* payload,
				       uint8_t len) {
    return TRUE;
  }

  default event bool
  SerialIntercept.forward[am_id_t amid](message_t* msg,
					void* payload,
					uint8_t len) {
    return TRUE;
  }
}  
